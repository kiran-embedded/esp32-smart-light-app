import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../providers/theme_provider.dart';
import '../../providers/voice_provider.dart';
import '../../providers/switch_provider.dart';
import '../../providers/immersive_provider.dart';
import '../../providers/switch_style_provider.dart';
import '../../providers/switch_background_provider.dart';
import '../../providers/connection_settings_provider.dart';
import '../../providers/sound_settings_provider.dart';
import '../../providers/switch_settings_provider.dart';
import '../../providers/performance_provider.dart';
import '../../providers/network_settings_provider.dart';
import '../../providers/haptic_provider.dart';
import '../../providers/update_provider.dart';
import '../../providers/live_info_provider.dart';
import '../../core/ui/responsive_layout.dart';
import '../../services/performance_monitor_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/haptic_service.dart';
import '../../providers/display_settings_provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/font_settings_provider.dart';
import '../../providers/display_settings_provider.dart';
import '../../services/esp32_code_generator.dart';
import '../../services/file_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/voice_service.dart';
import '../../services/update_service.dart';

import 'package:path_provider/path_provider.dart';

import 'help_support_screen.dart';
import '../../widgets/robo/robo_assistant.dart';
import '../../widgets/common/animated_cupertino_switch.dart';

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
            key: const PageStorageKey('settings_list_v2'),
            padding: EdgeInsets.only(
              bottom: 120,
              top: MediaQuery.of(context).padding.top + 20,
            ),
            physics: const BouncingScrollPhysics(),
            children:
                [
                      // --- UPDATES ---
                      const _IosSectionHeader(title: 'Updates'),
                      _buildUpdateTile(context, ref),

                      // --- 1. CORE SYSTEM ---
                      const _IosSectionHeader(title: 'Core System'),
                      _IosGroupedContainer(
                        children: [
                          _buildIosSettingTile(
                            context,
                            title: 'Fullscreen Mode',
                            subtitle: 'Hide status and navigation bars',
                            trailing: CupertinoSwitch(
                              value: ref.watch(immersiveModeProvider),
                              onChanged: (value) async {
                                ref
                                    .read(immersiveModeProvider.notifier)
                                    .setImmersiveMode(value);
                              },
                            ),
                          ),
                          _buildAnimationSettings(context, ref),
                        ],
                      ),

                      // --- 2. CONNECTIVITY ---
                      const _IosSectionHeader(title: 'Connectivity'),
                      _IosGroupedContainer(
                        children: [_buildConnectionSettings(context, ref)],
                      ),

                      // --- 2.5. OFFLINE CONTROL ---
                      const _IosSectionHeader(title: 'Offline Control'),
                      _IosGroupedContainer(
                        children: [
                          _buildIosSettingTile(
                            context,
                            title: 'Smart Hybrid Auto',
                            subtitle: 'Auto-switch WiFi/Cloud',
                            trailing: CupertinoSwitch(
                              value:
                                  ref.watch(connectionSettingsProvider).mode ==
                                  ConnectionMode.hybridAuto,
                              activeColor: Colors.cyanAccent,
                              onChanged: (val) {
                                ref
                                    .read(connectionSettingsProvider.notifier)
                                    .setMode(
                                      val
                                          ? ConnectionMode.hybridAuto
                                          : ConnectionMode.cloud,
                                    );
                              },
                            ),
                          ),
                          _buildIosSettingTile(
                            context,
                            title: 'Local Only Mode',
                            subtitle: 'Control via LAN/mDNS',
                            trailing: CupertinoSwitch(
                              value:
                                  ref.watch(connectionSettingsProvider).mode ==
                                  ConnectionMode.local,
                              activeColor: Colors.yellowAccent,
                              onChanged: (val) {
                                ref
                                    .read(connectionSettingsProvider.notifier)
                                    .setMode(
                                      val
                                          ? ConnectionMode.local
                                          : ConnectionMode.cloud,
                                    );
                              },
                            ),
                            isLast: true,
                          ),
                        ],
                  children: [
                    _buildIosSettingTile(
                      context,
                      title: 'Voice Feedback',
                      subtitle: 'Enable AI voice responses',
                      trailing: AnimatedCupertinoSwitch(
                        value: voiceEnabled,
                        onChanged: (value) async {
                          ref
                              .read(voiceEnabledProvider.notifier)
                              .setVoiceEnabled(value);
                        },
                      ),

                      // --- 3. SENSORY & FEEDBACK ---
                      const _IosSectionHeader(title: 'Sensory & Feedback'),
                      _IosGroupedContainer(
                        children: [
                          _buildIosSettingTile(
                            context,
                            title: 'Voice Feedback',
                            subtitle: 'Enable AI voice responses',
                            trailing: CupertinoSwitch(
                              value: voiceEnabled,
                              onChanged: (value) async {
                                ref
                                    .read(voiceEnabledProvider.notifier)
                                    .setVoiceEnabled(value);
                              },
                            ),
                          ),
                          _buildIosSettingTile(
                            context,
                            title: 'Master Sound',
                            subtitle: 'Enable all app sounds',
                            trailing: CupertinoSwitch(
                              value: ref
                                  .watch(soundSettingsProvider)
                                  .masterSound,
                              onChanged: (val) => ref
                                  .read(soundSettingsProvider.notifier)
                                  .setMasterSound(val),
                            ),
                          ),
                          if (ref.watch(soundSettingsProvider).masterSound) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                10,
                                20,
                                10,
                              ),
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
                                    inactiveColor: Colors.white.withOpacity(
                                      0.1,
                                    ),
                                    onChanged: (val) => ref
                                        .read(soundSettingsProvider.notifier)
                                        .setMasterVolume(val),
                                  ),
                                ],
                              ),
                            ),
                            _buildIosSettingTile(
                              context,
                              title: 'Switch Sounds',
                              subtitle: 'Click sound when toggling',
                              trailing: CupertinoSwitch(
                                value: ref
                                    .watch(soundSettingsProvider)
                                    .switchSound,
                                onChanged: (val) => ref
                                    .read(soundSettingsProvider.notifier)
                                    .setSwitchSound(val),
                              ),
                            ),
                          ],
                          if (voiceEnabled) ...[
                            _buildIosSettingTile(
                              context,
                              title: 'Voice Engine',
                              subtitle:
                                  ref.watch(voiceEngineProvider) ?? 'Default',
                              trailing: Icon(
                                Icons.record_voice_over,
                                color: Colors.white.withOpacity(0.3),
                              ),
                              onTap: () async {
                                final service = ref.read(voiceServiceProvider);
                                await service.testSpeak();
                              },
                            ),
                          ],
                          _buildIosSettingTile(
                            context,
                            title: 'Haptic Feedback',
                            subtitle: _getHapticName(
                              ref.watch(hapticStyleProvider),
                            ),
                            trailing: Icon(
                              Icons.vibration,
                              color: Colors.white.withOpacity(0.3),
                            ),
                            onTap: () => _showHapticPicker(context, ref),
                            isLast: true,
                          ),
                        ],
                      ),

                      // --- 3.5. PERFORMANCE ---
                      const _IosSectionHeader(title: 'Performance'),
                      _IosGroupedContainer(
                        children: [
                          _buildIosSettingTile(
                            context,
                            title: 'Performance Mode',
                            subtitle: ref.watch(performanceProvider)
                                ? 'Optimized (Fast, No Blur)'
                                : 'High Quality (Blur, Animations)',
                            trailing: CupertinoSwitch(
                              value: ref.watch(performanceProvider),
                              activeColor: Colors.amberAccent,
                              onChanged: (val) {
                                ref
                                    .read(performanceProvider.notifier)
                                    .toggle(val);
                              },
                            ),
                            isLast: true,
                          ),
                        ],
                      ),

                      // --- 4. DISPLAY & APPEARANCE ---
                      const _IosSectionHeader(title: 'Display & Appearance'),
                      _IosGroupedContainer(
                        children: [
                          _buildDisplaySizeSettings(context, ref),
                          Padding(
                            padding: const EdgeInsets.only(left: 20),
                            child: Divider(
                              height: 1,
                              thickness: 0.5,
                              color: Colors.white.withOpacity(0.05),
                            ),
                          ),
                          _buildIosSettingTile(
                            context,
                            title: 'Theme',
                            subtitle: _getThemeName(currentTheme),
                            onTap: () =>
                                _showThemePicker(context, ref, currentTheme),
                          ),
                          _buildIosSettingTile(
                            context,
                            title: 'Switch Style',
                            subtitle: _getSwitchStyleName(
                              ref.watch(switchStyleProvider),
                            ),
                            onTap: () => _showSwitchStylePicker(context, ref),
                          ),
                          _buildIosSettingTile(
                            context,
                            title: 'Tab Background',
                            subtitle: _getSwitchBackgroundName(
                              ref.watch(switchBackgroundProvider),
                            ),
                            onTap: () => _showBackgroundPicker(context, ref),
                          ),
                          _buildIosSettingTile(
                            context,
                            title: 'Glass Blur Effects',
                            subtitle: 'Frosted glass visuals (GPU heavy)',
                            trailing: CupertinoSwitch(
                              value: ref
                                  .watch(switchSettingsProvider)
                                  .blurEffectsEnabled,
                              onChanged: (val) => ref
                                  .read(switchSettingsProvider.notifier)
                                  .setBlurEffects(val),
                            ),
                          ),
                          _buildIosSettingTile(
                            context,
                            title: 'Dynamic Blending',
                            subtitle: ref.watch(performanceProvider)
                                ? 'Disabled by Performance Mode'
                                : 'Glass transparency effect',
                            trailing: CupertinoSwitch(
                              value: ref
                                  .watch(switchSettingsProvider)
                                  .dynamicBlending,
                              onChanged: ref.watch(performanceProvider)
                                  ? null
                                  : (val) => ref
                                        .read(switchSettingsProvider.notifier)
                                        .setDynamicBlending(val),
                            ),
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
                        child: const _IosSectionHeader(title: 'Advanced Tools'),
                      ),
                      _IosGroupedContainer(
                        children: [
                          _buildIosSettingTile(
                            context,
                            title: 'ESP32 Firmware',
                            subtitle: 'Generate C++ controller code',
                            onTap: () => _showEsp32FirmwareDialog(context, ref),
                          ),
                          _buildIosSettingTile(
                            context,
                            title: 'Unlink Google',
                            subtitle: 'Disconnect from Cloud services',
                            onTap: () {},
                            isLast: true,
                          ),
                        ],
                      ),

                      // --- 6. SUPPORT & IDENTITY ---
                      const _IosSectionHeader(title: 'Support & Identity'),
                      _IosGroupedContainer(
                        children: [
                          _buildIosSettingTile(
                            context,
                            title: 'Help Center',
                            subtitle: 'FAQ and troubleshooting',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const HelpSupportScreen(),
                                ),
                              );
                            },
                          ),
                          _buildIosSettingTile(
                            context,
                            title: 'Source Code',
                            subtitle: 'github.com/kiran-embedded',
                            onTap: () {
                              launchUrl(
                                Uri.parse(
                                  'https://github.com/kiran-embedded/esp32-smart-light-app',
                                ),
                                mode: LaunchMode.externalApplication,
                              );
                            },
                          ),
                          _buildIosSettingTile(
                            context,
                            title: 'Logout',
                            subtitle: 'Sign out from Nebula',
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
                        child: Text(
                          "Version ${ref.watch(updateProvider).updateInfo?.latestVersion ?? '1.2.0+22'}",
                          style: GoogleFonts.outfit(
                            color: Colors.white.withOpacity(0.2),
                            fontSize: 12.sp,
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
                    ]
                    .animate(interval: 50.ms) // STAGGERED ENTRANCE
                    .slideX(
                      begin: 0.1,
                      curve: Curves.easeOutQuart,
                      duration: 500.ms,
                    ) // Slide form right
                    .fade(duration: 400.ms),
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
                setState(() => _isScanning = true);
                Future.delayed(const Duration(milliseconds: 1500), () {
                  if (mounted) setState(() => _isScanning = false);
                });
              },
            ),
          ),
        ),

        // SCANNER OVERLAY
        if (_isScanning) Positioned.fill(child: _ScannerLineAnimation()),
      ],
    );
  }

  Widget _buildIosSettingTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    bool isLast = false,
  }) {
    return Column(
      children: [
        _SettingTileWrapper(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) trailing,
                if (onTap != null && trailing == null)
                  Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: Colors.white.withOpacity(0.2),
                      )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .slideX(
                        begin: 0,
                        end: 0.2,
                        duration: 2.seconds,
                        curve: Curves.easeInOutSine,
                      ),
              ],
            ),
          ),
        ),
        if (!isLast)
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Divider(
              height: 1,
              thickness: 0.5,
              color: Colors.white.withOpacity(0.05),
            ),
          ),
      ],
    );
  }

  Widget _buildUpdateTile(BuildContext context, WidgetRef ref) {
    final updateState = ref.watch(updateProvider);
    final hasUpdate = updateState.updateInfo?.hasUpdate ?? false;

    return _IosGroupedContainer(
      children: AnimateList(
        interval: 40.ms,
        effects: [
          FadeEffect(duration: 400.ms),
          SlideEffect(
            begin: const Offset(0, 0.1),
            end: Offset.zero,
            curve: Curves.easeOutCubic,
          ),
        ],
        children: [
          _buildIosSettingTile(
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
      ),
    );
  }

  void _showHapticPicker(BuildContext context, WidgetRef ref) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) =>
          CupertinoActionSheet(
            title: const Text('Haptic Intensity'),
            actions: HapticStyle.values.asMap().entries.map((entry) {
              final index = entry.key;
              final style = entry.value;
              return CupertinoActionSheetAction(
                    onPressed: () {
                      ref
                          .read(hapticStyleProvider.notifier)
                          .setHapticStyle(style);
                      HapticService.feedback(style);
                      Navigator.pop(context);
                    },
                    child: Text(_getHapticName(style)),
                  )
                  .animate()
                  .fadeIn(delay: (index * 50).ms)
                  .slideY(begin: 0.1, end: 0);
            }).toList(),
            cancelButton: CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context),
              isDestructiveAction: true,
              child: const Text('Cancel'),
            ),
          ).animate().scale(
            begin: const Offset(0.9, 0.9),
            curve: Curves.easeOutBack,
            duration: 400.ms,
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
      builder: (context) =>
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E1E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
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
                ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),
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
                          )
                          .animate()
                          .fadeIn(delay: (index * 40).ms)
                          .slideX(begin: 0.1, end: 0);
                    },
                  ),
                ),
              ],
            ),
          ).animate().slideY(
            begin: 1,
            end: 0,
            curve: Curves.easeOutCubic,
            duration: 400.ms,
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
      builder: (context) =>
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E1E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            const SizedBox(height: 10),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: SwitchStyleType.values.length,
                itemBuilder: (context, index) {
                  final currentStyle = ref.watch(switchStyleProvider);
                  final style = SwitchStyleType.values[index];
                  final isSelected = style == currentStyle;
                  return ListTile(
                    onTap: () {
                      ref.read(switchStyleProvider.notifier).setStyle(style);
                      Navigator.pop(context);
                    },
                    title: Text(
                      _getSwitchStyleName(style),
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
          ).animate().slideY(
            begin: 1,
            end: 0,
            curve: Curves.easeOutCubic,
            duration: 400.ms,
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
      builder: (context) =>
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E1E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            const SizedBox(height: 10),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: SwitchBackgroundType.values.length,
                itemBuilder: (context, index) {
                  final currentBg = ref.watch(switchBackgroundProvider);
                  final style = SwitchBackgroundType.values[index];
                  final isSelected = style == currentBg;
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
          ).animate().slideY(
            begin: 1,
            end: 0,
            curve: Curves.easeOutCubic,
            duration: 400.ms,
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

  Widget _buildConnectionSettings(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(connectionSettingsProvider);
    final notifier = ref.read(connectionSettingsProvider.notifier);

    return Column(
      children: [
        _buildDropdownTile<ConnectionMode>(
          context,
          title: 'Connection Mode',
          subtitle: 'Choose how to talk to devices',
          value: settings.mode,
          items: ConnectionMode.values,
          onChanged: (val) => notifier.setMode(val!),
        ),
        _buildIosSettingTile(
          context,
          title: 'Ultra Low Latency',
          subtitle: '1ms Target (Best for fast switches)',
          trailing: AnimatedCupertinoSwitch(
            value: ref.watch(lowLatencyProvider),
            onChanged: (val) {
              ref.read(lowLatencyProvider.notifier).toggle(val);
            },
          ),
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildDisplaySizeSettings(BuildContext context, WidgetRef ref) {
    final displaySettings = ref.watch(displaySettingsProvider);
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Display Size',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    Text(
                      'Adjust pill & UI scaling',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: CupertinoSlidingSegmentedControl<double>(
            backgroundColor: Colors.white.withOpacity(0.1),
            thumbColor: theme.colorScheme.primary,
            groupValue: displaySettings.pillScale,
            children: {
              0.8: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'Small',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: displaySettings.pillScale == 0.8
                        ? Colors.white
                        : Colors.white70,
                  ),
                ),
              ),
              1.0: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'Normal',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: displaySettings.pillScale == 1.0
                        ? Colors.white
                        : Colors.white70,
                  ),
                ),
              ),
              1.2: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'Large',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: displaySettings.pillScale == 1.2
                        ? Colors.white
                        : Colors.white70,
                  ),
                ),
              ),
            },
            onValueChanged: (value) {
              if (value != null) {
                ref.read(displaySettingsProvider.notifier).setPillScale(value);
                HapticService.selection();
              }
            },
          ),
        ),

        // Font Size Slider (Volume Panel Like)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Font Size',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  Text(
                    '${(displaySettings.fontSize * 100).toInt()}%',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Icon(
                        Icons.text_fields_rounded,
                        size: 14,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 8,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 16,
                          ),
                          trackHeight: 4,
                          activeTrackColor: theme.colorScheme.primary,
                          inactiveTrackColor: Colors.white.withOpacity(0.1),
                          thumbColor: Colors.white,
                        ),
                        child: Slider(
                          value: displaySettings.fontSize,
                          min: 0.8,
                          max: 1.4,
                          divisions: 6,
                          onChanged: (val) {
                            ref
                                .read(displaySettingsProvider.notifier)
                                .setFontSize(val);
                          },
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Icon(
                        Icons.text_fields_rounded,
                        size: 20,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnimationSettings(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(animationSettingsProvider);
    final notifier = ref.read(animationSettingsProvider.notifier);

    return Column(
      children: [
        _buildDropdownTile<AppLaunchAnimation>(
          context,
          title: 'Startup Energy',
          subtitle: 'Choose how the app awakens',
          value: settings.launchType,
          items: AppLaunchAnimation.values,
          onChanged: (val) {
            notifier.setLaunchAnimation(val!);
            HapticService.heavy();
          },
        ),
        _buildDropdownTile<UiTransitionAnimation>(
          context,
          title: 'Fluidity Style',
          subtitle: 'Navigation & touch physics',
          value: settings.uiType,
          items: UiTransitionAnimation.values,
          onChanged: (val) {
            notifier.setUiAnimation(val!);
            HapticService.selection();
          },
          isLast: true,
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
    bool isLast = false,
  }) {
    final theme = Theme.of(context);
    return _buildIosSettingTile(
      context,
      title: title,
      subtitle: subtitle,
      isLast: isLast,
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

  void _showVoltageCalibrationDialog(BuildContext context, WidgetRef ref) {
    final liveInfo = ref.read(liveInfoProvider);
    final controller = TextEditingController(
      text: liveInfo.acVoltage.toStringAsFixed(1),
    );

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Calibrate Voltage'),
        content: Column(
          children: [
            const SizedBox(height: 8),
            const Text(
              'Enter the value shown on your reference multimeter.\nThe app will calculate and save the offset automatically.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            CupertinoTextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              placeholder: 'e.g. 230.5',
              padding: const EdgeInsets.all(12),
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              final entered = double.tryParse(controller.text);
              if (entered != null) {
                ref.read(liveInfoProvider.notifier).calibrateVoltage(entered);
              }
              Navigator.pop(context);
            },
            child: const Text('Calibrate'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearCache(BuildContext context) async {
    try {
      final tempDir = await getTemporaryDirectory();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cache cleared successfully',
              style: GoogleFonts.outfit(),
            ),
            backgroundColor: Colors.greenAccent.withOpacity(0.8),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error clearing cache: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _resetAll(BuildContext context) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Factory Reset'),
        content: const Text(
          'This will clear all your settings and configurations. The app will restart. Are you sure?',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context, false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Reset Everything'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (context.mounted) {
        // Since we can't easily force restart the app from within on many platforms without native plugins,
        // we'll at least wipe state and go back to a safe route or inform user.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All data wiped. Please restart the app manually.'),
          ),
        );
        // Navigate to home or initial setup if possible
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }
}

class _IosSectionHeader extends StatelessWidget {
  final String title;
  const _IosSectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 24, 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.outfit(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.white.withOpacity(0.4),
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _IosGroupedContainer extends StatelessWidget {
  final List<Widget> children;
  const _IosGroupedContainer({required this.children});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05), width: 0.5),
        ),
        child: Column(children: children),
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
              child:
                  Container(
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
                      )
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.05, end: 0, curve: Curves.easeOutCubic),
            ),
          ],
        );
      },
    );
  }
}

class _SettingTileWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _SettingTileWrapper({required this.child, this.onTap});

  @override
  State<_SettingTileWrapper> createState() => _SettingTileWrapperState();
}

class _SettingTileWrapperState extends State<_SettingTileWrapper> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        if (widget.onTap != null) {
          HapticService.light();
          setState(() => _isPressed = true);
        }
      },
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
