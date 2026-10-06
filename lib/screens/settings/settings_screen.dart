import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/immersive_provider.dart';
import '../../services/haptic_service.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common/aurexa_app_bar.dart';
import 'privacy_policy_sheet.dart';
import 'help_center_sheet.dart';
import 'dummy_setting_sheet.dart';
import 'esp32_flasher/esp32_flasher_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _offlineAlerts = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final currentTheme = ref.watch(themeProvider);
    final isFullScreen = ref.watch(immersiveModeProvider);
    final themeText = currentTheme == AppThemeMode.dark ? 'Dark' : 'Light';

    final language = ref.watch(languageProvider);
    final timeFormat = ref.watch(timeFormatProvider);

    final pushNotifications = ref.watch(pushNotificationProvider);
    final timerNotifications = ref.watch(timerNotificationProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            AurexaAppBar(
              actions: [
                GestureDetector(
                  onTap: () {
                    HapticService.selection();
                    ref.read(themeProvider.notifier).toggleTheme();
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? const Color(0xFF111111) : Colors.white,
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF222222)
                            : const Color(0xFFE5E5EA),
                      ),
                    ),
                    child: Icon(
                      isDark
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded,
                      color: isDark ? Colors.white : Colors.black,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileSection(isDark),
                    const SizedBox(height: 32),
                    _buildSectionHeader(
                      isDark: isDark,
                      title: 'App Settings'.tr(language),
                      subtitle: 'Customize the app to your needs'.tr(language),
                    ),
                    const SizedBox(height: 12),
                    _buildSettingsGroup(
                      isDark: isDark,
                      children: [
                        _buildActionTile(
                          isDark: isDark,
                          title: 'Theme',
                          subtitle: 'Light or Dark mode',
                          icon: Icons.palette_rounded,
                          iconColor: AppTheme.neonGreen,
                          trailing: _buildSegmentedControl(
                            options: ['Light', 'Dark'],
                            selectedValue: themeText,
                            onChanged: (val) {
                              HapticService.selection();
                              final mode = val == 'Dark'
                                  ? AppThemeMode.dark
                                  : AppThemeMode.light;
                              ref.read(themeProvider.notifier).setTheme(mode);
                            },
                            isDark: isDark,
                          ),
                          onTap: () {},
                        ),
                        _buildDivider(isDark),
                        _buildSwitchTile(
                          isDark: isDark,
                          title: 'Full Screen Mode',
                          subtitle: 'Hide status bar for immersive experience',
                          icon: Icons.fullscreen_rounded,
                          iconColor: AppTheme.neonGreen,
                          value: isFullScreen,
                          onChanged: (val) {
                            HapticService.selection();
                            ref.read(immersiveModeProvider.notifier).setImmersiveMode(val);
                          },
                        ),
                        _buildDivider(isDark),
                        _buildActionTile(
                          isDark: isDark,
                          title: 'Language',
                          subtitle: 'Choose your language',
                          icon: Icons.language_rounded,
                          iconColor: AppTheme.accentBlue,
                          trailing: _buildSegmentedControl(
                            options: ['EN', 'HI', 'ML'],
                            selectedValue: language == AppLanguage.english
                                ? 'EN'
                                : (language == AppLanguage.hindi ? 'HI' : 'ML'),
                            onChanged: (val) {
                              HapticService.selection();
                              final lang = val == 'EN'
                                  ? AppLanguage.english
                                  : (val == 'HI'
                                        ? AppLanguage.hindi
                                        : AppLanguage.malayalam);
                              ref
                                  .read(languageProvider.notifier)
                                  .setLanguage(lang);
                              
                              if (val != 'EN') {
                                ScaffoldMessenger.of(context).clearSnackBars();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Language pack ($val) is downloading. It will be available in a future update!',
                                      style: GoogleFonts.outfit(
                                        color: isDark ? Colors.black : Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    duration: const Duration(seconds: 2),
                                    backgroundColor: AppTheme.neonGreen,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                              }
                            },
                            isDark: isDark,
                          ),
                          onTap: () {},
                        ),
                        _buildDivider(isDark),
                        _buildActionTile(
                          isDark: isDark,
                          title: 'Time Format',
                          subtitle: 'Choose time display format',
                          icon: Icons.access_time_rounded,
                          iconColor: AppTheme.neonGreen,
                          trailing: _buildSegmentedControl(
                            options: ['12h', '24h'],
                            selectedValue: timeFormat == TimeFormat.h12
                                ? '12h'
                                : '24h',
                            onChanged: (val) {
                              HapticService.selection();
                              ref
                                  .read(timeFormatProvider.notifier)
                                  .setTimeFormat(
                                    val == '12h'
                                        ? TimeFormat.h12
                                        : TimeFormat.h24,
                                  );
                            },
                            isDark: isDark,
                          ),
                          onTap: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    _buildSectionHeader(
                      title: 'Home Settings',
                      subtitle: 'Manage your smart home',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _buildSettingsGroup(
                      isDark: isDark,
                      children: [
                        _buildActionTile(
                          isDark: isDark,
                          title: 'ESP32 Flasher & Firmware',
                          subtitle: 'Generate and flash custom firmware',
                          icon: Icons.code_rounded,
                          iconColor: AppTheme.neonGreen,
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            color: isDark ? Colors.white38 : Colors.black38,
                            size: 20,
                          ),
                          onTap: () {
                            HapticService.selection();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const Esp32FlasherScreen(),
                              ),
                            );
                          },
                        ),
                        _buildDivider(isDark),
                        _buildActionTile(
                          isDark: isDark,
                          title: 'Manage Rooms',
                          subtitle: 'Add, edit or remove rooms',
                          icon: Icons.home_rounded,
                          iconColor: AppTheme.neonGreen,
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            color: isDark ? Colors.white38 : Colors.black38,
                            size: 20,
                          ),
                          onTap: () {
                            HapticService.selection();
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => const DummySettingSheet(
                                title: 'Manage Rooms',
                                icon: Icons.home_rounded,
                                iconColor: AppTheme.neonGreen,
                                description:
                                    'Create and organize rooms to group your smart devices. This feature is coming soon!',
                              ),
                            );
                          },
                        ),
                        _buildDivider(isDark),
                        _buildActionTile(
                          isDark: isDark,
                          title: 'Device Management',
                          subtitle: 'View and manage all devices',
                          icon: Icons.devices_rounded,
                          iconColor: AppTheme.neonGreen,
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            color: isDark ? Colors.white38 : Colors.black38,
                            size: 20,
                          ),
                          onTap: () {
                            HapticService.selection();
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => const DummySettingSheet(
                                title: 'Device Management',
                                icon: Icons.devices_rounded,
                                iconColor: AppTheme.neonGreen,
                                description:
                                    'Update firmware, reboot devices, and troubleshoot connectivity. This feature is coming soon!',
                              ),
                            );
                          },
                        ),
                        _buildDivider(isDark),
                        _buildActionTile(
                          isDark: isDark,
                          title: 'Default States',
                          subtitle: 'Set default power state for new devices',
                          icon: Icons.power_settings_new_rounded,
                          iconColor: AppTheme.neonGreen,
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            color: isDark ? Colors.white38 : Colors.black38,
                            size: 20,
                          ),
                          onTap: () {
                            HapticService.selection();
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => const DummySettingSheet(
                                title: 'Default States',
                                icon: Icons.power_settings_new_rounded,
                                iconColor: AppTheme.neonGreen,
                                description:
                                    'Configure how your devices should behave after a power outage. This feature is coming soon!',
                              ),
                            );
                          },
                        ),
                        _buildDivider(isDark),
                        _buildActionTile(
                          isDark: isDark,
                          title: 'Backup & Restore',
                          subtitle: 'Save or restore your data',
                          icon: Icons.cloud_outlined,
                          iconColor: AppTheme.neonGreen,
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            color: isDark ? Colors.white38 : Colors.black38,
                            size: 20,
                          ),
                          onTap: () {
                            HapticService.selection();
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => const DummySettingSheet(
                                title: 'Backup & Restore',
                                icon: Icons.cloud_outlined,
                                iconColor: AppTheme.neonGreen,
                                description:
                                    'Safely backup your home configuration to the cloud. This feature is coming soon!',
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    _buildSectionHeader(
                      title: 'Notifications',
                      subtitle: 'Stay updated with your home',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _buildSettingsGroup(
                      isDark: isDark,
                      children: [
                        _buildSwitchTile(
                          isDark: isDark,
                          title: 'Push Notifications',
                          subtitle: 'Get notified about device updates',
                          icon: Icons.notifications_rounded,
                          iconColor: AppTheme.neonGreen,
                          value: pushNotifications,
                          onChanged: (val) {
                            HapticService.heavy();
                            ref.read(pushNotificationProvider.notifier).state =
                                val;
                          },
                        ),
                        _buildDivider(isDark),
                        _buildSwitchTile(
                          isDark: isDark,
                          title: 'Timer Notifications',
                          subtitle: 'Alerts for scheduled timers',
                          icon: Icons.access_time_rounded,
                          iconColor: AppTheme.neonGreen,
                          value: timerNotifications,
                          onChanged: (val) {
                            HapticService.heavy();
                            ref.read(timerNotificationProvider.notifier).state =
                                val;
                          },
                        ),
                        _buildDivider(isDark),
                        _buildSwitchTile(
                          isDark: isDark,
                          title: 'Device Offline Alerts',
                          subtitle: 'Get notified when devices go offline',
                          icon: Icons.wifi_off_rounded,
                          iconColor: AppTheme.accentRed,
                          value: _offlineAlerts,
                          onChanged: (val) => setState(() {
                            HapticService.heavy();
                            _offlineAlerts = val;
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    _buildSectionHeader(
                      title: 'About',
                      subtitle: 'App info and support',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _buildSettingsGroup(
                      isDark: isDark,
                      children: [
                        _buildActionTile(
                          isDark: isDark,
                          title: 'App Version',
                          subtitle: 'Aurexa Home v2.0.0',
                          icon: Icons.info_outline_rounded,
                          iconColor: isDark ? Colors.white : Colors.black,
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            color: isDark ? Colors.white38 : Colors.black38,
                            size: 20,
                          ),
                          onTap: () {},
                        ),
                        _buildDivider(isDark),
                        _buildActionTile(
                          isDark: isDark,
                          title: 'Help & Support',
                          subtitle: 'FAQs, guides and contact support',
                          icon: Icons.help_outline_rounded,
                          iconColor: isDark ? Colors.white : Colors.black,
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            color: isDark ? Colors.white38 : Colors.black38,
                            size: 20,
                          ),
                          onTap: () {
                            HapticService.selection();
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => const HelpCenterSheet(),
                            );
                          },
                        ),
                        _buildDivider(isDark),
                        _buildActionTile(
                          isDark: isDark,
                          title: 'Privacy Policy',
                          subtitle: 'Read our terms and policies',
                          icon: Icons.shield_outlined,
                          iconColor: AppTheme.accentBlue,
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            color: isDark ? Colors.white38 : Colors.black38,
                            size: 20,
                          ),
                          onTap: () {
                            HapticService.selection();
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => const PrivacyPolicySheet(),
                            );
                          },
                        ),
                        _buildDivider(isDark),
                        _buildActionTile(
                          isDark: isDark,
                          title: 'Rate App',
                          subtitle: 'Support us on the Play Store',
                          icon: Icons.star_border_rounded,
                          iconColor: const Color(0xFFFFCA28),
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            color: isDark ? Colors.white38 : Colors.black38,
                            size: 20,
                          ),
                          onTap: () {
                            HapticService.selection();
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => const DummySettingSheet(
                                title: 'Rate App',
                                icon: Icons.star_border_rounded,
                                iconColor: Color(0xFFFFCA28),
                                description:
                                    'Thank you for your support! Store rating link will be available upon official release.',
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    GestureDetector(
                      onTap: () async {
                        HapticService.heavy();
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => Center(
                            child: CircularProgressIndicator(color: const Color(0xFFFF6B6B)),
                          ),
                        );
                        await Future.delayed(const Duration(milliseconds: 800));
                        if (context.mounted) Navigator.pop(context);
                        ref.read(authProvider.notifier).signOut();
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B6B),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.logout_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Sign Out',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(bool isDark) {
    final user = ref.read(authServiceProvider).currentUser;
    final name = user?.displayName ?? 'Kiran';
    final email = user?.email ?? 'kiran@example.com';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'K';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1411).withOpacity(0.8) : const Color(0xFFF2FDF7),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? const Color(0xFF1E3A2B) : const Color(0xFFC6F6D5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.neonGreen.withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00E676), Color(0xFF00B0FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.neonGreen.withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: GoogleFonts.outfit(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Colors.white, Color(0xFFE0E0E0)],
                  ).createShader(bounds),
                  child: Text(
                    name,
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : Colors.black,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.neonGreen.withOpacity(0.2),
                        AppTheme.neonGreen.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.neonGreen.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.shield_rounded,
                        color: AppTheme.neonGreen,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Smart Home Admin',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.neonGreen,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.edit_rounded,
              color: isDark ? Colors.white70 : Colors.black87,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppTheme.neonGreen,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF00E676), Color(0xFF69F0AE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSettingsGroup({
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111111) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF222222) : const Color(0xFFF0F0F0),
          width: 1,
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      color: isDark ? const Color(0xFF222222) : const Color(0xFFF0F0F0),
      indent: 64, // Matches the padding left of the title
    );
  }

  Widget _buildTrailingText(String text, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
        ),
        const SizedBox(width: 8),
        Icon(
          Icons.chevron_right_rounded,
          color: isDark ? Colors.white38 : Colors.black38,
          size: 20,
        ),
      ],
    );
  }

  Widget _buildSegmentedControl({
    required List<String> options,
    required String selectedValue,
    required ValueChanged<String> onChanged,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF222222) : const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((option) {
          final isSelected = option == selectedValue;
          return GestureDetector(
            onTap: () => onChanged(option),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.neonGreen : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                option,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white54 : Colors.black54),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActionTile({
    required bool isDark,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Widget trailing,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required bool isDark,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return InkWell(
      onTap: () {
        HapticService.selection();
        onChanged(!value);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Transform.scale(
              scale: 0.9,
              alignment: Alignment.centerRight,
              child: CupertinoSwitch(
                value: value,
                activeTrackColor: AppTheme.neonGreen,
                inactiveTrackColor: isDark
                    ? const Color(0xFF333333)
                    : const Color(0xFFE5E5EA),
                thumbColor: Colors.white,
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
