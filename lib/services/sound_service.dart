import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

final soundServiceProvider = Provider((ref) => SoundService());

class SoundService {
  final AudioPlayer _startupPlayer = AudioPlayer();
  // Store loaded sound handles
  final Map<String, AudioSource> _sounds = {};

  SoundService() {
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
        // Fire and forget, zero latency
        await SoLoud.instance.play(source);
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
      await _startupPlayer.stop();
      await _startupPlayer.setReleaseMode(ReleaseMode.stop);
      await _startupPlayer.play(AssetSource('audio/startup.mp3'));
    } catch (e) {
      debugPrint('Startup sound error: $e');
    }
  }

  void dispose() {
    SoLoud.instance.deinit();
    _startupPlayer.dispose();
  }
}
