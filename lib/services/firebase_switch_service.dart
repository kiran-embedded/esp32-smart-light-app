import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../core/constants/app_constants.dart';

/// Firebase Switch Service - PERFECT SYNC ARCHITECTURE
/// Strictly follows the predefined data contract:
/// Commands: /devices/{id}/commands/{relayX} -> 0 | 1
/// Telemetry: /devices/{id}/telemetry/{relayX} -> true | false
class FirebaseSwitchService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  /// Listen strictly to telemetry path for actual relay states
  Stream<Map<String, dynamic>> listenToTelemetry({String? deviceId}) {
    final id = deviceId ?? AppConstants.defaultDeviceId;
    final path = '${AppConstants.firebaseDevicesPath}/$id/telemetry';

    // OPTIMIZATION: Keep this specific path synced for instant updates
    try {
      _database.child(path).keepSynced(true);
    } catch (_) {}

    return _database.child(path).onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null || data is! Map) return {};
      return Map<String, dynamic>.from(data);
    });
  }

  Stream<Map<String, dynamic>> listenToCommands({String? deviceId}) {
    final id = deviceId ?? AppConstants.defaultDeviceId;
    final path = '${AppConstants.firebaseDevicesPath}/$id/commands';

    try {
      _database.child(path).keepSynced(true);
    } catch (_) {}

    return _database.child(path).onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null || data is! Map) return {};
      return Map<String, dynamic>.from(data);
    });
  }

  /// Write a command strictly to /devices/{deviceId}/commands/{relayKey}
  /// value: 0 = OFF, 1 = ON
  /// Uses update() to avoid overwriting other keys.
  /// Includes 2s TIMEOUT to prevent app freeze.

  /// Update the hardware name strictly at /devices/{id}/relayNames/{relayKey}
  Future<void> updateHardwareName(
    String relayKey,
    String newName, {
    String? deviceId,
  }) async {
    final id = deviceId ?? AppConstants.defaultDeviceId;
    final path = '${AppConstants.firebaseDevicesPath}/$id/relayNames';

    await _database.child(path).update({relayKey: newName});
  }

  /// Get hardware names strictly from /devices/{id}/relayNames
  Future<Map<String, String>> getHardwareNames({String? deviceId}) async {
    final id = deviceId ?? AppConstants.defaultDeviceId;
    final path = '${AppConstants.firebaseDevicesPath}/$id/relayNames';

    try {
      final snapshot = await _database.child(path).get();
      if (snapshot.exists && snapshot.value is Map) {
        final data = snapshot.value as Map;
        final safeMap = <String, String>{};
        data.forEach((key, value) {
          safeMap[key.toString()] = value.toString();
        });
        return safeMap;
      }
    } catch (e) {
      print('Firebase fetch error: $e');
    }
    return {};
  }

  /// WAKE-UP CALL: Tiny read to re-activate the socket connection
  /// Using .info/connected is efficient as it doesn't fetch large data.
  /// Includes throttling to prevent spam.
  DateTime? _lastWarmUp;

  Future<void> preWarmConnection({bool force = false}) async {
    final now = DateTime.now();
    // Throttle: only allow once every 15 seconds UNLESS forced (e.g. by user activity)
    if (!force &&
        _lastWarmUp != null &&
        now.difference(_lastWarmUp!).inSeconds < 15) {
      return;
    }

    _lastWarmUp = now;
    if (force) {
      print("FirebaseSwitchService: Force Pre-Warming Connection...");
    }

    try {
      // Just checks connection status, low bandwidth cost
      _database.child('.info/connected').get();
    } catch (_) {
      // Ignore errors
    }
  }

  /// FORCE RESET: Bounce the connection to fix stale sockets
  Future<void> resetConnection() async {
    print('DEBUG: Forcing Firebase Connection Reset...');
    try {
      await FirebaseDatabase.instance.goOffline();
      await Future.delayed(const Duration(milliseconds: 500));
      await FirebaseDatabase.instance.goOnline();
    } catch (e) {
      print('Reset failed (harmless): $e');
    }
  }

  /// Write a command strictly to /devices/{deviceId}/commands/{relayKey}
  /// value: 0 = OFF, 1 = ON
  /// NON-BLOCKING: This method returns immediately while the command sends in the background.
  /// Includes internal retry logic and connection reset.
  void sendCommand(String relayKey, int value, {String? deviceId}) {
    final id = deviceId ?? AppConstants.defaultDeviceId;
    final path = '${AppConstants.firebaseDevicesPath}/$id/commands';

    // Fire and forget
    _executeCommandWithRetry(path, relayKey, value);
  }

  Future<void> _executeCommandWithRetry(
    String path,
    String key,
    int value, {
    int retryCount = 0,
  }) async {
    try {
      await _database
          .child(path)
          .update({key: value})
          .timeout(const Duration(seconds: 3));
    } catch (e) {
      print('Background command failed (Attempt ${retryCount + 1}): $e');
      if (retryCount < 2) {
        // Retry logic: Wait 1s and try again once more after a connection reset
        if (retryCount == 0) await resetConnection();
        await Future.delayed(Duration(seconds: 1 * (retryCount + 1)));
        return _executeCommandWithRetry(
          path,
          key,
          value,
          retryCount: retryCount + 1,
        );
      }
    }
  }

  /// OPTIMIZATION: Enable offline persistence and faster syncing
  Future<void> optimizeConnection(bool enabled) async {
    try {
      FirebaseDatabase.instance.setPersistenceEnabled(enabled);
      FirebaseDatabase.instance.setPersistenceCacheSizeBytes(
        10000000,
      ); // 10MB cache
      print(
        'Firebase Optimization: Persistence ${enabled ? 'ENABLED' : 'DISABLED'}',
      );
    } catch (e) {
      print('Failed to set persistence (might be already set): $e');
    }
  }
}
