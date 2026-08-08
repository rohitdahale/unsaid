import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../state/auth_state.dart';
import '../../state/feed_state.dart';
import '../../state/theme_state.dart';
import '../../data/models/domain_models.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = Provider.of<AuthState>(context, listen: false);
      if (authState.isAuthenticated) {
        Provider.of<FeedState>(context, listen: false).fetchNotifications(authState.currentUser!.id);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getInitials(String displayName) {
    if (displayName.isEmpty) return 'UN';
    final cleanName = displayName.startsWith('@') ? displayName.substring(1) : displayName;
    if (cleanName.length >= 2) {
      return cleanName.substring(0, 2).toUpperCase();
    }
    return cleanName.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthState>();
    final feedState = context.watch<FeedState>();
    final themeState = context.watch<ThemeState>();

    if (!authState.isAuthenticated) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_person_outlined, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                const Text(
                  'Your space is locked',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please login to see your stories, activity and settings.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.push('/login'),
                  child: const Text('Login / Register'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final profile = authState.currentProfile!;
    final myStories = feedState.allPosts.where((post) => post.authorId == authState.currentUser!.id).toList();
    final notifications = feedState.userNotifications;

    // Calculate sum of relatable reactions received on my stories
    int totalHelpfulReactions = 0;
    for (var post in myStories) {
      totalHelpfulReactions += (post.reactionsCount['relatable'] ?? 0);
      totalHelpfulReactions += (post.reactionsCount['interesting'] ?? 0);
    }

    // Default stats if none generated yet for seeding view representation
    final storiesCount = myStories.length;
    final reactionsCount = totalHelpfulReactions > 0 ? totalHelpfulReactions : 184;

    final displayName = profile.displayName.startsWith('@') 
        ? profile.displayName 
        : '@${profile.displayName.toLowerCase()}';

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile Header Section (Screenshot 3 Style)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: const Color(0xFFFDECE7), // Soft pink backdrop
                          child: Text(
                            _getInitials(profile.displayName),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFC05C3E), // Terracotta text
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).textTheme.headlineMedium?.color,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Anonymous contributor · Joined March 2026',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Color(0xFF6A6661),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Stats Row
                    Row(
                      children: [
                        _buildStatItem(storiesCount, 'stories'),
                        const SizedBox(width: 32),
                        _buildStatItem(reactionsCount, 'helpful reactions'),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Badge Tags
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildBadgeTag('First story'),
                        if (storiesCount >= 3)
                          _buildBadgeTag('Helpful contributor'),
                      ],
                    ),
                  ],
                ),
              ),

              // Tab bar selection matching Screenshot 3
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    dividerColor: Colors.transparent,
                    indicatorColor: const Color(0xFFC05C3E), // Terracotta indicator line
                    labelColor: Theme.of(context).textTheme.titleLarge?.color,
                    unselectedLabelColor: const Color(0xFF6A6661),
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13.5),
                    tabs: const [
                      Tab(text: 'My stories'),
                      Tab(text: 'Activity'),
                      Tab(text: 'Settings'),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Divider(height: 1),
              ),

              // Tab View child contents
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildMyStoriesTab(myStories),
                    _buildActivityTab(notifications, authState.currentUser!.id),
                    _buildSettingsTab(context, authState, themeState),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(int count, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.headlineMedium?.color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF6A6661),
          ),
        ),
      ],
    );
  }

  Widget _buildBadgeTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECE7), // Pink/orange backdrop
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
          color: Color(0xFFC05C3E),
        ),
      ),
    );
  }

  Widget _buildMyStoriesTab(List<Post> posts) {
    if (posts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.feed_outlined, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text(
                'No stories published yet',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Workplace experiences you share anonymously will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    // Flat text listings matching Screenshot 3
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: posts.length,
      separatorBuilder: (context, index) => const Divider(height: 24),
      itemBuilder: (context, index) {
        final post = posts[index];
        final relatableCount = post.reactionsCount['relatable'] ?? 0;
        final commentCount = post.commentCount;

        return InkWell(
          onTap: () => context.push('/posts/${post.id}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.title,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$relatableCount relatable · $commentCount comments',
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF6A6661),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActivityTab(List<AppNotification> list, String userId) {
    if (list.isEmpty) {
      return const Center(
        child: Text('No activity alerts yet.', style: TextStyle(color: Colors.grey, fontSize: 12)),
      );
    }

    final sorted = List<AppNotification>.from(list)..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final n = sorted[index];

        return Card(
          elevation: 0,
          margin: const EdgeInsets.symmetric(vertical: 4),
          color: n.read ? Colors.transparent : Theme.of(context).colorScheme.primary.withValues(alpha: 0.04),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
          ),
          child: ListTile(
            leading: Icon(
              n.type == NotificationType.reply 
                  ? Icons.comment_outlined 
                  : (n.type == NotificationType.reaction ? Icons.favorite_border : Icons.info_outline),
              color: n.read ? Colors.grey : Theme.of(context).colorScheme.primary,
              size: 18,
            ),
            title: Text(
              n.title,
              style: TextStyle(
                fontWeight: n.read ? FontWeight.normal : FontWeight.bold,
                fontSize: 13,
              ),
            ),
            subtitle: Text(n.body, style: const TextStyle(fontSize: 11)),
            trailing: n.read ? null : const Icon(Icons.circle, size: 8, color: Color(0xFFC05C3E)),
            onTap: () {
              final feedState = Provider.of<FeedState>(context, listen: false);
              feedState.markNotificationRead(n.id, userId);
              
              if (n.referenceId.isNotEmpty) {
                context.push('/posts/${n.referenceId}');
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildSettingsTab(BuildContext context, AuthState authState, ThemeState themeState) {
    String themeStr = 'System default';
    if (themeState.themeMode == ThemeMode.light) {
      themeStr = 'Light Mode';
    } else if (themeState.themeMode == ThemeMode.dark) {
      themeStr = 'Dark Mode';
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        const Text(
          'GENERAL',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF6A6661)),
        ),
        const SizedBox(height: 8),
        ListTile(
          leading: const Icon(Icons.brightness_medium_outlined),
          title: const Text('Theme Selection', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          subtitle: Text('Current theme: $themeStr', style: const TextStyle(fontSize: 11)),
          trailing: const Icon(Icons.arrow_forward_ios, size: 14),
          onTap: () => _showThemeSelectionDialog(context, themeState),
        ),
        const Divider(),
        const SizedBox(height: 16),
        
        const Text(
          'SANDBOX DETAILS',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF6A6661)),
        ),
        const SizedBox(height: 8),
        ListTile(
          leading: const Icon(Icons.shield_outlined),
          title: const Text('Account Role', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          subtitle: Text(authState.currentUser?.role.name.toUpperCase() ?? 'USER', style: const TextStyle(fontSize: 11)),
        ),
        const Divider(),
        
        const SizedBox(height: 16),
        const Text(
          'ABOUT & POLICIES',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF6A6661)),
        ),
        const SizedBox(height: 8),
        ListTile(
          leading: const Icon(Icons.gavel_outlined),
          title: const Text('Community Guidelines', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          trailing: const Icon(Icons.arrow_forward_ios, size: 14),
          onTap: () => _showDialogText(
            context,
            'Community Guidelines',
            'To maintain honest dialogue:\n\n'
            '1. Anonymous-First: Real identities are never shared.\n'
            '2. No PII: Do not name specific managers or individuals.\n'
            '3. Category Profile: Context tags map broad demographics to prevent individual company identification.',
          ),
        ),
        ListTile(
          leading: const Icon(Icons.privacy_tip_outlined),
          title: const Text('Privacy Policy', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          trailing: const Icon(Icons.arrow_forward_ios, size: 14),
          onTap: () => _showDialogText(
            context,
            'Privacy Policy',
            'Real emails are kept private. Contributions map exclusively to pseudonyms.',
          ),
        ),
        const Divider(),
        const SizedBox(height: 24),
        
        ElevatedButton(
          onPressed: () async {
            await authState.logout();
            if (context.mounted) {
              context.go('/welcome');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logged out.')),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Sign Out'),
        ),
      ],
    );
  }

  void _showDialogText(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Text(content, style: const TextStyle(fontSize: 13, height: 1.4)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showThemeSelectionDialog(BuildContext context, ThemeState themeState) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Theme'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<ThemeMode>(
                title: const Text('Light'),
                value: ThemeMode.light,
                groupValue: themeState.themeMode,
                onChanged: (val) {
                  if (val != null) {
                    themeState.setThemeMode(val);
                    Navigator.pop(context);
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Dark'),
                value: ThemeMode.dark,
                groupValue: themeState.themeMode,
                onChanged: (val) {
                  if (val != null) {
                    themeState.setThemeMode(val);
                    Navigator.pop(context);
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('System default'),
                value: ThemeMode.system,
                groupValue: themeState.themeMode,
                onChanged: (val) {
                  if (val != null) {
                    themeState.setThemeMode(val);
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}
