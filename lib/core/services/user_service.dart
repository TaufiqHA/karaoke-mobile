import 'dart:async';
import '../../models/user_account_model.dart';

abstract class UserService {
  Future<List<UserAccountModel>> getUsers();
  Future<UserAccountModel> createUser({
    required String username,
    required String password,
    required String role,
  });
  Future<UserAccountModel> updateUser(UserAccountModel user);
  Future<void> deleteUser(int userid);
  Future<bool> isUsernameExists(String username, {int? excludeUserId});
  Future<bool> changePassword({
    required String username,
    required String oldPassword,
    required String newPassword,
  });
}
