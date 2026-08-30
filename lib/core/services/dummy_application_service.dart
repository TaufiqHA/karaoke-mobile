import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/application_model.dart';
import 'application_service.dart';

class DummyApplicationService implements ApplicationService {
  static const String _keyApplication = 'app_application_config';

  static const ApplicationModel defaultApplication = ApplicationModel(
    applicationid: 1,
    applicationcompany: 'PT Karaoke Musik Nusantara',
    applicationname: 'Karaoke Mobile App',
    applicationads1: null,
    applicationads2: null,
    applicationadsactive: 'Y',
    applicationadsbottom: null,
    applicationadsbottomactive: 'Y',
  );

  final SharedPreferences? _prefsInstance;

  DummyApplicationService([this._prefsInstance]);

  Future<SharedPreferences> _getPrefs() async {
    return _prefsInstance ?? await SharedPreferences.getInstance();
  }

  @override
  Future<ApplicationModel> getApplicationConfig() async {
    final prefs = await _getPrefs();
    final jsonString = prefs.getString(_keyApplication);
    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final Map<String, dynamic> jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
        return ApplicationModel.fromJson(jsonMap);
      } catch (_) {
        return defaultApplication;
      }
    }
    return defaultApplication;
  }

  @override
  Future<ApplicationModel> updateApplicationConfig(ApplicationModel config) async {
    final prefs = await _getPrefs();
    final jsonString = jsonEncode(config.toJson());
    await prefs.setString(_keyApplication, jsonString);
    return config;
  }
}
