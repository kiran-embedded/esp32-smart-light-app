import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/persistence_service.dart';
import '../../services/firebase_switch_service.dart';

// Simple provider for Low Latency Mode
final lowLatencyProvider = StateNotifierProvider<LowLatencyNotifier, bool>((
  ref,
) {
  return LowLatencyNotifier();
});

class LowLatencyNotifier extends StateNotifier<bool> {
  LowLatencyNotifier() : super(true) {
    _load();
  }

  Future<void> _load() async {
    final settings = await PersistenceService.getConnectionSettings();
    state = settings['isLowLatency'] ?? true;
  }

  Future<void> toggle(bool enabled) async {
    await PersistenceService.saveLowLatency(enabled);
    state = enabled;

    // Apply immediately
    final firebaseService = FirebaseSwitchService();
    await firebaseService.optimizeConnection(enabled);
  }
}
