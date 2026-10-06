import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../providers/switch_provider.dart';
import '../../../../models/switch_device.dart';
import '../../switch_grid/device_config_popup.dart';
import '../../../../services/haptic_service.dart';
import '../../../../services/sound_service.dart';

class QuickControlTile extends ConsumerWidget {
  final SwitchDevice device;
  final IconData icon;
  final Color iconColor;
  final String subtitle;

  const QuickControlTile({
    super.key,
    required this.device,
    required this.icon,
    required this.iconColor,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOn = device.isActive;

    return GestureDetector(
      onTap: () {
        HapticService.selection();
        ref.read(switchDevicesProvider.notifier).toggleSwitch(device.id);
        final soundService = ref.read(soundServiceProvider);
        Future.microtask(() {
          if (!isOn) {
            soundService.playSwitchOn();
          } else {
            soundService.playSwitchOff();
          }
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isOn ? iconColor.withOpacity(0.06) : const Color(0xFF0D1117),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isOn ? iconColor.withOpacity(0.2) : Colors.white.withOpacity(0.06),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(14),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Large circle icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isOn ? iconColor.withOpacity(0.18) : Colors.white.withOpacity(0.06),
                    boxShadow: isOn
                        ? [BoxShadow(color: iconColor.withOpacity(0.25), blurRadius: 12, spreadRadius: -2)]
                        : null,
                  ),
                  child: Icon(icon, color: isOn ? iconColor : Colors.white.withOpacity(0.3), size: 24),
                ),
                const Spacer(),
                // Device name
                Text(
                  device.nickname ?? device.name,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isOn ? Colors.white : Colors.white.withOpacity(0.8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  device.room?.isNotEmpty == true ? device.room! : subtitle,
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    color: isOn ? iconColor.withOpacity(0.8) : Colors.white.withOpacity(0.3),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 34),
              ],
            ),

            // 3-dot menu top right
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    builder: (context) => DeviceConfigPopup(deviceId: device.id),
                  );
                },
                child: Icon(Icons.more_vert_rounded, color: Colors.white.withOpacity(0.25), size: 18),
              ),
            ),

            // Toggle bottom right
            Positioned(
              bottom: 0,
              right: -8,
              child: Transform.scale(
                scale: 0.78,
                child: CupertinoSwitch(
                  value: isOn,
                  activeTrackColor: iconColor,
                  inactiveTrackColor: Colors.white.withOpacity(0.1),
                  onChanged: (value) {
                    HapticService.selection();
                    ref.read(switchDevicesProvider.notifier).toggleSwitch(device.id);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
