import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/ai_assistant_service.dart';
import '../providers/ai_settings_provider.dart';
import '../providers/switch_provider.dart';
import '../providers/voice_provider.dart';

class AiChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  AiChatMessage({required this.text, required this.isUser, DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();
}

class AiAssistantState {
  final List<AiChatMessage> messages;
  final bool isLoading;
  final String? error;

  AiAssistantState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
  });

  AiAssistantState copyWith({
    List<AiChatMessage>? messages,
    bool? isLoading,
    String? error,
  }) {
    return AiAssistantState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class AiAssistantNotifier extends StateNotifier<AiAssistantState> {
  final Ref _ref;
  final FlutterTts _tts = FlutterTts();

  AiAssistantNotifier(this._ref) : super(AiAssistantState());

  Future<void> sendMessage(String text) async {
    final aiSettings = _ref.read(aiSettingsProvider);
    if (aiSettings.apiKey.isEmpty) {
      state = state.copyWith(
        error: "Gemini API Key is missing. Please add it in Settings.",
      );
      return;
    }

    // Add user message to UI
    final userMsg = AiChatMessage(text: text, isUser: true);
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
      error: null,
    );

    try {
      final aiService = _ref.read(
        aiAssistantServiceProvider(aiSettings.apiKey),
      );

      // Convert history to Gemini format
      final history = state.messages.map((m) {
        return m.isUser
            ? Content.text(m.text)
            : Content.model([TextPart(m.text)]);
      }).toList();
      // Remove last message as it's the current prompt being sent by sendMessage
      if (history.isNotEmpty) history.removeLast();

      // Build Device Context (Report State)
      final devices = _ref.read(switchDevicesProvider);
      final deviceContext = devices
          .map((d) {
            return "- ${d.id} (${d.nickname}): ${d.isActive ? 'ON' : 'OFF'}";
          })
          .join('\n');

      final responseText = await aiService.sendMessage(
        text,
        history,
        deviceContext,
      );

      // Parse commands
      _processAiResponse(responseText);

      // Add AI message to UI (cleaned of commands for better display?)
      // Actually, let's keep the command in the message but maybe hide it in the UI later
      final aiMsg = AiChatMessage(text: responseText, isUser: false);
      state = state.copyWith(
        messages: [...state.messages, aiMsg],
        isLoading: false,
      );

      // Speak response if voice is enabled
      if (_ref.read(voiceEnabledProvider)) {
        await _speak(responseText);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: "Failed to connect to AI: $e",
      );
    }
  }

  void _processAiResponse(String response) {
    // Regex to match [COMMAND:RELAY_X:STATE]
    final regExp = RegExp(r'\[COMMAND:RELAY_([1-4]):(ON|OFF)\]');
    final matches = regExp.allMatches(response);

    for (final match in matches) {
      final relayId = "relay${match.group(1)}";
      final state = match.group(2) == 'ON';

      // Execute command
      _ref.read(switchDevicesProvider.notifier).setSwitchState(relayId, state);
    }
  }

  Future<void> _speak(String text) async {
    // Clean text from commands for TTS
    final cleanText = text.replaceAll(RegExp(r'\[COMMAND:.*?\]'), '').trim();
    if (cleanText.isEmpty) return;

    final pitch = _ref.read(voicePitchProvider);
    final rate = _ref.read(voiceRateProvider);
    final engine = _ref.read(voiceEngineProvider);

    if (engine != null) {
      await _tts.setEngine(engine);
    }
    await _tts.setPitch(pitch);
    await _tts.setSpeechRate(rate);
    await _tts.speak(cleanText);
  }

  void clearHistory() {
    state = AiAssistantState();
  }
}

final aiAssistantProvider =
    StateNotifierProvider<AiAssistantNotifier, AiAssistantState>((ref) {
      return AiAssistantNotifier(ref);
    });
