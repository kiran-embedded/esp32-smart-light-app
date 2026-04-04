import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AiSettings {
  final bool assistantEnabled;

  AiSettings({this.assistantEnabled = true});

  AiSettings copyWith({bool? assistantEnabled}) {
    return AiSettings(
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
      assistantEnabled: prefs.getBool('ai_assistant_enabled') ?? true,
    );
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
