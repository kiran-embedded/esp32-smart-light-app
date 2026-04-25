import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/switch_device.dart';
import '../services/firebase_switch_service.dart';
import '../services/persistence_service.dart';
import '../providers/google_home_provider.dart';
import '../core/constants/app_constants.dart';

final firebaseSwitchServiceProvider = Provider<FirebaseSwitchService>((ref) {
  return FirebaseSwitchService();
});

final invertedLogicProvider = StreamProvider.family<Map<int, bool>, String>((
  ref,
  deviceId,
) {
  return ref
      .read(firebaseSwitchServiceProvider)
      .listenToInvertedLogic(deviceId: deviceId);
});

final switchDevicesProvider =
    StateNotifierProvider<SwitchDevicesNotifier, List<SwitchDevice>>((ref) {
      return SwitchDevicesNotifier(ref);
    });

class SwitchDevicesNotifier extends StateNotifier<List<SwitchDevice>> {
  final Ref _ref;
  StreamSubscription<Map<String, dynamic>>? _telemetrySubscription;
  StreamSubscription<Map<String, dynamic>>? _commandsSubscription;
  StreamSubscription<Map<String, String>>? _namesSubscription;
  final Map<String, DateTime> _pendingSwitches = {};
  String _deviceId = AppConstants.defaultDeviceId;
  Map<String, dynamic> _lastTelemetry = {};
  Map<String, dynamic> _lastCommands = {};

  // DEDICATED COMMAND ENGINE: Queue for ultra-fast, non-blocking execution
  final List<Completer<void>> _commandQueue = [];
  bool _isProcessingQueue = false;

  // OPTIMIZED CLOUD SYNC TRACKERS
  final Map<String, bool> _lastSyncedState = {};
  final Map<String, DateTime> _lastSyncTime = {};

  bool get isEcoMode {
    final ecoVal = _lastTelemetry['ecoMode'] ?? _lastCommands['ecoMode'];
    return ecoVal == 1 || ecoVal == true;
  }

  String get currentDeviceId => _deviceId;

  SwitchDevicesNotifier(this._ref, {Map<String, String>? initialNicknames})
    : super([
        _createDefaultDevice('relay1', 'Switch 1'),
        _createDefaultDevice('relay2', 'Switch 2'),
        _createDefaultDevice('relay3', 'Switch 3'),
        _createDefaultDevice('relay4', 'Switch 4'),
        _createDefaultDevice('relay5', 'Switch 5'),
        _createDefaultDevice('relay6', 'Switch 6'),
        _createDefaultDevice('relay7', 'Switch 7'),
      ]) {
    if (initialNicknames != null) {
      _applyInitialNicknames(initialNicknames);
    }
    _loadDeviceId();
    _initTelemetryListener();
    forceRefreshHardwareNames();
  }

  Future<void> _loadDeviceId() async {
    final savedId = await PersistenceService.getDeviceId();
    if (savedId != null && savedId.isNotEmpty) {
      _deviceId = savedId;
      _initTelemetryListener(); // Re-init with new ID
    }
  }

