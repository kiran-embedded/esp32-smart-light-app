import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';
import '../services/security_service.dart';
import '../models/security_log.dart';
import '../services/sound_service.dart';
import '../services/voice_service.dart';
import 'device_id_provider.dart';
import 'dart:async';

class SensorState {
  final bool status;
  final int lastTriggered;
  final int lightLevel;
  final String? nickname;
  final bool isAlarmEnabled;
  final int triggerCount;

  SensorState({
    required this.status,
    required this.lastTriggered,
    required this.lightLevel,
    this.nickname,
    this.isAlarmEnabled = true,
    this.triggerCount = 0,
  });

  factory SensorState.fromMap(Map<dynamic, dynamic> map) {
    return SensorState(
      status: map['status'] ?? false,
      lastTriggered: map['lastTriggered'] ?? 0,
      lightLevel: map['lightLevel'] ?? 0,
      nickname: map['nickname']?.toString(),
      isAlarmEnabled: map['isAlarmEnabled'] ?? true,
      triggerCount: map['triggerCount'] ?? 0,
    );
  }
}

class SensorCalibration {
  final int sensitivity;
  final int debounce;
  final int mode;

  SensorCalibration({this.sensitivity = 1, this.debounce = 200, this.mode = 2});

  factory SensorCalibration.fromMap(Map<dynamic, dynamic> map) {
    return SensorCalibration(
      sensitivity: map['sensitivity'] ?? 1,
      debounce: map['debounce'] ?? 200,
      mode: map['mode'] ?? 2,
    );
  }
}

class SecurityState {
  final Map<String, SensorState> sensors;
  final Map<String, SensorCalibration> calibrations;
  final bool isArmed;
  final List<SecurityLog> logs;
  final int ldrThreshold;
  final bool isAlarmActive;
  final bool isNodeActive;
  final int masterLightLevel;
  final bool autoLightOnMotion;
  final bool isBuzzerMuted;
  final int securityMode; // 0: LDR, 1: Schedule, 2: Hybrid
  final Map<String, bool> activePeriods;
  final List<Map<String, dynamic>> activeBreaches;
  final Set<String> triggeredSensors;
  final int rssi; // Signal Strength in dBm
  final bool ldrValid; // Sensor Health Status

  SecurityState({
    required this.sensors,
    required this.isArmed,
    required this.logs,
    this.calibrations = const {},
    this.ldrThreshold = 50,
    this.isAlarmActive = false,
    this.masterLightLevel = 0,
    this.autoLightOnMotion = false,
    this.activePeriods = const {
      'morning': true,
      'afternoon': true,
      'evening': true,
      'night': true,
      'midnight': true,
    },
    this.isBuzzerMuted = false,
    this.securityMode = 2,
    this.isNodeActive = false,
    this.activeBreaches = const [],
    this.triggeredSensors = const {},
    this.rssi = -100,
    this.ldrValid = true,
  });

  SecurityState copyWith({
    Map<String, SensorState>? sensors,
    Map<String, SensorCalibration>? calibrations,
    bool? isArmed,
    List<SecurityLog>? logs,
    int? ldrThreshold,
    bool? isAlarmActive,
    bool? isNodeActive,
    int? masterLightLevel,
    bool? autoLightOnMotion,
    bool? isBuzzerMuted,
    int? securityMode,
    Map<String, bool>? activePeriods,
    List<Map<String, dynamic>>? activeBreaches,
    Set<String>? triggeredSensors,
    int? rssi,
    bool? ldrValid,
  }) {
    return SecurityState(
      sensors: sensors ?? this.sensors,
      calibrations: calibrations ?? this.calibrations,
      isArmed: isArmed ?? this.isArmed,
      logs: logs ?? this.logs,
      ldrThreshold: ldrThreshold ?? this.ldrThreshold,
      isAlarmActive: isAlarmActive ?? this.isAlarmActive,
      isNodeActive: isNodeActive ?? this.isNodeActive,
      masterLightLevel: masterLightLevel ?? this.masterLightLevel,
      autoLightOnMotion: autoLightOnMotion ?? this.autoLightOnMotion,
      isBuzzerMuted: isBuzzerMuted ?? this.isBuzzerMuted,
      securityMode: securityMode ?? this.securityMode,
      activePeriods: activePeriods ?? this.activePeriods,
      activeBreaches: activeBreaches ?? this.activeBreaches,
      triggeredSensors: triggeredSensors ?? this.triggeredSensors,
      rssi: rssi ?? this.rssi,
      ldrValid: ldrValid ?? this.ldrValid,
    );
  }
}

