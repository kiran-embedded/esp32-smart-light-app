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
        state = [
          for (final device in state)
            device.copyWith(name: hardwareNames[device.id] ?? device.name),
        ];
        final msg = 'Synced: $hardwareNames';
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

        // Parse global voltage (or voltage_ac)
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

        // IMPORTANT: Merge with existing nicknames in state to prevent overwrite
        final currentNicknames = {for (var d in state) d.id: d.nickname};

        state = state.map((device) {
          bool newIsActive =
              telemetry[device.id] == 0 || telemetry[device.id] == false;
          bool isPending = false;

          // JITTER PROTECTION:
          // If a user just toggled this switch, ignore stale telemetry for 2s
          if (_pendingSwitches.containsKey(device.id)) {
            final pendingTime = _pendingSwitches[device.id]!;
            if (DateTime.now().difference(pendingTime).inMilliseconds < 2000) {
              // If telemetry conflicts with our local optimistic state, ignore it
              if (newIsActive != device.isActive) {
                newIsActive = device.isActive; // Keep local state
                isPending = true; // Still pending check
              } else {
                // Telemetry caught up!
                _pendingSwitches.remove(device.id);
                isPending = false; // Resolved
              }
            } else {
              // Timeout -> stop protecting
              _pendingSwitches.remove(device.id);
              isPending = false;
            }
          }

          return device.copyWith(
            isActive: newIsActive,
            isPending: isPending,
            isConnected: isConnected,
            voltage: voltage,
            // Preserver nickname
            nickname: currentNicknames[device.id] ?? device.nickname,
          );
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
