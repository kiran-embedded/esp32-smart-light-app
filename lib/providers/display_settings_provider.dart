import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DisplaySize { small, medium, large }

enum NeonAnimationMode {
  sweep,
  dotRunner,
  comet,
  pulse,
  strobe,
  rainbow,
  autoChange,
}

class DisplaySettings {
  final DisplaySize displaySize;
  final double fontScale; // 0.0 to 1.0
  final double glowIntensity; // 0.0 to 1.0
  final NeonAnimationMode neonAnimationMode;

  DisplaySettings({
    this.displaySize = DisplaySize.medium,
    this.fontScale = 1.0, // Default scale
    this.glowIntensity = 0.5, // Default intensity
    this.neonAnimationMode = NeonAnimationMode.sweep,
  });

  DisplaySettings copyWith({
    DisplaySize? displaySize,
    double? fontScale,
    double? glowIntensity,
    NeonAnimationMode? neonAnimationMode,
  }) {
    return DisplaySettings(
      displaySize: displaySize ?? this.displaySize,
      fontScale: fontScale ?? this.fontScale,
      glowIntensity: glowIntensity ?? this.glowIntensity,
      neonAnimationMode: neonAnimationMode ?? this.neonAnimationMode,
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

  // Get font size multiplier
  double get fontSizeMultiplier => fontScale;

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
    final fontScale = prefs.getDouble('font_scale') ?? 1.0;
    final glowIntensity = prefs.getDouble('glow_intensity') ?? 0.5;
    final neonModeName = prefs.getString('neon_animation_mode') ?? 'sweep';

    state = DisplaySettings(
      displaySize: DisplaySize.values[sizeIndex.clamp(0, 2)],
      fontScale: fontScale.clamp(0.0, 1.0),
      glowIntensity: glowIntensity.clamp(0.0, 1.0),
      neonAnimationMode: NeonAnimationMode.values.firstWhere(
        (e) => e.name == neonModeName,
        orElse: () => NeonAnimationMode.sweep,
      ),
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

  Future<void> setGlowIntensity(double intensity) async {
    state = state.copyWith(glowIntensity: intensity.clamp(0.0, 1.0));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('glow_intensity', state.glowIntensity);
  }

  Future<void> setNeonAnimationMode(NeonAnimationMode mode) async {
    state = state.copyWith(neonAnimationMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('neon_animation_mode', mode.name);
  }
}
