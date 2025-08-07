import '../models/user_model.dart';
import '../providers/auth_provider.dart';

class AuthRepository {
  final AuthProvider _authProvider = AuthProvider();

  Future<UserModel?> register(String username, String password) {
    return _authProvider.register(username, password);
  }

  Future<UserModel?> login(String username, String password) {
    return _authProvider.login(username, password);
  }

  Future<void> logout() {
    return _authProvider.logout();
  }

  Future<UserModel?> getCurrentUser() {
    return _authProvider.getCurrentUser();
  }
}