class SecurityNotifier extends StateNotifier<SecurityState> {
  final SecurityService _service;
  final SoundService _soundService;
  final VoiceService _voiceService;
  final Map<String, DateTime> _lastTriggerTime = {};

  Map<String, bool> _prevSensorStatus = {};
  StreamSubscription? _sensorSub;
  StreamSubscription? _armedSub;
  StreamSubscription? _ldrSub;
  StreamSubscription? _logsSub;
  StreamSubscription? _periodsSub;
  StreamSubscription? _muteSub;
  StreamSubscription? _securityModeSub;
  StreamSubscription? _activeBreachSub;
  StreamSubscription? _alarmActiveSub;
  StreamSubscription? _calibrationSub;

  SecurityNotifier(this._service, this._soundService, this._voiceService)
    : super(SecurityState(sensors: {}, isArmed: false, logs: [])) {
    _init();
  }

  void _init() {
    _service.initAutoDiscovery();
    _sensorSub?.cancel();
    _sensorSub = _service.sensorStream.listen((data) {
      final sensors = data.map(
        (key, value) =>
            MapEntry(key.toString(), SensorState.fromMap(value as Map)),
      );

      final now = DateTime.now();
      final newTriggeredSensors = Set<String>.from(state.triggeredSensors);
      bool anyNewAlarmTrigger = false;
      String? firstNewZone;

      sensors.forEach((key, state) {
        final prevStatus = _prevSensorStatus[key] ?? false;

        if (state.status && !prevStatus) {
          final last = _lastTriggerTime[key];
          if (last == null || now.difference(last).inSeconds >= 10) {
            _lastTriggerTime[key] = now;

            if (this.state.isArmed &&
                state.isAlarmEnabled &&
                _isSystemActive()) {
              newTriggeredSensors.add(key);
              if (!this.state.isAlarmActive) {
                anyNewAlarmTrigger = true;
                firstNewZone ??= key;
              }
            }
          }
        }
        _prevSensorStatus[key] = state.status;
      });

      if (anyNewAlarmTrigger && firstNewZone != null) {
        _handleAlarmTrigger(firstNewZone!);
      }

      state = state.copyWith(
        sensors: sensors,
        triggeredSensors: newTriggeredSensors,
      );
    });

    _armedSub?.cancel();
    _armedSub = _service.isArmedStream.listen((isArmed) {
      if (!isArmed && state.isAlarmActive) {
        stopAlarm();
      }
      state = state.copyWith(isArmed: isArmed);
    });

    _ldrSub?.cancel();
    _ldrSub = _service.ldrThresholdStream.listen((threshold) {
      state = state.copyWith(ldrThreshold: threshold);
    });

    _logsSub?.cancel();
    _logsSub = _service.securityLogsStream.listen((data) {
      final logs = data.map((e) => SecurityLog.fromMap(e['id'], e)).toList();
      logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      state = state.copyWith(logs: logs);
    });

    // Master LDR & Auto-Light listeners
    _service.masterLdrStream.listen((ldr) {
      state = state.copyWith(masterLightLevel: ldr);
    });

    _service.autoLightStream.listen((enabled) {
      state = state.copyWith(autoLightOnMotion: enabled);
    });

    _periodsSub?.cancel();
    _periodsSub = _service.activePeriodsStream.listen((periods) {
      state = state.copyWith(activePeriods: periods);
    });

    _muteSub?.cancel();
    _muteSub = _service.isBuzzerMutedStream.listen((muted) {
      state = state.copyWith(isBuzzerMuted: muted);
    });

    _securityModeSub?.cancel();
    _securityModeSub = _service.securityModeStream.listen((mode) {
      state = state.copyWith(securityMode: mode);
    });

    _activeBreachSub?.cancel();
    _activeBreachSub = _service.activeBreachesStream.listen((breaches) {
      state = state.copyWith(activeBreaches: breaches);
    });

    _alarmActiveSub?.cancel();
    _alarmActiveSub = _service.isAlarmActiveStream.listen((isActive) {
      if (!isActive && state.isAlarmActive) {
        stopAlarm();
      }
    });

    _calibrationSub?.cancel();
    _calibrationSub = FirebaseDatabase.instance
        .ref('devices/${_service.deviceId}/commands/security/calibration')
        .onValue
        .listen((event) {
          final data = event.snapshot.value as Map<dynamic, dynamic>?;
          if (data == null) return;
          final calibrations = data.map(
            (key, value) => MapEntry(
              key.toString(),
              SensorCalibration.fromMap(value as Map),
            ),
          );
          state = state.copyWith(calibrations: calibrations);
        });

    _service.nodeActiveStream.listen((data) {
      final lastSeen = (data['lastSeen'] as num? ?? 0).toInt();
      final onlineStatus = data['online'] as bool? ?? false;
      final rssi = (data['rssi'] as num? ?? -100).toInt();
      final ldrValid = data['ldrValid'] as bool? ?? true;

      // Heartbeat Check: ts from ESP might be unix or millis
      bool isAlive = onlineStatus;
      if (lastSeen > 1000000000) {
        // Unix
        final nowUnix = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        isAlive = onlineStatus && (nowUnix - lastSeen < 30);
      } else {
        // Millis-based or no sync
        isAlive = onlineStatus;
      }

      state = state.copyWith(
        isNodeActive: isAlive,
        rssi: rssi,
        ldrValid: ldrValid,
      );
    });
  }

