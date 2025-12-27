import 'package:flutter/material.dart';
import '../../widgets/common/frosted_glass.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/theme_provider.dart';
import '../../providers/voice_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/google_home_provider.dart';
import '../../providers/haptic_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../services/esp32_code_generator.dart';
import '../../services/file_service.dart';
import '../../providers/switch_provider.dart';
import '../../core/constants/app_constants.dart';
import '../login/login_screen.dart';
import '../../services/haptic_service.dart';
import '../../services/voice_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentTheme = ref.watch(themeProvider);
    final voiceEnabled = ref.watch(voiceEnabledProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        20,
        20,
        20,
        100,
      ), // Added bottom padding for dock
      physics: const BouncingScrollPhysics(),
      children: [
        const SizedBox(height: 10),
        Text(
          'Settings',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 30),
        // Voice Toggle
        _buildSettingTile(
          context,
          title: 'Voice Feedback',
          subtitle: 'Enable AI voice responses',
          trailing: Switch(
            value: voiceEnabled,
            onChanged: (value) {
              ref.read(voiceEnabledProvider.notifier).setVoiceEnabled(value);
            },
          ),
        ),
        // Pitch & Rate Sliders
        if (voiceEnabled) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  'Voice Pitch: ${ref.watch(voicePitchProvider).toStringAsFixed(1)}',
                  style: theme.textTheme.bodyMedium,
                ),
                Slider(
                  value: ref.watch(voicePitchProvider),
                  min: 0.5,
                  max: 2.0,
                  divisions: 15,
                  label: ref.watch(voicePitchProvider).toStringAsFixed(1),
                  onChanged: (val) {
                    ref.read(voicePitchProvider.notifier).setPitch(val);
                    ref.read(voiceServiceProvider).setPitch(val);
                  },
                ),
                Text(
                  'Voice Speed: ${ref.watch(voiceRateProvider).toStringAsFixed(1)}',
                  style: theme.textTheme.bodyMedium,
                ),
                Slider(
                  value: ref.watch(voiceRateProvider),
                  min: 0.0,
                  max: 1.0,
                  divisions: 10,
                  label: ref.watch(voiceRateProvider).toStringAsFixed(1),
                  onChanged: (val) {
                    ref.read(voiceRateProvider.notifier).setRate(val);
                    ref.read(voiceServiceProvider).setRate(val);
                  },
                ),
                const SizedBox(height: 16),
                FutureBuilder<List<String>>(
                  future: ref.read(voiceServiceProvider).getEngines(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }

                    if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Voice Engine',
                              style: theme.textTheme.titleSmall,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceVariant
                                    .withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: DropdownButton<String>(
                                value:
                                    ref.watch(voiceEngineProvider) ??
                                    (snapshot.data!.contains(
                                          "com.google.android.tts",
                                        )
                                        ? "com.google.android.tts"
                                        : snapshot.data!.first),
                                isExpanded: true,
                                underline: const SizedBox(),
                                dropdownColor: theme.colorScheme.surface,
                                items: snapshot.data!
                                    .map(
                                      (e) => DropdownMenuItem(
                                        value: e,
                                        child: Text(
                                          e,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    ref
                                        .read(voiceEngineProvider.notifier)
                                        .setEngine(val);
                                    ref
                                        .read(voiceServiceProvider)
                                        .setEngine(val);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.record_voice_over),
                  label: const Text("Test Voice & Diagnose"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    foregroundColor: theme.colorScheme.onPrimaryContainer,
                  ),
                  onPressed: () async {
                    final service = ref.read(voiceServiceProvider);
                    final result = await service.testSpeak();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(result),
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
        const Divider(),
        // Haptic Feedback
        _buildSettingTile(
          context,
          title: 'Haptic Feedback',
          subtitle: _getHapticName(ref.watch(hapticStyleProvider)),
          trailing: PopupMenuButton<HapticStyle>(
            icon: const Icon(Icons.vibration),
            onSelected: (style) {
              ref.read(hapticStyleProvider.notifier).setHapticStyle(style);
              HapticService.feedback(style); // Preview
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: HapticStyle.light,
                child: Text('Butter (Light)'),
              ),
              const PopupMenuItem(
                value: HapticStyle.medium,
                child: Text('Smooth (Medium)'),
              ),
              const PopupMenuItem(
                value: HapticStyle.heavy,
                child: Text('Pulse (Heavy)'),
              ),
            ],
          ),
        ),
        const Divider(),
        // Theme Selector
        _buildSettingTile(
          context,
          title: 'Theme',
          subtitle: _getThemeName(currentTheme),
          trailing: PopupMenuButton<AppThemeMode>(
            icon: const Icon(Icons.palette),
            onSelected: (mode) {
              ref.read(themeProvider.notifier).setTheme(mode);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: AppThemeMode.darkNeon,
                child: Text('Dark Neon'),
              ),
              const PopupMenuItem(
                value: AppThemeMode.softDark,
                child: Text('Soft Dark'),
              ),
              const PopupMenuItem(
                value: AppThemeMode.light,
                child: Text('Light'),
              ),
              const PopupMenuItem(
                value: AppThemeMode.cyberNeon,
                child: Text('Cyber Neon'),
              ),
              const PopupMenuItem(
                value: AppThemeMode.liquidGlass,
                child: Text('Liquid Glass'),
              ),
              const PopupMenuItem(
                value: AppThemeMode.raindrop,
                child: Text('Raindrop'),
              ),
              const PopupMenuItem(
                value: AppThemeMode.amoledCyberpunk,
                child: Text('AMOLED Cyberpunk'),
              ),
              const PopupMenuItem(
                value: AppThemeMode.darkSpace,
                child: Text('Dark Space (Dashboard)'),
              ),
            ],
          ),
        ),
        const Divider(),
        // ESP32 Firmware
        _buildSettingTile(
          context,
          title: 'ESP32 Full Firmware',
          subtitle: 'Generate complete firmware code',
          trailing: const Icon(Icons.code),
          onTap: () {
            _showEsp32FirmwareDialog(context, ref);
          },
        ),
        const Divider(),
        // Google Unlink
        _buildSettingTile(
          context,
          title: 'Unlink Google Home',
          subtitle: 'Disconnect from Google services',
          trailing: const Icon(Icons.link_off),
          onTap: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Unlink Google Home'),
                content: const Text(
                  'Are you sure you want to unlink from Google Home? This will disconnect all Google services and clear cloud data.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                    child: const Text('Unlink'),
                  ),
                ],
              ),
            );
            if (confirmed == true && context.mounted) {
              try {
                final service = ref.read(googleHomeServiceProvider);
                await service.unlinkGoogleHome();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Google Home unlinked successfully'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            }
          },
        ),
        const Divider(),
        // Logout
        _buildSettingTile(
          context,
          title: 'Logout',
          subtitle: 'Sign out from your account',
          trailing: const Icon(Icons.logout),
          onTap: () async {
            await ref.read(authProvider.notifier).signOut();
            if (context.mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: FrostedGlass(
        opacity: 0.1,
        blur: 25,
        radius: BorderRadius.circular(20),
        child: ListTile(
          title: Text(title, style: theme.textTheme.titleMedium),
          subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
          trailing: trailing,
          onTap: onTap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  String _getThemeName(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.darkNeon:
        return 'Dark Neon';
      case AppThemeMode.softDark:
        return 'Soft Dark';
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.cyberNeon:
        return 'Cyber Neon';
      case AppThemeMode.liquidGlass:
        return 'Liquid Glass';
      case AppThemeMode.raindrop:
        return 'Raindrop';
      case AppThemeMode.amoledCyberpunk:
        return 'AMOLED Cyberpunk';
      case AppThemeMode.darkSpace:
        return 'Dark Space (Active)';
    }
  }

  String _getHapticName(HapticStyle style) {
    switch (style) {
      case HapticStyle.light:
        return 'Butter';
      case HapticStyle.medium:
        return 'Smooth';
      case HapticStyle.heavy:
        return 'Pulse';
    }
  }

  void _showEsp32FirmwareDialog(BuildContext context, WidgetRef ref) {
    final devices = ref.read(switchDevicesProvider);
    final code = Esp32CodeGenerator.generateFirebaseFirmware(
      devices: devices,
      wifiSsid: AppConstants.defaultWifiSsid,
      wifiPassword: AppConstants.defaultWifiPassword,
      firebaseApiKey: 'YOUR_FIREBASE_API_KEY',
      firebaseDatabaseUrl: 'YOUR_FIREBASE_DATABASE_URL',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ESP32 Firmware'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(
              code,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final fileService = FileService();
              await fileService.copyToClipboard(code);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Code copied to clipboard'),
                    duration: Duration(seconds: 2),
                  ),
                );
                Navigator.of(context).pop();
              }
            },
            child: const Text('Copy'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final fileService = FileService();
                final fileName = 'nebula_core_firmware.ino';
                final path = await fileService.saveEsp32Code(code, fileName);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('File saved to: $path'),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                  Navigator.of(context).pop();
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error saving file: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Download'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
