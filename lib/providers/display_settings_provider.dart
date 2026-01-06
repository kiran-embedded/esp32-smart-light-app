import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'display_settings_provider.g.dart';

@riverpod
class DisplaySettings extends _$DisplaySettings {
  static const String _densityKey = 'display_density_key';

  @override
  double build() {
    _loadSettings();
    return 1.0; // Default density (Medium)
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getDouble(_densityKey) ?? 1.0;
  }

  Future<void> setDensity(double density) async {
    state = density;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_densityKey, density);
  }
}
