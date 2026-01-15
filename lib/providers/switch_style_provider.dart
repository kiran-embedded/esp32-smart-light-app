import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SwitchStyleType {
  modern,
  fluid,
  realistic,
  different, // Cyberpunk/Abstract
  smooth,
  neonGlass, // New
  industrialMetallic, // New
  gamingRGB, // New
  holographic,
  liquidMetal,
  quantumDot,
  cosmicPulse, // 12
  retroVapor, // 13
  bioOrganic, // 14
  crystalPrism, // 15
  voidAbyss, // 16
  solarFlare,
  electricTundra,
  nanoCatalyst,
  phantomVelvet,
  prismFractal,
  magmaCore,
  cyberBloom,
  voidRift,
  starlightEcho,
  aeroStream,
}

final switchStyleProvider =
    StateNotifierProvider<SwitchStyleNotifier, SwitchStyleType>((ref) {
      return SwitchStyleNotifier();
    });

class SwitchStyleNotifier extends StateNotifier<SwitchStyleType> {
  SwitchStyleNotifier() : super(SwitchStyleType.modern) {
    _loadStyle();
  }

  Future<void> _loadStyle() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt('switch_style_index');
    if (index != null && index >= 0 && index < SwitchStyleType.values.length) {
      state = SwitchStyleType.values[index];
    }
  }

  Future<void> setStyle(SwitchStyleType style) async {
    state = style;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('switch_style_index', style.index);
  }
}