  void _handleAlarmTrigger(String zone) {
    state = state.copyWith(isAlarmActive: true);
    _soundService.playSiren(looping: true);
    _service.setPanicState(true); // TRIGGER PHYSICAL BUZZER
    final cleanZone = zone.replaceAll('PIR', '').replaceAll('_', ' ').trim();
    _voiceService.speak("$cleanZone motion detected. Security breach alert.");
  }

  Future<void> stopAlarm() async {
    await _soundService.stopAlarm();
    await _service.setPanicState(false); // SILENCE PHYSICAL BUZZER
    await _service.clearActiveBreaches();
    state = state.copyWith(
      isAlarmActive: false,
      triggeredSensors: {},
      activeBreaches: [],
    );
    for (var sensorName in state.sensors.keys) {
      if (state.sensors[sensorName]?.status == true) {
        await acknowledge(sensorName);
      }
    }
  }

  Future<void> testBuzzer() async {
    await _service.testBuzzer();
  }

  Future<void> toggleArmed() async {
    final newState = !state.isArmed;
    await _service.setArmedState(newState);
    if (!newState) {
      await stopAlarm();
    }
  }

  Future<void> updateLdrThreshold(int value) async {
    await _service.setLdrThreshold(value);
  }

  Future<void> toggleAutoLightOnMotion() async {
    final newState = !state.autoLightOnMotion;
    await _service.setAutoLightOnMotion(newState);
  }

  Future<void> setPeriodActive(String period, bool isActive) async {
    // ⚡ Optimistic Update for Industrial Responsiveness
    final newPeriods = Map<String, bool>.from(state.activePeriods);
    newPeriods[period] = isActive;
    state = state.copyWith(activePeriods: newPeriods);

    try {
      await _service.setPeriodActive(period, isActive);
    } catch (e) {
      // Revert on failure
      final revertedPeriods = Map<String, bool>.from(state.activePeriods);
      revertedPeriods[period] = !isActive;
      state = state.copyWith(activePeriods: revertedPeriods);
    }
  }

