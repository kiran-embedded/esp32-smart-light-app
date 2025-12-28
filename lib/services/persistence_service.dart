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

  static Future<void> saveAnimationSettings(
    int launchIndex,
    int uiIndex,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_animLaunchKey, launchIndex);
    await prefs.setInt(_animUiKey, uiIndex);
  }

  static Future<Map<String, int>> getAnimationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'launch': prefs.getInt(_animLaunchKey) ?? 0, // Default 0 (iPhoneBlend)
      'ui': prefs.getInt(_animUiKey) ?? 0, // Default 0 (iOSSlide)
    };
  }
}
