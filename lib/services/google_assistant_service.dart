import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/switch_provider.dart';
import 'voice_service.dart';

final googleAssistantServiceProvider = Provider<GoogleAssistantService>((ref) {
  final service = GoogleAssistantService(ref);
  service.initialize();
  return service;
});

class GoogleAssistantService {
  final Ref _ref;
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _isInitialized = false;

  GoogleAssistantService(this._ref);

  Future<void> initialize() async {
    if (_isInitialized) return;

    final available = await _speech.initialize(
      onError: (error) => print('Speech recognition error: $error'),
      onStatus: (status) => print('Speech recognition status: $status'),
    );

    _isInitialized = available;

    // Initialize TTS engine in background
    _ref.read(voiceServiceProvider);
  }

  Future<void> startListening(Function(String) onResult) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (!_isInitialized) {
      throw Exception('Speech recognition not available');
    }

    if (_isListening) {
      await stopListening();
    }

    _isListening = true;

    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          _isListening = false;
          onResult(result.recognizedWords);
          _processVoiceCommand(result.recognizedWords);
        }
      },
      listenFor: const Duration(seconds: 5),
      pauseFor: const Duration(seconds: 3),
      localeId: 'en_US',
    );
  }

  Future<void> stopListening() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
    }
  }

  bool get isListening => _isListening;

  Future<void> _processVoiceCommand(String command) async {
    final lowerCommand = command.toLowerCase();
    final devices = _ref.read(switchDevicesProvider);
    final voiceService = _ref.read(voiceServiceProvider);

    print("Voice Command Processed: $lowerCommand");

    // 1. Prepare candidate list (Hardware Name + Nickname)
    // Structure: { "fan": deviceId, "fan light": deviceId, ... }
    final Map<String, String> candidates = {};
    for (var device in devices) {
      // Add Hardware Name
      candidates[device.name.toLowerCase()] = device.id;
      // Add Nickname
      if (device.nickname != null && device.nickname!.isNotEmpty) {
        candidates[device.nickname!.toLowerCase()] = device.id;
      }
    }

    // 2. SORT keys by LENGTH DESCENDING (Critical for "Best Match")
    // This ensures "Fan Light" is matched before "Fan"
    final sortedKeys = candidates.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    String? matchedDeviceId;

    for (final key in sortedKeys) {
      if (lowerCommand.contains(key)) {
        matchedDeviceId = candidates[key];
        break; // Stop at first (best) match
      }
    }

    // 3. Execute Command
    if (matchedDeviceId != null) {
      final device = devices.firstWhere((d) => d.id == matchedDeviceId);
      final deviceLabel = device.nickname ?? device.name;

      // ON
      if (lowerCommand.contains('on') ||
          lowerCommand.contains('enable') ||
          lowerCommand.contains('start')) {
        if (!device.isActive) {
          _ref.read(switchDevicesProvider.notifier).toggleSwitch(device.id);
          await voiceService.speak("Turning on $deviceLabel");
        } else {
          await voiceService.speak("$deviceLabel is already on");
        }
      }
      // OFF
      else if (lowerCommand.contains('off') ||
          lowerCommand.contains('disable') ||
          lowerCommand.contains('stop')) {
        if (device.isActive) {
          _ref.read(switchDevicesProvider.notifier).toggleSwitch(device.id);
          await voiceService.speak("Turning off $deviceLabel");
        } else {
          await voiceService.speak("$deviceLabel is already off");
        }
      }
      // TOGGLE
      else if (lowerCommand.contains('toggle') ||
          lowerCommand.contains('switch')) {
        _ref.read(switchDevicesProvider.notifier).toggleSwitch(device.id);
        await voiceService.speak("Toggling $deviceLabel");
      }
      // Just name mentioned? Toggle it.
      else {
        _ref.read(switchDevicesProvider.notifier).toggleSwitch(device.id);
        await voiceService.speak("Switched $deviceLabel");
      }
    } else {
      // No ID matched
      // Check for generic "Turn on all lights" or similar?
      // For now, simple error feedback
      if (lowerCommand.isNotEmpty) {
        await voiceService.speak("I couldn't find a switch with that name.");
      }
    }
  }

  // Manual command processing (for testing)
  void processCommand(String command) {
    _processVoiceCommand(command);
  }
}
