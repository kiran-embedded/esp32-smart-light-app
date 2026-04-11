import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/app_theme.dart';

final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemeMode>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<AppThemeMode> {
  ThemeNotifier() : super(AppThemeMode.darkSpace) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Try string-based name (New method)
    final themeName = prefs.getString('theme_mode_str');
    if (themeName != null) {
      try {
        state = AppThemeMode.values.firstWhere(
          (e) => e.toString().split('.').last == themeName,
          orElse: () => AppThemeMode.darkSpace,
        );
        return;
      } catch (_) {
        state = AppThemeMode.darkSpace;
      }
    }

    // 2. Fallback to index-based (Legacy method)
    final themeIndex = prefs.getInt('theme_mode');
    if (themeIndex != null && themeIndex < AppThemeMode.values.length) {
      state = AppThemeMode.values[themeIndex];
    } else {
      state = AppThemeMode.darkSpace;
    }
  }

  Future<void> setTheme(AppThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode_str', mode.toString().split('.').last);
    await prefs.setInt(
      'theme_mode',
      mode.index,
    ); // Maintain index for old versions
  }
}
