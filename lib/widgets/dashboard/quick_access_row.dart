import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/switch_provider.dart';
import '../../../services/haptic_service.dart';
import '../../../widgets/scheduler/scheduler_settings_popup.dart';
import '../../../core/constants/app_constants.dart';

class QuickAccessRow extends ConsumerWidget {
  final VoidCallback? onGoogleHomeTap;
  final VoidCallback? onAssistantTap;

  const QuickAccessRow({
    super.key,
    this.onGoogleHomeTap,
    this.onAssistantTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final devices = ref.watch(switchDevicesProvider);
    final firebaseService = ref.read(firebaseSwitchServiceProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.tealAccent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Quick Actions',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildActionButton(
              theme: theme,
              icon: Icons.power_settings_new,
              label: 'All ON',
              color: Colors.tealAccent,
              onTap: () {
                HapticService.heavy();
                for (var device in devices) {
                  if (!device.isActive) {
                    ref.read(switchDevicesProvider.notifier).setSwitchState(device.id, true);
                  }
                }
              },
            ),
            const SizedBox(width: 8),
            _buildActionButton(
              theme: theme,
              icon: Icons.power_settings_new,
              label: 'All OFF',
              color: theme.colorScheme.error,
              onTap: () {
                HapticService.heavy();
                for (var device in devices) {
                  if (device.isActive) {
                    ref.read(switchDevicesProvider.notifier).setSwitchState(device.id, false);
                  }
                }
              },
            ),
            const SizedBox(width: 8),
            _buildActionButton(
              theme: theme,
              icon: Icons.access_time_rounded,
              label: 'Add Timer',
              color: theme.colorScheme.primary,
              onTap: () {
                HapticService.selection();
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const SchedulerSettingsPopup(
                    initialDeviceId: AppConstants.defaultDeviceId,
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            _buildActionButton(
              theme: theme,
              icon: Icons.grid_view_rounded,
              label: 'Scenes',
              color: theme.colorScheme.secondary,
              onTap: () {
                HapticService.selection();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Scenes coming soon...'),
                    backgroundColor: theme.colorScheme.secondary,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
