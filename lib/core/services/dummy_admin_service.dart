import 'dart:async';
import '../../models/admin_stats_model.dart';

abstract class AdminService {
  Future<AdminStatsModel> getStats();
}

class DummyAdminService implements AdminService {
  @override
  Future<AdminStatsModel> getStats() async {
    // Simulasi delay request data API (500 ms)
    await Future.delayed(const Duration(milliseconds: 500));

    return const AdminStatsModel(
      totalSongs: 1250,
      totalUsers: 348,
    );
  }
}
