import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/persistence_service.dart';

import 'switch_provider.dart';
import '../services/local_network_service.dart';

enum ConnectionMode { local, cloud }

class ConnectionSettings {
  final ConnectionMode mode;
  final bool isLowDataMode;
  final bool isPerformanceMode;

  ConnectionSettings({
    this.mode = ConnectionMode.cloud,
    this.isLowDataMode = false,
    this.isPerformanceMode = false,
  });

  ConnectionSettings copyWith({
    ConnectionMode? mode,
    bool? isLowDataMode,
    bool? isPerformanceMode,
  }) {
    return ConnectionSettings(
      mode: mode ?? this.mode,
      isLowDataMode: isLowDataMode ?? this.isLowDataMode,
      isPerformanceMode: isPerformanceMode ?? this.isPerformanceMode,
    );
  }
}

class ConnectionSettingsNotifier extends StateNotifier<ConnectionSettings> {
  final Ref _ref;

  ConnectionSettingsNotifier(this._ref) : super(ConnectionSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await PersistenceService.getConnectionSettings();
    final modeStr = settings['mode'] as String;
    final isLowData = settings['isLowData'] as bool;
    final isPerformance = settings['isPerformance'] as bool;

    state = ConnectionSettings(
      mode: ConnectionMode.values.firstWhere(
        (m) => m.name == modeStr,
        orElse: () => ConnectionMode.cloud,
      ),
      isLowDataMode: isLowData,
      isPerformanceMode: isPerformance,
    );

    // Apply optimization immediately
    _ref.read(firebaseSwitchServiceProvider).optimizeConnection(isLowData);
  }

  Future<void> setMode(ConnectionMode mode) async {
    state = state.copyWith(mode: mode);
    _save();

    // SYNC TO ESP32 (Strict Mode Enforcement)
    final modeStr = (mode == ConnectionMode.cloud) ? 'CLOUD' : 'LOCAL';
    final networkService = _ref.read(localNetworkServiceProvider);

    // Trigger discovery immediately if switching to Local
    if (mode == ConnectionMode.local) {
      networkService.startSmartDiscovery();
    }

    networkService.setDeviceMode(modeStr);
  }

  Future<void> setLowDataMode(bool enabled) async {
    state = state.copyWith(isLowDataMode: enabled);
    _ref.read(firebaseSwitchServiceProvider).optimizeConnection(enabled);
    _save();
  }

  Future<void> setPerformanceMode(bool enabled) async {
    state = state.copyWith(isPerformanceMode: enabled);
    _save();
  }

  Future<void> _save() async {
    await PersistenceService.saveConnectionSettings(
      mode: state.mode.name,
      isLowData: state.isLowDataMode,
      isPerformance: state.isPerformanceMode,
    );
  }
}

final connectionSettingsProvider =
    StateNotifierProvider<ConnectionSettingsNotifier, ConnectionSettings>((
      ref,
    ) {
      return ConnectionSettingsNotifier(ref);
    });
