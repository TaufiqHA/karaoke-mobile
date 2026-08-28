class UserAccountModel {
  final int userid;
  final String username;
  final String password;
  final String role; // 'admin' atau 'user'

  const UserAccountModel({
    required this.userid,
    required this.username,
    required this.password,
    this.role = 'user',
  });

  bool get isAdmin => role.toLowerCase() == 'admin';

  UserAccountModel copyWith({
    int? userid,
    String? username,
    String? password,
    String? role,
  }) {
    return UserAccountModel(
      userid: userid ?? this.userid,
      username: username ?? this.username,
      password: password ?? this.password,
      role: role ?? this.role,
    );
  }

  factory UserAccountModel.fromJson(Map<String, dynamic> json) {
    return UserAccountModel(
      userid: json['userid'] is int
          ? json['userid'] as int
          : int.tryParse(json['userid']?.toString() ?? '0') ?? 0,
      username: json['username'] as String? ?? '',
      password: json['password'] as String? ?? '',
      role: json['role'] as String? ?? 'user',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userid': userid,
      'username': username,
      'password': password,
      'role': role,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserAccountModel &&
          runtimeType == other.runtimeType &&
          userid == other.userid &&
          username == other.username &&
          password == other.password &&
          role == other.role;

  @override
  int get hashCode =>
      userid.hashCode ^ username.hashCode ^ password.hashCode ^ role.hashCode;
}
