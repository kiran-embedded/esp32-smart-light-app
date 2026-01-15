import 'dart:async';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PerformanceStats {
  final double fps;
  final double cpuUsage;
  final double memoryUsage;
  final bool globalFpsEnabled;
  final bool consoleVisible;

  PerformanceStats({
    required this.fps,
    required this.cpuUsage,
    required this.memoryUsage,
    required this.globalFpsEnabled,
    this.consoleVisible = false,
  });

  PerformanceStats copyWith({
    double? fps,
    double? cpuUsage,
    double? memoryUsage,
    bool? globalFpsEnabled,
    bool? consoleVisible,
  }) {
    return PerformanceStats(
      fps: fps ?? this.fps,
      cpuUsage: cpuUsage ?? this.cpuUsage,
      memoryUsage: memoryUsage ?? this.memoryUsage,
      globalFpsEnabled: globalFpsEnabled ?? this.globalFpsEnabled,
      consoleVisible: consoleVisible ?? this.consoleVisible,
    );
  }
}

final performanceStatsProvider =
    StateNotifierProvider<PerformanceStatsNotifier, PerformanceStats>((ref) {
      return PerformanceStatsNotifier();
    });

class PerformanceStatsNotifier extends StateNotifier<PerformanceStats> {
  PerformanceStatsNotifier()
    : super(
        PerformanceStats(
          fps: 60.0,
          cpuUsage: 0.1,
          memoryUsage: 124.0,
          globalFpsEnabled: false,
        ),
      );

  Timer? _fpsTimer;
  int _frameCount = 0;
  DateTime _lastTime = DateTime.now();

  bool _isMonitoring = false;

  void toggleGlobalFps(bool enabled) {
    state = state.copyWith(globalFpsEnabled: enabled);
    if (enabled) {
      startMonitoring();
    }
  }

  void toggleConsole(bool visible) {
    state = state.copyWith(consoleVisible: visible);
    if (visible) {
      startMonitoring();
    }
  }

  void startMonitoring() {
    if (_isMonitoring) return;
    _isMonitoring = true;
    _lastTime = DateTime.now();
    _frameCount = 0;

    // FPS Tracking using SchedulerBinding
    SchedulerBinding.instance.addPostFrameCallback(_onFrame);

    // Stats Update Timer
    _fpsTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      _updateStats();
    });
  }

  void stopMonitoring() {
    _isMonitoring = false;
    _fpsTimer?.cancel();
  }

  void _onFrame(Duration timestamp) {
    if (!_isMonitoring) return;
    _frameCount++;
    SchedulerBinding.instance.addPostFrameCallback(_onFrame);
  }

  void _updateStats() {
    final now = DateTime.now();
    final elapsed = now.difference(_lastTime).inMilliseconds;

    if (elapsed > 0) {
      double currentFps = (_frameCount * 1000) / elapsed;
      if (currentFps > 240) currentFps = 240; // Cap at 240 for logic

      // Simulate CPU usage based on FPS and some randomness
      // In a real debug build we could use VM service, but for a "Developer Test UI"
      // we usually want a clean, fast overlay.
      double simulatedCpu =
          0.05 + (0.15 * (1.0 - (currentFps / 120.0)).clamp(0, 1));
      simulatedCpu +=
          (DateTime.now().millisecond % 5) / 100.0; // Add some jitter

      state = state.copyWith(
        fps: currentFps,
        cpuUsage: simulatedCpu,
        memoryUsage: 120.0 + (DateTime.now().second % 10),
      );
    }

    _frameCount = 0;
    _lastTime = now;
  }

  @override
  void dispose() {
    stopMonitoring();
    super.dispose();
  }
}
