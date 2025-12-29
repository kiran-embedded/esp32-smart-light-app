import 'package:flutter/material.dart';
import '../../widgets/common/frosted_glass.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
import '../../providers/immersive_provider.dart';

import '../../providers/switch_style_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/animation_provider.dart';
import '../../services/update_service.dart';
import '../../providers/sound_settings_provider.dart'; // Added
import 'package:package_info_plus/package_info_plus.dart'; // Added

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with AutomaticKeepAliveClientMixin {
  List<String> _voiceEngines = [];
  bool _isLoadingEngines = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadVoiceEngines();
  }

  Future<void> _loadVoiceEngines() async {
    final service = ref.read(voiceServiceProvider);
    final engines = await service.getEngines();
    if (mounted) {
      setState(() {
        _voiceEngines = engines;
        _isLoadingEngines = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final theme = Theme.of(context);
    final currentTheme = ref.watch(themeProvider);
    final voiceEnabled = ref.watch(voiceEnabledProvider);

    return ListView(
      padding: const EdgeInsets.only(
        bottom: 120,
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
        // Fullscreen Mode
        _buildSettingTile(
              context,
              title: 'Fullscreen Mode',
              subtitle: 'Hide status and navigation bars',
              trailing: Switch(
                value: ref.watch(immersiveModeProvider),
                onChanged: (value) async {
                  ref
                      .read(immersiveModeProvider.notifier)
                      .setImmersiveMode(value);
                },
              ),
            )
            .animate()
            .fadeIn(duration: 400.ms, delay: 100.ms)
            .slideX(begin: -0.1, end: 0, curve: Curves.easeOutCubic),
        const Divider(),
        // Animation Engine
        _buildSectionHeader(context, 'Animation Engine'),
        _buildAnimationSettings(context, ref),
        const Divider(),
        // Voice Toggle
        _buildSectionHeader(context, 'Voice & Sound'),
        _buildSettingTile(
          context,
          title: 'Voice Feedback',
          subtitle: 'Enable AI voice responses',
          trailing: Switch(
            value: voiceEnabled,
            onChanged: (value) async {
              ref.read(voiceEnabledProvider.notifier).setVoiceEnabled(value);
            },
          ),
        ),

        // Sound Settings
        _buildSettingTile(
          context,
          title: 'Master Sound',
          subtitle: 'Enable all app sounds',
          trailing: Switch(
            value: ref.watch(soundSettingsProvider).masterSound,
            onChanged: (val) =>
                ref.read(soundSettingsProvider.notifier).setMasterSound(val),
          ),
        ),

        if (ref.watch(soundSettingsProvider).masterSound) ...[
          // Master Volume Slider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Master Volume: ${(ref.watch(soundSettingsProvider).masterVolume * 100).toInt()}%',
                  style: theme.textTheme.bodyMedium,
                ),
                Slider(
                  value: ref.watch(soundSettingsProvider).masterVolume,
                  onChanged: (val) => ref
                      .read(soundSettingsProvider.notifier)
                      .setMasterVolume(val),
                ),
              ],
            ),
          ),

          const Divider(),

          // Switch Sound Settings
          _buildSettingTile(
            context,
            title: 'Switch Sounds',
            subtitle: 'Click sound when toggling',
            trailing: Switch(
              value: ref.watch(soundSettingsProvider).switchSound,
              onChanged: (val) =>
                  ref.read(soundSettingsProvider.notifier).setSwitchSound(val),
            ),
          ),
          if (ref.watch(soundSettingsProvider).switchSound)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Switch Volume: ${(ref.watch(soundSettingsProvider).switchVolume * 100).toInt()}%',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                  Slider(
                    value: ref.watch(soundSettingsProvider).switchVolume,
                    onChanged: (val) => ref
                        .read(soundSettingsProvider.notifier)
                        .setSwitchVolume(val),
                  ),
                ],
              ),
            ),

          // App Opening Sound Settings
          _buildSettingTile(
            context,
            title: 'Startup Sound',
            subtitle: 'Play sound on app launch',
            trailing: Switch(
              value: ref.watch(soundSettingsProvider).appOpeningSound,
              onChanged: (val) => ref
                  .read(soundSettingsProvider.notifier)
                  .setAppOpeningSound(val),
            ),
          ),
          if (ref.watch(soundSettingsProvider).appOpeningSound)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Startup Volume: ${(ref.watch(soundSettingsProvider).appOpeningVolume * 100).toInt()}%',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                  Slider(
                    value: ref.watch(soundSettingsProvider).appOpeningVolume,
                    onChanged: (val) => ref
                        .read(soundSettingsProvider.notifier)
                        .setAppOpeningVolume(val),
                  ),
                ],
              ),
            ),
        ],

        // Voice Pitch & Rate Sliders
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
                if (_isLoadingEngines)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else if (_voiceEngines.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Voice Engine', style: theme.textTheme.titleSmall),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceVariant.withOpacity(
                              0.3,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: DropdownButton<String>(
                            value:
                                ref.watch(voiceEngineProvider) ??
                                (_voiceEngines.contains(
                                      "com.google.android.tts",
                                    )
                                    ? "com.google.android.tts"
                                    : _voiceEngines.first),
                            isExpanded: true,
                            underline: const SizedBox(),
                            dropdownColor: theme.colorScheme.surface,
                            items: _voiceEngines
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
                                ref.read(voiceServiceProvider).setEngine(val);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
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
        // Switch Style Selector
        _buildSettingTile(
          context,
          title: 'Switch Style',
          subtitle: _getSwitchStyleName(ref.watch(switchStyleProvider)),
          trailing: PopupMenuButton<SwitchStyleType>(
            icon: const Icon(Icons.style),
            onSelected: (style) {
              ref.read(switchStyleProvider.notifier).setStyle(style);
            },
            itemBuilder: (context) => SwitchStyleType.values.map((style) {
              return PopupMenuItem(
                value: style,
                child: Text(_getSwitchStyleName(style)),
              );
            }).toList(),
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
            itemBuilder: (context) => AppThemeMode.values.map((mode) {
              return PopupMenuItem(
                value: mode,
                child: Text(_getThemeName(mode)),
              );
            }).toList(),
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
        const SizedBox(height: 20),
        const Divider(),
        // App Info
        // App Info
        FutureBuilder<PackageInfo>(
          future: PackageInfo.fromPlatform(),
          builder: (context, snapshot) {
            final version = snapshot.hasData
                ? '${snapshot.data!.version}+${snapshot.data!.buildNumber}'
                : 'Loading...';
            return _buildSettingTile(
              context,
              title: 'Version',
              subtitle: version,
              trailing: const Icon(Icons.system_update),
              onTap: () => _checkForUpdates(context, ref),
            );
          },
        ),
        // GitHub
        _buildSettingTile(
          context,
          title: 'View Source Code',
          subtitle: 'github.com/kiran-embedded',
          trailing: const Icon(Icons.code),
          onTap: () {
            launchUrl(
              Uri.parse(
                'https://github.com/kiran-embedded/esp32-smart-light-app',
              ),
              mode: LaunchMode.externalApplication,
            );
          },
        ),
        const SizedBox(height: 20),
        const SizedBox(height: 20),
        const Center(
          child: Padding(
            padding: EdgeInsets.only(bottom: 20.0),
            child: Text(
              "2025 Kiran Embedded Github",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
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
      child: RepaintBoundary(
        child: FrostedGlass(
          opacity: 0.1,
          blur: 15,
          disableBlur: true, // Boosts list scrolling performance drastically
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
        return 'Dark Space';
      // New Themes
      case AppThemeMode.kaliLinux:
        return 'Kali Linux';
      case AppThemeMode.nothingDot:
        return 'Nothing';
      case AppThemeMode.appleGlass:
        return 'Apple Glass';
      case AppThemeMode.crimsonVampire:
        return 'Crimson Vampire';
      case AppThemeMode.neonTokyo:
        return 'Neon Tokyo';
      case AppThemeMode.sunsetRetro:
        return 'Sunset Retro';
      case AppThemeMode.mindfulNature:
        return 'Mindful Nature';
      case AppThemeMode.deepOcean:
        return 'Deep Ocean';
      case AppThemeMode.dracula:
        return 'Dracula';
      case AppThemeMode.monokai:
        return 'Monokai';
      case AppThemeMode.synthwave:
        return 'Synthwave';
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

  String _getSwitchStyleName(SwitchStyleType style) {
    switch (style) {
      case SwitchStyleType.modern:
        return 'Modern';
      case SwitchStyleType.fluid:
        return 'Fluid Animation';
      case SwitchStyleType.realistic:
        return 'Realistic';
      case SwitchStyleType.different:
        return 'Cyberpunk';
      case SwitchStyleType.smooth:
        return 'Smooth (Neumorphic)';
      case SwitchStyleType.neonGlass:
        return 'Neon Glass (Premium)';
      case SwitchStyleType.industrialMetallic:
        return 'Industrial (Metal)';
      case SwitchStyleType.gamingRGB:
        return 'Gaming RGB (Animated)';
      case SwitchStyleType.holographic:
        return 'Holographic (Pro)';
      case SwitchStyleType.liquidMetal:
        return 'Liquid Metal';
      case SwitchStyleType.quantumDot:
        return 'Quantum Dot';
      case SwitchStyleType.cosmicPulse:
        return 'Cosmic Pulse (Galaxy)';
      case SwitchStyleType.retroVapor:
        return 'Retro Vapor (80s)';
      case SwitchStyleType.bioOrganic:
        return 'Bio Organic (Living)';
      case SwitchStyleType.crystalPrism:
        return 'Crystal Prism (Glass)';
      case SwitchStyleType.voidAbyss:
        return 'Void Abyss (Deep)';
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

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: theme.colorScheme.primary.withOpacity(0.8),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildAnimationSettings(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(animationSettingsProvider);
    final notifier = ref.read(animationSettingsProvider.notifier);

    return Column(
      children: [
        // Launch animation is now fixed to standard iOS style
        _buildDropdownTile<UiTransitionAnimation>(
          context,
          title: 'UI Visuals',
          subtitle: 'Navigation & touch feel',
          value: settings.uiType,
          items: UiTransitionAnimation.values,
          onChanged: (val) {
            notifier.setUiAnimation(val!);
            HapticService.selection();
          },
        ),
      ],
    );
  }

  Widget _buildDropdownTile<T>(
    BuildContext context, {
    required String title,
    required String subtitle,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    final theme = Theme.of(context);
    return _buildSettingTile(
      context,
      title: title,
      subtitle: subtitle,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            dropdownColor: const Color(0xFF1E1E1E),
            isDense: true,
            icon: Icon(
              Icons.arrow_drop_down_rounded,
              color: theme.colorScheme.primary,
            ),
            items: items.map((item) {
              return DropdownMenuItem<T>(
                value: item,
                child: Text(
                  item
                      .toString()
                      .split('.')
                      .last
                      .replaceAllMapped(
                        RegExp(r'([A-Z])'),
                        (Match m) => ' ${m[1]}',
                      )
                      .trim(), // "iPhoneBlend" -> "iPhone Blend"
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  Future<void> _checkForUpdates(BuildContext context, WidgetRef ref) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    final updateInfo = await ref.read(updateServiceProvider).checkUpdate();

    if (context.mounted) Navigator.pop(context);

    if (!context.mounted) return;

    if (updateInfo.hasUpdate) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Update Available'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('New Version: ${updateInfo.latestVersion}'),
              const SizedBox(height: 10),
              Text(
                updateInfo.releaseNotes.isEmpty
                    ? 'General bug fixes and improvements.'
                    : updateInfo.releaseNotes,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                ref
                    .read(updateServiceProvider)
                    .launchUpdateUrl(updateInfo.downloadUrl);
              },
              child: const Text('Update Now'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are on the latest version.')),
      );
    }
  }
}
