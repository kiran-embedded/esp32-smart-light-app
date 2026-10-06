import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/live_info_provider.dart';

class AppHeaderWeather extends ConsumerWidget {
  const AppHeaderWeather({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveInfo = ref.watch(liveInfoProvider);
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getIconData(liveInfo.weatherIcon),
            color: primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${liveInfo.temperature.toStringAsFixed(1)}°C',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: primary,
                ),
              ),
              Text(
                liveInfo.weatherDescription,
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getIconData(String name) {
    switch (name) {
      case 'Moon':
        return Icons.nightlight_round;
      case 'Cloudy':
        return Icons.cloud_outlined;
      case 'Rain':
        return Icons.water_drop_outlined;
      case 'Snow':
        return Icons.ac_unit;
      case 'Lightning':
        return Icons.flash_on;
      case 'Sun':
      default:
        return Icons.wb_sunny_outlined;
    }
  }
}
