import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibration/vibration.dart';

enum HapticStyle {
  light, // "Butter" - System Click / Sharp
  medium, // "Smooth" - Noticeable bump
  heavy, // "Pulse" - Strong feedback
  success, // Multi-stage confirmation
  error, // Warning pattern
}

enum HardwareTier { low, mid, flagship }

class HapticService {
  static bool _initialized = false;
  static bool _hasVibrator = false;
  static bool _hasCustomSupport = false;
  static HardwareTier _tier = HardwareTier.low;

  static Future<void> init() async {
    if (_initialized) return;
    try {
      _hasVibrator = await Vibration.hasVibrator() == true;
      _hasCustomSupport = await Vibration.hasCustomVibrationsSupport() == true;

      if (!_hasVibrator) {
        _tier = HardwareTier.low;
      } else if (_hasCustomSupport) {
        _tier =
            HardwareTier.flagship; // Assume flagship if custom support is high
      } else {
        _tier = HardwareTier.low;
      }
    } catch (_) {
      _tier = HardwareTier.low;
    }
    _initialized = true;
  }

  static Future<void> feedback(HapticStyle style) async {
    if (!_initialized) await init();

    if (_tier == HardwareTier.low) {
      _triggerLowTier(style);
      return;
    }

    try {
      switch (style) {
        case HapticStyle.light:
          Vibration.vibrate(duration: 8);
          break;
        case HapticStyle.medium:
          Vibration.vibrate(duration: 20);
          break;
        case HapticStyle.heavy:
          Vibration.vibrate(duration: 50);
          break;
        case HapticStyle.success:
          Vibration.vibrate(pattern: [0, 10, 30, 10]);
          break;
        case HapticStyle.error:
          Vibration.vibrate(pattern: [0, 50, 50, 50]);
          break;
      }
    } catch (_) {
      HapticFeedback.mediumImpact();
    }
  }

  static void _triggerLowTier(HapticStyle style) {
    switch (style) {
      case HapticStyle.light:
        HapticFeedback.lightImpact();
        break;
      case HapticStyle.medium:
      case HapticStyle.success:
        HapticFeedback.mediumImpact();
        break;
      case HapticStyle.heavy:
      case HapticStyle.error:
        HapticFeedback.heavyImpact();
        break;
    }
  }

  // --- Static Aliases ---
  static Future<void> light() async => feedback(HapticStyle.light);
  static Future<void> medium() async => feedback(HapticStyle.medium);
  static Future<void> heavy() async => feedback(HapticStyle.heavy);
  static Future<void> success() async => feedback(HapticStyle.success);
  static Future<void> error() async => feedback(HapticStyle.error);
  static Future<void> selection() async => HapticFeedback.selectionClick();
  static Future<void> pulse() async => feedback(HapticStyle.heavy);

  static Future<void> variableSelection(double intensity) async {
    if (!_initialized) await init();
    if (!_hasVibrator) {
      HapticFeedback.selectionClick();
      return;
    }
    int duration = (5 + (intensity * 25)).toInt();
    Vibration.vibrate(duration: duration);
  }

  static Future<void> toggle(bool value) async {
    if (value) {
      await medium();
    } else {
      await light();
    }
  }

  // --- Immersive & Semantic Extensions ---
  static Future<void> impactOk() async => success();
  static Future<void> impactCancel() async => light();
  static Future<void> impactWarning() async => error();
  static Future<void> impactClick() async => selection();

  /// Immersive continuous feedback for sliders
  static Future<void> immersiveSliderFeedback(
    double value, {
    double min = 0,
    double max = 100,
  }) async {
    if (!_initialized) await init();
    // Normalize intensity based on value range
    final normalized = (value - min) / (max - min);
    // Exponential curve for "flagship" feel
    final intensity = math.pow(normalized, 1.5).toDouble();
    await variableSelection(intensity);
  }

  // --- Instance Bridge Placeholder ---
  // We avoid name collisions with static methods.
  // Any file needing instance-based haptics can call these.
  Future<void> runLight() => light();
  Future<void> runMedium() => medium();
  Future<void> runHeavy() => heavy();
  Future<void> runSuccess() => success();
  Future<void> runError() => error();
  Future<void> runPulse() => pulse();
  Future<void> runSelection() => selection();
  Future<void> runVariableSelection(double intensity) =>
      variableSelection(intensity);
}

final hapticServiceProvider = Provider((ref) => HapticService());
