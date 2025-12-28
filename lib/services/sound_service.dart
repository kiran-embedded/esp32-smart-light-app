import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final soundServiceProvider = Provider((ref) => SoundService());

class SoundService {
  // Use separate players for overlapping sounds and to avoid source switching delay
  final AudioPlayer _onPlayer = AudioPlayer();
  final AudioPlayer _offPlayer = AudioPlayer();
  final AudioPlayer _tabPlayer = AudioPlayer(); // New
  final AudioPlayer _startupPlayer = AudioPlayer(); // New

  SoundService() {
    _init();
  }

  Future<void> _init() async {
    // optimize for low latency (UI sounds)
    try {
      await _onPlayer.setReleaseMode(ReleaseMode.stop);
      await _offPlayer.setReleaseMode(ReleaseMode.stop);
      await _tabPlayer.setReleaseMode(ReleaseMode.stop);
      await _startupPlayer.setReleaseMode(ReleaseMode.stop);

      // Preload sources
      await _onPlayer.setSource(AssetSource('audio/switch_on.mp3'));
      await _offPlayer.setSource(AssetSource('audio/switch_off.mp3'));
      await _tabPlayer.setSource(AssetSource('audio/tab_switch.mp3'));
      await _startupPlayer.setSource(AssetSource('audio/startup.mp3'));
    } catch (e) {
      print('Audio init error: $e');
    }
  }

  Future<void> playSwitchOn() async {
    try {
      if (_onPlayer.state == PlayerState.playing) {
        await _onPlayer.stop();
      }
      await _onPlayer.resume();
    } catch (e) {
      // Fallback if preload failed or first run
      try {
        await _onPlayer.play(AssetSource('audio/switch_on.mp3'));
      } catch (_) {}
    }
  }

  Future<void> playSwitchOff() async {
    try {
      if (_offPlayer.state == PlayerState.playing) {
        await _offPlayer.stop();
      }
      await _offPlayer.resume();
    } catch (e) {
      try {
        await _offPlayer.play(AssetSource('audio/switch_off.mp3'));
      } catch (_) {}
    }
  }

  Future<void> playTabSwitch() async {
    try {
      if (_tabPlayer.state == PlayerState.playing) {
        await _tabPlayer.stop();
      }
      // Fire and forget to prevent UI blocking
      _tabPlayer.resume().then((_) {}, onError: (_) {});
    } catch (e) {
      try {
        _tabPlayer.play(AssetSource('audio/tab_switch.mp3'));
      } catch (_) {}
    }
  }

  Future<void> playStartup() async {
    try {
      if (_startupPlayer.state == PlayerState.playing) {
        await _startupPlayer.stop();
      }
      await _startupPlayer.resume();
    } catch (e) {
      try {
        await _startupPlayer.play(AssetSource('audio/startup.mp3'));
      } catch (_) {}
    }
  }
}
