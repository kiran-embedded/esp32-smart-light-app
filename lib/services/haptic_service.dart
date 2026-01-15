import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibration/vibration.dart';

enum HapticStyle {
  light, // "Butter" - System Click
  medium, // "Smooth" - 20ms
  heavy, // "Pulse" - 50ms
}

class HapticService {
  // Cache hardware capabilities to avoid async platform channel calls on every tap
  static bool _initialized = false;
  static bool _hasVibrator = false;
  static bool _hasCustomSupport = false;

  static Future<void> init() async {
    if (_initialized) return;
    try {
      _hasVibrator = await Vibration.hasVibrator() ?? false;
      _hasCustomSupport = await Vibration.hasCustomVibrationsSupport() ?? false;
    } catch (_) {
      _hasVibrator = false;
      _hasCustomSupport = false;
    }
    _initialized = true;
  }

  static Future<void> feedback(HapticStyle style) async {
    // Ensure initialized (lazy init fallback, though main() should call init)
    if (!_initialized) await init();

    // Fallback to basic haptics if no advanced control
    if (!_hasVibrator) {
      // Just try standard system feedback as a last resort
      await HapticFeedback.mediumImpact();
      return;
    }

    try {
      // "Butter" feel optimization
      if (style == HapticStyle.light && _hasCustomSupport) {
        // Ultra-sharp 10ms click for premium feel
        Vibration.vibrate(duration: 8, amplitude: 30);
        return;
      }

      switch (style) {
        case HapticStyle.light:
          // "Butter" - Very short, crisp
          if (_hasCustomSupport) {
            // Fallback for custom support but no amplitude control
            Vibration.vibrate(duration: 10);
          } else {
            HapticFeedback.lightImpact(); // System standard
          }
          break;

        case HapticStyle.medium:
          // "Smooth" - Noticeable bump
          if (_hasCustomSupport) {
            Vibration.vibrate(duration: 25, amplitude: 60);
          } else {
            HapticFeedback.mediumImpact();
          }
          break;

        case HapticStyle.heavy:
          // "Pulse" - Strong, undeniable vibration
          if (_hasCustomSupport) {
            Vibration.vibrate(duration: 50, amplitude: 128);
          } else {
            HapticFeedback.heavyImpact();
          }
          break;
      }
    } catch (e) {
      // Fallback on error
      HapticFeedback.mediumImpact();
    }
  }

  // Quick aliases
  static Future<void> light() async => feedback(HapticStyle.light);
  static Future<void> medium() async => feedback(HapticStyle.medium);
  static Future<void> heavy() async => feedback(HapticStyle.heavy);

  static Future<void> lightImpact() async => light();
  static Future<void> mediumImpact() async => medium();

  static Future<void> selection() async => HapticFeedback.selectionClick();

  static Future<void> pulse() async {
    await feedback(HapticStyle.heavy);
  }
}

// Provider to easily trigger haptics based on current settings
final hapticServiceProvider = Provider((ref) {
  // Import hapticStyleProvider from the new haptic_provider.dart
  return HapticService();
});

enum HapticType { buttonPress, notification }
