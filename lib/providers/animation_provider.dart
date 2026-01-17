import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/persistence_service.dart';

// Enums for the 2 categories
enum AppLaunchAnimation {
  iPhoneBlend,
  cinematicFade,
  cyberGlitch,
  bottomSpring,
  centerBurst,
  liquidReveal,
  glassDrop,
  galaxySpiral,
  pixelReveal,
  neonPulse,
  fluidWave,
  elasticPop,
  ghostFade,
  hologramRise,
  bladeRunner,
  quantumTunnel,
}

enum UiTransitionAnimation {
  iOSSlide,
  butterZoom,
  fluidFade,
  elasticSnap,
  gamingRGB,
  zeroLatency,
  iosExactSlide,
  magneticPull,
  gravityDrop,
  softAura,
  matrixRain,
  prismShatter,
  cosmicEcho,
  liquidMorph,
  deepScan,
  springRebounce,
}

// State class
class AnimationSettings {
  final AppLaunchAnimation launchType;
  final UiTransitionAnimation uiType;
  final bool animationsEnabled;

  const AnimationSettings({
    this.launchType = AppLaunchAnimation.neonPulse,
    this.uiType = UiTransitionAnimation.zeroLatency,
    this.animationsEnabled = true,
  });

  AnimationSettings copyWith({
    AppLaunchAnimation? launchType,
    UiTransitionAnimation? uiType,
    bool? animationsEnabled,
  }) {
    return AnimationSettings(
      launchType: launchType ?? this.launchType,
      uiType: uiType ?? this.uiType,
      animationsEnabled: animationsEnabled ?? this.animationsEnabled,
    );
  }
}

// Notifier
class AnimationSettingsNotifier extends StateNotifier<AnimationSettings> {
  AnimationSettingsNotifier({
    AppLaunchAnimation initialLaunch = AppLaunchAnimation.neonPulse,
    UiTransitionAnimation initialUi = UiTransitionAnimation.zeroLatency,
    bool initialEnabled = true,
  }) : super(
         AnimationSettings(
           launchType: initialLaunch,
           uiType: initialUi,
           animationsEnabled: initialEnabled,
         ),
       );

  void setLaunchAnimation(AppLaunchAnimation type) {
    state = state.copyWith(launchType: type);
    _save();
  }

  void setUiAnimation(UiTransitionAnimation type) {
    state = state.copyWith(uiType: type);
    _save();
  }

  void setAnimationsEnabled(bool enabled) {
    state = state.copyWith(animationsEnabled: enabled);
    _save();
  }

  void _save() {
    PersistenceService.saveAnimationSettings(
      state.launchType.index,
      state.uiType.index,
      state.animationsEnabled,
    );
  }
}

final animationSettingsProvider =
    StateNotifierProvider<AnimationSettingsNotifier, AnimationSettings>((ref) {
      return AnimationSettingsNotifier();
    });
