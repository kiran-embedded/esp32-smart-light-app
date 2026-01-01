import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final switchSettingsProvider =
    StateNotifierProvider<SwitchSettingsNotifier, SwitchSettingsState>((ref) {
      return SwitchSettingsNotifier();
    });

class SwitchSettingsState {
  final bool dynamicBlending;

  SwitchSettingsState({this.dynamicBlending = false});

  SwitchSettingsState copyWith({bool? dynamicBlending}) {
    return SwitchSettingsState(
      dynamicBlending: dynamicBlending ?? this.dynamicBlending,
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
    state = state.copyWith(dynamicBlending: blending);
  }

  Future<void> setDynamicBlending(bool value) async {
    state = state.copyWith(dynamicBlending: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dynamic_switch_blending', value);
  }
}
