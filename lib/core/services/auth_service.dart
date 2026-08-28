import '../../models/user_model.dart';

abstract class AuthService {
  Future<AuthResponse> login(String username, String password);
  Future<void> logout();
}
