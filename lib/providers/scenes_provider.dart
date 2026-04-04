import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'switch_provider.dart';

enum SmartScene { home, away, night }

final smartSceneProvider =
    StateNotifierProvider<SmartSceneNotifier, SmartScene>((ref) {
      return SmartSceneNotifier(ref);
    });

class SmartSceneNotifier extends StateNotifier<SmartScene> {
  final Ref ref;

  SmartSceneNotifier(this.ref) : super(SmartScene.home);

  void setScene(SmartScene scene) {
    state = scene;
    final switches = ref.read(switchDevicesProvider);
    final service = ref.read(firebaseSwitchServiceProvider);

    switch (scene) {
      case SmartScene.home:
        // Turn on primary lights (Relay 1 & 2)
        service.sendCommand('relay1', 1);
        service.sendCommand('relay2', 1);
        break;
      case SmartScene.away:
        // Turn off everything
        for (var s in switches) {
          service.sendCommand(s.id, 0);
        }
        break;
      case SmartScene.night:
        // Night mode (Relay 2 only, e.g. night lamp)
        service.sendCommand('relay1', 0);
        service.sendCommand('relay2', 1);
        service.sendCommand('relay3', 0);
        service.sendCommand('relay4', 0);
        break;
    }
  }
}
