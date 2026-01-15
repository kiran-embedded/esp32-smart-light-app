import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final voiceEnabledProvider = StateNotifierProvider<VoiceNotifier, bool>((ref) {
  return VoiceNotifier();
});

class VoiceNotifier extends StateNotifier<bool> {
  VoiceNotifier([bool initialValue = true]) : super(initialValue) {
    if (initialValue) {
      // Only load if we assumed true, otherwise trust the seed
      _loadVoiceSetting();
    }
  }

  Future<void> _loadVoiceSetting() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('voice_enabled') ?? true;
  }

  Future<void> setVoiceEnabled(bool enabled) async {
    state = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('voice_enabled', enabled);
  }
}

// Voice Pitch Provider with Persistence
final voicePitchProvider = StateNotifierProvider<VoicePitchNotifier, double>((
  ref,
) {
  return VoicePitchNotifier();
});

class VoicePitchNotifier extends StateNotifier<double> {
  VoicePitchNotifier() : super(1.0) {
    _loadPitch();
  }

  Future<void> _loadPitch() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getDouble('voice_pitch') ?? 1.0;
  }

  Future<void> setPitch(double pitch) async {
    state = pitch;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('voice_pitch', pitch);
  }
}

// Voice Rate Provider with Persistence
final voiceRateProvider = StateNotifierProvider<VoiceRateNotifier, double>((
  ref,
) {
  return VoiceRateNotifier();
});

class VoiceRateNotifier extends StateNotifier<double> {
  VoiceRateNotifier() : super(0.5) {
    _loadRate();
  }

  Future<void> _loadRate() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getDouble('voice_rate') ?? 0.5;
  }

  Future<void> setRate(double rate) async {
    state = rate;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('voice_rate', rate);
  }
}

final voiceEngineProvider = StateNotifierProvider<VoiceEngineNotifier, String?>(
  (ref) {
    return VoiceEngineNotifier();
  },
);

class VoiceEngineNotifier extends StateNotifier<String?> {
  VoiceEngineNotifier() : super(null) {
    _loadEngine();
  }

  Future<void> _loadEngine() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString('voice_engine');
  }

  Future<void> setEngine(String engine) async {
    state = engine;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('voice_engine', engine);
  }
}
