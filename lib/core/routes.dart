import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Screens
import '../ui/screens/splash_screen.dart';
import '../ui/screens/welcome_screen.dart';
import '../ui/screens/login_screen.dart';
import '../ui/screens/home_screen.dart';
import '../ui/screens/explore_screen.dart';
import '../ui/screens/create_story_screen.dart';
import '../ui/screens/saved_stories_screen.dart';
import '../ui/screens/user_profile_screen.dart';
import '../ui/screens/category_profile_screen.dart';
import '../ui/screens/story_detail_screen.dart';
import '../ui/screens/settings_screen.dart';
import '../ui/admin/admin_login_screen.dart';
import '../ui/admin/admin_dashboard_screen.dart';

// Shell Navigation Shell
import '../ui/widgets/responsive_navigation_shell.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> shellNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter router = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',
  routes: [
    // Non-shell routes
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/welcome',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/admin/login',
      builder: (context, state) => const AdminLoginScreen(),
    ),
    GoRoute(
      path: '/admin/dashboard',
      builder: (context, state) => const AdminDashboardScreen(),
    ),
    
    // Main App Shell containing bottom bar / sidebar
    ShellRoute(
      navigatorKey: shellNavigatorKey,
      builder: (context, state, child) {
        return ResponsiveNavigationShell(
          location: state.uri.toString(),
          child: child,
        );
      },
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/explore',
          builder: (context, state) => const ExploreScreen(),
        ),
        GoRoute(
          path: '/create',
          builder: (context, state) => const CreateStoryScreen(),
        ),
        GoRoute(
          path: '/saved',
          builder: (context, state) => const SavedStoriesScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const UserProfileScreen(),
        ),
      ],
    ),

    // Detail/Secondary screens that sit on top
    GoRoute(
      path: '/posts/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return StoryDetailScreen(postId: id);
      },
    ),
    GoRoute(
      path: '/category-profile',
      builder: (context, state) {
        final industry = state.uri.queryParameters['industry'];
        final size = state.uri.queryParameters['companySize'];
        final type = state.uri.queryParameters['companyType'];
        final region = state.uri.queryParameters['locationRegion'];
        return CategoryProfileScreen(
          industry: industry,
          companySize: size,
          companyType: type,
          locationRegion: region,
        );
      },
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
