import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'font_settings_provider.g.dart';

@riverpod
class FontSettings extends _$FontSettings {
  static const String _fontScaleKey = 'font_scale_key';

  @override
  double build() {
    _loadSettings();
    return 1.0; // Default scale
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getDouble(_fontScaleKey) ?? 1.0;
  }

  Future<void> setFontScale(double scale) async {
    state = scale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontScaleKey, scale);
  }
}
