import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final switchSettingsProvider =
    StateNotifierProvider<SwitchSettingsNotifier, SwitchSettingsState>((ref) {
      return SwitchSettingsNotifier();
    });

class SwitchSettingsState {
  final bool dynamicBlending;
  final bool blurEffectsEnabled;
  final bool lowLatencyMode;

  SwitchSettingsState({
    this.dynamicBlending = false,
    this.blurEffectsEnabled = true,
    this.lowLatencyMode = false,
  });

  SwitchSettingsState copyWith({
    bool? dynamicBlending,
    bool? blurEffectsEnabled,
    bool? lowLatencyMode,
  }) {
    return SwitchSettingsState(
      dynamicBlending: dynamicBlending ?? this.dynamicBlending,
      blurEffectsEnabled: blurEffectsEnabled ?? this.blurEffectsEnabled,
      lowLatencyMode: lowLatencyMode ?? this.lowLatencyMode,
    );
  }
}

class SwitchSettingsNotifier extends StateNotifier<SwitchSettingsState> {
  SwitchSettingsNotifier() : super(SwitchSettingsState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final blending = prefs.getBool('dynamic_switch_blending') ?? false;
    final blur = prefs.getBool('blur_effects_enabled') ?? true;
    final latency = prefs.getBool('low_latency_mode') ?? false;
    state = state.copyWith(
      dynamicBlending: blending,
      blurEffectsEnabled: blur,
      lowLatencyMode: latency,
    );
  }

  Future<void> setDynamicBlending(bool value) async {
    state = state.copyWith(dynamicBlending: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dynamic_switch_blending', value);
  }

  Future<void> setBlurEffects(bool value) async {
    state = state.copyWith(blurEffectsEnabled: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('blur_effects_enabled', value);
  }

  Future<void> setLowLatencyMode(bool value) async {
    state = state.copyWith(lowLatencyMode: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('low_latency_mode', value);
  }
}
