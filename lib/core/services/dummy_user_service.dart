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
      password: 'admin123',
      role: 'admin',
    ),
    UserAccountModel(
      userid: 2,
      username: 'operator',
      password: 'operator123',
      role: 'admin',
    ),
    UserAccountModel(
      userid: 3,
      username: 'karaoke_lover',
      password: 'user123',
      role: 'user',
    ),
    UserAccountModel(
      userid: 4,
      username: 'singing_star',
      password: 'star123',
      role: 'user',
    ),
  ];

  Future<SharedPreferences> _getPrefs() async {
    return await SharedPreferences.getInstance();
  }

  @override
  Future<List<UserAccountModel>> getUsers() async {
    final prefs = await _getPrefs();
    final jsonString = prefs.getString(_keyUsers);

    if (jsonString == null || jsonString.isEmpty) {
      await _saveUsersToStorage(_defaultUsers);
      return List.from(_defaultUsers);
    }

    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      final users = decoded
          .map((item) => UserAccountModel.fromJson(item as Map<String, dynamic>))
          .toList();
      return users;
    } catch (_) {
      await _saveUsersToStorage(_defaultUsers);
      return List.from(_defaultUsers);
    }
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
      password: password.trim(),
      role: role.trim().toLowerCase() == 'admin' ? 'admin' : 'user',
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
      password: user.password.trim(),
      role: user.role.trim().toLowerCase() == 'admin' ? 'admin' : 'user',
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

  Future<void> _saveUsersToStorage(List<UserAccountModel> users) async {
    final prefs = await _getPrefs();
    final jsonList = users.map((u) => u.toJson()).toList();
    await prefs.setString(_keyUsers, jsonEncode(jsonList));
  }
}
