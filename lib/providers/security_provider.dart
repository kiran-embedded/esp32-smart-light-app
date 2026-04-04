import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  SensorState({
    required this.status,
    required this.lastTriggered,
    required this.lightLevel,
  });

  factory SensorState.fromMap(Map<dynamic, dynamic> map) {
    return SensorState(
      status: map['status'] ?? false,
      lastTriggered: map['lastTriggered'] ?? 0,
      lightLevel: map['lightLevel'] ?? 0,
    );
  }
}

class SecurityState {
  final Map<String, SensorState> sensors;
  final bool isArmed;
  final List<SecurityLog> logs;
  final int ldrThreshold;
  final bool isAlarmActive;
  final int masterLightLevel;
  final bool autoLightOnMotion;

  SecurityState({
    required this.sensors,
    required this.isArmed,
    required this.logs,
    this.ldrThreshold = 50,
    this.isAlarmActive = false,
    this.masterLightLevel = 0,
    this.autoLightOnMotion = false,
  });

  SecurityState copyWith({
    Map<String, SensorState>? sensors,
    bool? isArmed,
    List<SecurityLog>? logs,
    int? ldrThreshold,
    bool? isAlarmActive,
    int? masterLightLevel,
    bool? autoLightOnMotion,
  }) {
    return SecurityState(
      sensors: sensors ?? this.sensors,
      isArmed: isArmed ?? this.isArmed,
      logs: logs ?? this.logs,
      ldrThreshold: ldrThreshold ?? this.ldrThreshold,
      isAlarmActive: isAlarmActive ?? this.isAlarmActive,
      masterLightLevel: masterLightLevel ?? this.masterLightLevel,
      autoLightOnMotion: autoLightOnMotion ?? this.autoLightOnMotion,
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

  SecurityNotifier(this._service, this._soundService, this._voiceService)
    : super(SecurityState(sensors: {}, isArmed: true, logs: [])) {
    _init();
  }

  void _init() {
    _sensorSub?.cancel();
    _sensorSub = _service.sensorStream.listen((data) {
      final sensors = data.map(
        (key, value) =>
            MapEntry(key.toString(), SensorState.fromMap(value as Map)),
      );

      final now = DateTime.now();
      bool shouldTriggerAlarm = false;
      String? triggeredZone;

      sensors.forEach((key, state) {
        final prevStatus = _prevSensorStatus[key] ?? false;

        if (state.status && !prevStatus) {
          final last = _lastTriggerTime[key];
          if (last == null || now.difference(last).inSeconds >= 10) {
            _lastTriggerTime[key] = now;

            if (this.state.isArmed) {
              shouldTriggerAlarm = true;
              triggeredZone = key;
            }
          }
        }
        _prevSensorStatus[key] = state.status;
      });

      if (shouldTriggerAlarm && triggeredZone != null) {
        _handleAlarmTrigger(triggeredZone!);
      }

      state = state.copyWith(sensors: sensors);
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
  }

  void _handleAlarmTrigger(String zone) {
    state = state.copyWith(isAlarmActive: true);
    _soundService.playSiren(looping: true);
    final cleanZone = zone.replaceAll('PIR', '').replaceAll('_', ' ').trim();
    _voiceService.speak("$cleanZone motion detected. Security breach alert.");
  }

  Future<void> stopAlarm() async {
    await _soundService.stopAlarm();
    state = state.copyWith(isAlarmActive: false);
    for (var sensorName in state.sensors.keys) {
      if (state.sensors[sensorName]?.status == true) {
        await acknowledge(sensorName);
      }
    }
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

  Future<void> acknowledge(String sensorName) async {
    await _service.acknowledgeAlert(sensorName);
  }

  void simulateTrigger(String sensorName, bool status) {
    final now = DateTime.now();
    final updatedSensors = Map<String, SensorState>.from(state.sensors);

    updatedSensors[sensorName] = SensorState(
      status: status,
      lastTriggered: now.millisecondsSinceEpoch ~/ 1000,
      lightLevel: updatedSensors[sensorName]?.lightLevel ?? 50,
    );

    if (status && state.isArmed && !state.isAlarmActive) {
      _handleAlarmTrigger(sensorName);
    }
    state = state.copyWith(sensors: updatedSensors);
  }

  @override
  void dispose() {
    _sensorSub?.cancel();
    _armedSub?.cancel();
    _ldrSub?.cancel();
    _logsSub?.cancel();
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
