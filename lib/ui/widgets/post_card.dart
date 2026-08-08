import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../data/models/domain_models.dart';
import '../../state/auth_state.dart';
import '../../state/feed_state.dart';

class PostCard extends StatelessWidget {
  final Post post;

  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthState>();
    final feedState = context.watch<FeedState>();
    final exp = post.experience;

    // Check if bookmarked
    final bookmarked = feedState.isBookmarked(BookmarkTargetType.post, post.id);

    // Determine current user's reaction
    ReactionType? activeReaction;
    if (authState.isAuthenticated) {
      final userReacts = feedState.userReactions.where((r) => r.postId == post.id);
      if (userReacts.isNotEmpty) {
        activeReaction = userReacts.first.type;
      }
    }

    // Avatar config
    final isCurrent = exp?.employmentStatus == 'current';
    final avatarBgColor = isCurrent ? const Color(0xFFD0F2E6) : const Color(0xFFF3D8C8);
    final avatarTextColor = isCurrent ? const Color(0xFF0F5A47) : const Color(0xFFC05C3E);
    
    final avatarInitials = post.authorPseudonym.length >= 2 
        ? post.authorPseudonym.substring(0, 2) 
        : post.authorPseudonym;

    // Experience ratings classification badge
    String experienceClass = 'Mixed experience';
    Color classBg = const Color(0xFFF1EDE8);
    Color classText = const Color(0xFF6A6661);
    
    if (exp != null) {
      if (exp.overallRating >= 3.5) {
        experienceClass = 'Positive experience';
        classBg = const Color(0xFFFDECE7); // Light pinkish-orange
        classText = const Color(0xFFC05C3E); // Terracotta
      } else if (exp.overallRating <= 2.2) {
        experienceClass = 'Negative experience';
        classBg = const Color(0xFFFCE8E6); // Light red
        classText = const Color(0xFFC93B2B);
      }
    }

    // Calculate reading time
    final wordCount = post.body.split(' ').length;
    final readTime = (wordCount / 100).ceil();
    final readTimeStr = '$readTime min read';

    return InkWell(
      onTap: () => context.push('/posts/${post.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Header information
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Initials Avatar
                CircleAvatar(
                  radius: 18,
                  backgroundColor: avatarBgColor,
                  child: Text(
                    avatarInitials,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: avatarTextColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Name & Context lines
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            post.authorPseudonym,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Theme.of(context).textTheme.titleLarge?.color,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified,
                            size: 14,
                            color: Color(0xFF0F5A47), // Green check color
                          ),
                        ],
                      ),
                      if (exp != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${exp.role} · ${exp.experienceDuration} · ${exp.employmentStatus == 'current' ? 'Current employee' : 'Former employee'}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF6A6661),
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '${exp.companyType} ${exp.companySize}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF6A6661),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Timestamp & more horizontal menu icon
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatDate(post.createdAt),
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF6A6661),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Icon(
                      Icons.more_horiz,
                      size: 18,
                      color: Color(0xFF6A6661),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Row 2: Title
            Text(
              post.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.titleLarge?.color,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 8),

            // Row 3: Body Snippet
            Text(
              post.body.length > 200 ? '${post.body.substring(0, 200)}...' : post.body,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.45,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            const SizedBox(height: 14),

            // Row 4: Tag chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Experience classification chip (Positive/Negative/Mixed)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: classBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    experienceClass,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: classText,
                    ),
                  ),
                ),
                
                // Context / tag chips
                if (exp != null) ...[
                  _buildTagChip(exp.industry),
                  if (exp.reasonTags.isNotEmpty)
                    _buildTagChip(exp.reasonTags.first),
                ],
                
                // Reading duration chip
                _buildTagChip(readTimeStr),
              ],
            ),
            const SizedBox(height: 16),

            // Row 5: Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Reaction Buttons
                Wrap(
                  spacing: 12,
                  children: [
                    _buildFlatReaction(
                      context,
                      ReactionType.relatable,
                      Icons.favorite_border,
                      Icons.favorite,
                      Colors.red,
                      post.reactionsCount['relatable'] ?? 0,
                      activeReaction == ReactionType.relatable,
                    ),
                    _buildFlatReaction(
                      context,
                      ReactionType.interesting,
                      Icons.lightbulb_outline,
                      Icons.lightbulb,
                      Colors.amber,
                      post.reactionsCount['interesting'] ?? 0,
                      activeReaction == ReactionType.interesting,
                    ),
                    _buildFlatReaction(
                      context,
                      ReactionType.redflag,
                      Icons.flag_outlined,
                      Icons.flag,
                      const Color(0xFFC05C3E),
                      post.reactionsCount['redflag'] ?? 0,
                      activeReaction == ReactionType.redflag,
                    ),
                    
                    // Comments button
                    InkWell(
                      onTap: () => context.push('/posts/${post.id}'),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.comment_outlined,
                            size: 16,
                            color: Color(0xFF6A6661),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${post.commentCount} comments',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6A6661),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Bookmark toggle
                IconButton(
                  icon: Icon(
                    bookmarked ? Icons.bookmark : Icons.bookmark_border_outlined,
                    size: 18,
                    color: bookmarked ? const Color(0xFFC05C3E) : const Color(0xFF6A6661),
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    if (!authState.isAuthenticated) {
                      _showAuthWarning(context, 'bookmark stories');
                    } else {
                      feedState.toggleBookmark(
                        authState.currentUser!.id,
                        BookmarkTargetType.post,
                        post.id,
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
          ],
        ),
      ),
    );
  }

  Widget _buildTagChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1EDE8),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFF6A6661),
        ),
      ),
    );
  }

  Widget _buildFlatReaction(
    BuildContext context,
    ReactionType type,
    IconData icon,
    IconData activeIcon,
    Color activeColor,
    int count,
    bool isSelected,
  ) {
    final authState = Provider.of<AuthState>(context, listen: false);
    final feedState = Provider.of<FeedState>(context, listen: false);

    return InkWell(
      onTap: () {
        if (!authState.isAuthenticated) {
          _showAuthWarning(context, 'react to stories');
        } else {
          feedState.toggleReaction(authState.currentUser!.id, post.id, type);
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSelected ? activeIcon : icon,
            size: 16,
            color: isSelected ? activeColor : const Color(0xFF6A6661),
          ),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? activeColor : const Color(0xFF6A6661),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  void _showAuthWarning(BuildContext context, String actionText) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Please sign in or register to $actionText.'),
        action: SnackBarAction(
          label: 'Sign In',
          onPressed: () => context.push('/login'),
        ),
      ),
    );
  }
}
