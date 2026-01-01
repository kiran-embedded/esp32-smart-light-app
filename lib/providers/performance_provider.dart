import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Provides access to performance settings
final performanceProvider = StateNotifierProvider<PerformanceNotifier, bool>((
  ref,
) {
  return PerformanceNotifier();
});

class PerformanceNotifier extends StateNotifier<bool> {
  PerformanceNotifier() : super(false) {
    _loadState();
  }

  // "High Performance Mode" (meaning: optimized for speed, low visuals)
  // OR "Performance Mode" meaning High Quality?
  // User asked for "Performance Mode" to "disable heavy blurs for low-end".
  // So: true = High Performance (Low Graphics), false = High Quality.
  // Let's call it "isPerformanceMode".
  // true: Simplify UI, lock FPS, disable blur.
  // false: Full visuals.

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('performance_mode') ?? false;
  }

  Future<void> toggle(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('performance_mode', enabled);
    state = enabled;
  }
}
