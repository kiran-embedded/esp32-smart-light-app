import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui'; // Added for ImageFilter
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart'; // Added for animations

import '../../providers/theme_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/voice_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/switch_provider.dart';
import '../../providers/immersive_provider.dart';
import '../../providers/google_home_provider.dart';
import '../../providers/switch_style_provider.dart';
import '../../providers/switch_background_provider.dart';

import '../../providers/sound_settings_provider.dart';
import '../../services/sound_service.dart';
import '../../providers/switch_settings_provider.dart';
import '../../providers/performance_provider.dart';
import '../../core/ui/responsive_layout.dart';
import '../../providers/haptic_provider.dart';
import '../../providers/update_provider.dart';
import '../../providers/display_settings_provider.dart';
import '../../providers/background_service_provider.dart';
import '../../services/performance_monitor_service.dart';
import '../../services/haptic_service.dart';

import '../../providers/animation_provider.dart';

import '../../core/constants/app_constants.dart';
import '../../services/esp32_code_generator.dart';
import '../../services/file_service.dart';
import '../../services/voice_service.dart';
import '../../services/update_service.dart';

import '../login/login_screen.dart';
import 'help_support_screen.dart';
import '../../widgets/robo/robo_assistant.dart';
import '../../widgets/ai/ai_assistant_dialog.dart';
import '../../widgets/settings/sprinkling_watermark.dart';
import 'developer_monitor_screen.dart';

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

  Future<void> _pickCustomAlarm(BuildContext context, WidgetRef ref) async {
    try {
      HapticService.selection();
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'm4a'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);

        // Copy to local app storage to ensure persistence
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = result.files.single.name;
        final savedFile = await file.copy('${appDir.path}/$fileName');

        // Update settings
        await ref
            .read(soundSettingsProvider.notifier)
            .setCustomAlarmPath(savedFile.path);

        // Load into SoundService
        await ref.read(soundServiceProvider).loadCustomAlarm(savedFile.path);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Custom alarm sound set: $fileName'),
              backgroundColor: Colors.greenAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking file: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final theme = Theme.of(context);

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
              _animatedSection(
                index: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _PremiumSectionHeader(title: 'Updates'),
                    _buildUpdateTile(context, ref),
                  ],
                ),
              ),

              // --- 1. CORE SYSTEM ---
              _animatedSection(
                index: 1,
                child: RepaintBoundary(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _PremiumSectionHeader(title: 'Core System'),
                      _PremiumGroupedContainer(
                        children: [
                          Consumer(
                            builder: (context, ref, _) =>
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
                          ),
                          Consumer(
                            builder: (context, ref, _) =>
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
                                        .read(
                                          animationSettingsProvider.notifier,
                                        )
                                        .setAnimationsEnabled(val),
                                  ),
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // --- 3. SENSORY & FEEDBACK ---
              _animatedSection(
                index: 2,
                child: RepaintBoundary(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _PremiumSectionHeader(title: 'Sensory & Feedback'),
                      _PremiumGroupedContainer(
                        children: [
                          Consumer(
                            builder: (context, ref, _) {
                              final voiceEnabled = ref.watch(
                                voiceEnabledProvider,
                              );
                              return _buildPremiumSettingTile(
                                context,
                                title: 'Voice Feedback',
                                subtitle: 'Enable AI voice responses',
                                leading: _buildPremiumIcon(
                                  Icons.mic,
                                  Colors.redAccent,
                                ),
                                trailing: _BreathingToggle(
                                  value: voiceEnabled,
                                  onChanged: (value) async {
                                    ref
                                        .read(voiceEnabledProvider.notifier)
                                        .setVoiceEnabled(value);
                                  },
                                ),
                              );
                            },
                          ),
                          Consumer(
                            builder: (context, ref, _) {
                              final masterSound = ref
                                  .watch(soundSettingsProvider)
                                  .masterSound;
                              return Column(
                                children: [
                                  _buildPremiumSettingTile(
                                    context,
                                    title: 'Master Sound',
                                    subtitle: 'Enable all app sounds',
                                    leading: _buildPremiumIcon(
                                      Icons.volume_up,
                                      Colors.pinkAccent,
                                    ),
                                    trailing: _BreathingToggle(
                                      value: masterSound,
                                      onChanged: (val) => ref
                                          .read(soundSettingsProvider.notifier)
                                          .setMasterSound(val),
                                    ),
                                    isLast: !masterSound,
                                  ),
                                  if (masterSound) ...[
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        20,
                                        10,
                                        20,
                                        10,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Master Volume: ${(ref.watch(soundSettingsProvider).masterVolume * 100).toInt()}%',
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  color: Colors.white
                                                      .withOpacity(0.7),
                                                  fontSize: 13,
                                                ),
                                          ),
                                          const SizedBox(height: 8),
                                          Slider(
                                            value: ref
                                                .watch(soundSettingsProvider)
                                                .masterVolume,
                                            activeColor:
                                                theme.colorScheme.primary,
                                            inactiveColor: Colors.white
                                                .withOpacity(0.1),
                                            onChanged: (val) => ref
                                                .read(
                                                  soundSettingsProvider
                                                      .notifier,
                                                )
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
                                        value: ref
                                            .watch(soundSettingsProvider)
                                            .switchSound,
                                        onChanged: (val) => ref
                                            .read(
                                              soundSettingsProvider.notifier,
                                            )
                                            .setSwitchSound(val),
                                      ),
                                    ),
                                    _buildPremiumSettingTile(
                                      context,
                                      title: 'Custom Alarm Sound',
                                      subtitle:
                                          ref
                                                  .watch(soundSettingsProvider)
                                                  .customAlarmPath !=
                                              null
                                          ? 'Selected: ${ref.watch(soundSettingsProvider).customAlarmPath!.split('/').last}'
                                          : 'Use default siren',
                                      leading: _buildPremiumIcon(
                                        Icons.music_note,
                                        Colors.amberAccent,
                                      ),
                                      onTap: () =>
                                          _pickCustomAlarm(context, ref),
                                      trailing:
                                          ref
                                                  .watch(soundSettingsProvider)
                                                  .customAlarmPath !=
                                              null
                                          ? IconButton(
                                              icon: const Icon(
                                                Icons.close,
                                                color: Colors.redAccent,
                                                size: 18,
                                              ),
                                              onPressed: () => ref
                                                  .read(
                                                    soundSettingsProvider
                                                        .notifier,
                                                  )
                                                  .setCustomAlarmPath(null),
                                            )
                                          : null,
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),
                          Consumer(
                            builder: (context, ref, _) {
                              final voiceEnabled = ref.watch(
                                voiceEnabledProvider,
                              );
                              if (!voiceEnabled) return const SizedBox.shrink();
                              return _buildPremiumSettingTile(
                                context,
                                title: 'Voice Engine',
                                subtitle:
                                    ref.watch(voiceEngineProvider) ?? 'Default',
                                leading: _buildPremiumIcon(
                                  Icons.record_voice_over,
                                  Colors.teal,
                                ),
                                onTap: () async {
                                  final service = ref.read(
                                    voiceServiceProvider,
                                  );
                                  await service.testSpeak();
                                },
                              );
                            },
                          ),
                          Consumer(
                            builder: (context, ref, _) =>
                                _buildPremiumSettingTile(
                                  context,
                                  title: 'Haptic Feedback',
                                  subtitle: _getHapticName(
                                    ref.watch(hapticStyleProvider),
                                  ),
                                  leading: _buildPremiumIcon(
                                    Icons.vibration,
                                    Colors.blue,
                                  ),
                                  onTap: () => _showHapticPicker(context, ref),
                                  isLast: true,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // --- 3.5. PERFORMANCE ---
              _animatedSection(
                index: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _PremiumSectionHeader(title: 'Performance'),
                    _PremiumGroupedContainer(
                      children: [
                        _buildPremiumSettingTile(
                          context,
                          title: 'Performance Mode',
                          subtitle: ref.watch(performanceProvider)
                              ? 'Optimized (Fast, No Blur)'
                              : 'High Quality (Blur, Animations)',
                          leading: _buildPremiumIcon(
                            Icons.speed,
                            Colors.orange,
                          ),
                          trailing: _BreathingToggle(
                            value: ref.watch(performanceProvider),
                            activeColor: Colors.amberAccent,
                            onChanged: (val) {
                              ref
                                  .read(performanceProvider.notifier)
                                  .toggle(val);
                            },
                          ),
                        ),
                        _buildPremiumSettingTile(
                          context,
                          title: 'Low Latency Mode',
                          subtitle:
                              ref.watch(switchSettingsProvider).lowLatencyMode
                              ? 'Ultra-Fast Cloud Sync (1000x)'
                              : 'Standard Sync',
                          leading: _buildPremiumIcon(Icons.bolt, Colors.yellow),
                          trailing: _BreathingToggle(
                            value: ref
                                .watch(switchSettingsProvider)
                                .lowLatencyMode,
                            activeColor: Colors.yellowAccent,
                            onChanged: (val) async {
                              await ref
                                  .read(switchSettingsProvider.notifier)
                                  .setLowLatencyMode(val);

                              // Trigger service optimization
                              await ref
                                  .read(firebaseSwitchServiceProvider)
                                  .applyLatencySettings(val);

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      val
                                          ? 'ULTRA LOW LATENCY ENABLED (Battery Intensive)'
                                          : 'Standard Latency Restored',
                                    ),
                                    backgroundColor: val
                                        ? Colors.yellow[700]
                                        : Colors.green,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                          ),
                          isLast: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // --- 3.7. SECURITY & RELIABILITY ---
              _animatedSection(
                index: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _PremiumSectionHeader(
                      title: 'Security & Reliability',
                    ),
                    _PremiumGroupedContainer(
                      children: [
                        _buildPremiumSettingTile(
                          context,
                          title: 'Battery Optimization',
                          subtitle:
                              'Ensure alarms trigger while device is asleep',
                          leading: _buildPremiumIcon(
                            Icons.battery_saver,
                            Colors.greenAccent,
                          ),
                          onTap: () async {
                            HapticService.heavy();
                            const channel = MethodChannel(
                              'com.iot.nebulacontroller/native_scheduler',
                            );
                            try {
                              await channel.invokeMethod('openBatterySettings');
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Could not open system settings',
                                    ),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                        _buildPremiumSettingTile(
                          context,
                          title: 'Alarm Audio Stream',
                          subtitle: 'Bypasses Do Not Disturb/Silent mode',
                          leading: _buildPremiumIcon(
                            Icons.notification_important,
                            Colors.redAccent,
                          ),
                          trailing: _BreathingToggle(
                            value: ref
                                .watch(switchSettingsProvider)
                                .alarmPriorityMode,
                            onChanged: (val) {
                              HapticService.selection();
                              ref
                                  .read(switchSettingsProvider.notifier)
                                  .setAlarmPriorityMode(val);
                            },
                          ),
                        ),
                        Consumer(
                          builder: (context, ref, _) =>
                              _buildPremiumSettingTile(
                                context,
                                title: 'Background Engine',
                                subtitle: 'Allow operations when app is closed',
                                leading: _buildPremiumIcon(
                                  Icons.memory,
                                  Colors.indigo,
                                ),
                                trailing: _BreathingToggle(
                                  value: ref.watch(backgroundServiceProvider),
                                  onChanged: (val) {
                                    HapticService.selection();
                                    ref
                                        .read(
                                          backgroundServiceProvider.notifier,
                                        )
                                        .toggle(val);
                                  },
                                ),
                                isLast: true,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // --- 4. APPEARANCE & STYLE ---
              _animatedSection(
                index: 4,
                child: RepaintBoundary(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _PremiumSectionHeader(title: 'Appearance'),
                      _PremiumGroupedContainer(
                        children: [
                          Consumer(
                            builder: (context, ref, _) {
                              final currentTheme = ref.watch(themeProvider);
                              return _buildPremiumSettingTile(
                                context,
                                title: 'Theme',
                                subtitle: _getThemeName(currentTheme),
                                leading: _buildPremiumIcon(
                                  Icons.palette,
                                  Colors.indigoAccent,
                                ),
                                onTap: () => _showThemePicker(
                                  context,
                                  ref,
                                  currentTheme,
                                ),
                              );
                            },
                          ),
                          Consumer(
                            builder: (context, ref, _) =>
                                _buildPremiumSettingTile(
                                  context,
                                  title: 'Display Size',
                                  subtitle: _getDisplaySizeName(
                                    ref
                                        .watch(displaySettingsProvider)
                                        .displaySize,
                                  ),
                                  leading: _buildPremiumIcon(
                                    Icons.aspect_ratio,
                                    Colors.cyan,
                                  ),
                                  onTap: () =>
                                      _showDisplaySizePicker(context, ref),
                                ),
                          ),
                          Consumer(
                            builder: (context, ref, _) {
                              final scale = ref
                                  .watch(displaySettingsProvider)
                                  .fontScale;
                              String label = 'Medium';
                              if (scale < 0.9) label = 'Small';
                              if (scale > 1.1) label = 'Large';
                              return _buildPremiumSettingTile(
                                context,
                                title: 'Font Scale',
                                subtitle: label,
                                leading: _buildPremiumIcon(
                                  Icons.text_fields,
                                  Colors.brown,
                                ),
                                onTap: () => _showFontSizePicker(context, ref),
                              );
                            },
                          ),
                          Consumer(
                            builder: (context, ref, _) =>
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
                                  onTap: () =>
                                      _showSwitchStylePicker(context, ref),
                                ),
                          ),
                          Consumer(
                            builder: (context, ref, _) =>
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
                                  onTap: () =>
                                      _showBackgroundPicker(context, ref),
                                ),
                          ),
                          Consumer(
                            builder: (context, ref, _) =>
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
                          ),
                          Consumer(
                            builder: (context, ref, _) {
                              final isPerformanceMode = ref.watch(
                                performanceProvider,
                              );
                              return _buildPremiumSettingTile(
                                context,
                                title: 'Dynamic Blending',
                                subtitle: isPerformanceMode
                                    ? 'Disabled for Performance'
                                    : 'Glass transparency effect',
                                leading: _buildPremiumIcon(
                                  Icons.opacity,
                                  Colors.deepPurpleAccent,
                                ),
                                trailing: _BreathingToggle(
                                  value: ref
                                      .watch(switchSettingsProvider)
                                      .dynamicBlending,
                                  onChanged: isPerformanceMode
                                      ? (val) {}
                                      : (val) => ref
                                            .read(
                                              switchSettingsProvider.notifier,
                                            )
                                            .setDynamicBlending(val),
                                ),
                                isLast: true,
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Removed redundant AI Assistant Toggle as requested

              // --- 5. ADVANCED TOOLS ---
              _animatedSection(
                index: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onDoubleTap: () {
                        debugPrint("NEBULA_DEV: Secret Trigger Activated");
                        HapticService.selection();
                        ref
                            .read(performanceStatsProvider.notifier)
                            .toggleConsole(true);
                      },
                      child: const _PremiumSectionHeader(
                        title: 'Advanced Tools',
                      ),
                    ),
                    _PremiumGroupedContainer(
                      children: [
                        _buildPremiumSettingTile(
                          context,
                          title: 'Developer Monitor',
                          subtitle: 'Raw Telemetry & Mesh Diagnostics',
                          leading: _buildPremiumIcon(
                            Icons.monitor_heart,
                            Colors.greenAccent,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              CupertinoPageRoute(
                                builder: (context) =>
                                    const DeveloperMonitorScreen(),
                              ),
                            );
                          },
                        ),
                        _buildPremiumSettingTile(
                          context,
                          title: 'Firmware Hub',
                          subtitle: 'Data Map, ESP32 & ESP8266 Templates',
                          leading: _buildPremiumIcon(
                            Icons.hub,
                            Colors.deepPurple,
                          ),
                          onTap: () => _showEsp32FirmwareDialog(context, ref),
                        ),
                        _buildPremiumSettingTile(
                          context,
                          title: 'Device ID',
                          subtitle: ref
                              .watch(switchDevicesProvider.notifier)
                              .currentDeviceId,
                          leading: _buildPremiumIcon(
                            Icons.perm_device_information,
                            Colors.cyan,
                          ),
                          onTap: () => _showDeviceIdDialog(context, ref),
                          isLast: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // --- 5. GOOGLE HOME ---
              _animatedSection(
                index: 7,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _PremiumSectionHeader(title: 'Google Home'),
                    _PremiumGroupedContainer(
                      children: [
                        _buildPremiumSettingTile(
                          context,
                          title: 'Link Status',
                          subtitle: 'Sync with Google Assistant',
                          leading: _buildPremiumIcon(
                            Icons.home_rounded,
                            Colors.blue,
                          ),
                          trailing: _BreathingToggle(
                            value:
                                ref
                                    .watch(googleHomeLinkedProvider)
                                    .valueOrNull ??
                                false,
                            onChanged: (val) async {
                              final service = ref.read(
                                googleHomeServiceProvider,
                              );
                              if (val) {
                                await service.linkGoogleHome();
                              } else {
                                await service.unlinkGoogleHome();
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
                  ],
                ),
              ),

              // --- 6. SUPPORT & IDENTITY ---
              _animatedSection(
                index: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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

                        // AI Assistant settings have been integrated into the Robo Assistant
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
                  ],
                ),
              ),

              const SizedBox(height: 20),
              const SprinklingWatermark(),
              const SizedBox(height: 100),
            ],
          ),
        ),

        // FLOATING ROBO ASSISTANT — Nebula AI Trigger
        Positioned(
          bottom: 24,
          right: 24,
          child: SizedBox(
            width: 80,
            height: 100,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticService.heavy();
                showGeneralDialog(
                  context: context,
                  pageBuilder: (context, _, __) => const AiAssistantDialog(),
                  barrierDismissible: true,
                  barrierLabel: 'AI Assistant',
                  barrierColor: Colors.black.withOpacity(0.5),
                  transitionDuration: const Duration(milliseconds: 300),
                );
              },
              child: AbsorbPointer(
                child: Transform.scale(
                  scale: 0.65,
                  child: const RoboAssistant(eyesOnly: false),
                ),
              ),
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
    final primaryColor = hasUpdate ? Colors.redAccent : Colors.tealAccent;
    final animationsEnabled = ref
        .watch(animationSettingsProvider)
        .animationsEnabled;

    Widget card = Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A).withOpacity(0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: primaryColor.withOpacity(0.3), width: 1),
        boxShadow: const [],
      ),
      child: Row(
        children: [
          Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: primaryColor.withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  hasUpdate ? Icons.rocket_launch : Icons.check_circle_outline,
                  color: primaryColor,
                  size: 24,
                ),
              )
              .animate(
                onPlay: (c) =>
                    animationsEnabled ? c.repeat(reverse: true) : null,
              )
              .shimmer(delay: 2000.ms, duration: 1500.ms),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasUpdate ? 'Update Available' : 'Nebula Core Optimized',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: hasUpdate ? Colors.redAccent : Colors.white,
                    shadows: hasUpdate
                        ? [
                            Shadow(
                              color: Colors.redAccent.withOpacity(0.5),
                              blurRadius: 12,
                            ),
                          ]
                        : [],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  hasUpdate
                      ? 'v${updateState.updateInfo!.latestVersion} Ready to Install'
                      : 'System is running at peak performance',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          if (hasUpdate)
            Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [],
                  ),
                  child: const Text(
                    'INSTALL',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      color: Colors.white,
                    ),
                  ),
                )
                .animate(
                  onPlay: (c) =>
                      animationsEnabled ? c.repeat(reverse: true) : null,
                )
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.1, 1.1),
                  duration: 1000.ms,
                ),
        ],
      ),
    );

    if (animationsEnabled) {
      card = card
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .boxShadow(
            begin: BoxShadow(
              color: primaryColor.withOpacity(0.05),
              blurRadius: 15,
            ),
            end: BoxShadow(
              color: primaryColor.withOpacity(0.15),
              blurRadius: 25,
            ),
            duration: 3000.ms,
          );
    }

    return GestureDetector(
      onTap: () => _checkForUpdates(context, ref),
      child: card,
    );
  }

  // --- HELPER FOR ANIMATED SECTIONS ---
  Widget _animatedSection({required int index, required Widget child}) {
    final animationsEnabled = ref
        .watch(animationSettingsProvider)
        .animationsEnabled;

    if (!animationsEnabled) return child;

    return child
        .animate()
        .fadeIn(
          delay: (index * 30).ms, // Faster stagger
          duration: 80.ms, // Snappier fade
          curve: Curves.easeOutQuad,
        )
        .slideY(begin: 0.1, duration: 80.ms, curve: Curves.easeOutQuad);
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

  void _showDeviceIdDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(
      text: ref.read(switchDevicesProvider.notifier).currentDeviceId,
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(
          'Device ID',
          style: GoogleFonts.outfit(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter the Device ID of your ESP32.',
              style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.black,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(switchDevicesProvider.notifier)
                  .updateDeviceId(controller.text);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Device ID Updated')),
              );
            },
            child: const Text('Save'),
          ),
        ],
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
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildModernPickerSheet(
        context: context,
        title: "Select Theme",
        child: SizedBox(
          height: 350,
          child: RepaintBoundary(
            child: GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.8,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: AppThemeMode.values.length,
              itemBuilder: (context, index) {
                final mode = AppThemeMode.values[index];
                final isSelected = mode == current;
                return _buildModernPickerItem(
                  context: context,
                  title: _getThemeName(mode),
                  isSelected: isSelected,
                  onTap: () {
                    ref.read(themeProvider.notifier).setTheme(mode);
                    Navigator.pop(context);
                  },
                  color: Theme.of(context).primaryColor,
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // --- MODERN PICKER UI HELPERS ---

  Widget _buildModernPickerSheet({
    required BuildContext context,
    required String title,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1.5),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFF1A1A1A), const Color(0xFF080808)],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 24),
          const SizedBox(height: 16),

          child,
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildModernPickerItem({
    required BuildContext context,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    Color? color,
  }) {
    final activeColor = color ?? Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: () {
        HapticService.selection();
        onTap();
      },
      child: RepaintBoundary(
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withOpacity(0.12)
                : const Color(0xFF121212),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? activeColor : Colors.white.withOpacity(0.06),
              width: isSelected ? 2.0 : 1.0,
            ),
          ),
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isSelected) ...[
                  Icon(Icons.check_circle, color: activeColor, size: 18),
                  const SizedBox(width: 10),
                ],
                Flexible(
                  child: Text(
                    title,
                    style: GoogleFonts.outfit(
                      color: isSelected ? Colors.white : Colors.white54,
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.w500,
                      fontSize: 15,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSwitchStylePicker(BuildContext context, WidgetRef ref) {
    final current = ref.read(switchStyleProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildModernPickerSheet(
        context: context,
        title: "Switch Style",
        child: SizedBox(
          height: 400,
          child: RepaintBoundary(
            child: GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.8,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: SwitchStyleType.values.length,
              itemBuilder: (context, index) {
                final style = SwitchStyleType.values[index];
                final isSelected = style == current;
                return _buildModernPickerItem(
                  context: context,
                  title: _getSwitchStyleName(style),
                  isSelected: isSelected,
                  onTap: () {
                    ref.read(switchStyleProvider.notifier).setStyle(style);
                    Navigator.pop(context);
                  },
                  color: Colors.lightGreenAccent,
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showBackgroundPicker(BuildContext context, WidgetRef ref) {
    final current = ref.read(switchBackgroundProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildModernPickerSheet(
        context: context,
        title: "Tab Background",
        child: SizedBox(
          height: 400,
          child: RepaintBoundary(
            child: GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.8,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: SwitchBackgroundType.values.length,
              itemBuilder: (context, index) {
                final style = SwitchBackgroundType.values[index];
                final isSelected = style == current;
                return _buildModernPickerItem(
                  context: context,
                  title: _getSwitchBackgroundName(style),
                  isSelected: isSelected,
                  onTap: () {
                    ref.read(switchBackgroundProvider.notifier).setStyle(style);
                    Navigator.pop(context);
                  },
                  color: Colors.purpleAccent,
                );
              },
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
      case AppThemeMode.cyberNeon:
        return 'Cyber Neon';
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
      case AppThemeMode.starlightEcho:
        return 'Starlight Echo';
      case AppThemeMode.pureGold:
        return 'Pure Gold';
      case AppThemeMode.platinumBlue:
        return 'Platinum Blue';
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
      case HapticStyle.success:
        return 'Success';
      case HapticStyle.error:
        return 'Error';
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
    _showFirmwareHub(context, ref);
  }

  void _showFirmwareHub(BuildContext context, WidgetRef ref) {
    final deviceId = ref.read(switchDevicesProvider.notifier).currentDeviceId;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _FirmwareHubSheet(deviceId: deviceId),
    );
  }

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

          return RepaintBoundary(
            child: Padding(
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
                    children: [
                      _buildFontSizePreset(
                        context,
                        ref,
                        'Small',
                        0.85,
                        Icons.text_fields,
                      ),
                      const SizedBox(width: 12),
                      _buildFontSizePreset(
                        context,
                        ref,
                        'Medium',
                        1.0,
                        Icons.text_fields,
                      ),
                      const SizedBox(width: 12),
                      _buildFontSizePreset(
                        context,
                        ref,
                        'Large',
                        1.15,
                        Icons.text_fields,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFontSizePreset(
    BuildContext context,
    WidgetRef ref,
    String label,
    double scale,
    IconData icon,
  ) {
    final currentScale = ref.watch(displaySettingsProvider).fontScale;
    final isSelected = (currentScale - scale).abs() < 0.01;
    final theme = Theme.of(context);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticService.selection();
          ref.read(displaySettingsProvider.notifier).setFontScale(scale);
        },
        child: AnimatedContainer(
          duration: 80.ms,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary.withOpacity(0.15)
                : Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : Colors.white.withOpacity(0.08),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20 * scale,
                color: isSelected ? theme.colorScheme.primary : Colors.white38,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : Colors.white38,
                ),
              ),
            ],
          ),
        ),
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
              boxShadow: const [],
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
    final currentThemeMode = ref.watch(themeProvider);
    final glowIntensity = AppTheme.getThemeGlowIntensity(currentThemeMode);
    final blurEnabled = ref.watch(switchSettingsProvider).blurEffectsEnabled;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: blurEnabled
            ? Colors.black.withOpacity(0.3)
            : const Color(0xFF151515),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.12 * glowIntensity),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.05 * glowIntensity),
            blurRadius: 15,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _BreathingToggle extends ConsumerStatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? activeColor;

  const _BreathingToggle({
    required this.value,
    required this.onChanged,
    this.activeColor,
  });

  @override
  ConsumerState<_BreathingToggle> createState() => _BreathingToggleState();
}

class _BreathingToggleState extends ConsumerState<_BreathingToggle> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = widget.activeColor ?? theme.colorScheme.primary;

    return GestureDetector(
      onTap: () {
        HapticService.toggle(!widget.value);
        widget.onChanged(!widget.value);
      },
      child: Container(
        padding: const EdgeInsets.all(4),
        child: CupertinoSwitch(
          value: widget.value,
          activeColor: activeColor,
          onChanged: (val) {
            HapticService.toggle(val);
            widget.onChanged(val);
          },
        ),
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
                  boxShadow: const [],
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

// ===========================================================================
// FIRMWARE HUB SHEET — Premium animated modal with Data Map + Firmware Download
// ===========================================================================
class _FirmwareHubSheet extends StatefulWidget {
  final String deviceId;
  const _FirmwareHubSheet({required this.deviceId});

  @override
  State<_FirmwareHubSheet> createState() => _FirmwareHubSheetState();
}

class _FirmwareHubSheetState extends State<_FirmwareHubSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _fileService = FileService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0F),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF141420), Color(0xFF080810)],
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 48,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.hub, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Firmware Hub',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Device: ${widget.deviceId}',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          color: const Color(0xFF6366F1),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white38),
                ),
              ],
            ),
          ),
          // Tabs
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.5),
                ),
              ),
              dividerHeight: 0,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white38,
              labelStyle: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: 'Data Map'),
                Tab(text: 'ESP32'),
                Tab(text: 'ESP8266'),
              ],
            ),
          ),
          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDataMapTab(),
                _buildFirmwareTab(
                  title: 'ESP32 Hub Firmware',
                  subtitle: 'v2.0.0 Template — Arduino Framework',
                  icon: Icons.memory,
                  color: const Color(0xFF10B981),
                  fileName: 'esp32_template.ino',
                ),
                _buildFirmwareTab(
                  title: 'ESP8266 Satellite Firmware',
                  subtitle: 'v2.1.0 Template — 4-Zone PIR Scanner',
                  icon: Icons.satellite_alt,
                  color: const Color(0xFF3B82F6),
                  fileName: 'esp8266_template.ino',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataMapTab() {
    final id = widget.deviceId;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildAddressGroup(
          'Commands (App → ESP32)',
          Colors.cyan,
          Icons.gamepad,
          {
            'Relay 1-7': 'devices/$id/commands/relay1..7',
            'Inverted Logic': 'devices/$id/commands/invert1..7',
            'Armed State': 'devices/$id/commands/isArmed',
            'PIR Timer': 'devices/$id/commands/pirTimer',
            'PIR Maps (bitmask)': 'devices/$id/commands/mapPIR1..5',
            'Automation Mode': 'devices/$id/commands/globalMotionMode',
            'LDR Threshold': 'devices/$id/commands/ldrThreshold',
            'Panic Alarm': 'devices/$id/commands/panic',
            'Buzzer Mute': 'devices/$id/commands/buzzerMute',
            'Eco Mode': 'devices/$id/commands/ecoMode',
          },
        ),
        _buildAddressGroup('Security Config', Colors.amber, Icons.shield, {
          'Security Mode': 'devices/$id/commands/security/securityMode',
          'Morning Period':
              'devices/$id/commands/security/activePeriods/morning',
          'Afternoon': 'devices/$id/commands/security/activePeriods/afternoon',
          'Evening': 'devices/$id/commands/security/activePeriods/evening',
          'Night': 'devices/$id/commands/security/activePeriods/night',
          'Midnight': 'devices/$id/commands/security/activePeriods/midnight',
          'PIR Sensitivity':
              'devices/$id/commands/security/calibration/PIR1/sensitivity',
        }),
        _buildAddressGroup(
          'Telemetry (ESP32 → App)',
          Colors.green,
          Icons.speed,
          {
            'Relay States': 'devices/$id/telemetry/relay1..7',
            'Voltage': 'devices/$id/telemetry/voltage',
            'Free Heap': 'devices/$id/telemetry/heap',
            'WiFi RSSI': 'devices/$id/telemetry/rssi',
            'Uptime': 'devices/$id/telemetry/uptime',
          },
        ),
        _buildAddressGroup('Hub Status', Colors.tealAccent, Icons.favorite, {
          'Online': 'devices/$id/status/online',
          'Last Seen': 'devices/$id/status/lastSeen',
          'Version': 'devices/$id/status/version',
        }),
        _buildAddressGroup(
          'Satellite (ESP8266)',
          Colors.blue,
          Icons.satellite_alt,
          {
            'Status': 'devices/$id/security/nodeActive/...',
            'Sensors': 'devices/$id/security/sensors/PIR1..4',
            'Config': 'devices/$id/satellite/config/pulses,window,hold...',
            'Dev Console Signals': 'devices/$id/security/nodeActive/signal_px',
          },
        ),
        _buildAddressGroup('Security Events', Colors.redAccent, Icons.warning, {
          'Breach Log': 'devices/$id/security/logs/{pushId}',
          'Alarm Active': 'devices/$id/security/alarmActive',
          'Active Breaches': 'devices/$id/security/activeBreaches/...',
        }),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildAddressGroup(
    String title,
    Color color,
    IconData icon,
    Map<String, String> addresses,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          // Address rows
          ...addresses.entries.map(
            (e) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      e.key,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: Colors.white54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: SelectableText(
                      e.value,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 9.5,
                        color: color.withValues(alpha: 0.8),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildFirmwareTab({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String fileName,
  }) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Big icon card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.1), Colors.transparent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.2),
                        color.withValues(alpha: 0.05),
                      ],
                    ),
                    border: Border.all(color: color.withValues(alpha: 0.4)),
                  ),
                  child: Icon(icon, size: 48, color: color),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Colors.white38,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'SKELETON — No credentials included',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 9,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Info chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildInfoChip('WiFi Config', Icons.wifi, color),
              _buildInfoChip('Firebase RTDB', Icons.cloud, color),
              _buildInfoChip('Pin Mapping', Icons.developer_board, color),
              _buildInfoChip('OTA Support', Icons.system_update, color),
            ],
          ),
          const Spacer(),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  label: 'Copy Code',
                  icon: Icons.copy,
                  color: Colors.white24,
                  onTap: () => _copyFirmware(fileName),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _buildActionButton(
                  label: 'Download $fileName',
                  icon: Icons.download,
                  color: color,
                  filled: true,
                  onTap: () => _saveFirmware(fileName),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color.withValues(alpha: 0.7)),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.outfit(fontSize: 11, color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    bool filled = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: filled
              ? color.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: filled
                ? color.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: filled ? color : Colors.white54),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: filled ? color : Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getFirmwareCode(String fileName) {
    // Return embedded skeleton code based on firmware type
    if (fileName.contains('esp32')) {
      return _esp32SkeletonCode;
    } else {
      return _esp8266SkeletonCode;
    }
  }

  Future<void> _copyFirmware(String fileName) async {
    final code = _getFirmwareCode(fileName);
    await _fileService.copyToClipboard(code);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$fileName copied to clipboard'),
          backgroundColor: const Color(0xFF6366F1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _saveFirmware(String fileName) async {
    try {
      final code = _getFirmwareCode(fileName);
      final path = await _fileService.saveEsp32Code(code, fileName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved: $path'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Embedded skeleton code strings
  static const String _esp32SkeletonCode = '''
/*
 * NEBULA CORE – ESP32 PASSIVE MUSCLES v3.0.0
 * The ESP32 is now entirely stripped of Neural Logic.
 * It is a pure actuator that listens to Firebase and triggers GPIO.
 */

#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include "addons/RTDBHelper.h"
#include "addons/TokenHelper.h"

#define WIFI_SSID     "YOUR_WIFI_NAME"
#define WIFI_PASS     "YOUR_WIFI_PASSWORD"
#define API_KEY       "YOUR_FIREBASE_API_KEY"
#define DATABASE_URL  "https://YOUR_PROJECT.firebasedatabase.app"
String deviceId =     "YOUR_DEVICE_ID";

// Pin Definitions
#define RELAY1 26  #define RELAY2 27  #define RELAY3 25
#define RELAY4 33  #define RELAY5 32  #define RELAY6 14  #define RELAY7 23
#define VOLTAGE_SENSOR 34
#define BUZZER_PIN 13
#define LED_RED 19  #define LED_GREEN 16  #define LED_BLUE 17

// Full firmware available in firmware/esp32_nebula_controller.ino
''';

  static const String _esp8266SkeletonCode = '''
/*
 * NEBULA CORE – ESP8266 NEURAL BRAIN v3.0.0
 * The ESP8266 is now the primary Neural link controller.
 * Processes PIR, Alarms, NTP Scheduling, and directly issues Firebase Commands.
 */

#include <ESP8266WiFi.h>
#include <Firebase_ESP_Client.h>
#include <NTPClient.h>
#include <WiFiUdp.h>

#define WIFI_SSID    "YOUR_WIFI_NAME"
#define WIFI_PASS    "YOUR_WIFI_PASSWORD"
#define API_KEY      "YOUR_FIREBASE_API_KEY"
#define DATABASE_URL "YOUR_PROJECT.firebasedatabase.app"
#define DEVICE_ID    "YOUR_DEVICE_ID"

// Pin Definitions
const uint8_t PIR_PINS[4] = {5, 4, 14, 12}; // D1, D2, D5, D6
// A0 = LDR Sensor

// Full firmware available in esp8266_satellite_node.ino
''';
}
