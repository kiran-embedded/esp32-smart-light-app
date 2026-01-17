import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AiSettings {
  final String apiKey;
  final bool assistantEnabled;

  AiSettings({this.apiKey = '', this.assistantEnabled = true});

  AiSettings copyWith({String? apiKey, bool? assistantEnabled}) {
    return AiSettings(
      apiKey: apiKey ?? this.apiKey,
      assistantEnabled: assistantEnabled ?? this.assistantEnabled,
    );
  }
}

class AiSettingsNotifier extends StateNotifier<AiSettings> {
  AiSettingsNotifier() : super(AiSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    state = AiSettings(
      apiKey: prefs.getString('gemini_api_key') ?? '',
      assistantEnabled: prefs.getBool('ai_assistant_enabled') ?? true,
    );
  }

  Future<void> setApiKey(String key) async {
    state = state.copyWith(apiKey: key);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_api_key', key);
  }

  Future<void> toggleAssistant(bool enabled) async {
    state = state.copyWith(assistantEnabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ai_assistant_enabled', enabled);
  }
}

final aiSettingsProvider =
    StateNotifierProvider<AiSettingsNotifier, AiSettings>((ref) {
      return AiSettingsNotifier();
    });
