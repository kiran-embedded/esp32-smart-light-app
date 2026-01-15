import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../providers/connection_settings_provider.dart';
import '../providers/switch_provider.dart';

class UserActivityState {
  final bool isMonitoring;
  final bool isMoving;
  final DateTime? lastMotion;

  UserActivityState({
    this.isMonitoring = false,
    this.isMoving = false,
    this.lastMotion,
  });

  UserActivityState copyWith({
    bool? isMonitoring,
    bool? isMoving,
    DateTime? lastMotion,
  }) {
    return UserActivityState(
      isMonitoring: isMonitoring ?? this.isMonitoring,
      isMoving: isMoving ?? this.isMoving,
      lastMotion: lastMotion ?? this.lastMotion,
    );
  }
}

/// Service to detect user activity and pre-warm connections
/// Uses Accelerometer to detect if the user picks up the phone.
class UserActivityService extends StateNotifier<UserActivityState>
    with WidgetsBindingObserver {
  final Ref _ref;
  StreamSubscription? _accelSubscription;
  DateTime? _lastSensorProcess;

  UserActivityService(this._ref) : super(UserActivityState()) {
    WidgetsBinding.instance.addObserver(this);
    _initSensors();
  }

  void _initSensors() {
    _checkAndToggleMonitoring();

    // Listen to setting changes
    _ref.listen(connectionSettingsProvider, (previous, next) {
      _checkAndToggleMonitoring();
    });
  }

  void _checkAndToggleMonitoring() {
    final isPerformance = _ref
        .read(connectionSettingsProvider)
        .isPerformanceMode;
    // Only monitor if Performance Mode is ON and App is VISIBLE (Resumed)
    final isActiveState =
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

    if (isPerformance && isActiveState) {
      if (_accelSubscription == null) _startMonitoring();
    } else {
      if (_accelSubscription != null) _stopMonitoring();
    }
  }

  void _startMonitoring() {
    state = state.copyWith(isMonitoring: true);
    _accelSubscription = accelerometerEventStream().listen((event) {
      final now = DateTime.now();

      // ADAPTIVE POLLING:
      final idleTime = state.lastMotion == null
          ? 60
          : now.difference(state.lastMotion!).inSeconds;
      final pollInterval = idleTime > 30
          ? 1000
          : 250; // Faster poll when active

      if (_lastSensorProcess != null &&
          now.difference(_lastSensorProcess!).inMilliseconds < pollInterval) {
        return;
      }
      _lastSensorProcess = now;

      // LOGIC: Simple magnitude check
      final total = event.x.abs() + event.y.abs() + event.z.abs();
      if ((total - 9.8).abs() > 1.0) {
        // Slightly more sensitive
        _onUserActive();
      } else if (state.isMoving) {
        state = state.copyWith(isMoving: false);
      }
    });
  }

  void _stopMonitoring() {
    if (_accelSubscription != null) {
      _accelSubscription?.cancel();
      _accelSubscription = null;
      state = state.copyWith(isMonitoring: false, isMoving: false);
    }
  }

  void _onUserActive() {
    final now = DateTime.now();
    state = state.copyWith(isMoving: true, lastMotion: now);

    // Throttle warmup call
    if (state.lastMotion != null &&
        now.difference(state.lastMotion!).inSeconds < 5) {
      // Still update motion state but don't re-trigger warmup
    }

    _ref.read(firebaseSwitchServiceProvider).preWarmConnection(force: true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _checkAndToggleMonitoring();
    if (state == AppLifecycleState.resumed) {
      _ref.read(firebaseSwitchServiceProvider).resetConnection();
      _ref.read(firebaseSwitchServiceProvider).preWarmConnection(force: true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopMonitoring();
    super.dispose();
  }
}

final userActivityServiceProvider =
    StateNotifierProvider<UserActivityService, UserActivityState>((ref) {
      return UserActivityService(ref);
    });
