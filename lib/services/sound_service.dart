import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import '../providers/sound_settings_provider.dart';

final soundServiceProvider = Provider((ref) => SoundService(ref));

class SoundService {
  final Ref _ref;
  final AudioPlayer _startupPlayer = AudioPlayer();
  // Store loaded sound handles
  final Map<String, AudioSource> _sounds = {};

  SoundService(this._ref) {
    _init();
  }

  Future<void> _init() async {
    try {
      // Initialize SoLoud engine (C++ backend for zero latency)
      await SoLoud.instance.init();

      // Preload assets into memory
      // Note: flutter_soloud loads assets differently.
      // We load them as AudioSource.
      _sounds['on'] = await SoLoud.instance.loadAsset(
        'assets/audio/switch_on.mp3',
      );
      _sounds['off'] = await SoLoud.instance.loadAsset(
        'assets/audio/switch_off.mp3',
      );
      _sounds['tab'] = await SoLoud.instance.loadAsset(
        'assets/audio/tab_switch.mp3',
      );
      _sounds['alarm_high'] = await SoLoud.instance.loadAsset(
        'assets/audio/alarm_high.mp3',
      );
      _sounds['alarm_med'] = await SoLoud.instance.loadAsset(
        'assets/audio/alarm_medium.mp3',
      );
      try {
        _sounds['siren'] = await SoLoud.instance.loadAsset(
          'assets/audio/siren.mp3',
        );
      } catch (e) {
        debugPrint('Siren sound not found, skipping...');
      }
    } catch (e) {
      debugPrint('SoLoud init error: $e');
    }

    // Init legacy player for startup sound
    try {
      await _startupPlayer.setReleaseMode(ReleaseMode.stop);
      await _startupPlayer.setSource(AssetSource('audio/startup.mp3'));
    } catch (e) {
      debugPrint('Startup player init error: $e');
    }
  }

  Future<void> _play(String key) async {
    try {
      final source = _sounds[key];
      if (source != null) {
        // Check settings
        final settings = _ref.read(soundSettingsProvider);
        if (!settings.masterSound) return;

        // Specific checks based on key
        if ((key == 'on' || key == 'off' || key == 'tab') &&
            !settings.switchSound) {
          return;
        }

        // Calculate volume
        double volume = settings.masterVolume;
        if (key == 'on' || key == 'off' || key == 'tab') {
          volume *= settings.switchVolume;
        }

        // Fire and forget, zero latency
        await SoLoud.instance.play(source, volume: volume);
      }
    } catch (e) {
      debugPrint('Error playing sound $key: $e');
    }
  }

  Future<void> playSwitchOn() async => _play('on');
  Future<void> playSwitchOff() async => _play('off');
  Future<void> playTabSwitch() async => _play('tab');

  Future<void> playStartup() async {
    try {
      final settings = _ref.read(soundSettingsProvider);
      if (!settings.masterSound || !settings.appOpeningSound) return;

      await _startupPlayer.stop();
      await _startupPlayer.setReleaseMode(ReleaseMode.stop);
      final volume = settings.masterVolume * settings.appOpeningVolume;
      await _startupPlayer.setVolume(volume);
      await _startupPlayer.play(AssetSource('audio/startup.mp3'));
    } catch (e) {
      debugPrint('Startup sound error: $e');
    }
  }

  SoundHandle? _alarmHandle;

  Future<void> playAlarmHigh({bool looping = true}) async {
    final source = _sounds['alarm_high'];
    if (source != null) {
      if (_alarmHandle != null) SoLoud.instance.stop(_alarmHandle!);
      _alarmHandle = await SoLoud.instance.play(
        source,
        volume: 1.0, // Force max volume for alarm
        looping: looping,
      );
    }
  }

  Future<void> playAlarmMedium({bool looping = true}) async {
    final source = _sounds['alarm_med'];
    if (source != null) {
      if (_alarmHandle != null) SoLoud.instance.stop(_alarmHandle!);
      _alarmHandle = await SoLoud.instance.play(
        source,
        volume: 0.7,
        looping: looping,
      );
    }
  }

  Future<void> playSiren({bool looping = true}) async {
    // Try siren first, fallback to alarm_high
    final source = _sounds['siren'] ?? _sounds['alarm_high'];
    if (source != null) {
      if (_alarmHandle != null) await SoLoud.instance.stop(_alarmHandle!);
      _alarmHandle = await SoLoud.instance.play(
        source,
        volume: 1.0,
        looping: looping,
      );
    }
  }

  Future<void> stopAlarm() async {
    if (_alarmHandle != null) {
      await SoLoud.instance.stop(_alarmHandle!);
      _alarmHandle = null;
    }
  }

  void dispose() {
    SoLoud.instance.deinit();
    _startupPlayer.dispose();
  }
}
