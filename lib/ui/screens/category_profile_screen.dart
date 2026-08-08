import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../state/auth_state.dart';
import '../../state/feed_state.dart';
import '../../data/models/domain_models.dart';
import '../widgets/post_card.dart';

class CategoryProfileScreen extends StatelessWidget {
  final String? industry;
  final String? companySize;
  final String? companyType;
  final String? locationRegion;

  const CategoryProfileScreen({
    super.key,
    this.industry,
    this.companySize,
    this.companyType,
    this.locationRegion,
  });

  String _getProfileTitle() {
    final parts = <String>[];
    if (industry != null) parts.add(industry!);
    if (companySize != null) parts.add(companySize!);
    if (companyType != null) parts.add(companyType!);
    if (locationRegion != null) parts.add(locationRegion!);
    
    if (parts.isEmpty) return 'General Workplace Profile';
    return parts.join(' • ');
  }

  String _serializeCategory() {
    final params = <String>[];
    if (industry != null) params.add('industry=${Uri.encodeComponent(industry!)}');
    if (companySize != null) params.add('companySize=${Uri.encodeComponent(companySize!)}');
    if (companyType != null) params.add('companyType=${Uri.encodeComponent(companyType!)}');
    if (locationRegion != null) params.add('locationRegion=${Uri.encodeComponent(locationRegion!)}');
    return params.join('&');
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthState>();
    final feedState = context.watch<FeedState>();
    
    final metrics = feedState.getCategoryMetrics(
      industry: industry,
      companySize: companySize,
      companyType: companyType,
      locationRegion: locationRegion,
    );

    final title = _getProfileTitle();
    final serializedCat = _serializeCategory();
    final isBookmarked = feedState.isBookmarked(BookmarkTargetType.category, serializedCat);

    // Filter matching posts for the feed list
    final matchingPosts = feedState.getRecentPosts(
      filterIndustry: industry,
      filterCompanySize: companySize,
      filterCompanyType: companyType,
      filterRegion: locationRegion,
    );

    final int totalCount = metrics['totalCount'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workplace Profile'),
        actions: [
          // Save category profile
          IconButton(
            icon: Icon(
              isBookmarked ? Icons.bookmark : Icons.bookmark_border_outlined,
              color: isBookmarked ? Theme.of(context).colorScheme.primary : null,
            ),
            onPressed: () {
              if (!authState.isAuthenticated) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Please sign in to bookmark this category.'),
                    action: SnackBarAction(
                      label: 'Sign In',
                      onPressed: () => context.push('/login'),
                    ),
                  ),
                );
              } else {
                feedState.toggleBookmark(
                  authState.currentUser!.id,
                  BookmarkTargetType.category,
                  serializedCat,
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile Header Card
            Container(
              padding: const EdgeInsets.all(20),
              color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.08),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$totalCount anonymous workplace stories contributed',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                    ),
                  ),
                  if (totalCount > 0) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          (metrics['overall'] as double).toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: List.generate(5, (index) {
                                final isHalf = (metrics['overall'] as double) - index >= 0.5 && (metrics['overall'] as double) - index < 1.0;
                                final isFull = (metrics['overall'] as double) - index >= 1.0;
                                return Icon(
                                  isFull ? Icons.star : (isHalf ? Icons.star_half : Icons.star_border),
                                  size: 16,
                                  color: Colors.amber,
                                );
                              }),
                            ),
                            const Text(
                              'Overall Rating',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            if (totalCount == 0)
              _buildEmptyState(context)
            else ...[
              // Score breakdown section
              _buildSectionTitle(context, 'Category Ratings Breakdown'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildRatingRow(context, 'Culture & Values', metrics['culture']),
                    _buildRatingRow(context, 'Management quality', metrics['management']),
                    _buildRatingRow(context, 'Compensation & Benefits', metrics['compensation']),
                    _buildRatingRow(context, 'Growth & Development', metrics['growth']),
                    _buildRatingRow(context, 'Work-Life Balance', metrics['workLife']),
                  ],
                ),
              ),

              const Divider(height: 32),

              // Why people leave chart section
              _buildSectionTitle(context, 'Why People Leave'),
              _buildLeaveBreakdown(context, metrics['whyPeopleLeave']),

              const Divider(height: 32),

              // Flag metrics section
              _buildSectionTitle(context, 'Common Community Signals'),
              _buildFlagsBreakdown(context, metrics['redFlags'], metrics['greenFlags']),

              const Divider(height: 32),

              // Posts feed list
              _buildSectionTitle(context, 'Workplace Stories in this Category'),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: matchingPosts.length,
                itemBuilder: (context, index) {
                  return PostCard(post: matchingPosts[index]);
                },
              ),
              const SizedBox(height: 32),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.query_stats_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'Be the first to share!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'No workplace stories have been shared in this specific category configuration yet.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go('/create'),
            icon: const Icon(Icons.add),
            label: const Text('Post Anonymous Experience'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildRatingRow(BuildContext context, String name, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              name,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            flex: 5,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value / 5.0,
                minHeight: 8,
                backgroundColor: Theme.of(context).dividerColor.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation<Color>(
                  value >= 3.5 ? Colors.green : (value >= 2.2 ? Colors.amber : Colors.red),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 24,
            child: Text(
              value.toStringAsFixed(1),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveBreakdown(BuildContext context, Map<String, int> leaveMap) {
    if (leaveMap.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Text('No reasons reported yet.', style: TextStyle(color: Colors.grey, fontSize: 12)),
      );
    }

    final sortedList = leaveMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final int maxVal = sortedList.isNotEmpty ? sortedList[0].value : 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: sortedList.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(entry.key, style: const TextStyle(fontSize: 12)),
                ),
                Expanded(
                  flex: 5,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: entry.value / maxVal,
                      minHeight: 10,
                      backgroundColor: Theme.of(context).dividerColor.withValues(alpha: 0.08),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 24,
                  child: Text(
                    '${entry.value}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFlagsBreakdown(BuildContext context, Map<String, int> redMap, Map<String, int> greenMap) {
    if (redMap.isEmpty && greenMap.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Text('No signals reported yet.', style: TextStyle(color: Colors.grey, fontSize: 12)),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (greenMap.isNotEmpty) ...[
            const Text(
              '🟢 Green Flags (Positive Signs)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: greenMap.entries.map((e) {
                return Chip(
                  avatar: const Icon(Icons.check, size: 12, color: Colors.teal),
                  label: Text('${e.key} (${e.value})'),
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
          if (redMap.isNotEmpty) ...[
            const Text(
              '🚩 Red Flags (Warning Signs)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: redMap.entries.map((e) {
                return Chip(
                  avatar: const Icon(Icons.warning, size: 12, color: Colors.red),
                  label: Text('${e.key} (${e.value})'),
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
