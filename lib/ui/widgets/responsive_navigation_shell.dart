import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../state/auth_state.dart';
import '../../state/feed_state.dart';

class ResponsiveNavigationShell extends StatelessWidget {
  final Widget child;
  final String location;

  const ResponsiveNavigationShell({
    super.key,
    required this.child,
    required this.location,
  });

  int _getSelectedIndex() {
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/explore')) return 1;
    if (location.startsWith('/saved')) return 2;
    if (location.startsWith('/profile')) return 3;
    return -1; // -1 if not in tab nav
  }

  void _onItemTapped(int index, BuildContext context) {
    final authState = Provider.of<AuthState>(context, listen: false);

    // Guard profile and saved for guests
    if (!authState.isAuthenticated && (index == 2 || index == 3)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(index == 2 
              ? 'Sign in to view your bookmarked stories.' 
              : 'Sign in to view your space.'),
          action: SnackBarAction(
            label: 'Sign In',
            onPressed: () => context.push('/login'),
          ),
        ),
      );
      return;
    }

    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/explore');
        break;
      case 2:
        context.go('/saved');
        break;
      case 3:
        context.go('/profile');
        break;
    }
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
    final isDesktop = MediaQuery.of(context).size.width >= 768;
    final selectedIndex = _getSelectedIndex();
    final authState = context.watch<AuthState>();
    final feedState = context.watch<FeedState>();

    final notificationCount = authState.isAuthenticated 
        ? feedState.userNotifications.where((n) => !n.read).length 
        : 0;

    final displayName = authState.isAuthenticated 
        ? (authState.currentProfile?.displayName ?? 'User') 
        : 'Guest';
        
    final initials = _getInitials(displayName);

    if (isDesktop) {
      return Scaffold(
        body: Column(
          children: [
            // Top Navigation Bar
            Container(
              height: 64,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
                  ),
                ),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        // Logo: unsaid.
                        InkWell(
                          onTap: () => context.go('/home'),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'unsaid',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                               color: Theme.of(context).textTheme.headlineMedium?.color,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Text(
                                '.',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 48),
                        
                        // Nav Links: Home, Search, Saved, Your space
                        _buildNavHeaderLink(context, 'Home', selectedIndex == 0, () => _onItemTapped(0, context)),
                        _buildNavHeaderLink(context, 'Search', selectedIndex == 1, () => _onItemTapped(1, context)),
                        _buildNavHeaderLink(context, 'Saved', selectedIndex == 2, () => _onItemTapped(2, context)),
                        _buildNavHeaderLink(context, 'Your space', selectedIndex == 3, () => _onItemTapped(3, context)),
                        
                        const Spacer(),
                        
                        // Admin dashboard quick access link for moderator
                        if (authState.isModerator)
                          Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: TextButton.icon(
                              icon: const Icon(Icons.admin_panel_settings, size: 16, color: Colors.amber),
                              label: const Text('Admin', style: TextStyle(color: Colors.amber, fontSize: 13)),
                              onPressed: () => context.go('/admin/dashboard'),
                            ),
                          ),

                        // Notification Bell with Badge
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.notifications_none_outlined,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                              onPressed: () {
                                if (authState.isAuthenticated) {
                                  context.go('/profile');
                                } else {
                                  _onItemTapped(3, context);
                                }
                              },
                            ),
                            if (notificationCount > 0)
                              Positioned(
                                right: 8,
                                top: 8,
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFC05C3E), // Red dot
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 8),

                        // User Avatar Circle
                        GestureDetector(
                          onTap: () {
                            if (authState.isAuthenticated) {
                              context.go('/profile');
                            } else {
                              context.push('/login');
                            }
                          },
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: const Color(0xFFF3D8C8), // Soft pink/terracotta backdrop
                            child: Text(
                              initials,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFC05C3E),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Terracotta Share Story Button
                        ElevatedButton.icon(
                          onPressed: () {
                            if (authState.isAuthenticated) {
                              context.push('/create');
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Please sign in to share a story.'),
                                  action: SnackBarAction(
                                    label: 'Sign In',
                                    onPressed: () => context.push('/login'),
                                  ),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: const Text(
                            'Share story',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // Content
            Expanded(
              child: child,
            ),
          ],
        ),
      );
    }

    // Mobile Navigation Layout
    return Scaffold(
      body: child,
      // Floating Action Button for mobile story creation
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (authState.isAuthenticated) {
            context.push('/create');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Please sign in to share a story.'),
                action: SnackBarAction(
                  label: 'Sign In',
                  onPressed: () => context.push('/login'),
                ),
              ),
            );
          }
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.edit),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex == -1 ? 0 : selectedIndex,
        onTap: (index) => _onItemTapped(index, context),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_outline),
            activeIcon: Icon(Icons.bookmark),
            label: 'Saved',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Space',
          ),
        ],
      ),
    );
  }

  Widget _buildNavHeaderLink(
    BuildContext context,
    String text,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Theme.of(context).textTheme.titleLarge?.color : const Color(0xFF6A6661),
            ),
          ),
        ),
      ),
    );
  }
}
