import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
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

    try {
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) return;

      final available = await _speech.initialize(
        onError: (error) => print('NEBULA_VOICE: Error -> $error'),
        onStatus: (status) => print('NEBULA_VOICE: Status -> $status'),
        finalTimeout: const Duration(seconds: 10),
      );
      _isInitialized = available;
    } catch (e) {
      _isInitialized = false;
    }

    _ref.read(voiceServiceProvider);
  }

  Future<void> startListening(Function(String, bool) onResult) async {
    if (!_isInitialized) await initialize();
    if (!_isInitialized) return;

    if (_isListening) await stopListening();
    _isListening = true;

    await _speech.listen(
      onResult: (result) {
        // Return both text and finality flag
        onResult(result.recognizedWords, result.finalResult);

        if (result.finalResult) {
          _isListening = false;
          _processVoiceCommand(result.recognizedWords);
        }
      },
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 4),
      partialResults: true,
      listenMode: stt.ListenMode.confirmation,
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
    if (lowerCommand.isEmpty) return;

    final devices = _ref.read(switchDevicesProvider);
    final voiceService = _ref.read(voiceServiceProvider);

    print("NEBULA_VOICE: Processing -> $lowerCommand");

    final Map<String, String> candidates = {};
    for (var device in devices) {
      candidates[device.name.toLowerCase()] = device.id;
      if (device.nickname != null && device.nickname!.isNotEmpty) {
        candidates[device.nickname!.toLowerCase()] = device.id;
      }
    }

    final sortedKeys = candidates.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    String? matchedDeviceId;
    for (final key in sortedKeys) {
      if (lowerCommand.contains(key)) {
        matchedDeviceId = candidates[key];
        break;
      }
    }

    if (matchedDeviceId != null) {
      final device = devices.firstWhere((d) => d.id == matchedDeviceId);
      final deviceLabel = device.nickname ?? device.name;

      if (lowerCommand.contains('on') || lowerCommand.contains('activate')) {
        _ref
            .read(switchDevicesProvider.notifier)
            .setSwitchState(device.id, true);
        await voiceService.speak("Engaging $deviceLabel.");
      } else if (lowerCommand.contains('off') ||
          lowerCommand.contains('deactivate')) {
        _ref
            .read(switchDevicesProvider.notifier)
            .setSwitchState(device.id, false);
        await voiceService.speak("Deactivating $deviceLabel.");
      } else {
        _ref.read(switchDevicesProvider.notifier).toggleSwitch(device.id);
        await voiceService.speak("Toggling $deviceLabel.");
      }
    } else {
      if (lowerCommand.contains('all') || lowerCommand.contains('everything')) {
        final state = !lowerCommand.contains('off');
        for (var d in devices) {
          _ref.read(switchDevicesProvider.notifier).setSwitchState(d.id, state);
        }
        await voiceService.speak(
          "Setting habitat to ${state ? 'active' : 'standby'}.",
        );
      } else {
        await voiceService.speak(
          "I heard you, but I'm not sure which device to toggle.",
        );
      }
    }
  }
}
