import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/security_service.dart';
import '../models/security_log.dart';
import '../services/sound_service.dart';
import '../services/voice_service.dart';
import 'device_id_provider.dart';
import '../services/haptic_service.dart';
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
    try {
      return SensorState(
        status: map['status'] == true || map['status'] == 1,
        lastTriggered: (map['lastTriggered'] as num? ?? 0).toInt(),
        lightLevel: (map['lightLevel'] as num? ?? 0).toInt(),
        nickname: map['nickname']?.toString(),
        isAlarmEnabled: map['isAlarmEnabled'] != false,
        triggerCount: (map['triggerCount'] as num? ?? 0).toInt(),
      );
    } catch (e) {
      return SensorState(status: false, lastTriggered: 0, lightLevel: 0);
    }
  }

  SensorState copyWith({
    bool? status,
    int? lastTriggered,
    int? lightLevel,
    String? nickname,
    bool? isAlarmEnabled,
    int? triggerCount,
  }) {
    return SensorState(
      status: status ?? this.status,
      lastTriggered: lastTriggered ?? this.lastTriggered,
      lightLevel: lightLevel ?? this.lightLevel,
      nickname: nickname ?? this.nickname,
      isAlarmEnabled: isAlarmEnabled ?? this.isAlarmEnabled,
      triggerCount: triggerCount ?? this.triggerCount,
    );
  }
}

class SatelliteConfig {
  final int pulses;
  final int window;
  final int hold;
  final int gap;
  final int valid;

  SatelliteConfig({
    this.pulses = 2,
    this.window = 15000,
    this.hold = 3000,
    this.gap = 2000,
    this.valid = 200,
  });

  factory SatelliteConfig.fromMap(Map<dynamic, dynamic> map) {
    return SatelliteConfig(
      pulses: (map['pulses'] as num? ?? 2).toInt(),
      window: (map['window'] as num? ?? 15000).toInt(),
      hold: (map['hold'] as num? ?? 3000).toInt(),
      gap: (map['gap'] as num? ?? 2000).toInt(),
      valid: (map['valid'] as num? ?? 200).toInt(),
    );
  }

  SatelliteConfig copyWith({
    int? pulses,
    int? window,
    int? hold,
    int? gap,
    int? valid,
  }) {
    return SatelliteConfig(
      pulses: pulses ?? this.pulses,
      window: window ?? this.window,
      hold: hold ?? this.hold,
      gap: gap ?? this.gap,
      valid: valid ?? this.valid,
    );
  }
}

class SecurityState {
  final Map<String, SensorState> sensors;
  final bool isArmed;
  final bool isNativeAlarmEnabled;
  final List<SecurityLog> logs;
  final int ldrThreshold;
  final bool isAlarmActive;
  final bool isHubOnline;
  final bool isSatOnline;
  final int hubLastSeen;
  final int satLastSeen;
  final int masterLightLevel;
  final bool isBuzzerMuted;
  final int securityMode; // 0: LDR, 1: Schedule, 2: Hybrid, 3: Always
  final Map<String, bool> activePeriods;
  final List<Map<String, dynamic>> activeBreaches;
  final Set<String> triggeredSensors;
  final int rssi; // Signal Strength in dBm
  final bool ldrValid; // Sensor Health Status
  final bool ldrSecurity; // Whether security (Alarm/Relay) is LDR-gated
  final String hubMac;
  final String satMac;
  final Map<String, dynamic> hubTelemetry;
  final Map<String, dynamic> satTelemetry;
  final Map<String, bool> localArmStatus;
  final int globalMotionMode; // 0: Always, 4: Night-Only
  final SatelliteConfig satConfig;
  final Map<String, int> satPulseData;

  SecurityState({
    required this.sensors,
    required this.isArmed,
    required this.logs,
    this.ldrThreshold = 50,
    this.isAlarmActive = false,
    this.isNativeAlarmEnabled = true,
    this.masterLightLevel = 0,
    this.activePeriods = const {
      'morning': true,
      'afternoon': true,
      'evening': true,
      'night': true,
      'midnight': true,
    },
    this.isBuzzerMuted = false,
    this.securityMode = 2,
    this.isHubOnline = false,
    this.isSatOnline = false,
    this.hubLastSeen = 0,
    this.satLastSeen = 0,
    this.activeBreaches = const [],
    this.triggeredSensors = const {},
    this.rssi = -100,
    this.ldrValid = true,
    this.ldrSecurity = false,
    this.localArmStatus = const {},
    this.globalMotionMode = 0,
    this.hubTelemetry = const {},
    this.satTelemetry = const {},
    required this.hubMac,
    required this.satMac,
    SatelliteConfig? satConfig,
    this.satPulseData = const {},
  }) : satConfig = satConfig ?? SatelliteConfig();

