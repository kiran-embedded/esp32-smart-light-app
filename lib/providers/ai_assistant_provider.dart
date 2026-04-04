import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/ai_assistant_service.dart';
import '../providers/switch_provider.dart';
import '../providers/voice_provider.dart';
import '../providers/theme_provider.dart';
import '../core/theme/app_theme.dart';
import '../core/constants/app_constants.dart';
import '../providers/security_provider.dart';
import '../providers/auth_provider.dart';

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
  final bool isSpeaking;
  final String? error;
  final List<String> activeOptions; // For interactive follow-ups

  AiAssistantState({
    this.messages = const [],
    this.isLoading = false,
    this.isSpeaking = false,
    this.error,
    this.activeOptions = const [],
  });

  AiAssistantState copyWith({
    List<AiChatMessage>? messages,
    bool? isLoading,
    bool? isSpeaking,
    String? error,
    List<String>? activeOptions,
  }) {
    return AiAssistantState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      error: error ?? this.error,
      activeOptions: activeOptions ?? this.activeOptions,
    );
  }
}

class AiAssistantNotifier extends StateNotifier<AiAssistantState> {
  final Ref _ref;
  final FlutterTts _tts = FlutterTts();

  AiAssistantNotifier(this._ref) : super(AiAssistantState()) {
    _tts.setStartHandler(() {
      state = state.copyWith(isSpeaking: true);
    });
    _tts.setCompletionHandler(() {
      state = state.copyWith(isSpeaking: false);
    });
    _tts.setErrorHandler((_) {
      state = state.copyWith(isSpeaking: false);
    });
  }

  Future<void> sendMessage(String text) async {
    // Add user message to UI
    final userMsg = AiChatMessage(text: text, isUser: true);
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
      error: null,
      activeOptions: const [], // Clear options when user sends new message
    );

    try {
      final aiService = _ref.read(aiAssistantServiceProvider);

      // Simple history
      final history = state.messages.map((m) => m.text).toList();
      if (history.isNotEmpty) history.removeLast();

      // Build Advanced Device Context
      final devices = _ref.read(switchDevicesProvider);
      final currentTheme = _ref.read(themeProvider);
      final user = _ref.read(authServiceProvider).currentUser;
      final userName = user?.displayName?.split(' ').first ?? "Commander";

      final deviceContext = [
        "USER: $userName",
        "ID: ${AppConstants.defaultDeviceId}",
        "THEME: ${currentTheme.name}",
        "RELAYS:",
        ...devices.map(
          (d) => "- ${d.id} (${d.nickname}): ${d.isActive ? 'ON' : 'OFF'}",
        ),
      ].join('\n');

      final responseText = await aiService.sendMessage(
        text,
        history,
        deviceContext,
      );

      // Parse commands
      _processAiResponse(responseText);

      // Add AI message to UI (cleaned of commands)
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
        error: "Assistant logic error: $e",
      );
    }
  }

  void _processAiResponse(String response) {
    // 1. Relay Commands
    final relayRegExp = RegExp(r'\[COMMAND:RELAY_([1-4]):(ON|OFF)\]');
    final relayMatches = relayRegExp.allMatches(response);
    for (final match in relayMatches) {
      final relayId = "relay${match.group(1)}";
      final state = match.group(2) == 'ON';
      _ref.read(switchDevicesProvider.notifier).setSwitchState(relayId, state);
    }

    // 1b. Relay All Support
    if (response.contains('[COMMAND:RELAY_ALL:ON]')) {
      final notifier = _ref.read(switchDevicesProvider.notifier);
      for (int i = 1; i <= 4; i++) {
        notifier.setSwitchState("relay$i", true);
      }
    } else if (response.contains('[COMMAND:RELAY_ALL:OFF]')) {
      final notifier = _ref.read(switchDevicesProvider.notifier);
      for (int i = 1; i <= 4; i++) {
        notifier.setSwitchState("relay$i", false);
      }
    }

    // 2. Theme Commands (Advanced)
    final themeRegExp = RegExp(r'\[COMMAND:THEME:(\w+)\]');
    final themeMatch = themeRegExp.firstMatch(response);
    if (themeMatch != null) {
      final themeName = themeMatch.group(1);
      try {
        final mode = AppThemeMode.values.firstWhere((e) => e.name == themeName);
        _ref.read(themeProvider.notifier).setTheme(mode);
      } catch (e) {
        // Fallback or ignore if theme name invalid
      }
    }

    // 3. Security Commands (Advanced)
    if (response.contains('[COMMAND:SECURITY:ARM]')) {
      final security = _ref.read(securityProvider.notifier);
      if (!_ref.read(securityProvider).isArmed) {
        security.toggleArmed();
      }
    } else if (response.contains('[COMMAND:SECURITY:DISARM]')) {
      final security = _ref.read(securityProvider.notifier);
      if (_ref.read(securityProvider).isArmed) {
        security.toggleArmed();
      }
    }

    // 4. Action Handlers (Follow-ups)
    final actionRegExp = RegExp(r'\[ACTION:(\w+)\]');
    final actionMatches = actionRegExp.allMatches(response);
    List<String> options = [];
    for (final match in actionMatches) {
      final action = match.group(1);
      if (action == 'THEME_PICKER') {
        options.addAll([
          'Modern',
          'Cyber Neon',
          'Dark Space',
          'Apple Glass',
          'Kali Linux',
          'Neon Tokyo',
        ]);
      } else if (action == 'SWITCH_PICKER') {
        final devices = _ref.read(switchDevicesProvider);
        options.addAll(devices.map((d) => d.nickname ?? d.name));
      }
    }

    if (options.isNotEmpty) {
      state = state.copyWith(activeOptions: options);
    }
  }

  Future<void> _speak(String text) async {
    // 1. Strip Command Tags & All non-word symbols/emojis
    String cleanText = text.replaceAll(RegExp(r'\[COMMAND:.*?\]'), '');
    cleanText = cleanText.replaceAll(RegExp(r'\[ACTION:.*?\]'), '');

    // Aggressive Emoji & Multi-symbol stripping for clean speech
    cleanText = cleanText.replaceAll(
      RegExp(r'[^\x00-\x7F\s]'),
      '',
    ); // Strips all non-ASCII (including all emojis)
    cleanText = cleanText.replaceAll(
      RegExp(r'\*\*|__'),
      '',
    ); // Strip leftover markdown stars

    cleanText = cleanText.trim();
    if (cleanText.isEmpty) return;

    // Premium "Cute Robot" Settings
    final pitch = 1.3; // Higher pitch for "cute" feel
    final rate = 0.45; // Slightly slower for clarity and "robot" charm
    final engine = _ref.read(voiceEngineProvider);

    if (engine != null) {
      await _tts.setEngine(engine);
    }

    try {
      // Attempt to find a female voice
      final voices = await _tts.getVoices;
      if (voices != null) {
        final femaleVoice = voices.firstWhere(
          (v) =>
              v['name'].toString().toLowerCase().contains('female') ||
              v['name'].toString().toLowerCase().contains('soft') ||
              v['name'].toString().toLowerCase().contains(
                'sfg',
              ), // Android high-quality
          orElse: () => null,
        );
        if (femaleVoice != null) {
          await _tts.setVoice({
            "name": femaleVoice["name"],
            "locale": femaleVoice["locale"],
          });
        }
      }
    } catch (e) {
      // Fallback to default if voice selection fails
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
