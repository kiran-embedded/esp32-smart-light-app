import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DisplaySize { small, medium, large }

class DisplaySettings {
  final DisplaySize displaySize;
  final double fontScale; // 0.0 to 1.0

  DisplaySettings({
    this.displaySize = DisplaySize.medium,
    this.fontScale = 0.5, // Default middle
  });

  DisplaySettings copyWith({DisplaySize? displaySize, double? fontScale}) {
    return DisplaySettings(
      displaySize: displaySize ?? this.displaySize,
      fontScale: fontScale ?? this.fontScale,
    );
  }

  // Get scale multiplier for display size
  double get displayScale {
    switch (displaySize) {
      case DisplaySize.small:
        return 0.85;
      case DisplaySize.medium:
        return 1.0;
      case DisplaySize.large:
        return 1.15;
    }
  }

  // Get font size multiplier (0.0 = smallest, 1.0 = largest)
  double get fontSizeMultiplier {
    return 0.7 + (fontScale * 0.6); // Range: 0.7 to 1.3
  }

  // Compatibility aliases for v1.2.0+22 widgets
  double get pillScale => displayScale;
  double get fontSize => fontSizeMultiplier;
}

final displaySettingsProvider =
    StateNotifierProvider<DisplaySettingsNotifier, DisplaySettings>((ref) {
      return DisplaySettingsNotifier();
    });

class DisplaySettingsNotifier extends StateNotifier<DisplaySettings> {
  DisplaySettingsNotifier() : super(DisplaySettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final sizeIndex = prefs.getInt('display_size') ?? 1; // Default medium
    final fontScale = prefs.getDouble('font_scale') ?? 0.5;

    state = DisplaySettings(
      displaySize: DisplaySize.values[sizeIndex.clamp(0, 2)],
      fontScale: fontScale.clamp(0.0, 1.0),
    );
  }

  Future<void> setDisplaySize(DisplaySize size) async {
    state = state.copyWith(displaySize: size);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('display_size', size.index);
  }

  Future<void> setFontScale(double scale) async {
    state = state.copyWith(fontScale: scale.clamp(0.0, 1.0));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('font_scale', state.fontScale);
  }
}
