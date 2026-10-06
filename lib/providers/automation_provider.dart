import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'switch_provider.dart';
import '../../services/haptic_service.dart';

final automationProvider = StateNotifierProvider<AutomationNotifier, Map<String, bool>>((ref) {
  return AutomationNotifier(ref);
});

class AutomationNotifier extends StateNotifier<Map<String, bool>> {
  final Ref _ref;
  static const String _prefsKey = 'aurexacore_automation_rules';

  AutomationNotifier(this._ref) : super({
    // Device Automation
    'device_street_light_630pm': false,
    'device_turn_off_11pm': false,
    'device_garden_light_sunset': false,
    'device_turn_off_tv_2h': false,
    // Sunrise / Sunset
    'sun_outdoor_on_sunset': false,
    'sun_outdoor_off_sunrise': false,
    // Location
    'loc_arrive_hall_on': false,
    'loc_leave_all_off': false,
    // Sensor Automation
    'sensor_motion_hall_30s': false,
    'sensor_temp_fan_on': false,
    'sensor_rain_outdoor_off': false,
    'sensor_water_pump_off': false,
    // Power Automation
    'power_low_disable_heavy': false,
    'power_restored_off_emergency': false,
    'power_offline_notify': false,
    // Delay Automation
    'delay_plug_wait_10m': false,
  }) {
    _loadState();
  }

  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedData = prefs.getString(_prefsKey);
      if (savedData != null) {
        final Map<String, dynamic> decoded = jsonDecode(savedData);
        state = {
          ...state,
          ...decoded.map((key, value) => MapEntry(key, value as bool)),
        };
      }
    } catch (e) {
      print('Error loading automations state: $e');
    }
  }

  Future<void> toggleRule(String ruleId) async {
    HapticService.selection();
    state = {
      ...state,
      ruleId: !(state[ruleId] ?? false),
    };
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(state));
    } catch (e) {
      print('Error saving automations state: $e');
    }
  }

  Future<bool> triggerRoutine(String routineName) async {
    HapticService.medium();
    final switchNotifier = _ref.read(switchDevicesProvider.notifier);
    final devices = _ref.read(switchDevicesProvider);

    if (routineName == 'Good Morning') {
      // Turn ON relay1 (Switch 1) and relay2 (Switch 2)
      switchNotifier.setSwitchState('relay1', true);
      switchNotifier.setSwitchState('relay2', true);
      return true;
    } else if (routineName == 'Good Night' || routineName == 'Away Mode') {
      // Turn OFF all switches
      for (final device in devices) {
        switchNotifier.setSwitchState(device.id, false);
      }
      return true;
    } else if (routineName == 'Movie Mode') {
      // Turn ON relay4 (Scenes) and turn OFF relay3 (Fans)
      switchNotifier.setSwitchState('relay4', true);
      switchNotifier.setSwitchState('relay3', false);
      return true;
    } else if (routineName == 'Office Mode') {
      // Turn ON relay1 (Switch 1) and relay3 (Switch 3)
      switchNotifier.setSwitchState('relay1', true);
      switchNotifier.setSwitchState('relay3', true);
      return true;
    }
    return false;
  }
}
