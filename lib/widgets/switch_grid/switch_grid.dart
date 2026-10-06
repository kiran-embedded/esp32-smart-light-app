import "../../core/utils/app_icons.dart";
import "../../core/theme/app_theme.dart";
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/switch_provider.dart';
import '../../core/ui/responsive_layout.dart';
import '../../models/switch_device.dart';
import '../../services/haptic_service.dart';
import '../../services/sound_service.dart';
import 'device_config_popup.dart';


class SwitchGrid extends ConsumerWidget {
  final String filterRoom; // 'All', 'Favorites', or custom room name
  final String searchQuery;

  const SwitchGrid({
    super.key,
    this.filterRoom = 'All',
    this.searchQuery = '',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allDevices = ref.watch(switchDevicesProvider);

    // Apply filter
    final devices = allDevices.where((device) {
      // Search query takes priority
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        final name = (device.nickname ?? device.name).toLowerCase();
        final room = (device.room ?? '').toLowerCase();
        return name.contains(q) || room.contains(q);
      }
      if (filterRoom == 'All') return true;
      if (filterRoom == 'Favorites') return device.isFavorite;
      return device.room == filterRoom;
    }).toList();

    if (devices.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.power_off_rounded, size: 52, color: Colors.white12),
            const SizedBox(height: 14),
            Text(
              searchQuery.isNotEmpty ? 'No results for "$searchQuery"' : 'No switches found',
              style: GoogleFonts.outfit(fontSize: 15, color: Colors.white30, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              searchQuery.isNotEmpty ? 'Try a different search term' : 'Try a different filter or add new switches',
              style: GoogleFonts.outfit(fontSize: 12, color: Colors.white.withOpacity(0.2)),
            ),
          ],
        ),
      );
    }

    final itemCount = devices.length;

    return GridView.builder(
      padding: EdgeInsets.fromLTRB(
        Responsive.horizontalPadding,
        0,
        Responsive.horizontalPadding,
        110,
      ),
      physics: const BouncingScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: Responsive.gridColumns,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.78,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        final device = devices[index];
        final config = _getTileConfig(device.nickname ?? device.name, device.iconKey);
        return _SwitchTile(
          device: device,
          icon: config.icon,
          iconColor: config.color,
          subtitle: config.subtitle,
        );
      },
    );
  }

  _TileConfig _getTileConfig(String deviceName, String? iconKey) {
    if (iconKey != null && iconKey.isNotEmpty) {
      // Map iconKey to IconData and standard colors
      final icon = AppIcons.availableIcons[iconKey] ?? Icons.power_rounded;
      Color color = const Color(0xFF00FF66); // default green
      if (iconKey.contains('light') || iconKey.contains('lamp')) color = const Color(0xFFFFCA28);
      if (iconKey.contains('fan') || iconKey.contains('ac')) color = const Color(0xFF26A69A);
      if (iconKey.contains('street') || iconKey.contains('outdoor')) color = const Color(0xFF42A5F5);
      return _TileConfig(icon, color, 'Device');
    }

    final n = deviceName.toLowerCase();
    if (n.contains('outdoor') || n.contains('kitchen')) return _TileConfig(Icons.lightbulb_rounded, const Color(0xFFFFA726), 'Outside');
    if (n.contains('street') || n.contains('pole')) return _TileConfig(Icons.streetview_rounded, const Color(0xFF42A5F5), 'Outside');
    if (n.contains('sit out') || n.contains('porch') || n.contains('lamp')) return _TileConfig(Icons.wb_twilight_rounded, const Color(0xFFAB47BC), 'Sit Out');
    if (n.contains('led') || n.contains('strip') || n.contains('aadu')) return _TileConfig(Icons.lightbulb_circle_rounded, const Color(0xFF9C27B0), 'Room');
    if (n.contains('fan')) return _TileConfig(Icons.mode_fan_off_rounded, const Color(0xFF26A69A), 'Fan');
    if (n.contains('plug') || n.contains('socket')) return _TileConfig(Icons.power_rounded, const Color(0xFF66BB6A), 'Plug');
    if (n.contains('light') || n.contains('bulb')) return _TileConfig(Icons.lightbulb_outline_rounded, const Color(0xFFFFCA28), 'Light');
    if (n.contains('switch') || n.contains('relay')) return _TileConfig(Icons.power_rounded, const Color(0xFF4CAF50), 'Switch');
    return _TileConfig(Icons.settings_remote_rounded, const Color(0xFF9E9E9E), 'Device');
  }
}

class _SwitchTile extends ConsumerWidget {
  final SwitchDevice device;
  final IconData icon;
  final Color iconColor;
  final String subtitle;

  const _SwitchTile({
    required this.device,
    required this.icon,
    required this.iconColor,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOn = device.isActive;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Clean solid colors (No glass)
    final tileBgColor = isDark ? const Color(0xFF111111) : Colors.white;
    final tileBorderColor = isDark ? const Color(0xFF222222) : const Color(0xFFE5E5EA);
    final iconCircleColor = isDark ? const Color(0xFF222222) : const Color(0xFFF2F2F7);
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? Colors.white54 : Colors.black54;

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
          color: isOn ? iconColor : tileBgColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isOn ? iconColor : tileBorderColor,
          ),
        ),
        padding: const EdgeInsets.all(14),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Large circle icon (exact reference match)
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isOn ? Colors.black.withOpacity(0.15) : iconCircleColor,
                  ),
                  child: Icon(icon, color: isOn ? Colors.black : subTextColor, size: 26),
                ),
                const Spacer(),
                // Device name
                Text(
                  device.nickname ?? device.name,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isOn ? Colors.black : textColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                // Room label
                Text(
                  device.room?.isNotEmpty == true ? device.room! : subtitle,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: isOn ? Colors.black54 : subTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 36), // space for toggle
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
                child: Icon(Icons.more_vert_rounded, color: isOn ? Colors.black54 : subTextColor, size: 18),
              ),
            ),

            // Toggle bottom right
            Positioned(
              bottom: 0,
              right: -8,
              child: Transform.scale(
                scale: 0.8,
                child: CupertinoSwitch(
                      activeColor: AppTheme.neonGreen,
                  value: isOn,
                  activeTrackColor: Colors.black, // Contrast dot color
                  inactiveTrackColor: isDark ? const Color(0xFF333333) : const Color(0xFFE5E5EA),
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

class _TileConfig {
  final IconData icon;
  final Color color;
  final String subtitle;
  _TileConfig(this.icon, this.color, this.subtitle);
}
