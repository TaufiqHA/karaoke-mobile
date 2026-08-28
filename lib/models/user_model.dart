class UserModel {
  final String id;
  final String username;
  final String displayName;
  final String? email;
  final String? avatarUrl;
  final String role; // 'admin' atau 'user'

  const UserModel({
    required this.id,
    required this.username,
    required this.displayName,
    this.email,
    this.avatarUrl,
    this.role = 'admin',
  });

  bool get isAdmin => role.toLowerCase() == 'admin';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      displayName: json['displayName'] as String? ?? json['username'] as String? ?? '',
      email: json['email'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      role: json['role'] as String? ?? 'admin',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'displayName': displayName,
      'role': role,
      if (email != null) 'email': email,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
    };
  }
}

class AuthResponse {
  final bool success;
  final String message;
  final String? token;
  final UserModel? user;

  const AuthResponse({
    required this.success,
    required this.message,
    this.token,
    this.user,
  });

  factory AuthResponse.success({
    required String token,
    required UserModel user,
    String message = 'Login berhasil',
  }) {
    return AuthResponse(
      success: true,
      message: message,
      token: token,
      user: user,
    );
  }

  factory AuthResponse.failed({required String message}) {
    return AuthResponse(
      success: false,
      message: message,
    );
  }
}
