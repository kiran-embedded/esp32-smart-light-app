import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/switch_device.dart';
import '../../providers/switch_provider.dart';
import '../../services/haptic_service.dart';
import '../../services/sound_service.dart';
import '../../widgets/bot/bot_assistant.dart' as robo;
import '../../core/ui/responsive_layout.dart';

class SwitchCard extends ConsumerWidget {
  final IconData icon;
  final String label;
  final SwitchDevice device;
  final bool spinIcon;

  const SwitchCard({
    super.key,
    required this.icon,
    required this.label,
    required this.device,
    this.spinIcon = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final activeColor = theme.colorScheme.primary;
    // Brighten the inactive state colors significantly for high visibility
    final inactiveColor = Colors.white.withOpacity(0.8);
    final isActive = device.isActive;

    Widget iconWidget = Icon(
      icon,
      color: isActive ? activeColor : inactiveColor,
      size: 24.sp, // Increased icon size for premium presence
    );

    // Dynamic rotation animation for Active Fans
    if (spinIcon && isActive) {
      iconWidget = iconWidget.animate(onPlay: (c) => c.repeat()).rotate(duration: 1200.ms);
    }

    return GestureDetector(
      onTap: () {
        HapticService.toggle(!isActive);
        ref.read(switchDevicesProvider.notifier).toggleSwitch(device.id);

        // Instant audio response
        final soundService = ref.read(soundServiceProvider);
        Future.microtask(() {
          if (!isActive) {
            soundService.playSwitchOn();
          } else {
            soundService.playSwitchOff();
          }
        });

        // Trigger robo eye reaction
        robo.triggerBotReaction(ref, robo.BotReaction.nod);
      },
      child: Container(
        height: 114.h, // Increased box height for larger layout size
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 6.w),
        decoration: BoxDecoration(
          color: const Color(0xFF090F0C).withOpacity(0.65),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isActive ? activeColor.withOpacity(0.2) : Colors.white.withOpacity(0.04),
            width: 0.8,
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: 4.h),
            // Icon
            iconWidget,
            const Spacer(),
            // Label
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 10.5.sp, // Increased text size for better readability
                fontWeight: FontWeight.bold,
                // Make the switch text highly visible even when OFF
                color: Colors.white.withOpacity(isActive ? 1.0 : 0.85),
              ),
            ),
            // Extra spacing to push the pill a bit more to the bottom
            SizedBox(height: 8.h),
            // Custom Switch indicator pill with a green glass border
            Container(
              width: 32.w,
              height: 16.h,
              padding: EdgeInsets.all(2.r),
              decoration: BoxDecoration(
                color: isActive ? activeColor : Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10.r),
                // Premium glowing neon green glass border around the pill
                border: Border.all(
                  color: const Color(0xFF00FF66).withOpacity(isActive ? 0.8 : 0.3),
                  width: 0.8,
                ),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOutQuad,
                alignment: isActive ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 10.h,
                  height: 10.h,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }
}
