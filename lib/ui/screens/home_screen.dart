import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../state/auth_state.dart';
import '../../state/feed_state.dart';
import '../widgets/post_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _trendingTopics = [
    'Notice period',
    'Return to office',
    'Manager quality',
    'Bench time',
    'Promotion freeze',
    'Fresher pay',
    'Remote work',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final feedState = Provider.of<FeedState>(context, listen: false);
      feedState.fetchPosts();
      
      final authState = Provider.of<AuthState>(context, listen: false);
      if (authState.isAuthenticated) {
        feedState.fetchUserBookmarks(authState.currentUser!.id);
        feedState.fetchUserReactions(authState.currentUser!.id);
        feedState.fetchNotifications(authState.currentUser!.id);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    final feedState = Provider.of<FeedState>(context, listen: false);
    final authState = Provider.of<AuthState>(context, listen: false);
    await feedState.fetchPosts();
    
    if (authState.isAuthenticated) {
      await feedState.fetchUserBookmarks(authState.currentUser!.id);
      await feedState.fetchUserReactions(authState.currentUser!.id);
      await feedState.fetchNotifications(authState.currentUser!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedState = context.watch<FeedState>();
    final width = MediaQuery.of(context).size.width;
    final isWideScreen = width >= 1000;

    Widget mainContent = feedState.isLoading
        ? const Center(child: CircularProgressIndicator())
        : feedState.errorMessage != null
            ? _buildErrorState(feedState.errorMessage!)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title Header matching Screenshot 1
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Good morning',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6A6661),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "What people don't say at work.",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Theme.of(context).textTheme.headlineMedium?.color ?? Theme.of(context).colorScheme.onBackground,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${feedState.allPosts.length * 12 + 14} experiences shared this week — all anonymous, all first-hand.',
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: Color(0xFF6A6661),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Flat Custom Tab Bar matching Screenshot 1
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        dividerColor: Colors.transparent,
                        indicatorColor: const Color(0xFFC05C3E), // Terracotta line
                        labelColor: Theme.of(context).textTheme.titleLarge?.color,
                        unselectedLabelColor: const Color(0xFF6A6661),
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13.5),
                        tabs: const [
                          Tab(text: 'Trending'),
                          Tab(text: 'Recent'),
                          Tab(text: 'Most discussed'),
                        ],
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Divider(height: 1),
                  ),

                  // Tab Views
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildFeedList(feedState.getTrendingPosts()),
                        _buildFeedList(feedState.getRecentPosts()),
                        _buildFeedList(feedState.getMostDiscussedPosts()),
                      ],
                    ),
                  ),
                ],
              );

    if (isWideScreen) {
      return Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  // Left Main Column
                  Expanded(
                    flex: 5,
                    child: mainContent,
                  ),
                  
                  const VerticalDivider(width: 1),
                  
                  // Right Sidebar Column (Screenshot 1 Layout)
                  Expanded(
                    flex: 2,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Section 1: Trending Topics
                          const Text(
                            'TRENDING TOPICS',
                            style: TextStyle(
                              fontSize: 11.5,
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
                                label: Text(
                                  topic,
                                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF6A6661)),
                                ),
                                backgroundColor: const Color(0xFFF1EDE8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                side: BorderSide.none,
                                onPressed: () {
                                  context.push('/explore');
                                },
                              );
                            }).toList(),
                          ),
                          
                          const SizedBox(height: 36),
                          const Divider(),
                          const SizedBox(height: 24),

                          // Section 2: Why People Leave
                          const Text(
                            'WHY PEOPLE LEAVE',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6A6661),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildLeaveMetric('Management', 34),
                          _buildLeaveMetric('Workload', 27),
                          _buildLeaveMetric('Compensation', 18),
                          _buildLeaveMetric('Growth', 13),
                          _buildLeaveMetric('Other', 8),
                          const SizedBox(height: 8),
                          const Text(
                            'Based on 124 experiences',
                            style: TextStyle(fontSize: 11, color: Color(0xFF6A6661), fontStyle: FontStyle.italic),
                          ),

                          const SizedBox(height: 36),
                          const Divider(),
                          const SizedBox(height: 24),

                          // Section 3: Most Discussed stories
                          const Text(
                            'MOST DISCUSSED',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6A6661),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildMostDiscussedList(feedState.getMostDiscussedPosts()),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: mainContent,
    );
  }

  Widget _buildLeaveMetric(String title, double percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F0F0F)),
              ),
              Text(
                '${percentage.toInt()}%',
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF6A6661)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 6,
              backgroundColor: const Color(0xFFF1EDE8),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFC05C3E)), // Terracotta indicator
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMostDiscussedList(List<dynamic> posts) {
    final list = posts.take(3).toList();
    if (list.isEmpty) {
      return const Text('No popular stories yet.', style: TextStyle(fontSize: 12, color: Colors.grey));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: list.map((post) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: InkWell(
            onTap: () => context.push('/posts/${post.id}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F0F0F),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${post.commentCount} comments',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF6A6661)),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFeedList(List<dynamic> posts) {
    if (posts.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.feed_outlined, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text(
                'No stories here yet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Be the first to share an anonymous story in this feed.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.go('/create'),
                icon: const Icon(Icons.add),
                label: const Text('Share Your Story'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        itemCount: posts.length,
        itemBuilder: (context, index) {
          return PostCard(post: posts[index]);
        },
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Failed to load feed',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _handleRefresh,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
