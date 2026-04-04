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
  final bool alarmPriorityMode;

  SwitchSettingsState({
    this.dynamicBlending = false,
    this.blurEffectsEnabled = true,
    this.lowLatencyMode = false,
    this.alarmPriorityMode = true,
  });

  SwitchSettingsState copyWith({
    bool? dynamicBlending,
    bool? blurEffectsEnabled,
    bool? lowLatencyMode,
    bool? alarmPriorityMode,
  }) {
    return SwitchSettingsState(
      dynamicBlending: dynamicBlending ?? this.dynamicBlending,
      blurEffectsEnabled: blurEffectsEnabled ?? this.blurEffectsEnabled,
      lowLatencyMode: lowLatencyMode ?? this.lowLatencyMode,
      alarmPriorityMode: alarmPriorityMode ?? this.alarmPriorityMode,
    );
  }
}

class SwitchSettingsNotifier extends StateNotifier<SwitchSettingsState> {
  SwitchSettingsNotifier() : super(SwitchSettingsState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    state = state.copyWith(
      dynamicBlending: prefs.getBool('dynamic_switch_blending') ?? false,
      blurEffectsEnabled: prefs.getBool('blur_effects_enabled') ?? true,
      lowLatencyMode: prefs.getBool('low_latency_mode') ?? false,
      alarmPriorityMode: prefs.getBool('alarm_priority_mode') ?? true,
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

  Future<void> setAlarmPriorityMode(bool value) async {
    state = state.copyWith(alarmPriorityMode: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('alarm_priority_mode', value);
  }
}
