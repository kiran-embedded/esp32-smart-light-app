import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../providers/switch_provider.dart';
import '../../../../services/haptic_service.dart';
import '../main_screen.dart';

class QuickActions extends ConsumerWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3.5,
              height: 14,
              decoration: BoxDecoration(
                color: AppTheme.neonGreen,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Actions',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    'Control your home with one tap',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: isDark ? Colors.white38 : Colors.black45,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildAction(
              icon: Icons.power_settings_new_rounded,
              label: 'All ON',
              subtitle: 'Turn on all',
              color: AppTheme.neonGreen,
              isDark: isDark,
              onTap: () {
                HapticService.heavy();
                ref.read(switchDevicesProvider.notifier).setAllSwitchesState(true);
              },
            ),
            const SizedBox(width: 8),
            _buildAction(
              icon: Icons.power_settings_new_rounded,
              label: 'All OFF',
              subtitle: 'Turn off all',
              color: const Color(0xFFEC4899),
              isDark: isDark,
              onTap: () {
                HapticService.heavy();
                ref.read(switchDevicesProvider.notifier).setAllSwitchesState(false);
              },
            ),
            const SizedBox(width: 8),
            _buildAction(
              icon: Icons.access_time_filled_rounded,
              label: 'Add Timer',
              subtitle: 'Schedule',
              color: AppTheme.accentBlue,
              isDark: isDark,
              onTap: () {
                HapticService.selection();
                ref.read(mainScreenStateProvider.notifier).state = 2;
              },
            ),
            const SizedBox(width: 8),
            _buildAction(
              icon: Icons.grid_view_rounded,
              label: 'Scenes',
              subtitle: 'Create & run',
              color: AppTheme.neonPurple,
              isDark: isDark,
              onTap: () {
                HapticService.selection();
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAction({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.14 : 0.10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: isDark ? 0.28 : 0.18),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black87,
                    height: 1.1,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white38 : Colors.black45,
                    height: 1.1,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
