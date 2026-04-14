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

  /// Listen reactively to hardware name changes
  Stream<Map<String, String>> listenToHardwareNames({String? deviceId}) {
    final id = deviceId ?? AppConstants.defaultDeviceId;
    final path = '${AppConstants.firebaseDevicesPath}/$id/relayNames';

    try {
      _database.child(path).keepSynced(true);
    } catch (_) {}

    return _database.child(path).onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null || data is! Map) return {};
      final rawMap = Map<String, dynamic>.from(data);
      final safeMap = <String, String>{};
      rawMap.forEach((key, value) {
        safeMap[key.toString()] = value.toString();
      });
      return safeMap;
    });
  }

  /// Write a command strictly to /devices/{deviceId}/commands/{relayKey}
  /// value: 0 = OFF, 1 = ON
  /// Uses update() to avoid overwriting other keys.
  /// Includes 2s TIMEOUT to prevent app freeze.

  /// Update the hardware name strictly at /devices/{id}/relayNames/{relayKey}
  Future<void> updateHardwareName(
    String relayId,
    String name, {
    required String deviceId,
  }) async {
    await _database.child('devices/$deviceId/relayNames').update({
      relayId: name,
    });
  }

  Future<void> deleteRelay(String relayId, {required String deviceId}) async {
    await _database.child('devices/$deviceId/commands/$relayId').remove();
    await _database.child('devices/$deviceId/telemetry/$relayId').remove();
    await _database.child('devices/$deviceId/relayNames/$relayId').remove();
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

  /// Update the inverted logic boolean at /devices/{id}/commands/invert{X}
  Future<void> updateInvertedLogic(
    int relayIndex,
    bool isInverted, {
    String? deviceId,
  }) async {
    final id = deviceId ?? AppConstants.defaultDeviceId;
    final path = '${AppConstants.firebaseDevicesPath}/$id/commands';

    // Commands path update to avoid overwriting other relays config
    await _database.child(path).update({'invert$relayIndex': isInverted});
  }

  /// Listen reactively to inverted logic state in /devices/{id}/commands
  Stream<Map<int, bool>> listenToInvertedLogic({String? deviceId}) {
    final id = deviceId ?? AppConstants.defaultDeviceId;
    final path = '${AppConstants.firebaseDevicesPath}/$id/commands';

    return _database.child(path).onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null || data is! Map) return {};
      final rawMap = Map<String, dynamic>.from(data);
      final safeMap = <int, bool>{};

      for (int i = 1; i <= 7; i++) {
        if (rawMap.containsKey('invert$i')) {
          final dynamic val = rawMap['invert$i'];
          // Safely handle booleans, strings, or integers stored natively
          safeMap[i] = (val == true || val == 1 || val == 'true' || val == '1');
        } else {
          safeMap[i] = false;
        }
      }
      return safeMap;
    });
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

  /// Write commands strictly to /devices/{deviceId}/commands/
  /// values: Map of relayKey to value (0 = OFF, 1 = ON)
  /// NON-BLOCKING: Returns immediately while the command sends in the background.
  Future<void> sendCommands(
    Map<String, int> relayUpdates, {
    String? deviceId,
    String? relayName, // Optional if multiple, usually null
    String triggeredBy = 'app',
  }) async {
    if (relayUpdates.isEmpty) return;
    final id = deviceId ?? AppConstants.defaultDeviceId;
    final path = '${AppConstants.firebaseDevicesPath}/$id/commands';

    // 1. Prepare and Batch execute commands with Priority
    final pRelayUpdates = Map<String, dynamic>.from(relayUpdates);
    final int priority = (triggeredBy == 'scheduler') ? 0 : 2;

    for (var relayKey in relayUpdates.keys) {
      final relayNum = relayKey.replaceAll('relay', '');
      pRelayUpdates['relPrio$relayNum'] = priority;
    }

    _executeBatchCommandsWithRetry(path, pRelayUpdates);
  }

  /// Legacy method for single command
  Future<void> sendCommand(
    String relayKey,
    int value, {
    String? deviceId,
    String? relayName,
    String triggeredBy = 'app',
  }) => sendCommands(
    {relayKey: value},
    deviceId: deviceId,
    relayName: relayName,
    triggeredBy: triggeredBy,
  );

  Future<void> _executeBatchCommandsWithRetry(
    String path,
    Map<String, dynamic> updates, {
    int retryCount = 0,
  }) async {
    try {
      await _database.child(path).update(updates);
    } catch (e) {
      print('Background batch command failed (Attempt ${retryCount + 1}): $e');
      if (retryCount < 2) {
        if (retryCount == 0) await resetConnection();
        await Future.delayed(Duration(seconds: 1 * (retryCount + 1)));
        return _executeBatchCommandsWithRetry(
          path,
          updates,
          retryCount: retryCount + 1,
        );
      }
    }
  }

  // --- AUTOMATION ENGINE ---
  Stream<Map<String, dynamic>> listenToAutomation(
    int relayIndex, {
    String deviceId = AppConstants.defaultDeviceId,
  }) {
    return _database.child('devices/$deviceId/commands').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return {};

      final r = relayIndex + 1;
      return {
        'sensor': data['auto_r${r}_sen'] ?? 'kitchen',
        'duration': data['auto_r${r}_dur'] ?? 60,
        'ldr': data['auto_r${r}_thr'] ?? 50,
        'isActive': data['auto_r${r}_act'] ?? false,
        'timeMode': data['auto_r${r}_tm'] ?? 0,
      };
    });
  }

  Future<void> updateAutomation(
    int relayIndex,
    String sensor,
    int duration,
    int ldr,
    bool isActive, [
    int timeMode = 0,
  ]) async {
    final r = relayIndex + 1;
    final String deviceId = AppConstants.defaultDeviceId;
    await _database.child('devices/$deviceId/commands').update({
      'auto_r${r}_sen': sensor,
      'auto_r${r}_dur': duration,
      'auto_r${r}_thr': ldr,
      'auto_r${r}_act': isActive,
      'auto_r${r}_tm': timeMode,
    });
  }

  static bool _persistenceSet = false;

  /// OPTIMIZATION: Enable offline persistence and faster syncing
  Future<void> optimizeConnection(bool enabled) async {
    if (_persistenceSet) return; // Cannot change after initialization
    try {
      FirebaseDatabase.instance.setPersistenceEnabled(enabled);
      FirebaseDatabase.instance.setPersistenceCacheSizeBytes(10000000);
      _persistenceSet = true;
      print(
        'Firebase Optimization: Persistence ${enabled ? 'ENABLED' : 'DISABLED'}',
      );
    } catch (e) {
      _persistenceSet = true; // Still mark as set to avoid retry crashes
      print('Firebase Persistence already set: $e');
    }
  }

  Future<bool> get isConnected async {
    try {
      final snapshot = await _database.child('.info/connected').get();
      return snapshot.exists && (snapshot.value == true);
    } catch (_) {
      return false;
    }
  }

  Future<void> applyLatencySettings(bool lowLatency) async {
    final id = AppConstants.defaultDeviceId;
    final telePath = '${AppConstants.firebaseDevicesPath}/$id/telemetry';
    final cmdPath = '${AppConstants.firebaseDevicesPath}/$id/commands';

    try {
      if (lowLatency) {
        // Force high priority sync
        await _database.child(telePath).keepSynced(true);
        await _database.child(cmdPath).keepSynced(true);
      } else {
        // Standard sync
        await _database.child(telePath).keepSynced(true);
      }
    } catch (_) {}
  }
}
