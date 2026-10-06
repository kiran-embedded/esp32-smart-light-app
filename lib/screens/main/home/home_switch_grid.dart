import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../providers/switch_provider.dart';
import '../../../../models/switch_device.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/haptic_service.dart';
import '../../../widgets/switch_grid/device_config_popup.dart';
import '../../../widgets/common/aurexa_toggle.dart';
import '../../../core/utils/app_icons.dart';
import '../main_screen.dart';

class HomeSwitchGrid extends ConsumerWidget {
  const HomeSwitchGrid({super.key});


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final devices = ref.watch(switchDevicesProvider);
    final preview = devices.length > 4 ? devices.sublist(0, 4) : devices;

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
                    'My Switches',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    'Tap to control your devices',
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
            GestureDetector(
              onTap: () {
                HapticService.selection();
                ref.read(mainScreenStateProvider.notifier).state = 1;
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.neonGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'View All →',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.neonGreen,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 10.0;
              final cardH = (constraints.maxHeight - spacing) / 2;
              final cardW = (constraints.maxWidth - spacing) / 2;
              final ratio = cardW / cardH;

              return GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: spacing,
                  childAspectRatio: ratio.clamp(0.70, 1.5),
                ),
                itemCount: preview.length,
                itemBuilder: (context, index) {
                  return _SwitchCard(
                    device: preview[index],
                    isDark: isDark,
                    accent: AppTheme.switchAccentPalette[
                        index % AppTheme.switchAccentPalette.length],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SwitchCard extends ConsumerWidget {
  final SwitchDevice device;
  final bool isDark;
  final Color accent;

  const _SwitchCard({
    required this.device,
    required this.isDark,
    required this.accent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = device.isActive;
    final statusColor =
        isActive ? AppTheme.neonGreen : const Color(0xFF9CA3AF);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111111) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF222222) : const Color(0xFFE8E8ED),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: isDark ? 0.12 : 0.10),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 3.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      accent.withValues(alpha: 0.9),
                      accent.withValues(alpha: 0.35),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.14),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          AppIcons.getIcon(device.iconKey, device.name),
                          color: accent,
                          size: 24,
                        ).animate(target: isActive ? 1 : 0)
                          .tint(color: Colors.white, end: 0.5),
                      ),
                      GestureDetector(
                        onTap: () {
                          HapticService.heavy();
                          showCupertinoModalPopup(
                            context: context,
                            builder: (context) =>
                                DeviceConfigPopup(deviceId: device.id),
                          );
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Icon(
                          Icons.more_vert_rounded,
                          color: isDark ? Colors.white30 : Colors.black38,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    device.name.toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                      color: isDark ? Colors.white : Colors.black,
                      height: 1.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    device.room?.isNotEmpty == true ? device.room! : 'Home',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: isDark ? Colors.white38 : Colors.black45,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isActive ? 'ON' : 'OFF',
                              style: GoogleFonts.outfit(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      AurexaToggle(
                        value: isActive,
                        width: 42,
                        height: 24,
                        onChanged: (_) {
                          HapticService.heavy();
                          ref
                              .read(switchDevicesProvider.notifier)
                              .toggleSwitch(device.id);
                        },
                      ),
                    ],
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
