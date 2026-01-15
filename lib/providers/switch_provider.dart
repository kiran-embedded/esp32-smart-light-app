import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/switch_device.dart';
import '../services/firebase_switch_service.dart';
import '../services/persistence_service.dart';
import '../services/local_network_service.dart';
import 'connection_settings_provider.dart';
import '../services/connectivity_service.dart';

final firebaseSwitchServiceProvider = Provider<FirebaseSwitchService>((ref) {
  return FirebaseSwitchService();
});

final switchDevicesProvider =
    StateNotifierProvider<SwitchDevicesNotifier, List<SwitchDevice>>((ref) {
      return SwitchDevicesNotifier(ref);
    });

class SwitchDevicesNotifier extends StateNotifier<List<SwitchDevice>> {
  final Ref _ref;
  StreamSubscription<Map<String, dynamic>>? _telemetrySubscription;
  final Map<String, DateTime> _pendingSwitches = {};
  Timer? _localPollingTimer;

  SwitchDevicesNotifier(this._ref, {Map<String, String>? initialNicknames})
    : super([
        _createDefaultDevice('relay1', 'Switch 1'),
        _createDefaultDevice('relay2', 'Switch 2'),
        _createDefaultDevice('relay3', 'Switch 3'),
        _createDefaultDevice('relay4', 'Switch 4'),
      ]) {
    if (initialNicknames != null) {
      _applyInitialNicknames(initialNicknames);
    }
    _initTelemetryListener();
    forceRefreshHardwareNames();
  }

  void _applyInitialNicknames(Map<String, String> nicknames) {
    state = [
      for (final device in state)
        device.copyWith(nickname: nicknames[device.id] ?? device.nickname),
    ];
  }

  Future<void> _saveNicknames() async {
    try {
      final Map<String, String> nicknames = {};
      for (final device in state) {
        if (device.nickname != null && device.nickname!.isNotEmpty) {
          nicknames[device.id] = device.nickname!;
        }
      }
      await PersistenceService.saveNicknames(nicknames);
    } catch (e) {
      print('Error saving nicknames: $e');
    }
  }

  Future<String> forceRefreshHardwareNames() async {
    try {
      final firebaseService = _ref.read(firebaseSwitchServiceProvider);
      final hardwareNames = await firebaseService.getHardwareNames();

      if (hardwareNames.isNotEmpty) {
        final Map<String, SwitchDevice> updatedDevices = {
          for (var device in state)
            device.id: device.copyWith(
              name: hardwareNames[device.id] ?? device.name,
            ),
        };

        for (final key in hardwareNames.keys) {
          if (!updatedDevices.containsKey(key) && key.startsWith("relay")) {
            updatedDevices[key] = SwitchDevice(
              id: key,
              name:
                  hardwareNames[key] ?? 'Switch ${key.replaceAll("relay", "")}',
              isActive: false,
              icon: 'power',
              gpioPin: 0,
              mqttTopic: 'generic/switch/$key',
            );
          }
        }

        final List<SwitchDevice> newList = updatedDevices.values.toList();
        newList.sort((a, b) {
          int? nA = int.tryParse(a.id.replaceAll(RegExp(r'[^0-9]'), ''));
          int? nB = int.tryParse(b.id.replaceAll(RegExp(r'[^0-9]'), ''));
          if (nA != null && nB != null) return nA.compareTo(nB);
          return a.id.compareTo(b.id);
        });

        state = newList;
        return 'Synced: ${hardwareNames.length} devices found.';
      } else {
        return 'No names found in Firebase.';
      }
    } catch (e) {
      return 'Error: $e';
    }
  }

  static SwitchDevice _createDefaultDevice(String id, String name) {
    return SwitchDevice(
      id: id,
      name: name,
      isActive: false,
      icon: 'power',
      gpioPin: 0,
      mqttTopic: '',
      isConnected: false,
    );
  }

  Map<String, dynamic> _lastTelemetry = {};
  Map<String, dynamic> _lastCommands = {};
  StreamSubscription<Map<String, dynamic>>? _commandsSubscription;

