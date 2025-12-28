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
import '../../core/ui/ui_composition_engine.dart';
import '../../providers/switch_style_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/animation_provider.dart';
import '../../services/update_service.dart';

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
        _buildSettingTile(
              context,
              title: 'Voice Feedback',
              subtitle: 'Enable AI voice responses',
              trailing: Switch(
                value: voiceEnabled,
                onChanged: (value) async {
                  ref
                      .read(voiceEnabledProvider.notifier)
                      .setVoiceEnabled(value);
                },
              ),
            )
            .animate()
            .fadeIn(duration: 400.ms, delay: 150.ms)
            .slideX(begin: -0.1, end: 0, curve: Curves.easeOutCubic),
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
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: SwitchStyleType.modern,
                child: Text('Modern (Minimal)'),
              ),
              const PopupMenuItem(
                value: SwitchStyleType.fluid,
                child: Text('Fluid (Liquid Anim)'),
              ),
              const PopupMenuItem(
                value: SwitchStyleType.realistic,
                child: Text('Realistic (Physical)'),
              ),
              const PopupMenuItem(
                value: SwitchStyleType.different,
                child: Text('Cyberpunk (Glitch)'),
              ),
              const PopupMenuItem(
                value: SwitchStyleType.smooth,
                child: Text('Smooth (Neumorphic)'),
              ),
              const PopupMenuItem(
                value: SwitchStyleType.neonGlass,
                child: Text('Neon Glass (Premium)'),
              ),
              const PopupMenuItem(
                value: SwitchStyleType.industrialMetallic,
                child: Text('Industrial (Metal)'),
              ),
              const PopupMenuItem(
                value: SwitchStyleType.gamingRGB,
                child: Text('Gaming RGB (Animated)'),
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
              const PopupMenuItem(
                value: AppThemeMode.kaliLinux,
                child: Text('Kali Linux'),
              ),
              const PopupMenuItem(
                value: AppThemeMode.nothingDot,
                child: Text('Nothing'),
              ),
              const PopupMenuItem(
                value: AppThemeMode.appleGlass,
                child: Text('Apple Glass'),
              ),
              const PopupMenuItem(
                value: AppThemeMode.crimsonVampire,
                child: Text('Crimson Vampire'),
              ),
              const PopupMenuItem(
                value: AppThemeMode.neonTokyo,
                child: Text('Neon Tokyo'),
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
        const SizedBox(height: 20),
        const Divider(),
        // App Info
        _buildSettingTile(
          context,
          title: 'Version',
          subtitle: '1.1.0+4', // TODO: Get from package_info
          trailing: const Icon(Icons.system_update),
          onTap: () => _checkForUpdates(context, ref),
        ),
        _buildSettingTile(
          context,
          title: 'GitHub Repository',
          subtitle: 'View source code & releases',
          trailing: const Icon(Icons.open_in_new),
          onTap: () async {
            final uri = Uri.parse(
              'https://github.com/kirancybergrid/nebula_core_restore/releases/latest',
            );
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
        ),
        const SizedBox(height: 20),
        const CopyrightFooter(),
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
