import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/haptic_service.dart';

/// Haptic Style Provider with Persistence
final hapticStyleProvider =
    StateNotifierProvider<HapticStyleNotifier, HapticStyle>((ref) {
      return HapticStyleNotifier();
    });

class HapticStyleNotifier extends StateNotifier<HapticStyle> {
  HapticStyleNotifier() : super(HapticStyle.medium) {
    _loadHapticStyle();
  }

  Future<void> _loadHapticStyle() async {
    final prefs = await SharedPreferences.getInstance();
    final styleIndex = prefs.getInt('haptic_style') ?? 1; // Default to medium
    if (styleIndex >= 0 && styleIndex < HapticStyle.values.length) {
      state = HapticStyle.values[styleIndex];
    }
  }

  Future<void> setHapticStyle(HapticStyle style) async {
    state = style;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('haptic_style', style.index);
  }
}
