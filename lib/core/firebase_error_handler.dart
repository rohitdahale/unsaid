import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class FirebaseErrorHandler {
  static String handle(dynamic error, {String context = ''}) {
    // Log to console
    debugPrint('Firebase Error [$context]: $error');

    // Record error to Crashlytics on native platforms
    if (!kIsWeb) {
      FirebaseCrashlytics.instance.recordError(error, null, reason: 'Firebase error in $context');
    }
    
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        case 'user-disabled':
          return 'This user account has been disabled.';
        case 'user-not-found':
          return 'No account found with this email.';
        case 'wrong-password':
          return 'Incorrect password. Please try again.';
        case 'email-already-in-use':
          return 'This email address is already in use.';
        case 'weak-password':
          return 'Password is too weak. Please use a stronger password.';
        case 'operation-not-allowed':
          return 'Auth operation not allowed.';
        case 'invalid-email':
          return 'Invalid email address format.';
        default:
          return error.message ?? 'Authentication error occurred (${error.code}).';
      }
    }
    
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'Access Denied: You do not have permission to perform this action.';
        case 'unavailable':
          return 'Service is temporarily unavailable. Please try again later.';
        case 'deadline-exceeded':
          return 'The action timed out. Please check your connection and try again.';
        case 'unauthenticated':
          return 'Please sign in to perform this action.';
        default:
          return error.message ?? 'Database error occurred (${error.code}).';
      }
    }
    
    return 'An unexpected error occurred. Please try again.';
  }
}
