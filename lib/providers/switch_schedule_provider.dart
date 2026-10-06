import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/switch_schedule.dart';
import '../core/constants/app_constants.dart';
import '../services/scheduler_service.dart';
import '../services/persistence_service.dart';

class SwitchScheduleNotifier extends StateNotifier<List<SwitchSchedule>> {
  StreamSubscription? _subscription;
  final _database = FirebaseDatabase.instance.ref();

  SwitchScheduleNotifier() : super([]) {
    _initListener();
  }

  void _initListener() {
    final path =
        '${AppConstants.firebaseDevicesPath}/${AppConstants.defaultDeviceId}/schedules';
    _subscription = _database.child(path).onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data == null) {
        // Only clear if we receive an explicit null (empty) from initialized firebase
        // Use caution to not wipe local data if offline (though onValue usually implies sync)
        if (state.isNotEmpty) {
          // Verify if this is a genuine empty list from server
          state = [];
        }
        return;
      }

      final List<SwitchSchedule> schedules = [];
      data.forEach((key, value) {
        if (value is Map) {
          try {
            schedules.add(
              SwitchSchedule.fromJson(Map<String, dynamic>.from(value)),
            );
          } catch (e) {
            print('Error parsing schedule: $e');
          }
        }
      });

      // Update state
      state = schedules;

      // PERSIST LOCALLY for Boot/Native access
      _persistSchedulesLocally(schedules);
    });
  }

  Future<void> _persistSchedulesLocally(List<SwitchSchedule> schedules) async {
    final data = schedules.map((s) => s.toJson()).toList();
    await PersistenceService.saveSchedules(data);
  }

  Future<void> _updateRawSchedules(List<SwitchSchedule> schedules) async {
    final List<String> rawList = [];
    for (var s in schedules) {
      if (!s.isEnabled) continue;
      String node = s.targetNode.replaceAll('relay', 'r');
      String days = s.days.join(',');
      if (days.isEmpty) days = "0"; // 0 means everyday
      String stateVal = s.targetState ? "1" : "0";
      // Format: 09:30:r1:1:1,2,3
      rawList.add('${s.hour.toString().padLeft(2, '0')}:${s.minute.toString().padLeft(2, '0')}:$node:$stateVal:$days');
    }
    final rawStr = rawList.join(';');
    final path = '${AppConstants.firebaseDevicesPath}/${AppConstants.defaultDeviceId}/commands/schedules_raw';
    await _database.child(path).set(rawStr);
  }

  Future<void> addSchedule(SwitchSchedule schedule) async {
    // Optimistic Update
    state = [...state, schedule];

    // Update raw string for ESP32 NTP Hardware Scheduler
    await _updateRawSchedules(state);

    // Schedule Background Job (Keep for redundancy/notifications if needed, or remove later)
    await SchedulerService.scheduleEvent(schedule);

    final path =
        '${AppConstants.firebaseDevicesPath}/${AppConstants.defaultDeviceId}/schedules/${schedule.id}';
    await _database.child(path).set(schedule.toJson());
  }

  Future<void> updateSchedule(SwitchSchedule schedule) async {
    // Optimistic Update
    state = [
      for (final s in state)
        if (s.id == schedule.id) schedule else s,
    ];

    // Update raw string for ESP32 NTP Hardware Scheduler
    await _updateRawSchedules(state);

    // Update Background Job
    await SchedulerService.scheduleEvent(schedule);

    final path =
        '${AppConstants.firebaseDevicesPath}/${AppConstants.defaultDeviceId}/schedules/${schedule.id}';
    await _database.child(path).update(schedule.toJson());
  }

  Future<void> deleteSchedule(String id) async {
    // Optimistic Update
    state = state.where((s) => s.id != id).toList();

    // Update raw string for ESP32 NTP Hardware Scheduler
    await _updateRawSchedules(state);

    // Cancel Background Job
    await SchedulerService.cancelEvent(id);

    final path =
        '${AppConstants.firebaseDevicesPath}/${AppConstants.defaultDeviceId}/schedules/$id';
    await _database.child(path).remove();
  }

  Future<void> deleteSchedules(List<String> ids) async {
    // Optimistic Update
    state = state.where((s) => !ids.contains(s.id)).toList();

    // Update raw string for ESP32 NTP Hardware Scheduler
    await _updateRawSchedules(state);

    for (final id in ids) {
      // Cancel Background Job
      await SchedulerService.cancelEvent(id);

      final path =
          '${AppConstants.firebaseDevicesPath}/${AppConstants.defaultDeviceId}/schedules/$id';
      await _database.child(path).remove();
    }
  }

  void suspend() {
    print('SwitchScheduleNotifier: Suspending listeners...');
    _subscription?.cancel();
    _subscription = null;
  }

  void resume() {
    print('SwitchScheduleNotifier: Resuming listeners...');
    _initListener();
  }

  @override
  void dispose() {
    suspend();
    super.dispose();
  }
}

final switchScheduleProvider =
    StateNotifierProvider<SwitchScheduleNotifier, List<SwitchSchedule>>((ref) {
      return SwitchScheduleNotifier();
    });
