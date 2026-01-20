import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PersistenceService {
  static const String _nicknamesKey = 'switch_nicknames';
  static const String _configKey = 'firebase_config';
  static const String _webClientIdKey = 'google_web_client_id';
  static const String _immersiveModeKey = 'immersive_mode';

  static Future<void> saveFirebaseConfig(Map<String, String> config) async {
    final prefs = await SharedPreferences.getInstance();
    if (config.containsKey('googleWebClientId')) {
      await prefs.setString(_webClientIdKey, config['googleWebClientId']!);
    }
    await prefs.setString(_configKey, jsonEncode(config));
  }

  static Future<Map<String, String>?> getFirebaseConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final configString = prefs.getString(_configKey);
    if (configString == null) return null;
    return Map<String, String>.from(jsonDecode(configString));
  }

  static Future<void> saveNicknames(Map<String, String> nicknames) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nicknamesKey, jsonEncode(nicknames));
  }

  static Future<Map<String, String>> getNicknames() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_nicknamesKey);
    if (data == null) return {};
    return Map<String, String>.from(jsonDecode(data));
  }

  static Future<String?> getGoogleWebClientId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_webClientIdKey);
  }

  static Future<void> clearFirebaseConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_configKey);
    await prefs.remove(_nicknamesKey);
  }

  static Future<void> saveImmersiveMode(bool isEnabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_immersiveModeKey, isEnabled);
  }

  static Future<bool> getImmersiveMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_immersiveModeKey) ??
        true; // Default to true (Immersive)
  }

  static const String _animLaunchKey = 'anim_launch_type';
  static const String _animUiKey = 'anim_ui_type';
  static const String _animEnabledKey = 'animations_enabled';

  static Future<void> saveAnimationSettings(
    int launchIndex,
    int uiIndex,
    bool enabled,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_animLaunchKey, launchIndex);
    await prefs.setInt(_animUiKey, uiIndex);
    await prefs.setBool(_animEnabledKey, enabled);
  }

  static Future<Map<String, dynamic>> getAnimationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'launch': prefs.getInt(_animLaunchKey) ?? 0, // Default 0 (iPhoneBlend)
      'ui': prefs.getInt(_animUiKey) ?? 0, // Default 0 (iOSSlide)
      'enabled': prefs.getBool(_animEnabledKey) ?? true,
    };
  }

  // Connection Settings key
  static const String _connectionModeKey = 'connection_mode';
  static const String _lowDataKey = 'low_data_mode';
  static const String _perfModeKey = 'perf_mode';

  static Future<void> saveConnectionSettings({
    required String mode,
    required bool isLowData,
    required bool isPerformance,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_connectionModeKey, mode);
    await prefs.setBool(_lowDataKey, isLowData);
    await prefs.setBool(_perfModeKey, isPerformance);
  }

  static Future<Map<String, dynamic>> getConnectionSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'mode': prefs.getString(_connectionModeKey) ?? 'cloud',
      'isLowData': prefs.getBool(_lowDataKey) ?? false,
      'isPerformance': prefs.getBool(_perfModeKey) ?? false,
      'isLowLatency':
          prefs.getBool('is_low_latency') ?? true, // Default true for speed
    };
  }

  static Future<void> saveLowLatency(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_low_latency', enabled);
  }

  // Schedule Persistence
  static const String _schedulesKey = 'switch_schedules';
  static const String _deviceIdKey = 'esp32_device_id';
  static const String _geofenceKey = 'geofence_rules';

  static Future<void> saveSchedules(
    List<Map<String, dynamic>> schedules,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_schedulesKey, jsonEncode(schedules));
  }

  static Future<List<Map<String, dynamic>>> getSchedules() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_schedulesKey);
    if (data == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveDeviceId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_deviceIdKey, id);
  }

  static Future<String?> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_deviceIdKey);
  }

  static Future<void> saveGeofenceRules(
    List<Map<String, dynamic>> rules,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_geofenceKey, jsonEncode(rules));
  }

  static Future<List<Map<String, dynamic>>> getGeofenceRules() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_geofenceKey);
    if (data == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      return [];
    }
  }
}
