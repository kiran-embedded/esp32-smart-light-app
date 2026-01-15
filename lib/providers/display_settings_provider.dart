import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/persistence_service.dart';

class DisplaySettings {
  final double pillScale;
  final double fontSize;

  const DisplaySettings({this.pillScale = 1.0, this.fontSize = 1.0});

  DisplaySettings copyWith({double? pillScale, double? fontSize}) {
    return DisplaySettings(
      pillScale: pillScale ?? this.pillScale,
      fontSize: fontSize ?? this.fontSize,
    );
  }
}

class DisplaySettingsNotifier extends StateNotifier<DisplaySettings> {
  DisplaySettingsNotifier() : super(const DisplaySettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await PersistenceService.getDisplaySettings();
    state = DisplaySettings(
      pillScale: settings['pillScale'] ?? 1.0,
      fontSize: settings['fontSize'] ?? 1.0,
    );
  }

  Future<void> setPillScale(double scale) async {
    state = state.copyWith(pillScale: scale);
    await PersistenceService.saveDisplaySettings(
      state.pillScale,
      state.fontSize,
    );
  }

  Future<void> setFontSize(double size) async {
    state = state.copyWith(fontSize: size);
    await PersistenceService.saveDisplaySettings(
      state.pillScale,
      state.fontSize,
    );
  }
}

final displaySettingsProvider =
    StateNotifierProvider<DisplaySettingsNotifier, DisplaySettings>((ref) {
      return DisplaySettingsNotifier();
    });
