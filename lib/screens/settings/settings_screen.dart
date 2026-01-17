import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/theme_provider.dart';
import '../../providers/voice_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/switch_provider.dart';
import '../../providers/immersive_provider.dart';
import '../../providers/google_home_provider.dart';
import '../../providers/switch_style_provider.dart';
import '../../providers/switch_background_provider.dart';

import '../../providers/sound_settings_provider.dart';
import '../../providers/switch_settings_provider.dart';
import '../../providers/performance_provider.dart';
import '../../core/ui/responsive_layout.dart';
import '../../providers/haptic_provider.dart';
import '../../providers/update_provider.dart';
import '../../providers/display_settings_provider.dart';
import '../../services/performance_monitor_service.dart';
import '../../services/haptic_service.dart';

import '../../providers/ai_settings_provider.dart';
import '../../providers/animation_provider.dart';
import '../../widgets/ai/ai_assistant_dialog.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../services/esp32_code_generator.dart';
import '../../services/file_service.dart';
import '../../services/voice_service.dart';
import '../../services/update_service.dart';

import '../login/login_screen.dart';
import 'help_support_screen.dart';
import '../../widgets/robo/robo_assistant.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(updateProvider.notifier).checkForUpdates();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final theme = Theme.of(context);
    final currentTheme = ref.watch(themeProvider);
    final voiceEnabled = ref.watch(voiceEnabledProvider);

    return Stack(
      children: [
        RepaintBoundary(
          child: ListView(
            padding: EdgeInsets.only(
              bottom: 120,
              top: MediaQuery.of(context).padding.top + 20,
            ),
            physics: const BouncingScrollPhysics(),
            children: [
              // --- UPDATES ---
              const _PremiumSectionHeader(title: 'Updates'),
              _buildUpdateTile(context, ref),

              // --- 1. CORE SYSTEM ---
              const _PremiumSectionHeader(title: 'Core System'),
              _PremiumGroupedContainer(
                children: [
                  _buildPremiumSettingTile(
                    context,
                    title: 'Fullscreen Mode',
                    subtitle: 'Hide status and navigation bars',
                    leading: _buildPremiumIcon(
                      Icons.fullscreen,
                      Colors.blueAccent,
                    ),
                    trailing: _BreathingToggle(
                      value: ref.watch(immersiveModeProvider),
                      onChanged: (value) async {
                        ref
                            .read(immersiveModeProvider.notifier)
                            .setImmersiveMode(value);
                      },
                    ),
                  ),
                  _buildPremiumSettingTile(
                    context,
                    title: 'Animations',
                    subtitle: 'System micro-interactions',
                    leading: _buildPremiumIcon(
                      Icons.animation,
                      Colors.purpleAccent,
                    ),
                    trailing: _BreathingToggle(
                      value: ref
                          .watch(animationSettingsProvider)
                          .animationsEnabled,
                      onChanged: (val) => ref
                          .read(animationSettingsProvider.notifier)
                          .setAnimationsEnabled(val),
                    ),
                  ),
                ],
              ),

              // --- 3. SENSORY & FEEDBACK ---
              const _PremiumSectionHeader(title: 'Sensory & Feedback'),
              _PremiumGroupedContainer(
                children: [
                  _buildPremiumSettingTile(
                    context,
                    title: 'Voice Feedback',
                    subtitle: 'Enable AI voice responses',
                    leading: _buildPremiumIcon(Icons.mic, Colors.redAccent),
                    trailing: _BreathingToggle(
                      value: voiceEnabled,
                      onChanged: (value) async {
                        ref
                            .read(voiceEnabledProvider.notifier)
                            .setVoiceEnabled(value);
                      },
                    ),
                  ),
                  _buildPremiumSettingTile(
                    context,
                    title: 'Master Sound',
                    subtitle: 'Enable all app sounds',
                    leading: _buildPremiumIcon(
                      Icons.volume_up,
                      Colors.pinkAccent,
                    ),
                    trailing: _BreathingToggle(
                      value: ref.watch(soundSettingsProvider).masterSound,
                      onChanged: (val) => ref
                          .read(soundSettingsProvider.notifier)
                          .setMasterSound(val),
                    ),
                    isLast: !ref.watch(soundSettingsProvider).masterSound,
                  ),
                  if (ref.watch(soundSettingsProvider).masterSound) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Master Volume: ${(ref.watch(soundSettingsProvider).masterVolume * 100).toInt()}%',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Slider(
                            value: ref
                                .watch(soundSettingsProvider)
                                .masterVolume,
                            activeColor: theme.colorScheme.primary,
                            inactiveColor: Colors.white.withOpacity(0.1),
                            onChanged: (val) => ref
                                .read(soundSettingsProvider.notifier)
                                .setMasterVolume(val),
                          ),
                        ],
                      ),
                    ),
                    _buildPremiumSettingTile(
                      context,
                      title: 'Switch Sounds',
                      subtitle: 'Click sound when toggling',
                      leading: _buildPremiumIcon(
                        Icons.touch_app,
                        Colors.blueGrey,
                      ),
                      trailing: _BreathingToggle(
                        value: ref.watch(soundSettingsProvider).switchSound,
                        onChanged: (val) => ref
                            .read(soundSettingsProvider.notifier)
                            .setSwitchSound(val),
                      ),
                    ),
                  ],
                  if (voiceEnabled) ...[
                    _buildPremiumSettingTile(
                      context,
                      title: 'Voice Engine',
                      subtitle: ref.watch(voiceEngineProvider) ?? 'Default',
                      leading: _buildPremiumIcon(
                        Icons.record_voice_over,
                        Colors.teal,
                      ),
                      onTap: () async {
                        final service = ref.read(voiceServiceProvider);
                        await service.testSpeak();
                      },
                    ),
                  ],
                  _buildPremiumSettingTile(
                    context,
                    title: 'Haptic Feedback',
                    subtitle: _getHapticName(ref.watch(hapticStyleProvider)),
                    leading: _buildPremiumIcon(Icons.vibration, Colors.blue),
                    onTap: () => _showHapticPicker(context, ref),
                    isLast: true,
                  ),
                ],
              ),

              // --- 3.5. PERFORMANCE ---
              const _PremiumSectionHeader(title: 'Performance'),
              _PremiumGroupedContainer(
                children: [
                  _buildPremiumSettingTile(
                    context,
                    title: 'Performance Mode',
                    subtitle: ref.watch(performanceProvider)
                        ? 'Optimized (Fast, No Blur)'
                        : 'High Quality (Blur, Animations)',
                    leading: _buildPremiumIcon(Icons.speed, Colors.orange),
                    trailing: _BreathingToggle(
                      value: ref.watch(performanceProvider),
                      activeColor: Colors.amberAccent,
                      onChanged: (val) {
                        ref.read(performanceProvider.notifier).toggle(val);
                      },
                    ),
                    isLast: true,
                  ),
                ],
              ),

              // --- 4. APPEARANCE & STYLE ---
              const _PremiumSectionHeader(title: 'Appearance'),
              _PremiumGroupedContainer(
                children: [
                  _buildPremiumSettingTile(
                    context,
                    title: 'Theme',
                    subtitle: _getThemeName(currentTheme),
                    leading: _buildPremiumIcon(
                      Icons.palette,
                      Colors.indigoAccent,
                    ),
                    onTap: () => _showThemePicker(context, ref, currentTheme),
                  ),
                  _buildPremiumSettingTile(
                    context,
                    title: 'Display Size',
                    subtitle: _getDisplaySizeName(
                      ref.watch(displaySettingsProvider).displaySize,
                    ),
                    leading: _buildPremiumIcon(Icons.aspect_ratio, Colors.cyan),
                    onTap: () => _showDisplaySizePicker(context, ref),
                  ),
                  _buildPremiumSettingTile(
                    context,
                    title: 'Font Scale',
                    subtitle:
                        '${((ref.watch(displaySettingsProvider).fontScale * 100).toInt())}%',
                    leading: _buildPremiumIcon(Icons.text_fields, Colors.brown),
                    onTap: () => _showFontSizePicker(context, ref),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(68, 8, 28, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Glow Intensity',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              '${(ref.watch(displaySettingsProvider).glowIntensity * 100).toInt()}%',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Slider(
                          value: ref
                              .watch(displaySettingsProvider)
                              .glowIntensity,
                          activeColor: theme.colorScheme.primary,
                          inactiveColor: Colors.white.withOpacity(0.05),
                          onChanged: (val) => ref
                              .read(displaySettingsProvider.notifier)
                              .setGlowIntensity(val),
                        ),
                        const SizedBox(height: 16),
                        _buildPremiumSettingTile(
                          context,
                          title: 'Neon Animation',
                          subtitle: ref
                              .watch(displaySettingsProvider)
                              .neonAnimationMode
                              .name
                              .toUpperCase(),
                          leading: _buildPremiumIcon(
                            Icons.animation_rounded,
                            Colors.purpleAccent,
                          ),
                          onTap: () => _showNeonModePicker(context, ref),
                        ),
                      ],
                    ),
                  ),
                  _buildPremiumSettingTile(
                    context,
                    title: 'Switch Style',
                    subtitle: _getSwitchStyleName(
                      ref.watch(switchStyleProvider),
                    ),
                    leading: _buildPremiumIcon(
                      Icons.dashboard_customize,
                      Colors.lightGreen,
                    ),
                    onTap: () => _showSwitchStylePicker(context, ref),
                  ),
                  _buildPremiumSettingTile(
                    context,
                    title: 'Tab Background',
                    subtitle: _getSwitchBackgroundName(
                      ref.watch(switchBackgroundProvider),
                    ),
                    leading: _buildPremiumIcon(
                      Icons.wallpaper,
                      Colors.blueGrey,
                    ),
                    onTap: () => _showBackgroundPicker(context, ref),
                  ),
                  _buildPremiumSettingTile(
                    context,
                    title: 'Glass Blur Effects',
                    subtitle: 'Frosted glass visuals',
                    leading: _buildPremiumIcon(
                      Icons.blur_on,
                      Colors.blueAccent,
                    ),
                    trailing: _BreathingToggle(
                      value: ref
                          .watch(switchSettingsProvider)
                          .blurEffectsEnabled,
                      onChanged: (val) => ref
                          .read(switchSettingsProvider.notifier)
                          .setBlurEffects(val),
                    ),
                  ),
                  _buildPremiumSettingTile(
                    context,
                    title: 'Dynamic Blending',
                    subtitle: ref.watch(performanceProvider)
                        ? 'Disabled for Performance'
                        : 'Glass transparency effect',
                    leading: _buildPremiumIcon(
                      Icons.opacity,
                      Colors.deepPurpleAccent,
                    ),
                    trailing: _BreathingToggle(
                      value: ref.watch(switchSettingsProvider).dynamicBlending,
                      onChanged: ref.watch(performanceProvider)
                          ? (val) {} // Do nothing if disabled
                          : (val) => ref
                                .read(switchSettingsProvider.notifier)
                                .setDynamicBlending(val),
                    ),
                    isLast: true,
                  ),
                ],
              ),

              // --- AI ASSISTANT ---
              const _PremiumSectionHeader(title: 'AI Assistant'),
              _PremiumGroupedContainer(
                children: [
                  _buildPremiumSettingTile(
                    context,
                    title: 'Nebula AI Assistant',
                    subtitle: 'Smart voice & text control',
                    leading: _buildPremiumIcon(
                      Icons.auto_awesome,
                      Colors.deepPurpleAccent,
                    ),
                    trailing: _BreathingToggle(
                      value: ref.watch(aiSettingsProvider).assistantEnabled,
                      onChanged: (val) => ref
                          .read(aiSettingsProvider.notifier)
                          .toggleAssistant(val),
                    ),
                  ),
                  _buildPremiumSettingTile(
                    context,
                    title: 'Gemini API Key',
                    subtitle: ref.watch(aiSettingsProvider).apiKey.isEmpty
                        ? 'Not Set (Required)'
                        : '••••••••••••${ref.watch(aiSettingsProvider).apiKey.substring(ref.watch(aiSettingsProvider).apiKey.length - 4)}',
                    leading: _buildPremiumIcon(Icons.vpn_key, Colors.grey),
                    onTap: () => _showApiKeyDialog(context, ref),
                    isLast: true,
                  ),
                ],
              ),

              // --- 5. ADVANCED TOOLS ---
              GestureDetector(
                onDoubleTap: () {
                  debugPrint("NEBULA_DEV: Secret Trigger Activated");
                  HapticService.selection();
                  ref
                      .read(performanceStatsProvider.notifier)
                      .toggleConsole(true);
                },
                child: const _PremiumSectionHeader(title: 'Advanced Tools'),
              ),
              _PremiumGroupedContainer(
                children: [
                  _buildPremiumSettingTile(
                    context,
                    title: 'ESP32 Firmware',
                    subtitle: 'Generate C++ controller code',
                    leading: _buildPremiumIcon(Icons.terminal, Colors.grey),
                    onTap: () => _showEsp32FirmwareDialog(context, ref),
                  ),
                  _buildPremiumSettingTile(
                    context,
                    title: 'Force Sync',
                    subtitle: 'Refresh hardware names',
                    leading: _buildPremiumIcon(Icons.sync, Colors.green),
                    onTap: () async {
                      HapticService.selection();
                      final result = await ref
                          .read(switchDevicesProvider.notifier)
                          .forceRefreshHardwareNames();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(result),
                            backgroundColor: result.contains('Error')
                                ? Colors.redAccent
                                : Colors.green.withOpacity(0.8),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),

              // --- 5. GOOGLE HOME ---
              const _PremiumSectionHeader(title: 'Google Home'),
              _PremiumGroupedContainer(
                children: [
                  _buildPremiumSettingTile(
                    context,
                    title: 'Link Status',
                    subtitle: 'Sync with Google Assistant',
                    leading: _buildPremiumIcon(Icons.home_rounded, Colors.blue),
                    trailing: _BreathingToggle(
                      value:
                          ref.watch(googleHomeLinkedProvider).valueOrNull ??
                          false,
                      onChanged: (val) {
                        final service = ref.read(googleHomeServiceProvider);
                        if (val) {
                          service.linkGoogleHome();
                        } else {
                          service.unlinkGoogleHome();
                        }
                      },
                    ),
                  ),
                  _buildPremiumSettingTile(
                    context,
                    title: 'Force Cloud Sync',
                    subtitle: 'Update Google HomeGraph',
                    leading: _buildPremiumIcon(
                      Icons.cloud_sync,
                      Colors.lightBlue,
                    ),
                    onTap: () async {
                      HapticService.selection();
                      final devices = ref.read(switchDevicesProvider);
                      final service = ref.read(googleHomeServiceProvider);
                      try {
                        await service.syncAllDevices(devices);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Synced to Google HomeGraph'),
                              backgroundColor: Colors.blueAccent,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Sync Failed: $e'),
                              backgroundColor: Colors.redAccent,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
                    isLast: true,
                  ),
                ],
              ),

              // --- 6. SUPPORT & IDENTITY ---
              const _PremiumSectionHeader(title: 'Support & Identity'),
              _PremiumGroupedContainer(
                children: [
                  _buildPremiumSettingTile(
                    context,
                    title: 'Help Center',
                    subtitle: 'FAQ and troubleshooting',
                    leading: _buildPremiumIcon(Icons.help, Colors.blue),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HelpSupportScreen(),
                        ),
                      );
                    },
                  ),
                  _buildPremiumSettingTile(
                    context,
                    title: 'Source Code',
                    subtitle: 'github.com/kiran-embedded',
                    leading: _buildPremiumIcon(Icons.code, Colors.purple),
                    onTap: () {
                      launchUrl(
                        Uri.parse(
                          'https://github.com/kiran-embedded/esp32-smart-light-app',
                        ),
                        mode: LaunchMode.externalApplication,
                      );
                    },
                  ),
                  _buildPremiumSettingTile(
                    context,
                    title: 'Logout',
                    subtitle: 'Sign out from Nebula',
                    leading: _buildPremiumIcon(Icons.logout, Colors.red),
                    onTap: () async {
                      await ref.read(authProvider.notifier).signOut();
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                          (route) => false,
                        );
                      }
                    },
                    isLast: true,
                  ),
                ],
              ),

              const SizedBox(height: 40),
              Center(
                child: ref
                    .watch(currentVersionProvider)
                    .when(
                      data: (version) => Text(
                        "Version $version",
                        style: GoogleFonts.outfit(
                          color: Colors.white.withOpacity(0.2),
                          fontSize: 12.sp,
                        ),
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (e, s) => Text(
                        "Version 1.2.0+17",
                        style: GoogleFonts.outfit(
                          color: Colors.white.withOpacity(0.2),
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  "2026 Kiran Embedded Github",
                  style: GoogleFonts.outfit(
                    color: Colors.white.withOpacity(0.1),
                    fontSize: 10.sp,
                  ),
                ),
              ),
              const SizedBox(height: 120),
            ],
          ),
        ),

        // FLOATING ROBO ASSISTANT
        Positioned(
          bottom: 120, // Above typical FAB/Dock area
          right: 20,
          child: Transform.scale(
            scale: 0.65, // Small and cute
            child: RoboAssistant(
              onActionStarted: () {
                // Trigger AI Dialog as requested
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const AiAssistantDialog(),
                );
              },
            ),
          ),
        ),

        // SCANNER OVERLAY
        if (_isScanning) Positioned.fill(child: _ScannerLineAnimation()),
      ],
    );
  }

  Widget _buildPremiumSettingTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    Widget? leading,
    Widget? trailing,
    VoidCallback? onTap,
    bool isLast = false,
  }) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: theme.colorScheme.primary.withOpacity(0.1),
        highlightColor: theme.colorScheme.primary.withOpacity(0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              if (leading != null) ...[leading, const SizedBox(width: 16)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.95),
                        letterSpacing: 0.3,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.outfit(
                          fontSize: 12.sp,
                          color: Colors.white.withOpacity(0.4),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 12), trailing],
              if (onTap != null && trailing == null)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Colors.white.withOpacity(0.15),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }

  Widget _buildUpdateTile(BuildContext context, WidgetRef ref) {
    final updateState = ref.watch(updateProvider);
    final hasUpdate = updateState.updateInfo?.hasUpdate ?? false;

    return _PremiumGroupedContainer(
      children: [
        _buildPremiumSettingTile(
          context,
          title: 'Software Update',
          subtitle: hasUpdate
              ? 'Version ${updateState.updateInfo!.latestVersion} Available'
              : 'App is up to date',
          trailing: hasUpdate
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    '1',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : Icon(
                  Icons.check_circle,
                  color: Colors.greenAccent.withOpacity(0.5),
                  size: 18,
                ),
          onTap: () => _checkForUpdates(context, ref),
          isLast: true,
        ),
      ],
    );
  }

  void _showHapticPicker(BuildContext context, WidgetRef ref) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Haptic Intensity'),
        actions: HapticStyle.values.map((style) {
          return CupertinoActionSheetAction(
            onPressed: () {
              ref.read(hapticStyleProvider.notifier).setHapticStyle(style);
              HapticService.feedback(style);
              Navigator.pop(context);
            },
            child: Text(_getHapticName(style)),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          isDestructiveAction: true,
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _showThemePicker(
    BuildContext context,
    WidgetRef ref,
    AppThemeMode current,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Theme',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: AppThemeMode.values.length,
                itemBuilder: (context, index) {
                  final mode = AppThemeMode.values[index];
                  final isSelected = mode == current;
                  return ListTile(
                    onTap: () {
                      ref.read(themeProvider.notifier).setTheme(mode);
                      Navigator.pop(context);
                    },
                    title: Text(
                      _getThemeName(mode),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.white.withOpacity(0.8),
                        fontWeight: isSelected ? FontWeight.bold : null,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSwitchStylePicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Switch Style',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: SwitchStyleType.values.length,
                itemBuilder: (context, index) {
                  final style = SwitchStyleType.values[index];
                  return ListTile(
                    onTap: () {
                      ref.read(switchStyleProvider.notifier).setStyle(style);
                      Navigator.pop(context);
                    },
                    title: Text(
                      _getSwitchStyleName(style),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBackgroundPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Tab Background',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: SwitchBackgroundType.values.length,
                itemBuilder: (context, index) {
                  final style = SwitchBackgroundType.values[index];
                  return ListTile(
                    onTap: () {
                      ref
                          .read(switchBackgroundProvider.notifier)
                          .setStyle(style);
                      Navigator.pop(context);
                    },
                    title: Text(
                      _getSwitchBackgroundName(style),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
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
      case AppThemeMode.solarFlare:
        return 'Solar Flare';
      case AppThemeMode.electricTundra:
        return 'Electric Tundra';
      case AppThemeMode.nanoCatalyst:
        return 'Nano Catalyst';
      case AppThemeMode.phantomVelvet:
        return 'Phantom Velvet';
      case AppThemeMode.prismFractal:
        return 'Prism Fractal';
      case AppThemeMode.magmaCore:
        return 'Magma Core';
      case AppThemeMode.cyberBloom:
        return 'Cyber Bloom';
      case AppThemeMode.voidRift:
        return 'Void Rift';
      case AppThemeMode.starlightEcho:
        return 'Starlight Echo';
      case AppThemeMode.aeroStream:
        return 'Aero Stream';
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
      case SwitchStyleType.solarFlare:
        return 'Solar Flare';
      case SwitchStyleType.electricTundra:
        return 'Electric Tundra';
      case SwitchStyleType.nanoCatalyst:
        return 'Nano Catalyst';
      case SwitchStyleType.phantomVelvet:
        return 'Phantom Velvet';
      case SwitchStyleType.prismFractal:
        return 'Prism Fractal';
      case SwitchStyleType.magmaCore:
        return 'Magma Core';
      case SwitchStyleType.cyberBloom:
        return 'Cyber Bloom';
      case SwitchStyleType.voidRift:
        return 'Void Rift';
      case SwitchStyleType.starlightEcho:
        return 'Starlight Echo';
      case SwitchStyleType.aeroStream:
        return 'Aero Stream';
    }
  }

  String _getSwitchBackgroundName(SwitchBackgroundType style) {
    switch (style) {
      case SwitchBackgroundType.defaultBlack:
        return 'Default Black';
      case SwitchBackgroundType.neonBorder:
        return 'Neon Border';
      case SwitchBackgroundType.danceFloor:
        return 'Dance Floor';
      case SwitchBackgroundType.cosmicNebula:
        return 'Cosmic Nebula';
      case SwitchBackgroundType.cyberGrid:
        return 'Cyber Grid';
      case SwitchBackgroundType.liquidPlasma:
        return 'Liquid Plasma';
      case SwitchBackgroundType.digitalRain:
        return 'Digital Matrix';
      case SwitchBackgroundType.retroSynth:
        return 'Retro Vaporwave';
      case SwitchBackgroundType.bokehLights:
        return 'Bokeh Lights';
      case SwitchBackgroundType.auroraBorealis:
        return 'Aurora Borealis';
      case SwitchBackgroundType.circuitBoard:
        return 'Circuit Board';
      case SwitchBackgroundType.fireEmbers:
        return 'Fire Embers';
      case SwitchBackgroundType.deepOcean:
        return 'Deep Ocean';
      case SwitchBackgroundType.glassPrism:
        return 'Glass Prism';
      case SwitchBackgroundType.starField:
        return 'Star Field';
      case SwitchBackgroundType.hexHive:
        return 'Hex Hive';
      case SwitchBackgroundType.neuralNodes:
        return 'Neural Nodes';
      case SwitchBackgroundType.dataStream:
        return 'Data Stream';
      case SwitchBackgroundType.whiteFlash:
        return 'White Flash';
      case SwitchBackgroundType.solarFlare:
        return 'Solar Flare';
      case SwitchBackgroundType.electricTundra:
        return 'Electric Tundra';
      case SwitchBackgroundType.nanoCatalyst:
        return 'Nano Catalyst';
      case SwitchBackgroundType.phantomVelvet:
        return 'Phantom Velvet';
      case SwitchBackgroundType.prismFractal:
        return 'Prism Fractal';
      case SwitchBackgroundType.magmaCore:
        return 'Magma Core';
      case SwitchBackgroundType.cyberBloom:
        return 'Cyber Bloom';
      case SwitchBackgroundType.voidRift:
        return 'Void Rift';
      case SwitchBackgroundType.starlightEcho:
        return 'Starlight Echo';
      case SwitchBackgroundType.aeroStream:
        return 'Aero Stream';
      case SwitchBackgroundType.nebulaDynamic:
        return 'Nebula Space (Premium)';
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

  // BLE Toggle Removed per User Request

  // Unused container removed

  // Unused container removed

  // Unused container removed

  // Unused container removed

  String _getDisplaySizeName(DisplaySize size) {
    switch (size) {
      case DisplaySize.small:
        return 'Small';
      case DisplaySize.medium:
        return 'Medium';
      case DisplaySize.large:
        return 'Large';
    }
  }

  void _showDisplaySizePicker(BuildContext context, WidgetRef ref) {
    final currentSize = ref.watch(displaySettingsProvider).displaySize;
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Display Size'),
        actions: DisplaySize.values.map((size) {
          return CupertinoActionSheetAction(
            onPressed: () {
              ref.read(displaySettingsProvider.notifier).setDisplaySize(size);
              HapticService.selection();
              Navigator.pop(context);
            },
            child: Text(
              _getDisplaySizeName(size),
              style: TextStyle(
                fontWeight: size == currentSize
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          isDestructiveAction: true,
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _showFontSizePicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final displaySettings = ref.watch(displaySettingsProvider);
          final theme = Theme.of(context);

          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.of(context).padding.bottom + 40,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Font Scale',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 30),
                // REAL-TIME PREVIEW CARD
                Container(
                  width: double.maxFinite,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.06),
                      width: 0.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "Aa",
                        style: GoogleFonts.outfit(
                          fontSize: 48 * displaySettings.fontScale,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Nebula Smart Light Control",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 16 * displaySettings.fontScale,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'A',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.4),
                      ),
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: theme.colorScheme.primary,
                          inactiveTrackColor: Colors.white.withOpacity(0.1),
                          thumbColor: Colors.white,
                          overlayColor: theme.colorScheme.primary.withOpacity(
                            0.2,
                          ),
                          trackHeight: 4,
                        ),
                        child: Slider(
                          value: displaySettings.fontScale,
                          min: 0.7,
                          max: 1.3,
                          onChanged: (val) {
                            ref
                                .read(displaySettingsProvider.notifier)
                                .setFontScale(val);
                            HapticService.selection();
                          },
                        ),
                      ),
                    ),
                    Text(
                      'A',
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  "${(displaySettings.fontScale * 100).toInt()}% Scale",
                  style: GoogleFonts.outfit(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showApiKeyDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(
      text: ref.read(aiSettingsProvider).apiKey,
    );
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Gemini API Key'),
        content: Column(
          children: [
            const SizedBox(height: 12),
            const Text(
              'Enter your free Gemini API key from Google AI Studio to enable the assistant.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: controller,
              placeholder: 'Paste API Key here',
              style: const TextStyle(color: Colors.white),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              ref
                  .read(aiSettingsProvider.notifier)
                  .setApiKey(controller.text.trim());
              Navigator.pop(context);
              HapticService.heavy();
            },
            isDefaultAction: true,
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // Unused method removed

  Future<void> _checkForUpdates(BuildContext context, WidgetRef ref) async {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CupertinoActivityIndicator()),
    );

    final updateInfo = await ref.read(updateServiceProvider).checkUpdate();

    if (context.mounted) Navigator.pop(context);

    if (!context.mounted) return;

    if (updateInfo.hasUpdate) {
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Update Available'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Text('Version: ${updateInfo.latestVersion}'),
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
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Later'),
            ),
            CupertinoDialogAction(
              onPressed: () {
                Navigator.pop(ctx);
                ref
                    .read(updateServiceProvider)
                    .launchUpdateUrl(updateInfo.downloadUrl);
              },
              isDefaultAction: true,
              child: const Text('Update Now'),
            ),
          ],
        ),
      );
    } else {
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Up to Date'),
          content: const Text('You are on the latest version of Nebula.'),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _showNeonModePicker(BuildContext context, WidgetRef ref) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('Neon Animation Mode'),
        message: const Text('Choose your preferred neon border effect'),
        actions: NeonAnimationMode.values.map((mode) {
          return CupertinoActionSheetAction(
            onPressed: () {
              ref
                  .read(displaySettingsProvider.notifier)
                  .setNeonAnimationMode(mode);
              Navigator.pop(context);
            },
            child: Text(mode.name.toUpperCase()),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }
}

class _PremiumSectionHeader extends StatelessWidget {
  final String title;
  const _PremiumSectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title.toUpperCase(),
            style: GoogleFonts.outfit(
              fontSize: 12.sp,
              fontWeight: FontWeight.w900,
              color: Colors.white.withOpacity(0.5),
              letterSpacing: 2.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumGroupedContainer extends ConsumerWidget {
  final List<Widget> children;

  const _PremiumGroupedContainer({required this.children});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final glowIntensity = ref.watch(displaySettingsProvider).glowIntensity;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.1 * glowIntensity),
            blurRadius: 30 * glowIntensity,
            spreadRadius: -10,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(children: children),
      ),
    );
  }
}

class _BreathingToggle extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? activeColor;

  const _BreathingToggle({
    required this.value,
    required this.onChanged,
    this.activeColor,
  });

  @override
  _BreathingToggleState createState() => _BreathingToggleState();
}

class _BreathingToggleState extends State<_BreathingToggle>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.value) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_BreathingToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.value && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = widget.activeColor ?? theme.colorScheme.primary;

    return GestureDetector(
      onTap: () {
        HapticService.selection();
        widget.onChanged(!widget.value);
      },
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.all(4),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (widget.value)
                  Container(
                    width: 44,
                    height: 24,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: activeColor.withOpacity(
                            0.3 * (_pulseAnimation.value - 0.5),
                          ),
                          blurRadius: 10 * _pulseAnimation.value,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                CupertinoSwitch(
                  value: widget.value,
                  activeColor: activeColor,
                  onChanged: (val) {
                    HapticService.selection();
                    widget.onChanged(val);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ScannerLineAnimation extends StatefulWidget {
  @override
  State<_ScannerLineAnimation> createState() => _ScannerLineAnimationState();
}

class _ScannerLineAnimationState extends State<_ScannerLineAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: [
            Positioned(
              top: _controller.value * MediaQuery.of(context).size.height,
              left: 0,
              right: 0,
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      theme.colorScheme.primary,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
