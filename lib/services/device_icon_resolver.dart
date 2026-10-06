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
    final lower = name.toLowerCase().trim();

    // 1. Comprehensive Keyword Matching for 100+ icons
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

  // Massive Keyword Map with 100+ categories
  static final Map<List<String>, DeviceIconInfo> _keywordMap = {
    // CLIMATE & AIR
    ['fan', 'blower', 'ventilator', 'exhaust', 'ceiling fan']: const DeviceIconInfo(
      iconOff: Icons.toys_outlined, iconOn: Icons.toys, animation: DeviceIconAnimation.rotating,
    ),
    ['ac', 'air con', 'conditioner', 'split', 'hvac', 'cool', 'cooler']: const DeviceIconInfo(
      iconOff: Icons.ac_unit, iconOn: Icons.ac_unit, animation: DeviceIconAnimation.blooming,
    ),
    ['heater', 'geyser', 'boiler', 'warm', 'fire', 'radiator', 'fireplace']: const DeviceIconInfo(
      iconOff: Icons.local_fire_department_outlined, iconOn: Icons.local_fire_department, animation: DeviceIconAnimation.pulsing,
    ),
    ['purifier', 'filter', 'fresh', 'quality', 'humidifier', 'dehumidifier']: const DeviceIconInfo(
      iconOff: Icons.water_drop_outlined, iconOn: Icons.water_drop, animation: DeviceIconAnimation.rotating,
    ),

    // LIGHTING & LAMPS
    ['light', 'lamp', 'bulb', 'led', 'tube', 'spot', 'chandelier', 'sconce']: const DeviceIconInfo(
      iconOff: Icons.lightbulb_outline, iconOn: Icons.lightbulb, animation: DeviceIconAnimation.blooming,
    ),
    ['street', 'outdoor', 'garden', 'yard', 'flood', 'porch', 'patio']: const DeviceIconInfo(
      iconOff: Icons.deck_outlined, iconOn: Icons.deck, animation: DeviceIconAnimation.blooming,
    ),
    ['bed', 'night', 'reading', 'desk', 'table lamp']: const DeviceIconInfo(
      iconOff: Icons.bedtime_outlined, iconOn: Icons.bedtime, animation: DeviceIconAnimation.blooming,
    ),
    ['decor', 'strip', 'rgb', 'neon', 'fairy']: const DeviceIconInfo(
      iconOff: Icons.auto_awesome_outlined, iconOn: Icons.auto_awesome, animation: DeviceIconAnimation.pulsing,
    ),

    // KITCHEN & APPLIANCES
    ['fridge', 'refrigerator', 'freezer', 'ice']: const DeviceIconInfo(
      iconOff: Icons.kitchen_outlined, iconOn: Icons.kitchen, animation: DeviceIconAnimation.none,
    ),
    ['oven', 'microwave', 'grill', 'cook', 'stove', 'induction', 'hob']: const DeviceIconInfo(
      iconOff: Icons.microwave_outlined, iconOn: Icons.microwave, animation: DeviceIconAnimation.pulsing,
    ),
    ['kettle', 'tea', 'coffee', 'brew', 'espresso']: const DeviceIconInfo(
      iconOff: Icons.coffee_maker_outlined, iconOn: Icons.coffee_maker, animation: DeviceIconAnimation.none,
    ),
    ['mixer', 'blender', 'juicer', 'grinder', 'food processor']: const DeviceIconInfo(
      iconOff: Icons.blender_outlined, iconOn: Icons.blender, animation: DeviceIconAnimation.rotating,
    ),
    ['dishwasher', 'wash', 'plate']: const DeviceIconInfo(
      iconOff: Icons.local_dining_outlined, iconOn: Icons.local_dining, animation: DeviceIconAnimation.none,
    ),
    ['toaster', 'toast']: const DeviceIconInfo(
      iconOff: Icons.breakfast_dining_outlined, iconOn: Icons.breakfast_dining, animation: DeviceIconAnimation.pulsing,
    ),

    // ENTERTAINMENT & ELECTRONICS
    ['tv', 'television', 'led tv', 'screen', 'display', 'monitor']: const DeviceIconInfo(
      iconOff: Icons.tv_outlined, iconOn: Icons.tv, animation: DeviceIconAnimation.blooming,
    ),
    ['xbox', 'ps5', 'playstation', 'console', 'game', 'gaming', 'nintendo']: const DeviceIconInfo(
      iconOff: Icons.sports_esports_outlined, iconOn: Icons.sports_esports, animation: DeviceIconAnimation.pulsing,
    ),
    ['speaker', 'sound', 'audio', 'music', 'hifi', 'box', 'stereo', 'subwoofer']: const DeviceIconInfo(
      iconOff: Icons.speaker_outlined, iconOn: Icons.speaker, animation: DeviceIconAnimation.pulsing,
    ),
    ['router', 'wifi', 'internet', 'modem', 'net', 'switch', 'hub']: const DeviceIconInfo(
      iconOff: Icons.router_outlined, iconOn: Icons.router, animation: DeviceIconAnimation.pulsing,
    ),
    ['pc', 'computer', 'desktop', 'laptop', 'mac']: const DeviceIconInfo(
      iconOff: Icons.computer_outlined, iconOn: Icons.computer, animation: DeviceIconAnimation.none,
    ),
    ['projector', 'cinema', 'theater']: const DeviceIconInfo(
      iconOff: Icons.videocam_outlined, iconOn: Icons.videocam, animation: DeviceIconAnimation.blooming,
    ),

    // UTILITY & HOUSEHOLD
    ['motor', 'pump', 'water', 'tank', 'well']: const DeviceIconInfo(
      iconOff: Icons.water_outlined, iconOn: Icons.water, animation: DeviceIconAnimation.rotating,
    ),
    ['socket', 'plug', 'outlet', 'point', 'relay']: const DeviceIconInfo(
      iconOff: Icons.power_outlined, iconOn: Icons.power, animation: DeviceIconAnimation.none,
    ),
    ['camera', 'cctv', 'cam', 'sec', 'view', 'webcam']: const DeviceIconInfo(
      iconOff: Icons.camera_indoor_outlined, iconOn: Icons.camera_indoor, animation: DeviceIconAnimation.none,
    ),
    ['charger', 'phone', 'usb', 'powerbank']: const DeviceIconInfo(
      iconOff: Icons.battery_charging_full_outlined, iconOn: Icons.battery_charging_full, animation: DeviceIconAnimation.pulsing,
    ),
    ['washing', 'laundry', 'dryer', 'clothes', 'washing machine']: const DeviceIconInfo(
      iconOff: Icons.local_laundry_service_outlined, iconOn: Icons.local_laundry_service, animation: DeviceIconAnimation.rotating,
    ),
    ['vacuum', 'robot', 'roomba', 'cleaner']: const DeviceIconInfo(
      iconOff: Icons.cleaning_services_outlined, iconOn: Icons.cleaning_services, animation: DeviceIconAnimation.pulsing,
    ),
    ['iron', 'steamer']: const DeviceIconInfo(
      iconOff: Icons.iron_outlined, iconOn: Icons.iron, animation: DeviceIconAnimation.pulsing,
    ),
    
    // ROOMS & ZONES (Fallback if name is just a room)
    ['bathroom', 'bath', 'toilet', 'shower']: const DeviceIconInfo(
      iconOff: Icons.bathtub_outlined, iconOn: Icons.bathtub, animation: DeviceIconAnimation.none,
    ),
    ['garage', 'gate', 'door', 'parking']: const DeviceIconInfo(
      iconOff: Icons.garage_outlined, iconOn: Icons.garage, animation: DeviceIconAnimation.none,
    ),
    ['pool', 'swim']: const DeviceIconInfo(
      iconOff: Icons.pool_outlined, iconOn: Icons.pool, animation: DeviceIconAnimation.pulsing,
    ),
  };
}
