import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/switch_provider.dart';
import '../../services/voice_service.dart';
import '../../services/sound_service.dart';
import '../../widgets/robo/robo_assistant.dart' as robo;
import '../../models/switch_device.dart';
import '../../core/constants/app_constants.dart';
import 'switch_tile.dart';

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
                fontSize: 14,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: AppConstants.gridColumns,
        crossAxisSpacing: AppConstants.gridSpacing,
        mainAxisSpacing: AppConstants.gridSpacing,
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
            _showAdvancedSheet(context, ref, device);
          },
        );
      },
    );
  }

  void _showAdvancedSheet(
    BuildContext context,
    WidgetRef ref,
    SwitchDevice device,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AdvancedBottomSheet(deviceIdOnly: device),
    );
  }
}

class _AdvancedBottomSheet extends ConsumerWidget {
  final SwitchDevice deviceIdOnly; // We only hold ID/Basic info, look up rest
  // Actually, better to look up the fresh device from provider using ID

  const _AdvancedBottomSheet({required this.deviceIdOnly});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Look up the LATEST device state
    final devices = ref.watch(switchDevicesProvider);
    final device = devices.firstWhere(
      (d) => d.id == deviceIdOnly.id,
      orElse: () => deviceIdOnly,
    );

    return Container(
      height: MediaQuery.of(context).size.height * 0.45,
      decoration: const BoxDecoration(
        color: Color(0xFF121212),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              (device.nickname ?? device.name).toUpperCase(),
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.edit_rounded, color: Colors.cyanAccent),
            title: const Text(
              'App Display Name',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Local-only nickname',
              style: TextStyle(color: Colors.grey),
            ),
            onTap: () {
              _showRename(
                context,
                'Rename Nickname',
                device.nickname ?? device.name,
                (val) async {
                  _showFeedback(context, 'Saving "$val"...');
                  await ref
                      .read(switchDevicesProvider.notifier)
                      .updateNickname(device.id, val);
                  if (context.mounted) {
                    _showFeedback(
                      context,
                      'Saved "$val" successfully!',
                      isError: false,
                    );
                  }
                },
              );
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.settings_remote_rounded,
              color: Colors.orangeAccent,
            ),
            title: const Text(
              'Hardware Name',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Syncs to Firebase',
              style: TextStyle(color: Colors.grey),
            ),
            onTap: () {
              _showRename(context, 'Rename Hardware', device.name, (val) async {
                try {
                  await ref
                      .read(switchDevicesProvider.notifier)
                      .updateHardwareName(device.id, val);
                  if (context.mounted) {
                    _showFeedback(context, 'Hardware name updated to $val');
                  }
                } catch (e) {
                  if (context.mounted) {
                    _showFeedback(
                      context,
                      'Failed to update: $e',
                      isError: true,
                    );
                  }
                }
              });
            },
          ),

          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(
              Icons.bug_report_rounded,
              color: Colors.redAccent,
            ),
            title: const Text(
              'Debug Info',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Diagnostics & Force Sync',
              style: TextStyle(color: Colors.grey),
            ),
            onTap: () {
              Navigator.pop(context);
              _showDebugDialog(context, ref, device);
            },
          ),
        ],
      ),
    );
  }

  void _showDebugDialog(
    BuildContext context,
    WidgetRef ref,
    SwitchDevice device,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Diagnostics',
          style: TextStyle(color: Colors.cyanAccent),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ID: ${device.id}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Hardware Name: ${device.name}',
              style: const TextStyle(color: Colors.white),
            ),
            Text(
              'Nickname: ${device.nickname ?? "null"}',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            const Text(
              'Actions:',
              style: TextStyle(
                color: Colors.cyanAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent.withOpacity(0.2),
                foregroundColor: Colors.blueAccent,
              ),
              onPressed: () async {
                Navigator.pop(context);
                try {
                  _showFeedback(context, 'Forcing Hardware Name Sync...');
                  final result = await ref
                      .read(switchDevicesProvider.notifier)
                      .forceRefreshHardwareNames();
                  if (context.mounted) {
                    _showFeedback(
                      context,
                      result,
                      isError:
                          result.contains('Error') ||
                          result.contains('No names'),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    _showFeedback(context, 'Sync Exception: $e', isError: true);
                  }
                }
              },
              icon: const Icon(Icons.sync),
              label: const Text('Force Hardware Sync'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  void _showRename(
    BuildContext context,
    String title,
    String current,
    Function(String) onConfirm,
  ) {
    final controller = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(title, style: const TextStyle(color: Colors.cyanAccent)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.cyanAccent),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                onConfirm(newName);
              }
              Navigator.pop(context);
            },
            child: const Text(
              'SAVE',
              style: TextStyle(color: Colors.cyanAccent),
            ),
          ),
        ],
      ),
    );
  }

  void _showFeedback(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Colors.redAccent
            : Colors.cyanAccent.withOpacity(0.8),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