  void _initTelemetryListener() {
    try {
      final firebaseService = _ref.read(firebaseSwitchServiceProvider);

      _telemetrySubscription = firebaseService.listenToTelemetry().listen((
        telemetry,
      ) {
        final mode = _ref.read(connectivityProvider).activeMode;
        if (mode == ConnectionMode.cloud) {
          _lastTelemetry = telemetry;
          _mergeAndEmit();
        }
      });

      _commandsSubscription = firebaseService.listenToCommands().listen((
        commands,
      ) {
        final mode = _ref.read(connectivityProvider).activeMode;
        if (mode == ConnectionMode.cloud) {
          _lastCommands = commands;
          _mergeAndEmit();
        }
      });

      // Start local polling if in local mode
      _updatePollingTimer();

      // Listen to effective connection mode changes and FLUSH buffer on change
      _ref.listen(connectivityProvider, (previous, next) {
        if (previous?.activeMode != next.activeMode) {
          // FLUSH BUFFER: Prevent random triggering from stale data of other mode
          _lastTelemetry = {};
          _lastCommands = {};
          _updatePollingTimer();
          if (next.activeMode == ConnectionMode.local) {
            _pollLocalStatus();
          }
        }
      });
    } catch (e) {
      print('Error initializing telemetry sync: $e');
    }
  }

