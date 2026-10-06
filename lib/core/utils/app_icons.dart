import 'package:flutter/material.dart';

class AppIcons {
  static IconData getIconForName(String name) {
    final lowerName = name.toLowerCase();
    
    if (lowerName.contains('light') || lowerName.contains('lamp') || lowerName.contains('bulb')) {
      return Icons.lightbulb_rounded;
    } else if (lowerName.contains('tv') || lowerName.contains('television')) {
      return Icons.tv_rounded;
    } else if (lowerName.contains('fan')) {
      return Icons.cyclone_rounded;
    } else if (lowerName.contains('ac') || lowerName.contains('air')) {
      return Icons.ac_unit_rounded;
    } else if (lowerName.contains('pump') || lowerName.contains('water') || lowerName.contains('motor')) {
      return Icons.water_drop_rounded;
    } else if (lowerName.contains('heater')) {
      return Icons.fireplace_rounded;
    } else if (lowerName.contains('computer') || lowerName.contains('pc')) {
      return Icons.computer_rounded;
    } else if (lowerName.contains('speaker') || lowerName.contains('audio')) {
      return Icons.speaker_rounded;
    } else if (lowerName.contains('fridge') || lowerName.contains('refrigerator')) {
      return Icons.kitchen_rounded;
    } else if (lowerName.contains('outdoor') || lowerName.contains('street') || lowerName.contains('porch')) {
      return Icons.wb_twilight_rounded;
    }
    
    return Icons.electrical_services_rounded;
  }

  static IconData getIcon(String? iconKey, String name) {
    if (iconKey != null && availableIcons.containsKey(iconKey)) {
      return availableIcons[iconKey]!;
    }
    return getIconForName(name);
  }

  static const Map<String, IconData> availableIcons = {
    'Default': Icons.electrical_services_rounded,
    'Light': Icons.lightbulb_rounded,
    'Desk Lamp': Icons.tungsten_rounded,
    'LED Strip': Icons.linear_scale_rounded,
    'Chandlier': Icons.wb_iridescent_rounded,
    'TV': Icons.tv_rounded,
    'AC': Icons.ac_unit_rounded,
    'Fan': Icons.cyclone_rounded,
    'Exhaust Fan': Icons.mode_fan_off_rounded,
    'Water Pump': Icons.water_drop_rounded,
    'Heater': Icons.fireplace_rounded,
    'Desktop PC': Icons.desktop_windows_rounded,
    'Laptop': Icons.laptop_mac_rounded,
    'Speaker': Icons.speaker_rounded,
    'Fridge': Icons.kitchen_rounded,
    'Microwave': Icons.microwave_rounded,
    'Coffee Maker': Icons.coffee_maker_rounded,
    'Outdoor': Icons.wb_twilight_rounded,
    'Gate': Icons.door_sliding_rounded,
    'Garage': Icons.garage_rounded,
    'Camera': Icons.camera_alt_rounded,
    'Lock': Icons.lock_rounded,
    'Router': Icons.router_rounded,
    'Iron': Icons.iron_rounded,
    'Washing Machine': Icons.local_laundry_service_rounded,
    'Bed': Icons.bed_rounded,
    'Chair': Icons.chair_rounded,
    'Plant': Icons.local_florist_rounded,
    'Vacuum': Icons.cleaning_services_rounded,
    'Thermometer': Icons.thermostat_rounded,
    'Door': Icons.door_front_door_rounded,
    'Window': Icons.window_rounded,
    'Curtain': Icons.blinds_rounded,
  };
}
