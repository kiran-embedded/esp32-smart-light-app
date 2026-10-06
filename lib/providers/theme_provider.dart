import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/app_theme.dart';

final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemeMode>((ref) {
  return ThemeNotifier(AppThemeMode.light);
});

class ThemeNotifier extends StateNotifier<AppThemeMode> {
  ThemeNotifier(super.initialTheme) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();

    final themeName = prefs.getString('theme_mode_str');
    if (themeName != null) {
      try {
        state = AppThemeMode.values.firstWhere(
          (e) => e.toString().split('.').last == themeName,
          orElse: () => AppThemeMode.light,
        );
        return;
      } catch (_) {
        state = AppThemeMode.light;
      }
    }
  }

  Future<void> setTheme(AppThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode_str', mode.toString().split('.').last);
  }
  
  void toggleTheme() {
    if (state == AppThemeMode.dark) {
      setTheme(AppThemeMode.light);
    } else {
      setTheme(AppThemeMode.dark);
    }
  }
}
