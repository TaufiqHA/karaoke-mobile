import 'dart:async';
import '../../models/user_model.dart';
import 'auth_service.dart';
import 'storage_service.dart';

class DummyAuthService implements AuthService {
  final StorageService? storageService;

  DummyAuthService({this.storageService});

  Future<StorageService> _getStorage() async {
    return storageService ?? await StorageService.getInstance();
  }

  @override
  Future<AuthResponse> login(String username, String password) async {
    // Simulasi delay jaringan API (1.2 detik)
    await Future.delayed(const Duration(milliseconds: 1200));

    final trimmedUser = username.trim();
    final trimmedPass = password.trim();

    if (trimmedUser.isEmpty || trimmedPass.isEmpty) {
      return AuthResponse.failed(message: 'Username dan Password wajib diisi');
    }

    final role = trimmedUser.toLowerCase() == 'user' ? 'user' : 'admin';

    // Validasi dummy sederhana
    final user = UserModel(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      username: trimmedUser,
      displayName: trimmedUser[0].toUpperCase() + (trimmedUser.length > 1 ? trimmedUser.substring(1) : ''),
      email: '$trimmedUser@karaokeapp.com',
      role: role,
    );

    final mockToken = 'dummy_jwt_token_${DateTime.now().millisecondsSinceEpoch}_$trimmedUser';

    // Simpan data sesi ke local storage
    final storage = await _getStorage();
    await storage.saveAuthSession(token: mockToken, user: user);

    return AuthResponse.success(
      token: mockToken,
      user: user,
      message: 'Selamat datang kembali, ${user.displayName}!',
    );
  }

  @override
  Future<void> logout() async {
    final storage = await _getStorage();
    await storage.clearSession();
  }
}
