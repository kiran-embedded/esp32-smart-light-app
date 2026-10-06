import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../providers/switch_provider.dart';
import '../../../../models/switch_device.dart';
import '../../../../services/haptic_service.dart';
import 'device_config_popup.dart';
import '../../../core/utils/app_icons.dart';
import '../common/aurexa_toggle.dart';

class SwitchListCard extends ConsumerWidget {
  final SwitchDevice device;
  final bool isDark;
  final Color accent;

  const SwitchListCard({
    super.key,
    required this.device,
    required this.isDark,
    required this.accent,
  });

  String get _roomLabel {
    final room = device.room?.trim();
    if (room != null && room.isNotEmpty) return room;
    return 'Home';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = device.isActive;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111111) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isActive 
              ? accent.withValues(alpha: 0.5) 
              : (isDark ? const Color(0xFF222222) : const Color(0xFFE8E8ED)),
          width: isActive ? 1.2 : 1,
        ),
        boxShadow: [
          if (isActive)
            BoxShadow(
              color: accent.withValues(alpha: isDark ? 0.15 : 0.1),
              blurRadius: 12,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          if (!isActive)
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
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
                      accent.withValues(alpha: 0.95),
                      accent.withValues(alpha: 0.35),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
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
                      color: isDark ? Colors.white : Colors.black87,
                      size: 24,
                    ).animate(target: isActive ? 1 : 0)
                      .tint(color: accent, end: 0.6),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          device.name.toUpperCase(),
                          style: GoogleFonts.outfit(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.15,
                            color: isDark ? Colors.white : Colors.black,
                            height: 1.15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          isActive ? 'ON' : 'OFF',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isActive ? accent : (isDark ? Colors.white38 : Colors.black45),
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.home_rounded,
                                size: 10,
                                color: accent,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                _roomLabel,
                                style: GoogleFonts.outfit(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: accent,
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
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
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: Icon(
                            Icons.more_vert_rounded,
                            color: isDark ? Colors.white30 : Colors.black38,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      AurexaToggle(
                        value: isActive,
                        width: 44,
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