  SecurityState copyWith({
    Map<String, SensorState>? sensors,
    bool? isArmed,
    List<SecurityLog>? logs,
    int? ldrThreshold,
    bool? isAlarmActive,
    bool? isNativeAlarmEnabled,
    bool? isHubOnline,
    bool? isSatOnline,
    int? hubLastSeen,
    int? satLastSeen,
    int? masterLightLevel,
    bool? isBuzzerMuted,
    int? securityMode,
    Map<String, bool>? activePeriods,
    List<Map<String, dynamic>>? activeBreaches,
    Set<String>? triggeredSensors,
    int? rssi,
    bool? ldrValid,
    bool? ldrSecurity,
    String? hubMac,
    String? satMac,
    Map<String, dynamic>? hubTelemetry,
    Map<String, dynamic>? satTelemetry,
    Map<String, bool>? localArmStatus,
    int? globalMotionMode,
    SatelliteConfig? satConfig,
    Map<String, int>? satPulseData,
  }) {
    return SecurityState(
      sensors: sensors ?? this.sensors,
      isArmed: isArmed ?? this.isArmed,
      logs: logs ?? this.logs,
      ldrThreshold: ldrThreshold ?? this.ldrThreshold,
      isAlarmActive: isAlarmActive ?? this.isAlarmActive,
      isNativeAlarmEnabled: isNativeAlarmEnabled ?? this.isNativeAlarmEnabled,
      isHubOnline: isHubOnline ?? this.isHubOnline,
      isSatOnline: isSatOnline ?? this.isSatOnline,
      hubLastSeen: hubLastSeen ?? this.hubLastSeen,
      satLastSeen: satLastSeen ?? this.satLastSeen,
      masterLightLevel: masterLightLevel ?? this.masterLightLevel,
      isBuzzerMuted: isBuzzerMuted ?? this.isBuzzerMuted,
      securityMode: securityMode ?? this.securityMode,
      activePeriods: activePeriods ?? this.activePeriods,
      activeBreaches: activeBreaches ?? this.activeBreaches,
      localArmStatus: localArmStatus ?? this.localArmStatus,
      triggeredSensors: triggeredSensors ?? this.triggeredSensors,
      rssi: rssi ?? this.rssi,
      ldrValid: ldrValid ?? this.ldrValid,
      ldrSecurity: ldrSecurity ?? this.ldrSecurity,
      hubMac: hubMac ?? this.hubMac,
      satMac: satMac ?? this.satMac,
      hubTelemetry: hubTelemetry ?? this.hubTelemetry,
      satTelemetry: satTelemetry ?? this.satTelemetry,
      globalMotionMode: globalMotionMode ?? this.globalMotionMode,
      satConfig: satConfig ?? this.satConfig,
      satPulseData: satPulseData ?? this.satPulseData,
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
  StreamSubscription? _statusSub;
  StreamSubscription? _satStatusSub;
  StreamSubscription? _ldrSecuritySub;
  StreamSubscription? _telemetrySub;
  StreamSubscription? _satTelemetrySub;
  StreamSubscription? _globalMotionSub;
  StreamSubscription? _satConfigSub;
  StreamSubscription? _satSensorsSub;

  Timer? _watchdogTimer;
  Timer? _rebuildTimer;
  SecurityState? _pendingState;

  SecurityNotifier(this._service, this._soundService, this._voiceService)
    : super(
        SecurityState(
          sensors: {},
          isArmed: false,
          logs: [],
          hubMac: 'Unknown',
          satMac: 'None',
          hubLastSeen: 0,
          satLastSeen: 0,
          isNativeAlarmEnabled: true,
        ),
      ) {
    _pendingState = state;
    debugPrint("SECURITY_NOTIFIER: Booting System...");
    _init();
    _startWatchdog();
    _loadLocalSettings();
    debugPrint("SECURITY_NOTIFIER: Boot Sequence Complete.");
  }

  void _startWatchdog() {
    _watchdogTimer?.cancel();
    _watchdogTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final hubDiff = now - state.hubLastSeen;
      final satDiff = now - state.satLastSeen;

      final isHubOnline = hubDiff < 30; // 30s threshold
      final isSatOnline = satDiff < 30;

      if (isHubOnline != state.isHubOnline ||
          isSatOnline != state.isSatOnline) {
        state = state.copyWith(
          isHubOnline: isHubOnline,
          isSatOnline: isSatOnline,
          // Purge stale telemetry on disconnect
          hubTelemetry: isHubOnline ? state.hubTelemetry : const {},
          satTelemetry: isSatOnline ? state.satTelemetry : const {},
          rssi: isHubOnline ? state.rssi : -100,
          masterLightLevel: isHubOnline ? state.masterLightLevel : 0,
        );
      }
    });
  }