  Future<void> updateDeviceId(String newId) async {
    if (newId.isEmpty) return;
    _deviceId = newId;
    await PersistenceService.saveDeviceId(newId);
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
      final hardwareNames = await firebaseService.getHardwareNames(
        deviceId: _deviceId,
      );

      if (hardwareNames.isNotEmpty) {
        final Map<String, SwitchDevice> updatedDevices = {
          for (var device in state) device.id: device,
        };

        hardwareNames.forEach((key, value) {
          if (value.toLowerCase().contains("node") || value.trim().isEmpty) {
            return;
          }

          if (updatedDevices.containsKey(key)) {
            updatedDevices[key] = updatedDevices[key]!.copyWith(name: value);
          } else if (key.startsWith("relay")) {
            updatedDevices[key] = SwitchDevice(
              id: key,
              name: value,
              isActive: false,
              icon: 'power',
              gpioPin: 0,
              mqttTopic: 'generic/switch/$key',
            );
          }
        });

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

  void _initTelemetryListener() {
    try {
      final firebaseService = _ref.read(firebaseSwitchServiceProvider);

      _telemetrySubscription?.cancel();
      _commandsSubscription?.cancel();
      _namesSubscription?.cancel();

      _telemetrySubscription = firebaseService
          .listenToTelemetry(deviceId: _deviceId)
          .listen((telemetry) {
            _lastTelemetry = telemetry;
            _mergeAndEmit();
          });

      _commandsSubscription = firebaseService
          .listenToCommands(deviceId: _deviceId)
          .listen((commands) {
            _lastCommands = commands;
            _mergeAndEmit();
          });

      _namesSubscription = firebaseService
          .listenToHardwareNames(deviceId: _deviceId)
          .listen((names) {
            _updateHardwareNamesFromStream(names);
          });
    } catch (e) {
      print('Error initializing telemetry sync: $e');
    }
  }

  void _updateHardwareNamesFromStream(Map<String, String> names) {
    if (names.isEmpty) return;

    final updatedDevices = {for (var device in state) device.id: device};
    bool changed = false;

    names.forEach((key, value) {
      if (value.toLowerCase().contains("node") || value.trim().isEmpty) {
        return;
      }

      if (updatedDevices.containsKey(key)) {
        if (updatedDevices[key]!.name != value) {
          updatedDevices[key] = updatedDevices[key]!.copyWith(name: value);
          changed = true;
        }
      }
    });

    if (changed) {
      final newList = updatedDevices.values.toList();
      newList.sort((a, b) {
        int? nA = int.tryParse(a.id.replaceAll(RegExp(r'[^0-9]'), ''));
        int? nB = int.tryParse(b.id.replaceAll(RegExp(r'[^0-9]'), ''));
        if (nA != null && nB != null) return nA.compareTo(nB);
        return a.id.compareTo(b.id);
      });
      state = newList;
    }
  }

  Future<void> _syncToCloud(SwitchDevice device) async {
    try {
      final googleHomeLinked =
          _ref.read(googleHomeLinkedProvider).valueOrNull ?? false;
      if (googleHomeLinked) {
        await _ref.read(googleHomeServiceProvider).syncDeviceToCloud(device);
      }
    } catch (e) {
      print('Google Home Sync Error: $e');
    }
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

    final allRelayIds = allKeys.toList();
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
          else if (rawVal is bool)
            newIsActive = rawVal;
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
        // STRICT OPTIMISTIC LOCK: Lock state fully for 3 seconds (3000ms) to ignore Firebase bounce echo.
        // During this period, the optimistic UI takes absolute precedence over any stale telemetry packets.
        if (DateTime.now().difference(pendingTime).inMilliseconds < 3000) {
          final existing = currentDeviceMap[id];
          if (existing != null && existing.isPending) {
            // PIN THE STATE: Force the optimistic state during the transition
            newIsActive = existing.isActive;
            isPending = true;
          }
        } else {
          _pendingSwitches.remove(id);
        }
      }

      final existingDevice = currentDeviceMap[id];
      if (existingDevice != null) {
        final updated = existingDevice.copyWith(
          isActive: newIsActive,
          isPending: isPending,
          isConnected: isConnected,
          voltage: voltage,
        );

        // OPTIMIZED CLOUD SYNC: Only sync if state changed AND 2s passed since last sync for this device
        final now = DateTime.now();
        final lastTime = _lastSyncTime[id] ?? DateTime(0);
        final lastState = _lastSyncedState[id];

        if (updated.isActive != lastState &&
            !isPending &&
            now.difference(lastTime).inSeconds > 2) {
          _lastSyncedState[id] = updated.isActive;
          _lastSyncTime[id] = now;
          _syncToCloud(updated);
        }

        return updated;
      } else {
        final device = _createDefaultDevice(
          id,
          'Switch ${id.replaceAll("relay", "")}',
        ).copyWith(isActive: newIsActive, isConnected: isConnected);

        return device;
      }
    }).toList();
  }

  bool _isDeviceConnected(dynamic lastSeen) {
    if (lastSeen == null) return false;
    try {
      final timestamp = lastSeen is int
          ? lastSeen
          : int.parse(lastSeen.toString());
      // lastSeen is epoch SECONDS from ESP32, not milliseconds
      final nowEpoch = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return (nowEpoch - timestamp).abs() < 30;
    } catch (e) {
      return false;
    }
  }

  final Map<String, DateTime> _lastToggleTime = {};

  Future<void> toggleSwitch(String id) async {
    final now = DateTime.now();
    if (_lastToggleTime.containsKey(id)) {
      if (now.difference(_lastToggleTime[id]!).inMilliseconds < 400) {
        return; // Deny double-click rapid glitch
      }
    }
    _lastToggleTime[id] = now;

    final deviceIndex = state.indexWhere((d) => d.id == id);
    if (deviceIndex == -1) return;
    final device = state[deviceIndex];
    await setSwitchState(id, !device.isActive);
  }

  Future<void> setSwitchState(String id, bool newState) async {
    final deviceIndex = state.indexWhere((d) => d.id == id);
    if (deviceIndex == -1) return;

    _pendingSwitches[id] = DateTime.now();

    // OPTIMISTIC UPDATE: Change state immediately for zero-latency feel
    final previousState = state;
    state = [
      for (final d in state)
        if (d.id == id) d.copyWith(isActive: newState, isPending: true) else d,
    ];

    // Non-blocking Firebase command via Dedicated Engine
    _enqueueCommand(
      id,
      newState,
      state[deviceIndex].nickname ?? state[deviceIndex].name,
    ).then((_) {
      _ref
          .read(firebaseSwitchServiceProvider)
          .sendCommand(
            id,
            newState ? 1 : 0,
            deviceId: _deviceId,
            relayName: state[deviceIndex].nickname ?? state[deviceIndex].name,
          )
          .catchError((e) {
            state = previousState;
          });
    });

    _syncToCloud(state[deviceIndex].copyWith(isActive: newState));
  }

  // --- PRIVATE COMMAND ENGINE HELPERS ---
  Future<void> _enqueueCommand(String id, bool newState, String name) async {
    final completer = Completer<void>();
    _commandQueue.add(completer);
    if (!_isProcessingQueue) {
      _processQueue();
    }
  }

  Future<void> _processQueue() async {
    _isProcessingQueue = true;
    while (_commandQueue.isNotEmpty) {
      final item = _commandQueue.removeAt(0);
      try {
        // Instant execution
        item.complete();
      } catch (_) {
        if (!item.isCompleted) item.complete();
      }
    }
    _isProcessingQueue = false;
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
          .updateHardwareName(id, newName, deviceId: _deviceId);
      _saveNicknames();
    } catch (e) {
      state = previousList;
      rethrow;
    }
  }

  Future<void> deleteDevice(String id) async {
    final previousState = state;
    state = state.where((d) => d.id != id).toList();

    try {
      await _ref
          .read(firebaseSwitchServiceProvider)
          .deleteRelay(id, deviceId: _deviceId);
    } catch (e) {
      state = previousState;
      rethrow;
    }
  }

  void suspend() {
    print(
      'SwitchDevicesNotifier: Suspending listeners for RAM optimization...',
    );
    _telemetrySubscription?.cancel();
    _commandsSubscription?.cancel();
    _namesSubscription?.cancel();
    _telemetrySubscription = null;
    _commandsSubscription = null;
    _namesSubscription = null;
  }

  void resume() {
    print('SwitchDevicesNotifier: Resuming listeners...');
    _initTelemetryListener();
    forceRefreshHardwareNames();
  }

  @override
  void dispose() {
    suspend();
    super.dispose();
  }
}
