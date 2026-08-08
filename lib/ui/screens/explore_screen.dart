import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/feed_state.dart';
import '../widgets/post_card.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  // Seeded listings matching Screenshot 2
  final List<String> _recentSearches = [
    'Large IT services',
    'startup equity',
    'manager',
  ];

  final List<String> _trendingTopics = [
    'Notice period',
    'Return to office',
    'Manager quality',
    'Bench time',
    'Promotion freeze',
    'Fresher pay',
    'Remote work',
  ];

  final List<String> _experiences = [
    'Why I left',
    'Management',
    'Growth',
    'Work-life balance',
    'Interview',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onChipSelected(String value) {
    setState(() {
      _searchController.text = value;
      _searchQuery = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final feedState = context.watch<FeedState>();
    final searchResults = feedState.searchPosts(_searchQuery);

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search Input Section matching Screenshot 2
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Search',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.headlineMedium?.color,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Try "startup equity" or "manager"',
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF6A6661)),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    _searchController.clear();
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.4)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                        ),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val.trim();
                        });
                      },
                    ),
                  ],
                ),
              ),

              // Content split
              Expanded(
                child: _searchQuery.isNotEmpty
                    ? _buildSearchResults(searchResults)
                    : _buildDefaultLayout(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults(List<dynamic> posts) {
    if (posts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off_outlined, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text(
                'No matching stories found',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Try searching with other keywords.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        return PostCard(post: posts[index]);
      },
    );
  }

  Widget _buildDefaultLayout(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // Section 1: Recent Searches
        const Text(
          'RECENT SEARCHES',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF6A6661),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Column(
          children: _recentSearches.map((search) {
            return ListTile(
              leading: const Icon(Icons.search, size: 18, color: Color(0xFF6A6661)),
              title: Text(
                search,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Theme.of(context).textTheme.titleLarge?.color),
              ),
              contentPadding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              onTap: () => _onChipSelected(search),
            );
          }).toList(),
        ),
        
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 24),

        // Section 2: Trending Topics
        const Text(
          'TRENDING TOPICS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF6A6661),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _trendingTopics.map((topic) {
            return ActionChip(
              label: Text(topic, style: const TextStyle(fontSize: 12, color: Color(0xFF6A6661))),
              backgroundColor: const Color(0xFFF1EDE8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              side: BorderSide.none,
              onPressed: () => _onChipSelected(topic),
            );
          }).toList(),
        ),

        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 24),

        // Section 3: Browse by Experience
        const Text(
          'BROWSE BY EXPERIENCE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF6A6661),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _experiences.map((exp) {
            return ActionChip(
              label: Text(exp, style: const TextStyle(fontSize: 12, color: Color(0xFF6A6661))),
              backgroundColor: const Color(0xFFF1EDE8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              side: BorderSide.none,
              onPressed: () => _onChipSelected(exp),
            );
          }).toList(),
        ),
      ],
    );
  }
}
