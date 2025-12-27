import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/switch_provider.dart';

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

  void _processVoiceCommand(String command) {
    final lowerCommand = command.toLowerCase();
    final devices = _ref.read(switchDevicesProvider);

    // Parse commands like:
    // "Turn on living room light"
    // "Turn off fan"
    // "Switch on kitchen light"

    for (final device in devices) {
      final deviceName = device.name.toLowerCase();

      // Check if device name is mentioned
      if (lowerCommand.contains(deviceName)) {
        // Check for ON command
        if (lowerCommand.contains('turn on') ||
            lowerCommand.contains('switch on') ||
            lowerCommand.contains('enable') ||
            lowerCommand.contains('activate')) {
          if (!device.isActive) {
            _ref.read(switchDevicesProvider.notifier).toggleSwitch(device.id);
          }
          return;
        }

        // Check for OFF command
        if (lowerCommand.contains('turn off') ||
            lowerCommand.contains('switch off') ||
            lowerCommand.contains('disable') ||
            lowerCommand.contains('deactivate')) {
          if (device.isActive) {
            _ref.read(switchDevicesProvider.notifier).toggleSwitch(device.id);
          }
          return;
        }

        // Check for TOGGLE command
        if (lowerCommand.contains('toggle')) {
          _ref.read(switchDevicesProvider.notifier).toggleSwitch(device.id);
          return;
        }
      }
    }
  }

  // Manual command processing (for testing)
  void processCommand(String command) {
    _processVoiceCommand(command);
  }
}
