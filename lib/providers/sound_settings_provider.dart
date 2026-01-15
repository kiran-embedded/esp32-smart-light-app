import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final soundSettingsProvider =
    StateNotifierProvider<SoundSettingsNotifier, SoundSettings>((ref) {
      return SoundSettingsNotifier();
    });

class SoundSettings {
  final bool masterSound;
  final bool appOpeningSound;
  final bool switchSound;
  final double masterVolume;
  final double appOpeningVolume;
  final double switchVolume;

  SoundSettings({
    this.masterSound = true,
    this.appOpeningSound = true,
    this.switchSound = true,
    this.masterVolume = 1.0,
    this.appOpeningVolume = 1.0,
    this.switchVolume = 1.0,
  });

  SoundSettings copyWith({
    bool? masterSound,
    bool? appOpeningSound,
    bool? switchSound,
    double? masterVolume,
    double? appOpeningVolume,
    double? switchVolume,
  }) {
    return SoundSettings(
      masterSound: masterSound ?? this.masterSound,
      appOpeningSound: appOpeningSound ?? this.appOpeningSound,
      switchSound: switchSound ?? this.switchSound,
      masterVolume: masterVolume ?? this.masterVolume,
      appOpeningVolume: appOpeningVolume ?? this.appOpeningVolume,
      switchVolume: switchVolume ?? this.switchVolume,
    );
  }
}

class SoundSettingsNotifier extends StateNotifier<SoundSettings> {
  SoundSettingsNotifier() : super(SoundSettings()) {
    _loadSettings();
  }

  void seed(SoundSettings settings) {
    state = settings;
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    state = SoundSettings(
      masterSound: prefs.getBool('master_sound') ?? true,
      appOpeningSound: prefs.getBool('app_opening_sound') ?? true,
      switchSound: prefs.getBool('switch_sound') ?? true,

      masterVolume: prefs.getDouble('master_volume') ?? 1.0,
      appOpeningVolume: prefs.getDouble('app_opening_volume') ?? 1.0,
      switchVolume: prefs.getDouble('switch_volume') ?? 1.0,
    );
  }

  Future<void> setMasterSound(bool enabled) async {
    state = state.copyWith(masterSound: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('master_sound', enabled);
  }

  Future<void> setAppOpeningSound(bool enabled) async {
    state = state.copyWith(appOpeningSound: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('app_opening_sound', enabled);
  }

  Future<void> setSwitchSound(bool enabled) async {
    state = state.copyWith(switchSound: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('switch_sound', enabled);
  }

  Future<void> setMasterVolume(double volume) async {
    state = state.copyWith(masterVolume: volume);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('master_volume', volume);
  }

  Future<void> setAppOpeningVolume(double volume) async {
    state = state.copyWith(appOpeningVolume: volume);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('app_opening_volume', volume);
  }

  Future<void> setSwitchVolume(double volume) async {
    state = state.copyWith(switchVolume: volume);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('switch_volume', volume);
  }
}
