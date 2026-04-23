import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import '../core/constants/app_constants.dart';

class SecurityService {
  final String deviceId;
  final _database = FirebaseDatabase.instance;

  SecurityService(this.deviceId);

  Stream<Map<String, dynamic>> get sensorStream {
    final path =
        '${AppConstants.firebaseDevicesPath}/$deviceId/${AppConstants.firebaseSecurityPath}/${AppConstants.firebaseSensorsPath}';
    return _database.ref(path).onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return {};
      return Map<String, dynamic>.from(data);
    });
  }

  Stream<Map<String, dynamic>> get nodeActiveStream {
    return _database.ref('devices/$deviceId/status').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return {'online': false, 'lastSeen': 0};
      return Map<String, dynamic>.from(data);
    });
  }

  Stream<Map<String, dynamic>> get satStatusStream {
    return _database.ref('devices/$deviceId/security/nodeActive').onValue.map((
      event,
    ) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return {'online': false, 'lastSeen': 0};
      return Map<String, dynamic>.from(data);
    });
  }

  Stream<bool> get isArmedStream {
    final path =
        '${AppConstants.firebaseDevicesPath}/$deviceId/${AppConstants.firebaseCommandsPath}/isArmed';
    return _database.ref(path).onValue.map((event) {
      return (event.snapshot.value as bool?) ?? false;
    });
  }

  Stream<List<Map<String, dynamic>>> get securityLogsStream {
    return _database
        .ref('devices/$deviceId/security/logs')
        .orderByChild('timestamp')
        .limitToLast(50)
        .onValue
        .map((event) {
          final data = event.snapshot.value as Map<dynamic, dynamic>?;
          if (data == null) return [];
          return data.entries
              .map(
                (e) => {
                  'id': e.key,
                  ...Map<String, dynamic>.from(e.value as Map? ?? {}),
                },
              )
              .toList();
        });
  }

  Stream<int> get ldrThresholdStream {
    final path =
        '${AppConstants.firebaseDevicesPath}/$deviceId/${AppConstants.firebaseCommandsPath}/ldrThreshold';
    return _database.ref(path).onValue.map((event) {
      return (event.snapshot.value as int?) ?? 50;
    });
  }

  Stream<bool> get isBuzzerMutedStream {
    return _database
        .ref('devices/$deviceId/commands/buzzerMute')
        .onValue
        .map((event) => (event.snapshot.value as bool?) ?? false);
  }

  Stream<int> get securityModeStream {
    return _database
        .ref('devices/$deviceId/commands/security/securityMode')
        .onValue
        .map((event) => (event.snapshot.value as int?) ?? 2);
  }

  Stream<bool> get ldrSecurityStream {
    final path =
        '${AppConstants.firebaseDevicesPath}/$deviceId/${AppConstants.firebaseCommandsPath}/ldrSecurity';
    return _database.ref(path).onValue.map((event) {
      return (event.snapshot.value as bool?) ?? false;
    });
  }

  Stream<int> get masterLdrStream {
    return _database.ref('devices/$deviceId/security/masterLDR').onValue.map((
      event,
    ) {
      return (event.snapshot.value as int?) ?? 0;
    });
  }

  Stream<Map<String, bool>> get activePeriodsStream {
    return _database
        .ref('devices/$deviceId/commands/security/activePeriods')
        .onValue
        .map((event) {
          final data = event.snapshot.value as Map<dynamic, dynamic>?;
          if (data == null) {
            return {
              'morning': true,
              'afternoon': true,
              'evening': true,
              'night': true,
              'midnight': true,
            };
          }
          return Map<String, bool>.from(data);
        });
  }

  Stream<List<Map<String, dynamic>>> get activeBreachesStream {
    return _database
        .ref('devices/$deviceId/security/activeBreaches')
        .onValue
        .map((event) {
          final data = event.snapshot.value as Map<dynamic, dynamic>?;
          if (data == null) return [];
          return data.entries
              .map(
                (e) => {
                  'id': e.key,
                  ...Map<String, dynamic>.from(e.value as Map? ?? {}),
                },
              )
              .toList()
            ..sort(
              (a, b) =>
                  (b['timestamp'] as num).compareTo(a['timestamp'] as num),
            );
        });
  }

  Stream<Map<String, dynamic>> get telemetryStream {
    return _database.ref('devices/$deviceId/telemetry').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return {};
      return Map<String, dynamic>.from(data);
    });
  }

  Stream<Map<String, dynamic>> get satTelemetryStream {
    return _database.ref('devices/$deviceId/satellite/telemetry').onValue.map((
      event,
    ) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return {};
      return Map<String, dynamic>.from(data);
    });
  }

  Stream<Map<String, dynamic>> get satConfigStream {
    return _database.ref('devices/$deviceId/satellite/config').onValue.map((
      event,
    ) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return {};
      return Map<String, dynamic>.from(data);
    });
  }

  Stream<int> get globalMotionModeStream {
    return _database
        .ref('devices/$deviceId/commands/globalMotionMode')
        .onValue
        .map((event) => (event.snapshot.value as int?) ?? 0);
  }

  Stream<Map<String, dynamic>> get satSensorsStream {
    return _database.ref('devices/$deviceId/satellite/sensors').onValue.map((
      event,
    ) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return {};
      return Map<String, dynamic>.from(data);
    });
  }

  Future<void> setArmedState(bool armed) async {
    final path =
        '${AppConstants.firebaseDevicesPath}/$deviceId/${AppConstants.firebaseCommandsPath}/isArmed';
    await _database.ref(path).set(armed);
  }

  Future<void> setLdrThreshold(int value) async {
    await _database.ref('devices/$deviceId/commands/ldrThreshold').set(value);
  }

  Future<void> setPeriodActive(String period, bool isActive) async {
    await _database
        .ref('devices/$deviceId/commands/security/activePeriods/$period')
        .set(isActive);
  }

  Future<void> clearActiveBreaches() async {
    final batch = {
      'devices/$deviceId/security/activeBreaches': null,
      'devices/$deviceId/security/alarmActive': false,
      'devices/$deviceId/commands/panic': false,
    };
    await _database.ref().update(batch);
  }

  Future<void> acknowledgeAlert(String sensorName) async {
    await _database
        .ref('devices/$deviceId/security/sensors/$sensorName')
        .update({'status': false});
  }

  Future<void> setSensorAlarmEnabled(String sensorName, bool enabled) async {
    await _database
        .ref('devices/$deviceId/security/sensors/$sensorName')
        .update({'isAlarmEnabled': enabled});
  }

  Future<void> renameSensor(String sensorName, String newName) async {
    await _database
        .ref('devices/$deviceId/security/sensors/$sensorName')
        .update({'nickname': newName});
  }

  Future<void> setPanicState(bool active) async {
    final path =
        '${AppConstants.firebaseDevicesPath}/$deviceId/${AppConstants.firebaseCommandsPath}';
    await _database.ref(path).update({'panic': active});
  }

  Future<void> setBuzzerMute(bool muted) async {
    await _database.ref('devices/$deviceId/commands/buzzerMute').set(muted);
  }

  Future<void> setLdrSecurityEnabled(bool enabled) async {
    await _database.ref('devices/$deviceId/commands/ldrSecurity').set(enabled);
  }

  Future<void> setSecurityMode(int mode) async {
    await _database
        .ref('devices/$deviceId/commands/security/securityMode')
        .set(mode);
  }

  Future<void> setGlobalMotionMode(int mode) async {
    await _database
        .ref('devices/$deviceId/commands/globalMotionMode')
        .set(mode);
  }

  Future<void> setSatConfig(String key, dynamic value) async {
    await _database.ref('devices/$deviceId/satellite/config/$key').set(value);
  }

  Future<void> deleteSensor(String sensorName) async {
    final batch = <String, dynamic>{
      'devices/$deviceId/security/sensors/$sensorName': null,
      'devices/$deviceId/security/calibration/$sensorName': null,
      'devices/$deviceId/telemetry/$sensorName': null,
      'devices/$deviceId/relayNames/$sensorName': null,
    };

    // Clean up hardware mapping bitmask if it follows PIR naming convention
    final reg = RegExp(r'PIR(\d+)');
    final match = reg.firstMatch(sensorName);
    if (match != null) {
      final slot = match.group(1);
      batch['devices/$deviceId/commands/mapPIR$slot'] = 0;
    }

    // Also clean up any automation links in commands
    final commandsRef = _database.ref('devices/$deviceId/commands');
    final snapshot = await commandsRef.get();
    if (snapshot.exists && snapshot.value is Map) {
      final data = snapshot.value as Map;
      data.forEach((key, value) {
        if (key.toString().startsWith('auto_r') &&
            key.toString().endsWith('_sen')) {
          if (value.toString() == sensorName) {
            batch['devices/$deviceId/commands/$key'] =
                'kitchen'; // Default fallback
          }
        }
      });
    }

    await _database.ref().update(batch);
  }

  /// Listen for new sensors appearing in the discovery path (usually pushed by ESP32/ESP8266)
  /// If a sensor is found that isn't in the established sensors list, it's added automatically.
  void initAutoDiscovery() {
    _database
        .ref('devices/$deviceId/security/discovery/pending')
        .onChildAdded
        .listen((event) async {
          final sensorId = event.snapshot.key;
          if (sensorId == null) return;

          final sensorData =
              event.snapshot.value as Map<dynamic, dynamic>? ?? {};

          // Check if already exists in main sensors list
          final existing = await _database
              .ref('devices/$deviceId/security/sensors/$sensorId')
              .get();
          if (!existing.exists) {
            await _database
                .ref('devices/$deviceId/security/sensors/$sensorId')
                .set({
                  'status': false,
                  'lastTriggered': 0,
                  'lightLevel': 50,
                  'nickname': sensorData['name'] ?? 'New Sensor',
                  'isAlarmEnabled': true,
                  'triggerCount': 0,
                  'isLdrSecurityEnabled': false,
                });

            // Push notification or log can go here
          }

          // Clear discovery once processed
          await _database
              .ref('devices/$deviceId/security/discovery/pending/$sensorId')
              .remove();
        });
  }

  Future<void> testBuzzer() async {
    await setPanicState(true);
    await Future.delayed(const Duration(milliseconds: 800));
    await setPanicState(false);
  }

  Stream<bool> get isAlarmActiveStream {
    return _database
        .ref('devices/$deviceId/security/alarmActive')
        .onValue
        .map((event) => (event.snapshot.value as bool?) ?? false);
  }
}
