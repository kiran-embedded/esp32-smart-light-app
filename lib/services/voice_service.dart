import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/voice_provider.dart';

final voiceServiceProvider = Provider<VoiceService>((ref) {
  return VoiceService(ref);
});

class VoiceService {
  final Ref _ref;
  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;
  String? lastError;

  VoiceService(this._ref) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      lastError = null;
      // Don't wait forever, max 2 seconds for each step
      await _tts
          .awaitSpeakCompletion(true)
          .timeout(const Duration(seconds: 2), onTimeout: () {});

      if (Platform.isAndroid) {
        final selectedEngine = _ref.read(voiceEngineProvider);
        if (selectedEngine != null) {
          try {
            await _tts
                .setEngine(selectedEngine)
                .timeout(const Duration(seconds: 2));
          } catch (e) {
            lastError = "Failed to set engine $selectedEngine: $e";
          }
        } else {
          try {
            final List<String> engines = await getEngines();
            if (engines.isNotEmpty) {
              if (engines.contains("com.google.android.tts")) {
                await _tts.setEngine("com.google.android.tts");
              } else {
                await _tts.setEngine(engines.first);
              }
            } else {
              // lastError = "No engines found during initialization";
              debugPrint("No engines found during initialization");
            }
          } catch (e) {
            lastError = "Engine detection error: $e";
            debugPrint("Engine detection timeout or error: $e");
          }
        }
      }

      await _tts
          .setLanguage('en-US')
          .timeout(
            const Duration(seconds: 2),
            onTimeout: () {
              lastError = "Language setup timeout";
              throw Exception("Language setup timeout");
            },
          );
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      _isInitialized = true;
    } catch (e) {
      if (lastError == null) lastError = "Init Error: $e";
      debugPrint("Voice Init Error: $e");
      _isInitialized = false; // Keep it false if it failed
    }
  }

  Future<void> speak(String text) async {
    final voiceEnabled = _ref.read(voiceEnabledProvider);
    if (!voiceEnabled) return;

    if (!_isInitialized) {
      await _initialize();
    }

    if (!_isInitialized) return;

    try {
      await _tts.setVolume(1.0);
      await _tts.stop();
      await _tts.speak(text);
    } catch (e) {
      lastError = "Speak Error: $e";
      debugPrint("Speech Error: $e");
    }
  }

  // Debug Method
  Future<String> testSpeak() async {
    try {
      await _initialize().timeout(const Duration(seconds: 5));
      if (lastError != null && lastError!.contains("Init"))
        return "Error: $lastError";

      await _tts
          .speak("Voice system check operational.")
          .timeout(const Duration(seconds: 3));
      return "Voice command sent. Did you hear it?";
    } catch (e) {
      return "Test Failed or Timeout: $e";
    }
  }

  Future<List<String>> getEngines() async {
    if (!Platform.isAndroid) return [];

    try {
      // Try to get engines with a few retries if empty
      for (int i = 0; i < 3; i++) {
        final engines = await _tts.getEngines.timeout(
          const Duration(seconds: 2),
          onTimeout: () => [],
        );
        if (engines != null && engines.isNotEmpty) {
          return engines.map((e) => e.toString()).toList();
        }
        await Future.delayed(Duration(milliseconds: 500 * (i + 1)));
      }
    } catch (e) {
      debugPrint("Error fetching engines: $e");
      lastError = "Get Engines Error: $e";
    }
    return [];
  }

  Future<void> setEngine(String engine) async {
    await _tts.setEngine(engine);
    _initialize(); // Re-init with new engine
  }

  Future<void> stop() async {
    await _tts.stop();
  }

  Future<void> setPitch(double pitch) async {
    await _tts.setPitch(pitch);
  }

  Future<void> setRate(double rate) async {
    await _tts.setSpeechRate(rate);
  }
}
