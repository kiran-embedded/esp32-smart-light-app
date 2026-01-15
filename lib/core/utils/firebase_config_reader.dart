import 'dart:convert';
import 'package:flutter/services.dart';

/// Reads and parses google-services.json to extract configuration
class FirebaseConfigReader {
  static Future<Map<String, dynamic>> readAndroidConfig() async {
    try {
      final jsonString = await rootBundle.loadString('android/app/google-services.json');
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      
      final client = (jsonData['client'] as List).first;
      final androidInfo = client['client_info']['android_client_info'];
      
      return {
        'package_name': androidInfo['package_name'] as String,
        'project_id': jsonData['project_info']['project_id'] as String,
        'project_number': jsonData['project_info']['project_number'] as String,
        'mobilesdk_app_id': client['client_info']['mobilesdk_app_id'] as String,
        'api_key': (client['api_key'] as List).first['current_key'] as String,
      };
    } catch (e) {
      throw Exception('Failed to read google-services.json: $e');
    }
  }

  static Future<Map<String, dynamic>> readIOSConfig() async {
    try {
      // For iOS, we'd read GoogleService-Info.plist
      // This is a placeholder - iOS config would be in plist format
      return {
        'bundle_id': 'com.example.nebulacontroller', // From google-services.json
        'project_id': 'nebula-smartpowergrid',
      };
    } catch (e) {
      throw Exception('Failed to read iOS config: $e');
    }
  }
}

