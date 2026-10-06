import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibration/vibration.dart';

enum HapticStyle {
  light,
  medium,
  heavy,
  success,
  error,
}

enum HardwareTier { low, mid, flagship }

class HapticService {
  static bool _initialized = false;
  static HardwareTier _tier = HardwareTier.low;

  static Future<void> init() async {
    if (_initialized) return;
    
    try {
      bool? hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator != true) {
        _tier = HardwareTier.low;
        _initialized = true;
        return;
      }

      bool? hasAmplitude = await Vibration.hasAmplitudeControl();
      bool? hasCustom = await Vibration.hasCustomVibrationsSupport();

      if (hasAmplitude == true) {
        _tier = HardwareTier.flagship; // X-axis linear motor (amplitude control)
      } else if (hasCustom == true) {
        _tier = HardwareTier.mid; // Z-axis linear motor (custom durations)
      } else {
        _tier = HardwareTier.low; // ERM motor (basic on/off)
      }
    } catch (_) {
      _tier = HardwareTier.low;
    }
    
    _initialized = true;
  }

  static Future<void> feedback(HapticStyle style) async {
    if (!_initialized) await init();

    try {
      if (_tier == HardwareTier.flagship) {
        _triggerFlagship(style);
      } else if (_tier == HardwareTier.mid) {
        _triggerMidRange(style);
      } else {
        _triggerLowTier(style);
      }
    } catch (_) {
      HapticFeedback.vibrate();
    }
  }

  static void _triggerFlagship(HapticStyle style) {
    switch (style) {
      case HapticStyle.light:
        Vibration.vibrate(pattern: [0, 15], intensities: [0, 128]);
        break;
      case HapticStyle.medium:
        Vibration.vibrate(pattern: [0, 25], intensities: [0, 192]);
        break;
      case HapticStyle.heavy:
        Vibration.vibrate(pattern: [0, 40], intensities: [0, 255]);
        break;
      case HapticStyle.success:
        Vibration.vibrate(pattern: [0, 20, 50, 20], intensities: [0, 150, 0, 255]);
        break;
      case HapticStyle.error:
        Vibration.vibrate(pattern: [0, 30, 40, 50, 40, 50], intensities: [0, 255, 0, 200, 0, 255]);
        break;
    }
  }

  static void _triggerMidRange(HapticStyle style) {
    switch (style) {
      case HapticStyle.light:
        Vibration.vibrate(duration: 20);
        break;
      case HapticStyle.medium:
        Vibration.vibrate(duration: 40);
        break;
      case HapticStyle.heavy:
        Vibration.vibrate(duration: 70);
        break;
      case HapticStyle.success:
        Vibration.vibrate(pattern: [0, 30, 60, 40]);
        break;
      case HapticStyle.error:
        Vibration.vibrate(pattern: [0, 50, 50, 70, 50, 80]);
        break;
    }
  }

  static void _triggerLowTier(HapticStyle style) {
    switch (style) {
      case HapticStyle.light:
        HapticFeedback.selectionClick();
        break;
      case HapticStyle.medium:
        HapticFeedback.vibrate();
        break;
      case HapticStyle.heavy:
        HapticFeedback.vibrate();
        break;
      case HapticStyle.success:
        HapticFeedback.vibrate();
        break;
      case HapticStyle.error:
        HapticFeedback.vibrate();
        break;
    }
  }

  // --- Static Aliases ---
  static Future<void> light() async => feedback(HapticStyle.light);
  static Future<void> medium() async => feedback(HapticStyle.medium);
  static Future<void> heavy() async => feedback(HapticStyle.heavy);
  static Future<void> success() async => feedback(HapticStyle.success);
  static Future<void> error() async => feedback(HapticStyle.error);
  static Future<void> selection() async => light();
  static Future<void> pulse() async => heavy();

  static Future<void> variableSelection(double intensity) async {
    if (!_initialized) await init();
    
    if (_tier == HardwareTier.flagship) {
      int mappedIntensity = (64 + (intensity * 191)).clamp(0, 255).toInt();
      int mappedDuration = (10 + (intensity * 20)).clamp(0, 30).toInt();
      Vibration.vibrate(pattern: [0, mappedDuration], intensities: [0, mappedIntensity]);
    } else if (_tier == HardwareTier.mid) {
      int mappedDuration = (15 + (intensity * 35)).clamp(0, 50).toInt();
      Vibration.vibrate(duration: mappedDuration);
    } else {
      if (intensity > 0.6) {
        HapticFeedback.vibrate();
      } else {
        HapticFeedback.selectionClick();
      }
    }
  }

  static Future<void> toggle(bool value) async {
    if (value) {
      if (_tier == HardwareTier.flagship) {
        Vibration.vibrate(pattern: [0, 15, 30, 20], intensities: [0, 150, 0, 255]);
      } else {
        await heavy();
      }
    } else {
      if (_tier == HardwareTier.flagship) {
        Vibration.vibrate(pattern: [0, 20, 30, 10], intensities: [0, 200, 0, 100]);
      } else {
        await medium();
      }
    }
  }

  static Future<void> impactOk() async => success();
  static Future<void> impactCancel() async => light();
  static Future<void> impactWarning() async => error();
  static Future<void> impactClick() async => selection();

  static Future<void> immersiveSliderFeedback(
    double value, {
    double min = 0,
    double max = 100,
  }) async {
    if (!_initialized) await init();
    final normalized = (value - min) / (max - min);
    final intensity = math.pow(normalized, 1.5).toDouble();
    await variableSelection(intensity);
  }

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
