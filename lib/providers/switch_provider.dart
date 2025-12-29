import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/switch_device.dart';
import '../services/firebase_switch_service.dart';
import '../services/persistence_service.dart';

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
  }

  void _applyInitialNicknames(Map<String, String> nicknames) {
    state = [
      for (final device in state)
        device.copyWith(nickname: nicknames[device.id] ?? device.nickname),
    ];
    print('DEBUG: Initialized with nicknames: $nicknames');
  }

  Future<void> _saveNicknames() async {
    try {
      final Map<String, String> nicknames = {};
      for (final device in state) {
        if (device.nickname != null && device.nickname!.isNotEmpty) {
          nicknames[device.id] = device.nickname!;
        }
      }
      print('DEBUG: Saving nicknames: $nicknames');
      await PersistenceService.saveNicknames(nicknames);
    } catch (e) {
      print('Error saving nicknames: $e');
    }
  }

  Future<String> forceRefreshHardwareNames() async {
    try {
      final firebaseService = _ref.read(firebaseSwitchServiceProvider);

      // Perform normal fetch
      final hardwareNames = await firebaseService.getHardwareNames();

      if (hardwareNames.isNotEmpty) {
        // 1. Update names for EXISTING devices
        final Map<String, SwitchDevice> updatedDevices = {
          for (var device in state)
            device.id: device.copyWith(
              name: hardwareNames[device.id] ?? device.name,
            ),
        };

        // 2. Create NEW devices for keys found in Firebase but not in state
        for (final key in hardwareNames.keys) {
          if (!updatedDevices.containsKey(key) && key.startsWith("relay")) {
            updatedDevices[key] = SwitchDevice(
              id: key,
              name:
                  hardwareNames[key] ?? 'Switch ${key.replaceAll("relay", "")}',
              isActive: false,
              icon: 'power',
              gpioPin: 0,
              mqttTopic: '',
              isConnected: false,
              nickname: null, // New devices have no local nickname yet
            );
          }
        }

        // 3. Convert to list and SORT naturally (relay1, relay2, ..., relay10)
        final List<SwitchDevice> newList = updatedDevices.values.toList();
        newList.sort((a, b) {
          // Extract numbers for natural sort
          int? nA = int.tryParse(a.id.replaceAll(RegExp(r'[^0-9]'), ''));
          int? nB = int.tryParse(b.id.replaceAll(RegExp(r'[^0-9]'), ''));
          if (nA != null && nB != null) return nA.compareTo(nB);
          return a.id.compareTo(b.id);
        });

        // 4. Update state
        state = newList;

        final msg =
            'Synced & Discovered: ${hardwareNames.length} devices found.';
        print('DEBUG: $msg');
        return msg;
      } else {
        const msg = 'No names found in Firebase path.';
        print('DEBUG: $msg');
        return msg;
      }
    } catch (e) {
      final msg = 'Error: $e';
      print(msg);
      return msg;
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

      // Listener 1: Telemetry
      _telemetrySubscription = firebaseService.listenToTelemetry().listen((
        telemetry,
      ) {
        _lastTelemetry = telemetry;
        _mergeAndEmit();
      });

      // Listener 2: Commands (For discovery of manually added switches)
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

  void _mergeAndEmit() {
    // 1. Telemetry Data
    final telemetry = _lastTelemetry;

    // Parse voltage from telemetry
    double voltage = 0.0;
    if (telemetry.containsKey('voltage_ac')) {
      voltage = (telemetry['voltage_ac'] is num)
          ? (telemetry['voltage_ac'] as num).toDouble()
          : 0.0;
    } else if (telemetry.containsKey('voltage')) {
      voltage = (telemetry['voltage'] is num)
          ? (telemetry['voltage'] as num).toDouble()
          : 0.0;
    }

    // 2. Discover Keys from BOTH sources
    final Set<String> allKeys = {};

    // Add keys from telemetry
    allKeys.addAll(
      telemetry.keys
          .where((key) => key.toString().startsWith('relay'))
          .map((key) => key.toString()),
    );

    // Add keys from commands (Fix for dynamic creation)
    allKeys.addAll(
      _lastCommands.keys
          .where((key) => key.toString().startsWith('relay'))
          .map((key) => key.toString()),
    );

    // Merge with existing IDs
    final currentIds = state.map((d) => d.id).toSet();
    final allRelayIds = {...currentIds, ...allKeys}.toList();

    // Natural Sort
    allRelayIds.sort((a, b) {
      int? nA = int.tryParse(a.replaceAll(RegExp(r'[^0-9]'), ''));
      int? nB = int.tryParse(b.replaceAll(RegExp(r'[^0-9]'), ''));
      if (nA != null && nB != null) return nA.compareTo(nB);
      return a.compareTo(b);
    });

    final currentDeviceMap = {for (var d in state) d.id: d};
    final currentNicknames = {for (var d in state) d.id: d.nickname};

    state = allRelayIds.map((id) {
      // State Priority: Telemetry > Command > Existing > Default OFF
      // If telemetry has value, use it.
      // If not, check commands (maybe we just created it and set it to 0).
      // If not, keep existing state.

      bool newIsActive = false;
      // Telemetry has highest truth
      if (telemetry.containsKey(id)) {
        final rawVal = telemetry[id];
        if (rawVal != null) {
          if (rawVal is int)
            newIsActive = (rawVal == 0);
          else if (rawVal is bool)
            newIsActive = !rawVal;
          else
            newIsActive =
                rawVal.toString() == '0' || rawVal.toString() == 'false';
        }
      }
      // Fallback to command value if telemetry missing (e.g. new switch)
      else if (_lastCommands.containsKey(id)) {
        final rawVal = _lastCommands[id];
        if (rawVal != null) {
          if (rawVal is int)
            newIsActive =
                (rawVal == 1); // Commands are positive logic usually? Wait.
          // Code says: active=true -> send 0. So 0 is ON?
          // "sendCommand(id, newState ? 0 : 1)" -> True (Active) sends 0.
          // So in commands, 0 means ON.
          if (rawVal is int)
            newIsActive = (rawVal == 0);
          else
            newIsActive = rawVal.toString() == '0';
        }
      } else if (currentDeviceMap.containsKey(id)) {
        newIsActive = currentDeviceMap[id]!.isActive;
      }

      bool isPending = false;
      bool isConnected = _isDeviceConnected(telemetry['lastSeen']);

      // JITTER PROTECTION
      if (_pendingSwitches.containsKey(id)) {
        final pendingTime = _pendingSwitches[id]!;
        if (DateTime.now().difference(pendingTime).inMilliseconds < 2000) {
          final existing = currentDeviceMap[id];
          if (existing != null && newIsActive != existing.isActive) {
            newIsActive = existing.isActive;
            isPending = true;
          } else {
            _pendingSwitches.remove(id);
            isPending = false;
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
          nickname: currentNicknames[id] ?? currentDeviceMap[id]!.nickname,
        );
      } else {
        return SwitchDevice(
          id: id,
          name: 'Switch ${id.replaceAll("relay", "")}',
          isActive: newIsActive,
          icon: 'power',
          gpioPin: 0,
          mqttTopic: '',
          isConnected: isConnected,
          nickname: currentNicknames[id],
        );
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
      // Consider offline if no update for 10 seconds
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

    // 1. OPTIMISTIC UI: Update instantly
    _pendingSwitches[id] = DateTime.now();
    state = [
      for (final d in state)
        if (d.id == id) d.copyWith(isActive: newState, isPending: true) else d,
    ];

    try {
      // 2. SEND COMMAND: Strict 0 (OFF) | 1 (ON) contract
      // Logic: Active UI (newState=true) -> Send 0 (OFF)
      //        Inactive UI (newState=false) -> Send 1 (ON)
      await _ref
          .read(firebaseSwitchServiceProvider)
          .sendCommand(id, newState ? 0 : 1);

      // 3. WAIT FOR TELEMETRY: Handled by listener
    } catch (e) {
      // 4. ROLLBACK: Revert UI if command fails
      _pendingSwitches.remove(id);
      state = [
        for (final d in state)
          if (d.id == id) d.copyWith(isActive: previousState) else d,
      ];
      print('Command failed, rolling back: $e');
    }
  }

  /// Update local-only nickname
  Future<void> updateNickname(String id, String newName) async {
    state = [
      for (final d in state)
        if (d.id == id) d.copyWith(nickname: newName) else d,
    ];
    await _saveNicknames();
    print('DEBUG: Nickname updated and saved for $id -> $newName');
  }

  /// Update hardware name in Firebase
  Future<void> updateHardwareName(String id, String newName) async {
    // 1. Optimistic Update (UI)
    final previousList = state;
    state = [
      for (final d in state)
        if (d.id == id) d.copyWith(name: newName) else d,
    ];

    try {
      // 2. Firebase Sync
      await _ref
          .read(firebaseSwitchServiceProvider)
          .updateHardwareName(id, newName);

      // Also save nickname locally if it was changed
      _saveNicknames();
    } catch (e) {
      // 3. Rollback on failure
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
