import 'package:firebase_database/firebase_database.dart';
import 'dart:async';

class SecurityService {
  final String deviceId;
  final _database = FirebaseDatabase.instance;

  SecurityService(this.deviceId);

  Stream<Map<String, dynamic>> get sensorStream {
    return _database.ref('devices/$deviceId/security/sensors').onValue.map((
      event,
    ) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return {};
      return Map<String, dynamic>.from(data);
    });
  }

  Stream<Map<String, dynamic>> get nodeActiveStream {
    return _database.ref('devices/$deviceId/security/nodeActive').onValue.map((
      event,
    ) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return {'status': false, 'lastSeen': 0};
      return Map<String, dynamic>.from(data);
    });
  }

  Stream<bool> get isArmedStream {
    return _database.ref('devices/$deviceId/security/isArmed').onValue.map((
      event,
    ) {
      return (event.snapshot.value as bool?) ?? true;
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
                  ...Map<String, dynamic>.from(e.value as Map),
                },
              )
              .toList();
        });
  }

  Stream<int> get ldrThresholdStream {
    return _database.ref('devices/$deviceId/security/ldrThreshold').onValue.map(
      (event) {
        return (event.snapshot.value as int?) ?? 50;
      },
    );
  }

  Stream<int> get masterLdrStream {
    return _database.ref('devices/$deviceId/security/masterLDR').onValue.map((
      event,
    ) {
      return (event.snapshot.value as int?) ?? 0;
    });
  }

  Stream<bool> get autoLightStream {
    return _database
        .ref('devices/$deviceId/security/autoLightOnMotion')
        .onValue
        .map((event) {
          return (event.snapshot.value as bool?) ?? false;
        });
  }

  Stream<Map<String, bool>> get activePeriodsStream {
    return _database
        .ref('devices/$deviceId/security/activePeriods')
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

  Future<void> setArmedState(bool armed) async {
    await _database.ref('devices/$deviceId/security/isArmed').set(armed);
  }

  Future<void> setLdrThreshold(int value) async {
    await _database.ref('devices/$deviceId/security/ldrThreshold').set(value);
  }

  Future<void> setAutoLightOnMotion(bool enabled) async {
    await _database
        .ref('devices/$deviceId/security/autoLightOnMotion')
        .set(enabled);
  }

  Future<void> setPeriodActive(String period, bool isActive) async {
    await _database
        .ref('devices/$deviceId/security/activePeriods/$period')
        .set(isActive);
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
}
