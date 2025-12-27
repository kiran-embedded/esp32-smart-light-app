import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

class JsonImportService {
  Future<Map<String, dynamic>?> pickJsonFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final file = File(filePath);
        final fileContent = await file.readAsString();
        return json.decode(fileContent) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to import JSON file: $e');
    }
  }

  Map<String, dynamic>? parseJsonString(String jsonString) {
    try {
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      throw FormatException('Invalid JSON format: $e');
    }
  }

  bool validateGoogleServicesJson(Map<String, dynamic> json) {
    return json.containsKey('project_info') && json.containsKey('client');
  }

  Map<String, String>? extractFirebaseConfig(Map<String, dynamic> json) {
    try {
      final projectInfo = json['project_info'] as Map<String, dynamic>;
      final clients = json['client'] as List<dynamic>;

      // Look for the android client
      final client = clients.firstWhere(
        (c) =>
            (c['client_info']['android_client_info']['package_name'] ==
            'com.iot.nebulacontroller'),
        orElse: () => clients.first,
      );

      final apiKey = client['api_key'][0]['current_key'] as String;
      final appId = client['client_info']['mobilesdk_app_id'] as String;
      final projectId = projectInfo['project_id'] as String;
      final messagingSenderId = projectInfo['project_number'] as String;

      // Extract RTDB URL if present, else fallback
      final databaseURL =
          projectInfo['firebase_url'] as String? ??
          'https://$projectId-default-rtdb.firebaseio.com';

      // Extract Web Client ID for Google Sign-In
      String? webClientId;
      final oauthClients = client['oauth_client'] as List<dynamic>?;
      if (oauthClients != null) {
        final webClient = oauthClients.firstWhere(
          (c) => c['client_type'] == 3,
          orElse: () => null,
        );
        if (webClient != null) {
          webClientId = webClient['client_id'] as String;
        }
      }

      return {
        'apiKey': apiKey,
        'projectId': projectId,
        'databaseURL': databaseURL,
        'appId': appId,
        'messagingSenderId': messagingSenderId,
        'googleWebClientId': webClientId ?? '',
      };
    } catch (e) {
      return null;
    }
  }
}
