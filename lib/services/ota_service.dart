import 'dart:async';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class OtaService {
  final String ip;

  OtaService(this.ip);

  Future<void> flash(Uint8List firmware, Function(String) onLog, Function(double) onProgress) async {
    try {
      final uri = Uri.parse('http://$ip/update');
      onLog('Preparing HTTP OTA Upload to $uri...');

      var request = http.MultipartRequest('POST', uri);
      
      // We pass the raw bytes as a Multipart file
      var file = http.MultipartFile.fromBytes(
        'update',
        firmware,
        filename: 'firmware.bin',
        contentType: MediaType('application', 'octet-stream'),
      );
      
      request.files.add(file);

      onLog('Uploading ${firmware.length} bytes. Please wait, this may take 30-60 seconds...');
      onProgress(0.1); // Indicate start
      
      // We use a StreamedResponse to simulate progress if needed, but since it's a single post,
      // we'll just wait for the response.
      final streamedResponse = await request.send().timeout(const Duration(seconds: 90));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        if (response.body.contains("OK")) {
          onProgress(1.0);
          onLog('✔ Firmware upload successful!');
          onLog('Device is restarting. Please wait 10 seconds for it to reconnect.');
        } else {
          onLog('Error: Device responded with: ${response.body}');
          throw Exception('Device rejected update: ${response.body}');
        }
      } else {
        onLog('HTTP Error ${response.statusCode}: ${response.body}');
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      if (e is TimeoutException) {
         onLog('OTA Error: Connection timed out. Make sure the ESP32 is online and on the same network.');
      } else {
         onLog('OTA Error: $e');
      }
      throw Exception('OTA failed: $e');
    }
  }
}