  Future<void> toggleBuzzerMute() async {
    await _service.setBuzzerMute(!state.isBuzzerMuted);
  }

  Future<void> setSecurityMode(int mode) async {
    await _service.setSecurityMode(mode);
  }

  Future<void> updateCalibration(
    String pirId, {
    int? sensitivity,
    int? debounce,
  }) async {
    final deviceId = _service.deviceId;
    final updates = <String, dynamic>{};
    if (sensitivity != null) updates['sensitivity'] = sensitivity;
    if (debounce != null) updates['debounce'] = debounce;

    if (updates.isNotEmpty) {
      await FirebaseDatabase.instance
          .ref('devices/$deviceId/commands/security/calibration/$pirId')
          .update(updates);
    }
  }

  Future<void> deleteSensor(String sensorName) async {
    await _service.deleteSensor(sensorName);
  }

  Future<void> toggleSensorAlarm(String sensorName) async {
    final sensor = state.sensors[sensorName];
    if (sensor == null) return;
    await _service.setSensorAlarmEnabled(sensorName, !sensor.isAlarmEnabled);
  }

  Future<void> acknowledge(String sensorName) async {
    await _service.acknowledgeAlert(sensorName);
  }

  Future<void> renameSensor(String sensorName, String newName) async {
    await _service.renameSensor(sensorName, newName);
  }

  Future<void> updateSensorMode(String sensorName, int mode) async {
    await _service.setSensorMode(sensorName, mode);
  }

  void simulateTrigger(String sensorName, bool status) {
    final now = DateTime.now();
    final updatedSensors = Map<String, SensorState>.from(state.sensors);

    updatedSensors[sensorName] = SensorState(
      status: status,
      lastTriggered: now.millisecondsSinceEpoch ~/ 1000,
      lightLevel: updatedSensors[sensorName]?.lightLevel ?? 50,
    );

    if (status && state.isArmed && !state.isAlarmActive && _isSystemActive()) {
      _handleAlarmTrigger(sensorName);
    }
    state = state.copyWith(sensors: updatedSensors);
  }

  bool _isSystemActive() {
    final mode = state.securityMode;
    final isDark = state.masterLightLevel <= state.ldrThreshold;

    final hour = DateTime.now().hour;
    String period;
    if (hour >= 6 && hour < 12)
      period = 'morning';
    else if (hour >= 12 && hour < 17)
      period = 'afternoon';
    else if (hour >= 17 && hour < 20)
      period = 'evening';
    else if (hour >= 20 || hour < 0)
      period = 'night';
    else
      period = 'midnight';

    final isTimeActive = state.activePeriods[period] ?? true;

    if (mode == 0) return isDark;
    if (mode == 1) return isTimeActive;
    if (mode == 2) return isDark && isTimeActive;
    return true;
  }

  @override
  void dispose() {
    _sensorSub?.cancel();
    _armedSub?.cancel();
    _ldrSub?.cancel();
    _logsSub?.cancel();
    _periodsSub?.cancel();
    _muteSub?.cancel();
    _securityModeSub?.cancel();
    _activeBreachSub?.cancel();
    _alarmActiveSub?.cancel();
    _calibrationSub?.cancel();
    super.dispose();
  }
}

final securityServiceProvider = Provider<SecurityService>((ref) {
  final id = ref.watch(deviceIdProvider);
  return SecurityService(id);
});

final securityProvider = StateNotifierProvider<SecurityNotifier, SecurityState>(
  (ref) {
    final service = ref.watch(securityServiceProvider);
    final sound = ref.watch(soundServiceProvider);
    final voice = ref.watch(voiceServiceProvider);
    return SecurityNotifier(service, sound, voice);
  },
);
