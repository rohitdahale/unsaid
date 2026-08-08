import 'package:flutter/material.dart';
import '../data/models/domain_models.dart';
import '../repositories/auth_repository.dart';

class AuthState extends ChangeNotifier {
  final AuthRepository _authRepo;

  AppUser? _currentUser;
  PublicProfile? _currentProfile;
  bool _isLoading = false;
  String? _errorMessage;

  AuthState(this._authRepo) {
    checkCurrentUser();
  }

  AppUser? get currentUser => _currentUser;
  PublicProfile? get currentProfile => _currentProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  bool get isAdmin => _currentUser?.role == UserRole.admin;
  bool get isModerator => _currentUser?.role == UserRole.moderator || _currentUser?.role == UserRole.admin;
  bool get isSuspendedOrBanned => 
      _currentUser?.status == UserStatus.suspended || _currentUser?.status == UserStatus.banned;

  Future<void> checkCurrentUser() async {
    _setLoading(true);
    try {
      _currentUser = await _authRepo.getCurrentUser();
      if (_currentUser != null) {
        _currentProfile = await _authRepo.getProfile(_currentUser!.id);
      } else {
        _currentProfile = null;
      }
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final user = await _authRepo.login(email, password);
      if (user != null) {
        if (user.status == UserStatus.suspended || user.status == UserStatus.banned) {
          _errorMessage = 'This account has been suspended or banned due to policy violations.';
          await _authRepo.logout();
          _currentUser = null;
          _currentProfile = null;
          _setLoading(false);
          return false;
        }
        _currentUser = user;
        _currentProfile = await _authRepo.getProfile(user.id);
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Invalid email or password.';
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signUp(String email, String password, {String role = 'user'}) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final user = await _authRepo.register(email, password, role: role);
      _currentUser = user;
      _currentProfile = await _authRepo.getProfile(user.id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    try {
      await _authRepo.logout();
      _currentUser = null;
      _currentProfile = null;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<PublicProfile?> getProfileById(String userId) async {
    try {
      return await _authRepo.getProfile(userId);
    } catch (_) {
      return null;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
