import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_account_model.dart';
import 'user_service.dart';

class DummyUserService implements UserService {
  static const String _keyUsers = 'app_users_data';

  final List<UserAccountModel> _defaultUsers = const [
    UserAccountModel(
      userid: 1,
      username: 'admin',
      name: 'Administrator',
      email: 'admin@example.com',
      password: 'admin123',
      role: 'admin',
    ),
    UserAccountModel(
      userid: 2,
      username: 'operator',
      name: 'Operator Karaoke',
      email: 'operator@example.com',
      password: 'operator123',
      role: 'admin',
    ),
    UserAccountModel(
      userid: 3,
      username: 'karaoke_lover',
      name: 'Karaoke Lover',
      email: 'lover@example.com',
      password: 'user123',
      role: 'user',
    ),
    UserAccountModel(
      userid: 4,
      username: 'singing_star',
      name: 'Singing Star',
      email: 'star@example.com',
      password: 'star123',
      role: 'user',
    ),
  ];

  Future<SharedPreferences> _getPrefs() async {
    return await SharedPreferences.getInstance();
  }

  @override
  Future<List<UserAccountModel>> getUsers({String? search, String? role}) async {
    final prefs = await _getPrefs();
    final jsonString = prefs.getString(_keyUsers);

    List<UserAccountModel> users;
    if (jsonString == null || jsonString.isEmpty) {
      await _saveUsersToStorage(_defaultUsers);
      users = List.from(_defaultUsers);
    } else {
      try {
        final List<dynamic> decoded = jsonDecode(jsonString);
        users = decoded
            .map((item) => UserAccountModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (_) {
        await _saveUsersToStorage(_defaultUsers);
        users = List.from(_defaultUsers);
      }
    }

    if (search != null && search.trim().isNotEmpty) {
      final q = search.trim().toLowerCase();
      users = users.where((u) {
        final matchUsername = u.username.toLowerCase().contains(q);
        final matchName = u.name?.toLowerCase().contains(q) ?? false;
        final matchEmail = u.email?.toLowerCase().contains(q) ?? false;
        final matchId = '#${u.userid}'.contains(q) || '${u.userid}'.contains(q);
        return matchUsername || matchName || matchEmail || matchId;
      }).toList();
    }

    if (role != null && role.trim().isNotEmpty) {
      users = users.where((u) => u.role.toLowerCase() == role.trim().toLowerCase()).toList();
    }

    return users;
  }

  @override
  Future<bool> isUsernameExists(String username, {int? excludeUserId}) async {
    final users = await getUsers();
    final normalized = username.trim().toLowerCase();
    return users.any((u) =>
        u.username.trim().toLowerCase() == normalized &&
        (excludeUserId == null || u.userid != excludeUserId));
  }

  @override
  Future<UserAccountModel> createUser({
    required String username,
    required String password,
    required String role,
    String? name,
    String? email,
  }) async {
    final trimmedUsername = username.trim();
    if (trimmedUsername.isEmpty) {
      throw Exception('Username tidak boleh kosong');
    }
    if (password.trim().isEmpty) {
      throw Exception('Password tidak boleh kosong');
    }

    final users = await getUsers();
    if (await isUsernameExists(trimmedUsername)) {
      throw Exception('Username "$trimmedUsername" sudah digunakan');
    }

    int nextId = 1;
    if (users.isNotEmpty) {
      final maxId = users.map((u) => u.userid).reduce((a, b) => a > b ? a : b);
      nextId = maxId + 1;
    }

    final newUser = UserAccountModel(
      userid: nextId,
      username: trimmedUsername,
      name: (name != null && name.trim().isNotEmpty) ? name.trim() : trimmedUsername,
      email: (email != null && email.trim().isNotEmpty)
          ? email.trim()
          : '${trimmedUsername.toLowerCase()}@karaoke.local',
      password: password.trim(),
      role: role.trim().toLowerCase() == 'admin' ? 'admin' : 'user',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    users.add(newUser);
    await _saveUsersToStorage(users);
    return newUser;
  }

  @override
  Future<UserAccountModel> updateUser(UserAccountModel user) async {
    final trimmedUsername = user.username.trim();
    if (trimmedUsername.isEmpty) {
      throw Exception('Username tidak boleh kosong');
    }
    if (user.password.trim().isEmpty) {
      throw Exception('Password tidak boleh kosong');
    }

    final users = await getUsers();
    final index = users.indexWhere((u) => u.userid == user.userid);
    if (index == -1) {
      throw Exception('Pengguna dengan ID ${user.userid} tidak ditemukan');
    }

    if (await isUsernameExists(trimmedUsername, excludeUserId: user.userid)) {
      throw Exception('Username "$trimmedUsername" sudah digunakan');
    }

    final updatedUser = user.copyWith(
      username: trimmedUsername,
      name: user.name?.trim().isNotEmpty == true ? user.name!.trim() : trimmedUsername,
      email: user.email?.trim().isNotEmpty == true
          ? user.email!.trim()
          : '${trimmedUsername.toLowerCase()}@karaoke.local',
      password: user.password.trim(),
      role: user.role.trim().toLowerCase() == 'admin' ? 'admin' : 'user',
      updatedAt: DateTime.now(),
    );

    users[index] = updatedUser;
    await _saveUsersToStorage(users);
    return updatedUser;
  }

  @override
  Future<void> deleteUser(int userid) async {
    final users = await getUsers();
    users.removeWhere((u) => u.userid == userid);
    await _saveUsersToStorage(users);
  }

  @override
  Future<bool> changePassword({
    required String username,
    required String oldPassword,
    required String newPassword,
  }) async {
    final trimmedUser = username.trim().toLowerCase();
    final trimmedOldPass = oldPassword.trim();
    final trimmedNewPass = newPassword.trim();

    if (trimmedNewPass.length < 6) {
      throw Exception('Password baru minimal 6 karakter');
    }

    final users = await getUsers();
    final index = users.indexWhere(
      (u) => u.username.trim().toLowerCase() == trimmedUser,
    );

    if (index != -1) {
      final existingUser = users[index];
      if (existingUser.password != trimmedOldPass) {
        throw Exception('Password lama tidak sesuai');
      }
      users[index] = existingUser.copyWith(password: trimmedNewPass);
      await _saveUsersToStorage(users);
      return true;
    }

    // Jika user dibuat secara dinamis oleh dummy auth
    return true;
  }

  Future<void> _saveUsersToStorage(List<UserAccountModel> users) async {
    final prefs = await _getPrefs();
    final jsonList = users.map((u) => u.toJson()).toList();
    await prefs.setString(_keyUsers, jsonEncode(jsonList));
  }
}
