import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/switch_provider.dart';
import '../../../screens/main/main_screen.dart';
import 'controls/quick_control_tile.dart';

class QuickControlsGrid extends ConsumerWidget {
  const QuickControlsGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = ref.watch(switchDevicesProvider);

    // Show max 4: favorites first, fallback to first 4 devices
    final favorites = devices.where((d) => d.isFavorite).toList();
    final displayDevices = favorites.isNotEmpty
        ? favorites.take(4).toList()
        : devices.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 3,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.purpleAccent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'My Switches',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () {
                ref.read(mainScreenStateProvider.notifier).state = 1;
              },
              child: Row(
                children: [
                  Text(
                    'View All',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.white38,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Colors.white38),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        if (displayDevices.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Icon(Icons.power_off_rounded, size: 40, color: Colors.white12),
                  const SizedBox(height: 10),
                  Text(
                    'No switches found.\nMark some as favorites!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: Colors.white30,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.25,
            ),
            itemCount: displayDevices.length,
            itemBuilder: (context, index) {
              final device = displayDevices[index];
              final config = _getTileConfig(device.nickname ?? device.name);

              return QuickControlTile(
                device: device,
                icon: config.icon,
                iconColor: config.color,
                subtitle: config.subtitle,
              );
            },
          ),
      ],
    );
  }

  _TileConfig _getTileConfig(String deviceName) {
    final lowerName = deviceName.toLowerCase();

    if (lowerName.contains('outdoor') || lowerName.contains('garden')) {
      return _TileConfig(Icons.lightbulb_rounded, const Color(0xFFFFA726), 'Outdoor');
    }
    if (lowerName.contains('street') || lowerName.contains('pole')) {
      return _TileConfig(Icons.streetview_rounded, const Color(0xFF42A5F5), 'Outside');
    }
    if (lowerName.contains('sit out') || lowerName.contains('porch')) {
      return _TileConfig(Icons.wb_twilight_rounded, const Color(0xFFAB47BC), 'Sit Out');
    }
    if (lowerName.contains('led') || lowerName.contains('strip')) {
      return _TileConfig(Icons.lightbulb_circle_rounded, const Color(0xFF26C6DA), 'Room');
    }
    if (lowerName.contains('fan')) {
      return _TileConfig(Icons.mode_fan_off_rounded, const Color(0xFF26A69A), 'Fan');
    }
    if (lowerName.contains('plug') || lowerName.contains('socket')) {
      return _TileConfig(Icons.power_rounded, const Color(0xFF66BB6A), 'Plug');
    }
    if (lowerName.contains('switch')) {
      return _TileConfig(Icons.power_rounded, const Color(0xFF4CAF50), 'Switch');
    }
    if (lowerName.contains('light') || lowerName.contains('bulb')) {
      return _TileConfig(Icons.lightbulb_outline_rounded, const Color(0xFFFFCA28), 'Light');
    }

    return _TileConfig(Icons.settings_remote_rounded, const Color(0xFF9E9E9E), 'Device');
  }
}

class _TileConfig {
  final IconData icon;
  final Color color;
  final String subtitle;

  _TileConfig(this.icon, this.color, this.subtitle);
}
