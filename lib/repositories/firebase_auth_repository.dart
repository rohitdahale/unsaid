import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../core/firebase_error_handler.dart';
import '../data/models/domain_models.dart';
import 'auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  @override
  Future<AppUser?> getCurrentUser() async {
    try {
      final fbUser = _auth.currentUser;
      if (fbUser == null) return null;

      final doc = await _firestore.collection('users').doc(fbUser.uid).get();
      if (doc.exists && doc.data() != null) {
        return AppUser.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      final msg = FirebaseErrorHandler.handle(e, context: 'getCurrentUser');
      throw Exception(msg);
    }
  }

  @override
  Future<PublicProfile?> getProfile(String userId) async {
    try {
      final doc = await _firestore.collection('profiles').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        return PublicProfile.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      final msg = FirebaseErrorHandler.handle(e, context: 'getProfile');
      throw Exception(msg);
    }
  }

  @override
  Future<AppUser?> login(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (credential.user != null) {
        await _analytics.logLogin();
        return getCurrentUser();
      }
      return null;
    } catch (e) {
      final msg = FirebaseErrorHandler.handle(e, context: 'login');
      throw Exception(msg);
    }
  }

  @override
  Future<AppUser> register(String email, String password, {String role = 'user'}) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final fbUser = credential.user!;

      // Create private user account data
      final userRole = role == 'admin' 
          ? UserRole.admin 
          : (role == 'moderator' ? UserRole.moderator : UserRole.user);
          
      final newUser = AppUser(
        id: fbUser.uid,
        email: email.trim(),
        role: userRole,
        status: UserStatus.active,
        createdAt: DateTime.now(),
      );

      // Generate public profile pseudonym
      final pseudonym = _generatePseudonym();
      final newProfile = PublicProfile(
        userId: fbUser.uid,
        displayName: pseudonym,
        avatarSeed: 'seed_${Random().nextInt(1000)}',
        badges: userRole == UserRole.moderator ? ['Moderator'] : (userRole == UserRole.admin ? ['Admin'] : []),
        contributionCount: 0,
        createdAt: DateTime.now(),
      );

      // Save to Firestore users and profiles collections
      await _firestore.collection('users').doc(fbUser.uid).set(newUser.toJson());
      await _firestore.collection('profiles').doc(fbUser.uid).set(newProfile.toJson());

      await _analytics.logSignUp(signUpMethod: 'email');

      return newUser;
    } catch (e) {
      final msg = FirebaseErrorHandler.handle(e, context: 'register');
      throw Exception(msg);
    }
  }

  @override
  Future<void> logout() async {
    await _auth.signOut();
  }

  String _generatePseudonym() {
    final adjectives = ['Silent', 'Candid', 'Quiet', 'Frank', 'Honest', 'Open', 'Brave', 'Curious', 'Bold', 'Observant'];
    final nouns = ['Builder', 'Coder', 'Thinker', 'Designer', 'Strategist', 'Writer', 'Analyst', 'Planner', 'Engineer', 'Specialist'];
    final rand = Random();
    final adj = adjectives[rand.nextInt(adjectives.length)];
    final noun = nouns[rand.nextInt(nouns.length)];
    final num = rand.nextInt(90) + 10; // 10 to 99
    return '$adj$noun-$num';
  }
}
