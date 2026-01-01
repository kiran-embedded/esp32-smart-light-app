import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SwitchBackgroundType {
  defaultBlack,
  neonBorder,
  danceFloor,
  cosmicNebula,
  cyberGrid,
  liquidPlasma, // Fluid
  digitalRain, // Matrix
  retroSynth, // Vaporwave
  bokehLights,
  auroraBorealis,
  circuitBoard,
  fireEmbers,
  deepOcean,
  whiteFlash,
  glassPrism,
  starField,
  hexHive,
  neuralNodes,
  dataStream,
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

final switchBackgroundProvider =
    StateNotifierProvider<SwitchBackgroundNotifier, SwitchBackgroundType>((
      ref,
    ) {
      return SwitchBackgroundNotifier();
    });

class SwitchBackgroundNotifier extends StateNotifier<SwitchBackgroundType> {
  SwitchBackgroundNotifier() : super(SwitchBackgroundType.defaultBlack) {
    _loadStyle();
  }

  Future<void> _loadStyle() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt('switch_background_index');
    if (index != null &&
        index >= 0 &&
        index < SwitchBackgroundType.values.length) {
      state = SwitchBackgroundType.values[index];
    }
  }

  Future<void> setStyle(SwitchBackgroundType style) async {
    state = style;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('switch_background_index', style.index);
  }
}
