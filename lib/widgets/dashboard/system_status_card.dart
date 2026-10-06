import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/live_info_provider.dart';
import '../../../providers/switch_provider.dart';

class SystemStatusCard extends ConsumerWidget {
  const SystemStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveInfo = ref.watch(liveInfoProvider);
    final devices = ref.watch(switchDevicesProvider);
    final theme = Theme.of(context);

    // ESP32 Status: Connected if voltage is > 0
    final isOnline = liveInfo.acVoltage >= 100;

    // Active Switches
    final activeSwitchesCount = devices.where((d) => d.isActive).length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildPill(
          theme: theme,
          icon: Icons.wifi,
          iconColor: isOnline ? Colors.tealAccent : theme.colorScheme.error,
          iconBgColor: (isOnline ? Colors.tealAccent : theme.colorScheme.error).withOpacity(0.15),
          title: 'ESP32',
          value: isOnline ? 'Online' : 'Offline',
          isOnlineStatus: true,
          statusColor: isOnline ? Colors.tealAccent : theme.colorScheme.error,
        ),
        const SizedBox(width: 12),
        _buildPill(
          theme: theme,
          icon: Icons.power_rounded,
          iconColor: Colors.blueAccent,
          iconBgColor: Colors.blueAccent.withOpacity(0.15),
          title: 'Active Sw',
          value: '$activeSwitchesCount',
        ),
        const SizedBox(width: 12),
        _buildPill(
          theme: theme,
          icon: Icons.access_time_rounded,
          iconColor: Colors.purpleAccent,
          iconBgColor: Colors.purpleAccent.withOpacity(0.15),
          title: 'Active Timers',
          value: '0',
        ),
      ],
    );
  }

  Widget _buildPill({
    required ThemeData theme,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String value,
    bool isOnlineStatus = false,
    Color? statusColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF101418), // AMOLED soft card color
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  if (isOnlineStatus)
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            value,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      value,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
