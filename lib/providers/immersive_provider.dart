import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/persistence_service.dart';

class ImmersiveModeNotifier extends StateNotifier<bool> {
  ImmersiveModeNotifier() : super(true) {
    _loadState();
  }

  Future<void> _loadState() async {
    final mode = await PersistenceService.getImmersiveMode();
    state = mode;
    _applyMode(mode);
  }

  Future<void> setImmersiveMode(bool isEnabled) async {
    state = isEnabled;
    await PersistenceService.saveImmersiveMode(isEnabled);
    _applyMode(isEnabled);
  }

  void _applyMode(bool isEnabled) {
    if (isEnabled) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }
}

final immersiveModeProvider =
    StateNotifierProvider<ImmersiveModeNotifier, bool>((ref) {
      return ImmersiveModeNotifier();
    });
