import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PersistenceService {
  static const String _nicknamesKey = 'switch_nicknames';
  static const String _configKey = 'firebase_config';
  static const String _webClientIdKey = 'google_web_client_id';

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
}
