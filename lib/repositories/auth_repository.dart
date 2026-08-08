import '../data/models/domain_models.dart';
import '../data/mock_database_service.dart';

abstract class AuthRepository {
  Future<AppUser?> getCurrentUser();
  Future<PublicProfile?> getProfile(String userId);
  Future<AppUser?> login(String email, String password);
  Future<AppUser> register(String email, String password, {String role = 'user'});
  Future<void> logout();
}

class MockAuthRepository implements AuthRepository {
  final MockDatabaseService _db = MockDatabaseService();

  @override
  Future<AppUser?> getCurrentUser() async {
    await _db.init();
    return _db.getCurrentUser();
  }

  @override
  Future<PublicProfile?> getProfile(String userId) async {
    await _db.init();
    return _db.getProfile(userId);
  }

  @override
  Future<AppUser?> login(String email, String password) async {
    await _db.init();
    final user = await _db.loginUser(email, password);
    if (user != null) {
      await _db.setCurrentUser(user.id);
    }
    return user;
  }

  @override
  Future<AppUser> register(String email, String password, {String role = 'user'}) async {
    await _db.init();
    final user = await _db.registerUser(email, password, role);
    await _db.setCurrentUser(user.id);
    return user;
  }

  @override
  Future<void> logout() async {
    await _db.init();
    await _db.setCurrentUser(null);
  }
}
