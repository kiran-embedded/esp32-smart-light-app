import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

final updateServiceProvider = Provider((ref) => UpdateService());

class UpdateInfo {
  final bool hasUpdate;
  final String latestVersion;
  final String downloadUrl;
  final String releaseNotes;

  UpdateInfo({
    required this.hasUpdate,
    required this.latestVersion,
    required this.downloadUrl,
    required this.releaseNotes,
  });
}

class UpdateService {
  // TODO: Replace with actual URL hosted on GitHub/Gist
  static const String _versionCheckUrl =
      'https://raw.githubusercontent.com/kiran-embedded/esp32-smart-light-app/main/version.json';

  Future<UpdateInfo> checkUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      // Combine version and build number for comparison (e.g. "1.0.0+1")
      // because package_info_plus splits them on Android.
      final currentVersion =
          '${packageInfo.version}+${packageInfo.buildNumber}';

      final response = await http.get(
        Uri.parse(
          '$_versionCheckUrl?t=${DateTime.now().millisecondsSinceEpoch}',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final latestVersion = data['version'] as String;
        final downloadUrl = data['download_url'] as String;
        final notes = data['release_notes'] as String;

        final hasUpdate = _compareVersions(currentVersion, latestVersion);

        return UpdateInfo(
          hasUpdate: hasUpdate,
          latestVersion: latestVersion,
          downloadUrl: downloadUrl,
          releaseNotes: notes,
        );
      }
    } catch (e) {
      debugPrint('Update check failed: $e');
    }

    return UpdateInfo(
      hasUpdate: false,
      latestVersion: '',
      downloadUrl: '',
      releaseNotes: '',
    );
  }

  bool _compareVersions(String current, String latest) {
    try {
      // Remove 'v' prefix if present (e.g. "v1.1.0" -> "1.1.0")
      current = current.replaceAll(RegExp(r'^v', caseSensitive: false), '');
      latest = latest.replaceAll(RegExp(r'^v', caseSensitive: false), '');

      final cParts = current.split('+');
      final lParts = latest.split('+');

      final cSemVer = cParts[0].split('.').map(int.parse).toList();
      final lSemVer = lParts[0].split('.').map(int.parse).toList();

      // 1. Compare SemVer (x.y.z)
      for (int i = 0; i < 3; i++) {
        final cV = i < cSemVer.length ? cSemVer[i] : 0;
        final lV = i < lSemVer.length ? lSemVer[i] : 0;
        if (lV > cV) return true;
        if (lV < cV) return false;
      }

      // 2. If SemVer matches, compare Build Number
      final cBuild = cParts.length > 1 ? int.tryParse(cParts[1]) ?? 0 : 0;
      final lBuild = lParts.length > 1 ? int.tryParse(lParts[1]) ?? 0 : 0;

      if (lBuild > cBuild) return true;
    } catch (e) {
      debugPrint('Version compare error: $e');
    }
    return false;
  }

  Future<void> launchUpdateUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
