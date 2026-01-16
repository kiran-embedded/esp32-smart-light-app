import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/switch_device.dart';
import '../services/firebase_switch_service.dart';
import '../services/persistence_service.dart';

import '../services/local_network_service.dart';
import '../providers/connection_settings_provider.dart';

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
    _initLocalPolling();
  }

  void _initLocalPolling() {
    // Poll every 3 seconds to reduce load and network contention
    Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      // Don't poll if we have pending switches (User is interacting)
      if (_pendingSwitches.isNotEmpty) return;

      try {
        final mode = _ref.read(connectionSettingsProvider).mode;
        if (mode == ConnectionMode.local) {
          final localService = _ref.read(localNetworkServiceProvider);
          // We don't have the device ID handy in a clean way,
          // but we can ask the service to fetch from *any* discovered device
          // Or iterate known devices.
          // For now, let's assume we want to pull status from the first available.
          // The service's getDeviceStatus handles fallback logic.

          // We can pass an empty ID or a dummy if we just want "the connected device"
          // Let's modify service to allow fetching "any"

          // Actually, let's just rely on what we have.
          // We can try to get ALL statuses.

          // Hack: Use a known ID if we have one or just rely on the service's fallback
          final status = await localService.getDeviceStatus("any");
          if (status != null) {
            _updateFromLocalStatus(status);
          }
        }
      } catch (_) {}
    });
  }

  void _updateFromLocalStatus(Map<String, dynamic> status) {
    final mode = _ref.read(connectionSettingsProvider).mode;
    if (mode != ConnectionMode.local) return; // double check

    // Convert local status (relay1: 1) to match telemetry format
    final Map<String, dynamic> fakeTelemetry = {};
    if (status.containsKey('voltage'))
      fakeTelemetry['voltage'] = status['voltage'];
    if (status.containsKey('relay1'))
      fakeTelemetry['relay1'] = status['relay1'];
    if (status.containsKey('relay2'))
      fakeTelemetry['relay2'] = status['relay2'];
    if (status.containsKey('relay3'))
      fakeTelemetry['relay3'] = status['relay3'];
    if (status.containsKey('relay4'))
      fakeTelemetry['relay4'] = status['relay4'];

    // Set last seen to now to show "Connected"
    fakeTelemetry['lastSeen'] = DateTime.now().millisecondsSinceEpoch;

    _lastTelemetry = fakeTelemetry;

    // We need to bypass the _mergeAndEmit strict check for this local update
    // So we'll duplicate the logic slightly or refactor _mergeAndEmit
    // simpler: Just temporary override the check or pass a flag

    _mergeAndEmit(forceLocal: true);
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
        _lastTelemetry = telemetry;
        _mergeAndEmit();
      });

      _commandsSubscription = firebaseService.listenToCommands().listen((
        commands,
      ) {
        _lastCommands = commands;
        _mergeAndEmit();
      });
    } catch (e) {
      print('Error initializing telemetry sync: $e');
    }
  }

  void _mergeAndEmit({bool forceLocal = false}) {
    // STRICT MODE: If in Local Mode, IGNORE Firebase updates completely
    final mode = _ref.read(connectionSettingsProvider).mode;
    if (mode == ConnectionMode.local && !forceLocal) return;

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

    state = allRelayIds.map((id) {
      bool newIsActive = false;
      if (telemetry.containsKey(id)) {
        final rawVal = telemetry[id];
        if (rawVal != null) {
          if (rawVal is int)
            newIsActive = (rawVal == 1); // 1 = Active (Normalized)
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
        // Increase guard time to 5s for local mode latency
        if (DateTime.now().difference(pendingTime).inMilliseconds < 5000) {
          final existing = currentDeviceMap[id];
          if (existing != null && newIsActive != existing.isActive) {
            newIsActive = existing.isActive;
            isPending = true;
          } else {
            // State matched, we can clear pending
            _pendingSwitches.remove(id);
          }
        } else {
          // Timeout expired, use telemetry
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

    // Non-blocking fire and forget
    final settingsMode = _ref.read(connectionSettingsProvider).mode;

    // Helpers to avoid code duplication
    void sendLocal() {
      int relayIndex = 0;
      try {
        final numStr = id.replaceAll(RegExp(r'[^0-9]'), '');
        relayIndex = (int.tryParse(numStr) ?? 1) - 1;
      } catch (_) {}

      final localService = _ref.read(localNetworkServiceProvider);
      // Removed force: true to prevent UI shutter on every tap
      // Background discovery handles IP caching
      if (!localService.hasDiscoveredDevices) {
        localService.startSmartDiscovery();
      }

      final targetIp = localService.anyIp;
      if (targetIp != null) {
        localService.sendLocalCommand(targetIp, relayIndex, newState);
      } else {
        // Fallback: try hotspot IP if no device discovered yet
        localService.sendLocalCommand("192.168.4.1", relayIndex, newState);
      }
    }

    void sendCloud() {
      _ref
          .read(firebaseSwitchServiceProvider)
          .sendCommand(id, newState ? 1 : 0);
    }

    // STRICT MODE LOGIC
    // STRICT MODE LOGIC (NO AUTO)
    if (settingsMode == ConnectionMode.local) {
      sendLocal();
    } else {
      // Default to Cloud for safety
      sendCloud();
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
    super.dispose();
  }
}
