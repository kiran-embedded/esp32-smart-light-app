import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../core/constants/app_constants.dart';
import '../core/system/runtime_stability_buffer.dart';

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

  Future<void> preWarmConnection() async {
    final now = DateTime.now();
    // Throttle: only allow once every 15 seconds
    if (_lastWarmUp != null && now.difference(_lastWarmUp!).inSeconds < 15) {
      return;
    }

    _lastWarmUp = now;
    try {
      _database.child('.info/connected').get();
    } catch (_) {
      // Ignore errors
    }
  }

  /// FORCE RESET: Bounce the connection to fix stale sockets
  Future<void> resetConnection() async {
    print('DEBUG: Forcing Firebase Connection Reset...');
    try {
      // Buffer Sync
      await RuntimeStabilityBuffer.sync(200, 1000);
      await FirebaseDatabase.instance.goOffline();
      await Future.delayed(const Duration(milliseconds: 500));
      await FirebaseDatabase.instance.goOnline();
    } catch (e) {
      print('Reset failed (harmless): $e');
    }
  }

  /// Write a command strictly to /devices/{deviceId}/commands/{relayKey}
  /// value: 0 = OFF, 1 = ON
  /// Uses update() to avoid overwriting other keys.
  /// Includes 2s TIMEOUT to prevent app freeze.
  Future<void> sendCommand(
    String relayKey,
    int value, {
    String? deviceId,
  }) async {
    final id = deviceId ?? AppConstants.defaultDeviceId;
    final path = '${AppConstants.firebaseDevicesPath}/$id/commands';

    try {
      // Optimize Sync
      await RuntimeStabilityBuffer.sync(300, 1500);

      // Per strict contract: update ONLY the specific relay key
      await _database
          .child(path)
          .update({relayKey: value})
          .timeout(const Duration(seconds: 2));
    } catch (e) {
      print('Command timed out or failed. Resetting connection. Error: $e');
      // If write hangs/fails, reset connection for next time
      resetConnection();
      rethrow; // Propagate error to UI so it can rollback
    }
  }
}
