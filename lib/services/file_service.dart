import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';

class FileService {
  Future<String> saveEsp32Code(String code, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(code);
      return file.path;
    } catch (e) {
      throw Exception('Failed to save file: $e');
    }
  }

  Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  Future<String?> getDownloadPath() async {
    try {
      final directory = await getDownloadsDirectory() ?? 
                       await getApplicationDocumentsDirectory();
      return directory?.path;
    } catch (e) {
      return null;
    }
  }
}