  Future<void> _loadLocalSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool('native_alarm_enabled') ?? true;

    // Load per-sensor gates
    final Map<String, bool> localGates = {};
    for (int i = 1; i <= 4; i++) {
      final key = "PIR$i";
      localGates[key] = prefs.getBool('arm_gate_$key') ?? true;
    }

    state = state.copyWith(
      isNativeAlarmEnabled: isEnabled,
      localArmStatus: localGates,
    );
    _pendingState = _pendingState?.copyWith(
      isNativeAlarmEnabled: isEnabled,
      localArmStatus: localGates,
    );
  }

  Future<void> toggleNativeAlarm() async {
    final newState = !state.isNativeAlarmEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('native_alarm_enabled', newState);
    state = state.copyWith(isNativeAlarmEnabled: newState);
    _pendingState = _pendingState?.copyWith(isNativeAlarmEnabled: newState);
  }

  void _init() {
    _service.initAutoDiscovery();
    _sensorSub?.cancel();
    _sensorSub = _service.sensorStream.listen((data) {
      try {
        final Map<String, SensorState> sensors = {};
        data.forEach((key, value) {
          if (value is Map) {
            sensors[key.toString()] = SensorState.fromMap(value);
          }
        });

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

              if ((_pendingState?.isArmed ?? this.state.isArmed) &&
                  (this.state.localArmStatus[key] ?? true) &&
                  _isSystemActive()) {
                anyNewAlarmTrigger = true;
                firstNewZone ??= key;

                // Notification removed in favor of full-screen alarm as per user request
              }
            }
          }
          _prevSensorStatus[key] = state.status;
        });

        // 🛡️ ANTI-SPAM UI THREAD SAVER (Deep Identity Guard)
        bool uiNeedsRebuild = false;
        if (sensors.length != state.sensors.length) {
          uiNeedsRebuild = true;
        } else {
          sensors.forEach((key, s) {
            final old = state.sensors[key];
            if (old == null ||
                old.status != s.status ||
                old.lightLevel != s.lightLevel ||
                old.isAlarmEnabled != s.isAlarmEnabled ||
                old.nickname != s.nickname) {
              uiNeedsRebuild = true;
            }
          });
        }

        if (uiNeedsRebuild || anyNewAlarmTrigger) {
          _pendingState = _pendingState?.copyWith(
            sensors: sensors,
            triggeredSensors: newTriggeredSensors,
          );

          if (anyNewAlarmTrigger && firstNewZone != null) {
            _handleAlarmTrigger(firstNewZone!);
          }

          _scheduleRebuild(immediate: anyNewAlarmTrigger);
        }
      } catch (e) {
        print("❌ SENSOR PARSE ERROR: $e");
      }
    });

    _armedSub?.cancel();
    _armedSub = _service.isArmedStream.listen((isArmed) {
      if (isArmed == state.isArmed) return;
      if (!isArmed && state.isAlarmActive) {
        stopAlarm();
      }
      _pendingState = _pendingState?.copyWith(isArmed: isArmed);
      _scheduleRebuild(immediate: true);
    });

    _ldrSub?.cancel();
    _ldrSub = _service.ldrThresholdStream.listen((threshold) {
      if (threshold == state.ldrThreshold) return;
      _pendingState = _pendingState?.copyWith(ldrThreshold: threshold);
      _scheduleRebuild();
    });

    _logsSub?.cancel();
    _logsSub = _service.securityLogsStream.listen((data) {
      final logs = data.map((e) => SecurityLog.fromMap(e['id'], e)).toList();
      logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      _pendingState = _pendingState?.copyWith(logs: logs);
      _scheduleRebuild();
    });

    _service.masterLdrStream.listen((ldr) {
      _pendingState = _pendingState?.copyWith(masterLightLevel: ldr);
      _scheduleRebuild();
    });

    _periodsSub?.cancel();
    _periodsSub = _service.activePeriodsStream.listen((periods) {
      _pendingState = _pendingState?.copyWith(activePeriods: periods);
      _scheduleRebuild();
    });

    _muteSub?.cancel();
    _muteSub = _service.isBuzzerMutedStream.listen((muted) {
      _pendingState = _pendingState?.copyWith(isBuzzerMuted: muted);
      _scheduleRebuild();
    });

    _securityModeSub?.cancel();
    _securityModeSub = _service.securityModeStream.listen((mode) {
      _pendingState = _pendingState?.copyWith(securityMode: mode);
      _scheduleRebuild();
    });

    _activeBreachSub?.cancel();
    _activeBreachSub = _service.activeBreachesStream.listen((breaches) {
      if (breaches.length == state.activeBreaches.length) {
        bool identical = true;
        for (int i = 0; i < breaches.length; i++) {
          if (breaches[i]['id'] != state.activeBreaches[i]['id']) {
            identical = false;
            break;
          }
        }
        if (identical) return;
      }
      _pendingState = _pendingState?.copyWith(activeBreaches: breaches);
      _scheduleRebuild();
    });

    _alarmActiveSub?.cancel();
    _alarmActiveSub = _service.isAlarmActiveStream.listen((isActive) {
      if (isActive == state.isAlarmActive) return;
      if (!isActive && state.isAlarmActive) {
        stopAlarm();
      } else {
        _pendingState = _pendingState?.copyWith(isAlarmActive: isActive);
        _scheduleRebuild(immediate: true);
      }
    });

    _statusSub?.cancel();
    _statusSub = _service.nodeActiveStream.listen((data) {
      final lastSeen = (data['lastSeen'] as num? ?? 0).toInt();
      final rssi = (data['rssi'] as num? ?? -100).toInt();
      final ldrValid = data['ldrValid'] ?? true;

      _pendingState = _pendingState?.copyWith(
        isHubOnline: true,
        hubLastSeen: lastSeen,
        rssi: rssi,
        ldrValid: ldrValid,
      );
      _scheduleRebuild();
    });

    _satStatusSub?.cancel();
    _satStatusSub = _service.satStatusStream.listen((data) {
      final lastSeen = (data['lastSeen'] as num? ?? 0).toInt();
      _pendingState = _pendingState?.copyWith(
        isSatOnline: true,
        satLastSeen: lastSeen,
      );
      _scheduleRebuild();
    });

    _service.ldrSecurityStream.listen((val) {
      _pendingState = _pendingState?.copyWith(ldrSecurity: val);
      _scheduleRebuild();
    });

    _telemetrySub?.cancel();
    _telemetrySub = _service.telemetryStream.listen((data) {
      _pendingState = _pendingState?.copyWith(
        hubMac: data['hubMac']?.toString() ?? 'Unknown',
        satMac: data['satMac']?.toString() ?? 'None',
        satLastSeen: (data['lastSatSeen'] as num? ?? 0).toInt(),
        hubTelemetry: data,
      );
      _scheduleRebuild();
    });

    _satTelemetrySub?.cancel();
    _satTelemetrySub = _service.satTelemetryStream.listen((data) {
      _pendingState = _pendingState?.copyWith(satTelemetry: data);
      _scheduleRebuild();
    });

    _globalMotionSub?.cancel();
    _globalMotionSub = _service.globalMotionModeStream.listen((mode) {
      _pendingState = _pendingState?.copyWith(globalMotionMode: mode);
      _scheduleRebuild();
    });

    _satConfigSub?.cancel();
    _satConfigSub = _service.satConfigStream.listen((data) {
      _pendingState = _pendingState?.copyWith(
        satConfig: SatelliteConfig.fromMap(data),
      );
      _scheduleRebuild();
    });

    _satSensorsSub?.cancel();
    _satSensorsSub = _service.satSensorsStream.listen((data) {
      final pulsesMap = data['pulses'] as Map<dynamic, dynamic>?;
      final normalizedPulses = <String, int>{};

      if (pulsesMap != null) {
        pulsesMap.forEach((k, v) {
          // Normalize "P1" -> "PIR1" for system alignment
          final key = k.toString().replaceAll('P', 'PIR');
          normalizedPulses[key] = (v as num).toInt();
        });
      }

      _pendingState = _pendingState?.copyWith(satPulseData: normalizedPulses);
      _scheduleRebuild();
    });
  }

  bool _isSystemActive() {
    final mode = state.securityMode;
    final isDark = state.masterLightLevel <= state.ldrThreshold;
    final now = DateTime.now();

    bool isTimeActive = false;
    final hour = now.hour;
    if (hour >= 6 && hour < 12) {
      isTimeActive = state.activePeriods['morning'] ?? true;
    } else if (hour >= 12 && hour < 17) {
      isTimeActive = state.activePeriods['afternoon'] ?? true;
    } else if (hour >= 17 && hour < 21) {
      isTimeActive = state.activePeriods['evening'] ?? true;
    } else if (hour >= 21 || hour < 0) {
      isTimeActive = state.activePeriods['night'] ?? true;
    } else {
      isTimeActive = state.activePeriods['midnight'] ?? true;
    }

    if (mode == 0) return isDark;
    if (mode == 1) return isTimeActive;
    if (mode == 2) return isDark && isTimeActive;
    if (mode == 3) return true; // ALWAYS ACTIVE
    return true;
  }

  void _handleAlarmTrigger(String zone) {
    // 🛡️ INDIVIDUAL BASED GATING (Not Cloud Linked)
    if (!(state.localArmStatus[zone] ?? true)) return;

    if (state.isNativeAlarmEnabled) {
      _pendingState = _pendingState?.copyWith(isAlarmActive: true);
      _scheduleRebuild(immediate: true);
      _soundService.playSiren(looping: true);
      _service.setPanicState(true); // TRIGGER PHYSICAL BUZZER
      final cleanZone = zone.replaceAll('PIR', '').replaceAll('_', ' ').trim();
      _voiceService.speak("$cleanZone motion detected. Security breach alert.");
    } else {
      // 🔔 FALLBACK TO STANDARD NOTIFICATION
      // We don't set isAlarmActive to true here, so no full-screen UI
      final sensorName = state.sensors[zone]?.nickname ?? zone;
      _soundService.playAlarmMedium(); // Standard notification-like sound
      _voiceService.speak("Alert: $sensorName motion discovered.");
    }
  }

  Future<void> stopAlarm() async {
    await _soundService.stopAlarm();
    await _service.setPanicState(false); // SILENCE PHYSICAL BUZZER
    await _service.clearActiveBreaches();
    _pendingState = _pendingState?.copyWith(
      isAlarmActive: false,
      triggeredSensors: {},
      activeBreaches: [],
    );
    _scheduleRebuild(immediate: true);
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
    // ⚡ Optimistic Update
    state = state.copyWith(isArmed: newState);
    _pendingState = _pendingState?.copyWith(isArmed: newState);

    try {
      await _service.setArmedState(newState);
      if (!newState) {
        await stopAlarm();
      }
    } catch (e) {
      // Revert on failure
      state = state.copyWith(isArmed: !newState);
      _pendingState = _pendingState?.copyWith(isArmed: !newState);
    }
  }

  Future<void> updateLdrThreshold(int value) async {
    // ⚡ Optimistic Update
    state = state.copyWith(ldrThreshold: value);
    _pendingState = _pendingState?.copyWith(ldrThreshold: value);
    await _service.setLdrThreshold(value);
  }

  Future<void> setPeriodActive(String period, bool isActive) async {
    // ⚡ Optimistic Update for Industrial Responsiveness
    final newPeriods = Map<String, bool>.from(state.activePeriods);
    newPeriods[period] = isActive;
    state = state.copyWith(activePeriods: newPeriods);
    _pendingState = _pendingState?.copyWith(activePeriods: newPeriods);

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
    final newState = !state.isBuzzerMuted;
    // ⚡ Optimistic Update
    state = state.copyWith(isBuzzerMuted: newState);
    _pendingState = _pendingState?.copyWith(isBuzzerMuted: newState);
    await _service.setBuzzerMute(newState);
  }

  Future<void> toggleLdrSecurity() async {
    final newState = !state.ldrSecurity;
    // ⚡ Optimistic Update
    state = state.copyWith(ldrSecurity: newState);
    _pendingState = _pendingState?.copyWith(ldrSecurity: newState);
    await _service.setLdrSecurityEnabled(newState);
  }

  Future<void> setSecurityMode(int mode) async {
    // ⚡ Optimistic Update
    state = state.copyWith(securityMode: mode);
    _pendingState = _pendingState?.copyWith(securityMode: mode);
    await _service.setSecurityMode(mode);
  }

  Future<void> setGlobalMotionMode(int mode) async {
    // ⚡ Optimistic Update
    state = state.copyWith(globalMotionMode: mode);
    _pendingState = _pendingState?.copyWith(globalMotionMode: mode);
    await _service.setGlobalMotionMode(mode);
    HapticService.heavy();
  }

  Future<void> deleteSensor(String sensorName) async {
    await _service.deleteSensor(sensorName);
  }

  Future<void> toggleSensorAlarm(String sensorName) async {
    final currentStatus = state.localArmStatus[sensorName] ?? true;
    final newState = !currentStatus;

    // ⚡ Local App Update (Individual Based, NOT Cloud Linked)
    final newLocalStatus = Map<String, bool>.from(state.localArmStatus);
    newLocalStatus[sensorName] = newState;

    state = state.copyWith(localArmStatus: newLocalStatus);
    _pendingState = _pendingState?.copyWith(localArmStatus: newLocalStatus);

    // Persist Locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('arm_gate_$sensorName', newState);

    HapticService.light();
  }

  Future<void> acknowledge(String sensorName) async {
    await _service.acknowledgeAlert(sensorName);
  }

  Future<void> renameSensor(String sensorName, String newName) async {
    await _service.renameSensor(sensorName, newName);
  }

  Future<void> updateSatConfig(String key, int value) async {
    // ⚡ Forward to service for RTDB sync
    await _service.setSatConfig(key, value);
    HapticService.light();
  }

  Future<void> resetSatConfigToDefaults() async {
    final defaults = {
      'pulses': 2,
      'window': 15000,
      'hold': 3000,
      'gap': 2000,
      'valid': 200,
    };

    HapticService.heavy();

    // Batch update via Service
    for (var entry in defaults.entries) {
      await _service.setSatConfig(entry.key, entry.value);
    }

    // Optimistic UI state update
    state = state.copyWith(satConfig: SatelliteConfig());
  }

  void simulateTrigger(String sensorName, bool status) {
    final now = DateTime.now();
    final updatedSensors = Map<String, SensorState>.from(state.sensors);

    updatedSensors[sensorName] = SensorState(
      status: status,
      lastTriggered: now.millisecondsSinceEpoch ~/ 1000,
      lightLevel: updatedSensors[sensorName]?.lightLevel ?? 50,
    );

    if (status &&
        (_pendingState?.isArmed ?? state.isArmed) &&
        !state.isAlarmActive &&
        _isSystemActive()) {
      _handleAlarmTrigger(sensorName);
    }
    state = state.copyWith(sensors: updatedSensors);
  }

  void _scheduleRebuild({bool immediate = false}) {
    if (immediate) {
      if (_pendingState != null) {
        state = _pendingState!;
        _rebuildTimer?.cancel();
      }
      return;
    }

    if (_rebuildTimer?.isActive ?? false) return;

    _rebuildTimer = Timer(const Duration(milliseconds: 100), () {
      if (_pendingState != null && mounted) {
        state = _pendingState!;
      }
    });
  }

  @override
  void dispose() {
    _rebuildTimer?.cancel();
    _sensorSub?.cancel();
    _armedSub?.cancel();
    _ldrSub?.cancel();
    _logsSub?.cancel();
    _periodsSub?.cancel();
    _muteSub?.cancel();
    _securityModeSub?.cancel();
    _activeBreachSub?.cancel();
    _alarmActiveSub?.cancel();
    _statusSub?.cancel();
    _ldrSecuritySub?.cancel();
    _telemetrySub?.cancel();
    _globalMotionSub?.cancel();
    _satSensorsSub?.cancel();
    _satConfigSub?.cancel();
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
