import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibration/vibration.dart';

enum HapticStyle {
  light, // "Butter" - System Click
  medium, // "Smooth" - 20ms
  heavy, // "Pulse" - 50ms
}

class HapticService {
  static Future<void> feedback(HapticStyle style) async {
    final hasVibrator = await Vibration.hasVibrator();

    // Fallback to basic haptics if no advanced control or custom vibration fails
    if (hasVibrator != true) {
      // Just try standard system feedback as a last resort
      await HapticFeedback.mediumImpact();
      return;
    }

    try {
      switch (style) {
        case HapticStyle.light:
          // "Butter" - Very short, crisp
          if (await Vibration.hasCustomVibrationsSupport()) {
            await Vibration.vibrate(duration: 10);
          } else {
            await HapticFeedback.lightImpact();
          }
          break;

        case HapticStyle.medium:
          // "Smooth" - Noticeable bump
          if (await Vibration.hasCustomVibrationsSupport()) {
            await Vibration.vibrate(duration: 30);
          } else {
            await HapticFeedback.mediumImpact();
          }
          break;

        case HapticStyle.heavy:
          // "Pulse" - Strong, undeniable vibration
          await Vibration.vibrate(duration: 70);
          break;
      }
    } catch (e) {
      // Fallback on error
      await HapticFeedback.mediumImpact();
    }
  }

  // Quick aliases
  static Future<void> light() async => feedback(HapticStyle.light);
  static Future<void> medium() async => feedback(HapticStyle.medium);
  static Future<void> heavy() async => feedback(HapticStyle.heavy);

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
