import 'package:flutter/material.dart';
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
}

enum UiTransitionAnimation {
  iOSSlide,
  butterZoom,
  fluidFade,
  elasticSnap,
  gamingRGB,
  zeroLatency,
}

// State class
class AnimationSettings {
  final AppLaunchAnimation launchType;
  final UiTransitionAnimation uiType;

  const AnimationSettings({
    this.launchType = AppLaunchAnimation.iPhoneBlend,
    this.uiType = UiTransitionAnimation.iOSSlide,
  });

  AnimationSettings copyWith({
    AppLaunchAnimation? launchType,
    UiTransitionAnimation? uiType,
  }) {
    return AnimationSettings(
      launchType: launchType ?? this.launchType,
      uiType: uiType ?? this.uiType,
    );
  }
}

// Notifier
class AnimationSettingsNotifier extends StateNotifier<AnimationSettings> {
  AnimationSettingsNotifier({
    AppLaunchAnimation initialLaunch = AppLaunchAnimation.iPhoneBlend,
    UiTransitionAnimation initialUi = UiTransitionAnimation.iOSSlide,
  }) : super(AnimationSettings(launchType: initialLaunch, uiType: initialUi));

  // Async load is no longer needed inside the notifier as we inject it
  // But we keep the setter methods which save to persistence.

  void setLaunchAnimation(AppLaunchAnimation type) {
    state = state.copyWith(launchType: type);
    PersistenceService.saveAnimationSettings(
      state.launchType.index,
      state.uiType.index,
    );
  }

  void setUiAnimation(UiTransitionAnimation type) {
    state = state.copyWith(uiType: type);
    PersistenceService.saveAnimationSettings(
      state.launchType.index,
      state.uiType.index,
    );
  }
}

final animationSettingsProvider =
    StateNotifierProvider<AnimationSettingsNotifier, AnimationSettings>((ref) {
      // Default fallback if not overridden
      return AnimationSettingsNotifier();
    });