  void _updatePollingTimer() {
    _localPollingTimer?.cancel();
    final mode = _ref.read(connectivityProvider).activeMode;

    if (mode == ConnectionMode.local) {
      _localPollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        _pollLocalStatus();
      });
    }
  }

  Future<void> _pollLocalStatus() async {
    try {
      final connectivity = _ref.read(connectivityProvider);
      final localService = _ref.read(localNetworkServiceProvider);
      final status = await localService.getDeviceStatus(
        "hotspot_fallback", // Or dynamic ID if we had it mapped
      );
      if (status != null) {
        _processLocalStatus(status);
      }
    } catch (e) {
      print('Local polling error: $e');
    }
  }

  void _processLocalStatus(Map<String, dynamic> status) {
    // Map local status to telemetry format
    final Map<String, dynamic> telemetry = {
      'lastSeen': DateTime.now().millisecondsSinceEpoch,
      'voltage': status['voltage'] ?? 0.0,
    };

    if (status.containsKey('relays') && status['relays'] is List) {
      final relays = status['relays'] as List;
      for (int i = 0; i < relays.length; i++) {
        // Unified Hardware Logic: 1 = Active, 0 = Inactive
        telemetry['relay${i + 1}'] = (relays[i] == true || relays[i] == 1)
            ? 1
            : 0;
      }
    }

    _lastTelemetry = telemetry;
    _mergeAndEmit();
  }

  void _mergeAndEmit() {
    final telemetry = _lastTelemetry;
    double voltage = 0.0;
    if (telemetry.containsKey('voltage')) {
      voltage = (telemetry['voltage'] is num)
          ? (telemetry['voltage'] as num).toDouble()
          : 0.0;
    }

    final Set<String> allKeys = {};
    allKeys.addAll(
      telemetry.keys
          .where((key) => key.toString().startsWith('relay'))
          .map((key) => key.toString()),
    );
    allKeys.addAll(
      _lastCommands.keys
          .where((key) => key.toString().startsWith('relay'))
          .map((key) => key.toString()),
    );

    final currentIds = state.map((d) => d.id).toSet();
    final allRelayIds = {...currentIds, ...allKeys}.toList();

    allRelayIds.sort((a, b) {
      int? nA = int.tryParse(a.replaceAll(RegExp(r'[^0-9]'), ''));
      int? nB = int.tryParse(b.replaceAll(RegExp(r'[^0-9]'), ''));
      if (nA != null && nB != null) return nA.compareTo(nB);
      return a.compareTo(b);
    });

    final currentDeviceMap = {for (var d in state) d.id: d};

    // OPTIMIZATION: Cache sorted list instead of re-sorting every frame
    // For now, sorting logic stays but mapped operation is lighter
    var newState = allRelayIds.map((id) {
      bool newIsActive = false;
      if (telemetry.containsKey(id)) {
        final rawVal = telemetry[id];
        if (rawVal != null) {
          if (rawVal is int)
            newIsActive = (rawVal == 1);
          else if (rawVal is bool)
            newIsActive = rawVal;
          else
            newIsActive =
                (rawVal.toString() == '1' || rawVal.toString() == 'true');
        }
      } else if (_lastCommands.containsKey(id)) {
        final rawVal = _lastCommands[id];
        if (rawVal != null) {
          if (rawVal is int)
            newIsActive = (rawVal == 1);
          else
            newIsActive =
                (rawVal.toString() == '1' || rawVal.toString() == 'true');
        }
      } else if (currentDeviceMap.containsKey(id)) {
        newIsActive = currentDeviceMap[id]!.isActive;
      }

      bool isPending = false;
      bool isConnected = _isDeviceConnected(telemetry['lastSeen']);

      if (_pendingSwitches.containsKey(id)) {
        final pendingTime = _pendingSwitches[id]!;
        // Sync latency window: 1.5 seconds for snappy feedback
        if (DateTime.now().difference(pendingTime).inMilliseconds < 1500) {
          final existing = currentDeviceMap[id];
          if (existing != null && newIsActive != existing.isActive) {
            newIsActive = existing.isActive;
            isPending = true;
          } else {
            _pendingSwitches.remove(id);
          }
        } else {
          _pendingSwitches.remove(id);
        }
      }

      if (currentDeviceMap.containsKey(id)) {
        return currentDeviceMap[id]!.copyWith(
          isActive: newIsActive,
          isPending: isPending,
          isConnected: isConnected,
          voltage: voltage,
        );
      } else {
        return _createDefaultDevice(
          id,
          'Switch ${id.replaceAll("relay", "")}',
        ).copyWith(isActive: newIsActive, isConnected: isConnected);
      }
    }).toList();

    // PERFORMANCE: Only update state if something actually changed
    // Simple deep equality check (optimistic)
    if (_hasStateChanged(state, newState)) {
      state = newState;
    }
  }

  bool _hasStateChanged(
    List<SwitchDevice> oldState,
    List<SwitchDevice> newState,
  ) {
    if (oldState.length != newState.length) return true;
    for (int i = 0; i < oldState.length; i++) {
      if (oldState[i] != newState[i]) return true;
    }
    return false;
  }

  bool _isDeviceConnected(dynamic lastSeen) {
    if (lastSeen == null) return false;
    try {
      final timestamp = lastSeen is int
          ? lastSeen
          : int.parse(lastSeen.toString());
      final now = DateTime.now().millisecondsSinceEpoch;
      return (now - timestamp) < 10000;
    } catch (e) {
      return false;
    }
  }

  Future<void> toggleSwitch(String id) async {
    final deviceIndex = state.indexWhere((d) => d.id == id);
    if (deviceIndex == -1) return;

    final device = state[deviceIndex];
    final bool previousState = device.isActive;
    final bool newState = !previousState;

    _pendingSwitches[id] = DateTime.now();
    state = [
      for (final d in state)
        if (d.id == id) d.copyWith(isActive: newState, isPending: true) else d,
    ];

    // FIX: Read ACTIVE mode, not just user setting
    final mode = _ref.read(connectivityProvider).activeMode;

    if (mode == ConnectionMode.local) {
      // Use Local Service
      // Assuming 'hotspot_fallback' or similar; in real scenario we use d.id mapping
      // For now, if local mode is active, we assume we want to talk to the discovered device override.
      // But typically we should use: _ref.read(localNetworkServiceProvider).getIp(id);

      // Ensure we have discovery running if we haven't found anything yet
      final localService = _ref.read(localNetworkServiceProvider);
      if (localService.getIp("hotspot_fallback") == null) {
        // Trigger a quick aggressive scan/verification on current subnet if possible?
        // Or just rely on the service's internal fallback we just added.
        print(
          "SwitchProvider: No IP for hotspot_fallback, hoping service has ANY IP...",
        );
      }

      final success = await localService.sendLocalCommand(
        "hotspot_fallback", // Or discovered ID
        deviceIndex, // 0-3
        newState,
      );

      if (!success) {
        // Revert on failure
        state = [
          for (final d in state)
            if (d.id == id)
              d.copyWith(isActive: previousState, isPending: false)
            else
              d,
        ];
        _pendingSwitches.remove(id);
      } else {
        // Success: Trigger immediate poll to update state
        _pollLocalStatus();
      }
    } else {
      // Use Firebase Service
      _ref
          .read(firebaseSwitchServiceProvider)
          .sendCommand(id, newState ? 1 : 0);
    }
  }

  Future<void> updateNickname(String id, String newName) async {
    state = [
      for (final d in state)
        if (d.id == id) d.copyWith(nickname: newName) else d,
    ];
    await _saveNicknames();
  }

  Future<void> updateHardwareName(String id, String newName) async {
    final previousList = state;
    state = [
      for (final d in state)
        if (d.id == id) d.copyWith(name: newName) else d,
    ];

    try {
      await _ref
          .read(firebaseSwitchServiceProvider)
          .updateHardwareName(id, newName);
      _saveNicknames();
    } catch (e) {
      state = previousList;
      rethrow;
    }
  }

  @override
  void dispose() {
    _telemetrySubscription?.cancel();
    _commandsSubscription?.cancel();
    _localPollingTimer?.cancel();
    super.dispose();
  }
}
