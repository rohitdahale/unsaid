import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../state/auth_state.dart';
import '../../state/feed_state.dart';
import '../../data/models/domain_models.dart';
import '../widgets/post_card.dart';

class SavedStoriesScreen extends StatefulWidget {
  const SavedStoriesScreen({super.key});

  @override
  State<SavedStoriesScreen> createState() => _SavedStoriesScreenState();
}

class _SavedStoriesScreenState extends State<SavedStoriesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = Provider.of<AuthState>(context, listen: false);
      if (authState.isAuthenticated) {
        Provider.of<FeedState>(context, listen: false).fetchUserBookmarks(authState.currentUser!.id);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feedState = context.watch<FeedState>();
    final authState = context.watch<AuthState>();

    if (!authState.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('Saved Stories')),
        body: const Center(child: Text('Sign in to view your bookmarks.')),
      );
    }

    // Filter posts that are bookmarked
    final bookmarkedPosts = feedState.allPosts.where((post) {
      return feedState.isBookmarked(BookmarkTargetType.post, post.id);
    }).toList();

    // Get bookmarked category structures
    final bookmarkedCategories = feedState.userBookmarks
        .where((b) => b.targetType == BookmarkTargetType.category)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Bookmarks'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Stories'),
            Tab(text: 'Workplace Profiles'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStoriesTab(bookmarkedPosts),
          _buildCategoriesTab(bookmarkedCategories),
        ],
      ),
    );
  }

  Widget _buildStoriesTab(List<Post> posts) {
    if (posts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bookmark_outline, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text(
                'No saved stories',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Stories you bookmark will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        return PostCard(post: posts[index]);
      },
    );
  }

  Widget _buildCategoriesTab(List<Bookmark> bookmarks) {
    if (bookmarks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.category_outlined, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text(
                'No saved categories',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Workplace category profiles you bookmark will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: bookmarks.length,
      itemBuilder: (context, index) {
        final b = bookmarks[index];
        final title = _parseCategoryTitle(b.targetId);

        return Card(
          elevation: 0,
          margin: const EdgeInsets.symmetric(vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
          ),
          child: ListTile(
            leading: Icon(Icons.domain, color: Theme.of(context).colorScheme.primary),
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            subtitle: const Text('Workplace Category Profile', style: TextStyle(fontSize: 11)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () {
              context.push('/category-profile?${b.targetId}');
            },
          ),
        );
      },
    );
  }

  String _parseCategoryTitle(String serializedString) {
    final queryParams = Uri.splitQueryString(serializedString);
    final parts = <String>[];
    if (queryParams.containsKey('industry')) parts.add(queryParams['industry']!);
    if (queryParams.containsKey('companySize')) parts.add(queryParams['companySize']!);
    if (queryParams.containsKey('companyType')) parts.add(queryParams['companyType']!);
    if (queryParams.containsKey('locationRegion')) parts.add(queryParams['locationRegion']!);
    
    if (parts.isEmpty) return 'General Profile';
    return parts.join(' • ');
  }
}
