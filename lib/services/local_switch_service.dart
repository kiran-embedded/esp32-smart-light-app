import 'dart:convert';
import 'package:http/http.dart' as http;

class LocalSwitchService {
  static const String baseUrl = 'http://nebula.local';
  static const String fallbackUrl = 'http://192.168.4.1'; // Default ESP32 AP IP

  Future<bool> sendCommand(
    String relayId,
    int value, {
    bool prioritizeDirectIp = false,
  }) async {
    final firstUrl = prioritizeDirectIp ? fallbackUrl : baseUrl;
    final secondUrl = prioritizeDirectIp ? baseUrl : fallbackUrl;

    // Try primary route
    if (await _safeGet('$firstUrl/set?id=$relayId&state=$value')) return true;

    // Fallback to secondary route
    return await _safeGet('$secondUrl/set?id=$relayId&state=$value');
  }

  Future<Map<String, dynamic>?> getStatus({
    bool prioritizeDirectIp = false,
  }) async {
    final firstUrl = prioritizeDirectIp ? fallbackUrl : baseUrl;
    final secondUrl = prioritizeDirectIp ? baseUrl : fallbackUrl;

    // Try primary
    final res1 = await _safeGetBody('$firstUrl/status');
    if (res1 != null) return res1;

    // Secondary
    return await _safeGetBody('$secondUrl/status');
  }

  Future<bool> _safeGet(String url) async {
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(milliseconds: 1000));
      return response.statusCode == 200;
    } catch (e) {
      print('HTTP GET failed ($url): $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> _safeGetBody(String url) async {
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(milliseconds: 1000));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('HTTP GET Body failed ($url): $e');
    }
    return null;
  }
}
