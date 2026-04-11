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
      // Initialize SoLoud (engine will handle double-init internally or we catch)
      try {
        await SoLoud.instance.init();
      } catch (e) {
        debugPrint('SoLoud already initialized or failed: $e');
      }

      await _loadAppAssets();

      // Listen for changes in custom alarm path
      _ref.listen(soundSettingsProvider.select((s) => s.customAlarmPath), (
        previous,
        next,
      ) {
        if (next != null && next != previous) {
          loadCustomAlarm(next);
        } else if (next == null) {
          _sounds.remove('custom_alarm');
        }
      });

      // Initial load
      final settings = _ref.read(soundSettingsProvider);
      if (settings.customAlarmPath != null) {
        await loadCustomAlarm(settings.customAlarmPath!);
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

  Future<void> _loadAppAssets() async {
    final assets = {
      'on': 'assets/audio/switch_on.mp3',
      'off': 'assets/audio/switch_off.mp3',
      'tab': 'assets/audio/tab_switch.mp3',
      'siren': 'assets/audio/siren.mp3',
      'alarm_high': 'assets/audio/alarm_high.mp3',
      'alarm_med': 'assets/audio/alarm_medium.mp3',
    };

    for (final entry in assets.entries) {
      try {
        _sounds[entry.key] = await SoLoud.instance.loadAsset(entry.value);
      } catch (e) {
        debugPrint('Error loading asset ${entry.key}: $e');
      }
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
    // Priority: Custom > Siren > AlarmHigh (missing)
    final source =
        _sounds['custom_alarm'] ?? _sounds['siren'] ?? _sounds['alarm_high'];
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
    // Priority: Custom > Siren > AlarmMed (missing)
    final source =
        _sounds['custom_alarm'] ?? _sounds['siren'] ?? _sounds['alarm_med'];
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
    // Try custom first, then siren, fallback to alarm_high
    final source =
        _sounds['custom_alarm'] ?? _sounds['siren'] ?? _sounds['alarm_high'];
    if (source != null) {
      if (_alarmHandle != null) await SoLoud.instance.stop(_alarmHandle!);
      _alarmHandle = await SoLoud.instance.play(
        source,
        volume: 1.0,
        looping: looping,
      );
    }
  }

  Future<void> loadCustomAlarm(String path) async {
    try {
      final source = await SoLoud.instance.loadFile(path);
      _sounds['custom_alarm'] = source;
    } catch (e) {
      debugPrint('Error loading custom alarm: $e');
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
