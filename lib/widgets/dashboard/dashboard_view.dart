import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../providers/live_info_provider.dart';
import '../../providers/switch_provider.dart';
import '../../providers/google_home_provider.dart';
import '../../models/switch_device.dart';
import '../../services/haptic_service.dart';
import '../../core/ui/responsive_layout.dart';
import '../../widgets/common/frosted_glass.dart';
import '../../widgets/voice/voice_assistant_overlay.dart';

import 'aurexa_header_card.dart';
import 'status_indicator_card.dart';
import 'time_card.dart';
import 'action_tile.dart';
import 'switch_card.dart';

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveInfo = ref.watch(liveInfoProvider);
    final devices = ref.watch(switchDevicesProvider);
    final googleHomeLinked = ref.watch(googleHomeLinkedProvider).valueOrNull ?? false;

    // Dynamic states
    final isESPConnected = devices.any((d) => d.isConnected);

    // Dynamic Favorite Smart Switches states
    final favorites = devices.where((d) => d.isFavorite).toList();
    final displaySwitches = favorites.isNotEmpty
        ? favorites.take(4).toList()
        : devices.take(4).toList();

    while (displaySwitches.length < 4) {
      final idx = displaySwitches.length + 1;
      displaySwitches.add(_emptyDevice('relay$idx', 'Switch $idx'));
    }

    // Helper to resolve device icon dynamically
    IconData resolveDeviceIcon(SwitchDevice d) {
      final name = d.name.toLowerCase();
      if (name.contains('light') || name.contains('bulb') || d.id == 'relay1') {
        return Icons.lightbulb_outline_rounded;
      } else if (name.contains('plug') || name.contains('socket') || d.id == 'relay2') {
        return Icons.power_rounded;
      } else if (name.contains('fan') || name.contains('ac') || d.id == 'relay3') {
        return Icons.mode_fan_off_rounded;
      } else {
        return Icons.settings_remote_rounded;
      }
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.horizontalPadding,
        vertical: 16.h,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. AUREXA HOME HEADER BANNER CARD
          const AurexaHeaderCard()
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.1, end: 0, curve: Curves.easeOut),
          SizedBox(height: 16.h),

          // 2. ESP32 STATUS ROW
          StatusIndicatorRow(
            isESPConnected: isESPConnected,
          ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
          SizedBox(height: 16.h),

          // 3. TIME CARD
          const TimeCard().animate().fadeIn(delay: 200.ms, duration: 400.ms),
          SizedBox(height: 16.h),

          // 5. GOOGLE HOME & VOICE ASSISTANT ACTIONS ROW
          Row(
            children: [
              Expanded(
                child: ActionTile(
                  icon: Icons.home_rounded,
                  title: 'Google Home',
                  subtitle: googleHomeLinked ? 'Linked' : 'Open Home',
                  onTap: () => _showGoogleHomeDialog(context, ref),
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: ActionTile(
                  icon: Icons.mic_rounded,
                  title: 'Assistant',
                  subtitle: 'Voice Control',
                  onTap: () async {
                    HapticService.selection();
                    await showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      barrierColor: Colors.transparent,
                      isScrollControlled: true,
                      builder: (context) => const VoiceAssistantOverlay(),
                    );
                  },
                ),
              ),
            ],
          ).animate().fadeIn(delay: 350.ms, duration: 400.ms),
          SizedBox(height: 40.h),

          // 6. SMART SWITCHES SECTION
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(left: 4.w, bottom: 12.h),
                child: Text(
                  'SMART SWITCHES',
                  style: GoogleFonts.outfit(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withOpacity(0.4),
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              Row(
                children: List.generate(displaySwitches.length, (index) {
                  final device = displaySwitches[index];
                  final icon = resolveDeviceIcon(device);
                  final isFan = icon == Icons.mode_fan_off_rounded;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: index < displaySwitches.length - 1 ? 8.w : 0,
                      ),
                      child: SwitchCard(
                        icon: icon,
                        label: device.nickname ?? device.name,
                        device: device,
                        spinIcon: isFan,
                      ),
                    ),
                  );
                }),
              ),
            ],
          ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  void _showGoogleHomeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final googleHomeLinked = ref.watch(googleHomeLinkedProvider).valueOrNull ?? false;
          final service = ref.read(googleHomeServiceProvider);
          final theme = Theme.of(context);

          return Dialog(
            backgroundColor: Colors.transparent,
            child: FrostedGlass(
              padding: const EdgeInsets.all(24),
              radius: BorderRadius.circular(28),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.3),
                width: 1.2,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Google Home',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontSize: 22.sp,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    googleHomeLinked
                        ? 'Google Home is linked. Your devices are synced to the cloud.'
                        : 'Google Home is not linked. Link it to sync devices across platforms.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (googleHomeLinked)
                        TextButton(
                          onPressed: () async {
                            await service.unlinkGoogleHome();
                            Navigator.of(context).pop();
                          },
                          child: const Text('Unlink'),
                        ),
                      if (!googleHomeLinked)
                        ElevatedButton(
                          onPressed: () async {
                            await service.linkGoogleHome();
                            Navigator.of(context).pop();
                          },
                          child: const Text('Link'),
                        ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  SwitchDevice _emptyDevice(String id, String name) {
    return SwitchDevice(id: id, name: name, icon: 'power', gpioPin: 0, mqttTopic: '');
  }
}
