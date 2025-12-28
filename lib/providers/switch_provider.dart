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

  void _initTelemetryListener() {
    try {
      final firebaseService = _ref.read(firebaseSwitchServiceProvider);

      _telemetrySubscription = firebaseService.listenToTelemetry().listen((
        telemetry,
      ) {
        final lastSeen = telemetry['lastSeen'];
        final bool isConnected = _isDeviceConnected(lastSeen);

        // Parse global voltage
        double voltage = 0.0;
        if (telemetry.containsKey('voltage_ac')) {
          voltage = (telemetry['voltage_ac'] is num)
              ? (telemetry['voltage_ac'] as num).toDouble()
              : double.tryParse(telemetry['voltage_ac'].toString()) ?? 0.0;
        } else if (telemetry.containsKey('voltage')) {
          voltage = (telemetry['voltage'] is num)
              ? (telemetry['voltage'] as num).toDouble()
              : double.tryParse(telemetry['voltage'].toString()) ?? 0.0;
        }

        // DYNAMIC DISCOVERY: Find all 'relayX' keys
        final Set<String> telemetryRelayIds = telemetry.keys
            .where((key) => key.toString().startsWith('relay'))
            .map((key) => key.toString())
            .toSet();

        // Merge with existing IDs to prevent flickering if telemetry misses one
        final currentIds = state.map((d) => d.id).toSet();
        final allRelayIds = {...currentIds, ...telemetryRelayIds}.toList();

        // Natural Sort (relay1, relay2, ... relay10)
        allRelayIds.sort((a, b) {
          int? nA = int.tryParse(a.replaceAll(RegExp(r'[^0-9]'), ''));
          int? nB = int.tryParse(b.replaceAll(RegExp(r'[^0-9]'), ''));
          if (nA != null && nB != null) return nA.compareTo(nB);
          return a.compareTo(b);
        });

        // Lookup maps for efficiency
        final currentDeviceMap = {for (var d in state) d.id: d};
        // Reuse nicknames (IMPORTANT)
        final currentNicknames = {for (var d in state) d.id: d.nickname};

        state = allRelayIds.map((id) {
          // Get value from telemetry (Active Low: 0 = ON)
          final rawVal = telemetry[id];
          bool newIsActive = false;
          if (rawVal != null) {
            // Handle 0/1/true/false
            if (rawVal is int) {
              newIsActive = (rawVal == 0);
            } else if (rawVal is bool) {
              newIsActive = !rawVal; // Logic inversion: false -> ON
            } else {
              // Fallback string parse
              newIsActive =
                  rawVal.toString() == '0' || rawVal.toString() == 'false';
            }
          } else {
            // retain previous state if missing in this packet (or defaulting to off)
            // If device exists, keep its state. If new, default off.
            if (currentDeviceMap.containsKey(id)) {
              newIsActive = currentDeviceMap[id]!.isActive;
            }
          }

          bool isPending = false;

          // JITTER PROTECTION logic (Same as before)
          if (_pendingSwitches.containsKey(id)) {
            final pendingTime = _pendingSwitches[id]!;
            if (DateTime.now().difference(pendingTime).inMilliseconds < 2000) {
              final existing = currentDeviceMap[id];
              if (existing != null && newIsActive != existing.isActive) {
                newIsActive = existing.isActive; // Ignore telemetry, keep local
                isPending = true;
              } else {
                _pendingSwitches.remove(id); // Telemetry matches!
                isPending = false;
              }
            } else {
              _pendingSwitches.remove(id); // Timeout
            }
          }

          if (currentDeviceMap.containsKey(id)) {
            // UPDATE EXISTING
            return currentDeviceMap[id]!.copyWith(
              isActive: newIsActive,
              isPending: isPending,
              isConnected: isConnected,
              voltage: voltage,
              nickname: currentNicknames[id] ?? currentDeviceMap[id]!.nickname,
            );
          } else {
            // CREATE NEW (Dynamic)
            return SwitchDevice(
              id: id,
              name: 'Switch ${id.replaceAll("relay", "")}',
              isActive: newIsActive,
              icon: 'power',
              gpioPin: 0,
              mqttTopic: '',
              isConnected: isConnected,
              nickname: currentNicknames[id], // Might be null
            );
          }
        }).toList();
      });
    } catch (e) {
      print('Error initializing telemetry sync: $e');
    }
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
    super.dispose();
  }
}
