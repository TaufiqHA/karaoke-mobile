class AdminStatsModel {
  final int totalSongs;
  final int totalUsers;

  const AdminStatsModel({
    required this.totalSongs,
    required this.totalUsers,
  });

  factory AdminStatsModel.fromJson(Map<String, dynamic> json) {
    return AdminStatsModel(
      totalSongs: json['totalSongs'] as int? ?? 0,
      totalUsers: json['totalUsers'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalSongs': totalSongs,
      'totalUsers': totalUsers,
    };
  }
}
