import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DeviceClass { low, mid, high }

class PerformanceService {
  static Future<void> optimizeSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Check if we've already optimized (don't override user choice)
    if (prefs.getBool('performance_optimized') ?? false) return;

    final deviceClass = await _detectDeviceClass();
    debugPrint("🔥 Auto-Detected Device Class: $deviceClass");

    switch (deviceClass) {
      case DeviceClass.high:
        // Max everything
        await prefs.setInt('anim_launch', 0); // iPhoneBlend
        await prefs.setInt('anim_ui', 1); // ButterZoom
        // Ensure switch_style is set to something premium if not set
        if (prefs.getInt('switch_style_index') == null) {
          // Default to Holographic or similar? Let's leave style alone but ensure FPS
        }
        break;
      case DeviceClass.mid:
        // Balanced
        await prefs.setInt('anim_launch', 1); // AndroidReveal (Cheaper)
        await prefs.setInt('anim_ui', 2); // FluidFade (Fast)
        break;
      case DeviceClass.low:
        // Performance
        await prefs.setInt('anim_launch', 3); // Minimal
        await prefs.setInt('anim_ui', 3); // ZeroLatency
        break;
    }

    // Mark as optimized so we don't overwrite user changes later
    await prefs.setBool('performance_optimized', true);
  }

  static Future<DeviceClass> _detectDeviceClass() async {
    try {
      int processors = Platform.numberOfProcessors;

      // Heuristic: Check available Refresh Rates
      // High-end usually has > 60Hz
      bool hasHighRefresh = false;
      try {
        final modes = await FlutterDisplayMode.supported;
        hasHighRefresh = modes.any((m) => m.refreshRate > 60);
      } catch (e) {
        // Ignore on iOS/Web or errors
      }

      if (processors >= 8 && hasHighRefresh) {
        return DeviceClass.high;
      } else if (processors >= 6) {
        return DeviceClass.mid;
      } else {
        return DeviceClass.low;
      }
    } catch (e) {
      // Fallback
      return DeviceClass.mid;
    }
  }
}
