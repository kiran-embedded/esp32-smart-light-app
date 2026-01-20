import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/switch_provider.dart';
import '../../services/voice_service.dart';
import '../../services/sound_service.dart';
import '../../widgets/robo/robo_assistant.dart' as robo;
// Removed unused import
import '../../core/constants/app_constants.dart';
import '../../core/ui/responsive_layout.dart';
import 'switch_tile.dart';
import '../scheduler/scheduler_settings_popup.dart';

class SwitchGrid extends ConsumerWidget {
  const SwitchGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = ref.watch(switchDevicesProvider);

    if (devices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.cyanAccent),
            const SizedBox(height: 24),
            Text(
              'Waiting for device to come online...',
              style: GoogleFonts.outfit(
                color: Colors.grey,
                fontSize: 14.sp,
                letterSpacing: 1.1.w,
              ),
            ),
          ],
        ),
      );
    }

    Widget grid = GridView.builder(
      padding: EdgeInsets.fromLTRB(
        Responsive.horizontalPadding,
        0,
        Responsive.horizontalPadding,
        100.h,
      ),
      physics: const BouncingScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: Responsive.gridColumns,
        crossAxisSpacing: AppConstants.gridSpacing.w,
        mainAxisSpacing: AppConstants.gridSpacing.h,
        childAspectRatio: 1.0,
      ),
      itemCount: devices.length,
      itemBuilder: (context, index) {
        final device = devices[index];
        return SwitchTile(
          device: device,
          onTap: () {
            ref.read(switchDevicesProvider.notifier).toggleSwitch(device.id);

            // Sound Effect
            final soundService = ref.read(soundServiceProvider);
            if (!device.isActive) {
              soundService.playSwitchOn();
            } else {
              soundService.playSwitchOff();
            }

            // Trigger robo reaction
            robo.triggerRoboReaction(ref, robo.RoboReaction.nod);

            // Voice feedback
            final voiceService = ref.read(voiceServiceProvider);
            final status = !device.isActive ? 'on' : 'off';
            voiceService.speak('${device.name} is $status.');
          },
          onLongPress: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) =>
                  SchedulerSettingsPopup(initialDeviceId: device.id),
            );
          },
        );
      },
    );

    return grid;
  }
}
