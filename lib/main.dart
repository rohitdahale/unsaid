import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'firebase_options.dart';
import 'core/routes.dart';
import 'core/theme.dart';
import 'repositories/auth_repository.dart';
import 'repositories/post_repository.dart';
import 'repositories/moderation_repository.dart';
import 'repositories/firebase_auth_repository.dart';
import 'repositories/firestore_post_repository.dart';
import 'repositories/firestore_moderation_repository.dart';
import 'state/auth_state.dart';
import 'state/feed_state.dart';
import 'state/story_creator_state.dart';
import 'state/moderation_state.dart';
import 'state/theme_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('DEBUG: Initializing Firebase...');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('DEBUG: Firebase initialization completion.');
  print('DEBUG: Firebase project ID: ${Firebase.app().options.projectId}');
  print('DEBUG: Firebase app ID: ${Firebase.app().options.appId}');

  // Setup Crashlytics error logging on native platforms
  if (!kIsWeb) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  // Setup App Check security shielding on native platforms
  if (!kIsWeb) {
    try {
      await FirebaseAppCheck.instance.activate(
        providerAndroid: kDebugMode ? AndroidDebugProvider() : AndroidPlayIntegrityProvider(),
      );
    } catch (e) {
      debugPrint('Firebase App Check initialization failed: $e');
    }
  }
  
  // Dependency injection setup
  final authRepo = FirebaseAuthRepository();
  final postRepo = FirestorePostRepository();
  final modRepo = FirestoreModerationRepository();

  runApp(
    MultiProvider(
      providers: [
        // Repositories
        Provider<AuthRepository>.value(value: authRepo),
        Provider<PostRepository>.value(value: postRepo),
        Provider<ModerationRepository>.value(value: modRepo),
        
        // Notifiers (State management)
        ChangeNotifierProvider<AuthState>(
          create: (_) => AuthState(authRepo),
        ),
        ChangeNotifierProvider<FeedState>(
          create: (_) => FeedState(postRepo),
        ),
        ChangeNotifierProvider<StoryCreatorState>(
          create: (_) => StoryCreatorState(postRepo),
        ),
        ChangeNotifierProvider<ModerationState>(
          create: (_) => ModerationState(modRepo, postRepo),
        ),
        ChangeNotifierProvider<ThemeState>(
          create: (_) => ThemeState(),
        ),
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeState = context.watch<ThemeState>();
    return MaterialApp.router(
      title: 'UNSAID',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeState.themeMode,
      routerConfig: router,
    );
  }
}
