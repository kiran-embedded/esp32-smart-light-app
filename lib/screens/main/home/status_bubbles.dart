import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../providers/switch_provider.dart';
import '../../../../providers/live_info_provider.dart';
import '../../../../core/theme/app_theme.dart';

class StatusBubbles extends ConsumerWidget {
  const StatusBubbles({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final devices = ref.watch(switchDevicesProvider);
    final isOnline = devices.isNotEmpty && devices.first.isConnected;
    final int rssi = isOnline ? -50 : -100; // Simulated good signal if online
    
    IconData getWifiIcon() {
      if (!isOnline) return Icons.wifi_off_rounded;
      if (rssi > -65) return Icons.wifi_rounded;
      if (rssi > -85) return Icons.wifi_2_bar_rounded;
      return Icons.wifi_1_bar_rounded;
    }
    
    final activeCount = devices.where((d) => d.isActive).length;
    final total = devices.isEmpty ? 4 : devices.length;

    final onlineColor = isDark ? AppTheme.neonGreen : const Color(0xFF059669); // Darker emerald for light mode
    final activeCountColor = const Color(0xFF3B82F6);
    final activeNowColor = isDark ? AppTheme.neonGreen : const Color(0xFF059669);

    return Row(
      children: [
        Expanded(
          child: _StatusPill(
            isDark: isDark,
            accent: isOnline ? onlineColor : const Color(0xFFEF4444),
            icon: getWifiIcon(),
            title: 'ESP32',
            value: isOnline ? 'Online' : 'Offline',
            caption: isOnline ? 'Connected' : 'Not Connected',
            showDot: true,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatusPill(
            isDark: isDark,
            accent: activeCountColor,
            icon: Icons.electrical_services_rounded,
            title: 'Active Switches',
            value: '$activeCount / $total',
            caption: 'Devices Online',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatusPill(
            isDark: isDark,
            accent: activeNowColor,
            icon: Icons.power_settings_new_rounded,
            title: 'Active Now',
            value: '0',
            caption: 'Running Scenes',
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final bool isDark;
  final Color accent;
  final IconData icon;
  final String title;
  final String value;
  final String caption;
  final bool showDot;

  const _StatusPill({
    required this.isDark,
    required this.accent,
    required this.icon,
    required this.title,
    required this.value,
    required this.caption,
    this.showDot = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111111) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accent.withValues(alpha: isDark ? 0.25 : 0.18),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: isDark ? 0.18 : 0.14),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: icon == Icons.wifi_rounded
                ? Icon(icon, color: accent, size: 15)
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .fade(duration: 800.ms, begin: 0.5, end: 1.0)
                : Icon(icon, color: accent, size: 15),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white54 : Colors.black45,
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Row(
                  children: [
                    if (showDot) ...[
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 3),
                    ],
                    Flexible(
                      child: Text(
                        value,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: showDot
                              ? accent
                              : (isDark ? Colors.white : Colors.black),
                          height: 1.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Text(
                  caption,
                  style: GoogleFonts.outfit(
                    fontSize: 7.5,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white38 : Colors.black38,
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
