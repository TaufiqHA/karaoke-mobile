import 'dart:io';
import 'package:flutter/foundation.dart';

/// Konfigurasi terpusat untuk Base URL API backend.
/// Cukup ubah konfigurasi di file ini untuk mengubah endpoint seluruh aplikasi.
class ApiConfig {
  /// Host/IP default untuk backend (misal '127.0.0.1', '10.0.2.2', atau IP LAN seperti '192.168.1.50')
  static const String defaultHost = '103.30.146.68';
  //static const String defaultHost = '10.89.124.207';

  /// Port default untuk Android
  static const String androidPort = '8001';

  /// Port default untuk Desktop / iOS Simulator
  static const String defaultPort = '8001';

  /// Path prefix API
  static const String apiPrefix = '/api';

  /// Base URL custom opsional yang dapat diubah saat runtime (misal dari menu pengaturan).
  /// Jika bernilai tidak null/tidak kosong, nilai ini akan diprioritaskan.
  static String? customBaseUrl;

  /// Mendapatkan base URL otomatis berdasarkan platform yang berjalan.
  static String get baseUrl {
    final custom = customBaseUrl;
    if (custom != null && custom.isNotEmpty) {
      return custom;
    }
    if (kIsWeb) {
      return 'http://localhost:$androidPort$apiPrefix';
    }
    try {
      if (Platform.isAndroid) {
        return 'http://$defaultHost:$androidPort$apiPrefix';
      } else {
        return 'http://$defaultHost:$defaultPort$apiPrefix';
      }
    } catch (_) {
      return 'http://$defaultHost:$defaultPort$apiPrefix';
    }
  }
}
