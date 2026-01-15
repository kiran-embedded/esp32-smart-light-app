import 'package:flutter/material.dart';

enum DeviceIconAnimation {
  none,
  rotating, // Fans, Motors
  blooming, // Lights, Bulbs
  pulsing, // Motors, Dynamic appliances
}

class DeviceIconInfo {
  final IconData iconOff;
  final IconData iconOn;
  final DeviceIconAnimation animation;

  const DeviceIconInfo({
    required this.iconOff,
    required this.iconOn,
    this.animation = DeviceIconAnimation.none,
  });
}

class DeviceIconResolver {
  static DeviceIconInfo resolve(String name, [String? category]) {
    // Standardize input
    final lower = name.toLowerCase().trim();

    // 1. Exact Category Override
    if (category != null) {
      final info = _categoryMap[category.toLowerCase()];
      if (info != null) return info;
    }

    // 2. Comprehensive Keyword Matching
    for (final entry in _keywordMap.entries) {
      for (final keyword in entry.key) {
        if (lower.contains(keyword)) {
          return entry.value;
        }
      }
    }

    // Default Appliance
    return const DeviceIconInfo(
      iconOff: Icons.power_settings_new_outlined,
      iconOn: Icons.power_settings_new,
      animation: DeviceIconAnimation.none,
    );
  }

  // Massive Keyword Map for "10k" appliance support feel
  static final Map<List<String>, DeviceIconInfo> _keywordMap = {
    // CLIMATE & AIR
    ['fan', 'blower', 'ventilator', 'exhaust']: const DeviceIconInfo(
      iconOff: Icons.toys_outlined,
      iconOn: Icons.toys,
      animation: DeviceIconAnimation.rotating,
    ),
    [
      'ac',
      'air con',
      'conditioner',
      'split',
      'hvac',
      'cool',
    ]: const DeviceIconInfo(
      iconOff: Icons.ac_unit,
      iconOn: Icons.ac_unit,
      animation: DeviceIconAnimation.blooming, // Cold bloom
    ),
    ['heater', 'geyser', 'boiler', 'warm', 'fire']: const DeviceIconInfo(
      iconOff: Icons.local_fire_department_outlined,
      iconOn: Icons.local_fire_department,
      animation: DeviceIconAnimation.pulsing,
    ),
    ['purifier', 'filter', 'fresh', 'quality']: const DeviceIconInfo(
      iconOff: Icons.filter_vintage_outlined,
      iconOn: Icons.filter_vintage,
      animation: DeviceIconAnimation.rotating,
    ),

    // LIGHTING
    [
      'light',
      'lamp',
      'bulb',
      'led',
      'tube',
      'spot',
      'chandelier',
      'sconce',
    ]: const DeviceIconInfo(
      iconOff: Icons.lightbulb_outline,
      iconOn: Icons.lightbulb,
      animation: DeviceIconAnimation.blooming,
    ),
    ['street', 'outdoor', 'garden', 'yard', 'flood']: const DeviceIconInfo(
      iconOff: Icons.light_mode_outlined,
      iconOn: Icons.light_mode,
      animation: DeviceIconAnimation.blooming,
    ),
    ['bed', 'night', 'reading', 'desk']: const DeviceIconInfo(
      iconOff: Icons.bedtime_outlined,
      iconOn: Icons.bedtime,
      animation: DeviceIconAnimation.blooming,
    ),
    ['decor', 'strip', 'rgb', 'neon']: const DeviceIconInfo(
      iconOff: Icons.auto_awesome_outlined,
      iconOn: Icons.auto_awesome,
      animation: DeviceIconAnimation.pulsing,
    ),

    // KITCHEN
    ['fridge', 'refrigerator', 'freezer', 'ice']: const DeviceIconInfo(
      iconOff: Icons.kitchen_outlined,
      iconOn: Icons.kitchen,
      animation: DeviceIconAnimation.none,
    ),
    ['oven', 'microwave', 'grill', 'cook', 'stove']: const DeviceIconInfo(
      iconOff: Icons.microwave_outlined,
      iconOn: Icons.microwave,
      animation: DeviceIconAnimation.pulsing, // Heat pulse
    ),
    ['kettle', 'tea', 'coffee', 'brew']: const DeviceIconInfo(
      iconOff: Icons.coffee_maker_outlined,
      iconOn: Icons.coffee_maker,
      animation: DeviceIconAnimation.none,
    ),
    ['mixer', 'blender', 'juicer', 'grinder']: const DeviceIconInfo(
      iconOff: Icons.blender_outlined,
      iconOn: Icons.blender,
      animation: DeviceIconAnimation.rotating,
    ),
    ['dishwasher', 'wash', 'plate']: const DeviceIconInfo(
      iconOff: Icons.local_dining_outlined,
      iconOn: Icons.local_dining,
      animation: DeviceIconAnimation.none,
    ),

    // ENTERTAINMENT
    ['tv', 'television', 'led tv', 'screen', 'display']: const DeviceIconInfo(
      iconOff: Icons.tv_outlined,
      iconOn: Icons.tv,
      animation: DeviceIconAnimation.blooming, // Screen glow
    ),
    [
      'xbox',
      'ps5',
      'playstation',
      'console',
      'game',
      'gaming',
    ]: const DeviceIconInfo(
      iconOff: Icons.sports_esports_outlined,
      iconOn: Icons.sports_esports,
      animation: DeviceIconAnimation.pulsing,
    ),
    ['speaker', 'sound', 'audio', 'music', 'hifi', 'box']: const DeviceIconInfo(
      iconOff: Icons.speaker_outlined,
      iconOn: Icons.speaker,
      animation: DeviceIconAnimation.pulsing, // Bass bump
    ),
    ['router', 'wifi', 'internet', 'modem', 'net']: const DeviceIconInfo(
      iconOff: Icons.wifi,
      iconOn: Icons.wifi,
      animation: DeviceIconAnimation.pulsing, // Signal pulse
    ),
    ['pc', 'computer', 'desktop', 'laptop', 'mac']: const DeviceIconInfo(
      iconOff: Icons.computer_outlined,
      iconOn: Icons.computer,
      animation: DeviceIconAnimation.none,
    ),

    // UTILITY
    ['motor', 'pump', 'water', 'tank']: const DeviceIconInfo(
      iconOff: Icons.water_drop_outlined,
      iconOn: Icons.water_drop,
      animation: DeviceIconAnimation.rotating, // Impeller
    ),
    ['socket', 'plug', 'outlet', 'point', 'switch']: const DeviceIconInfo(
      iconOff: Icons.power_outlined,
      iconOn: Icons.power,
      animation: DeviceIconAnimation.none,
    ),
    ['camera', 'cctv', 'cam', 'sec', 'view']: const DeviceIconInfo(
      iconOff: Icons.videocam_outlined,
      iconOn: Icons.videocam,
      animation: DeviceIconAnimation.none,
    ),
    ['charger', 'phone', 'usb']: const DeviceIconInfo(
      iconOff: Icons.battery_charging_full_outlined,
      iconOn: Icons.battery_charging_full,
      animation: DeviceIconAnimation.pulsing,
    ),
    ['washing', 'laundry', 'dryer', 'clothes']: const DeviceIconInfo(
      iconOff: Icons.local_laundry_service_outlined,
      iconOn: Icons.local_laundry_service,
      animation: DeviceIconAnimation.rotating,
    ),
  };

  static const Map<String, DeviceIconInfo> _categoryMap =
      {}; // Deprecated in favor of keyword map
}
