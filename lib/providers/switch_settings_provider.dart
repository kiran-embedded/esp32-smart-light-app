import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final switchSettingsProvider =
    StateNotifierProvider<SwitchSettingsNotifier, SwitchSettingsState>((ref) {
      return SwitchSettingsNotifier();
    });

class SwitchSettingsState {
  final bool dynamicBlending;
  final bool blurEffectsEnabled;

  SwitchSettingsState({
    this.dynamicBlending = false,
    this.blurEffectsEnabled = true,
  });

  SwitchSettingsState copyWith({
    bool? dynamicBlending,
    bool? blurEffectsEnabled,
  }) {
    return SwitchSettingsState(
      dynamicBlending: dynamicBlending ?? this.dynamicBlending,
      blurEffectsEnabled: blurEffectsEnabled ?? this.blurEffectsEnabled,
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
    state = state.copyWith(dynamicBlending: blending, blurEffectsEnabled: blur);
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
}
