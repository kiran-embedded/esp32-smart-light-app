import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';

class HelpCenterSheet extends StatefulWidget {
  const HelpCenterSheet({super.key});

  @override
  State<HelpCenterSheet> createState() => _HelpCenterSheetState();
}

class _HelpCenterSheetState extends State<HelpCenterSheet> {
  late PageController _pageController;
  double _currentPage = 0.0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page!;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final List<Widget> pages = [
      _buildBookPage(
        isDark: isDark,
        title: 'Step 1: Firebase Login',
        icon: Icons.login_rounded,
        color: AppTheme.accentBlue,
        content: 'Aurexa uses Firebase for secure, real-time smart home control. Log in with your Google account on the startup screen to establish a secure link between your phone and the cloud infrastructure.',
      ),
      _buildBookPage(
        isDark: isDark,
        title: 'Step 2: Firebase Setup',
        icon: Icons.cloud_done_rounded,
        color: AppTheme.neonGreen,
        content: 'Go to console.firebase.google.com and create a project. Add an Android app with package name: com.aurexa.app. Download google-services.json and paste its contents during the app onboarding process.',
      ),
      _buildBookPage(
        isDark: isDark,
        title: 'Step 3: Flash Firmware',
        icon: Icons.memory_rounded,
        color: AppTheme.neonPurple,
        content: 'Navigate to Settings > ESP32 Flasher. Connect your ESP32 via USB to a PC, copy the provided firmware, and flash it to enable dual-core real-time performance.',
      ),
      _buildBookPage(
        isDark: isDark,
        title: 'How do I control my devices?',
        icon: Icons.touch_app_rounded,
        color: AppTheme.neonGreen,
        content: 'On the Home screen, tap any switch card to toggle it. You can also use the "All On" or "All Off" buttons at the top to control all 4 relays simultaneously with a fluid animation.',
      ),
      _buildBookPage(
        isDark: isDark,
        title: 'How do I set timers?',
        icon: Icons.access_time_rounded,
        color: AppTheme.neonPurple,
        content: 'Go to the Timers tab. You can set individual turn-on and turn-off schedules for each relay. The ESP32 handles these automatically using NTP time.',
      ),
      _buildBookPage(
        isDark: isDark,
        title: 'What do the ESP32 LEDs mean?',
        icon: Icons.lightbulb_rounded,
        color: AppTheme.accentBlue,
        content: 'Red means Wi-Fi disconnected. Yellow means Cloud/Firebase disconnected. Pulsing Blue (heartbeat) means everything is healthy and connected perfectly.',
      ),
      _buildBookPage(
        isDark: isDark,
        title: 'What if the internet drops?',
        icon: Icons.wifi_off_rounded,
        color: Colors.redAccent,
        content: 'Our industrial-grade firmware automatically attempts to reconnect in the background using a 15-second loop without freezing the device or your scheduled timers.',
      ),
      _buildSupportPage(isDark),
    ];

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1411) : const Color(0xFFF2FDF7),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(
          color: isDark ? const Color(0xFF1E3A2B) : const Color(0xFFC6F6D5),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black26,
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.neonGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    color: Colors.black,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Help Center',
                  style: GoogleFonts.outfit(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: pages.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                // Book page turn effect
                double value = 1.0;
                if (_pageController.position.haveDimensions) {
                  value = _pageController.page! - index;
                  value = (1 - (value.abs() * .5)).clamp(0.0, 1.0);
                }
                final isLeaving = (index - _currentPage) < 0;
                final rotationY = isLeaving ? (pi / 2) * (_currentPage - index) : 0.0;
                
                return Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001) // perspective
                    ..rotateY(rotationY),
                  alignment: isLeaving ? Alignment.centerRight : Alignment.centerLeft,
                  child: Opacity(
                    opacity: value,
                    child: pages[index],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // Pagination Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              pages.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage.round() == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage.round() == index
                      ? AppTheme.neonGreen
                      : (isDark ? Colors.white24 : Colors.black26),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildBookPage({
    required bool isDark,
    required String title,
    required IconData icon,
    required Color color,
    required String content,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111111) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF222222) : const Color(0xFFE5E5EA),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 48),
          ),
          const SizedBox(height: 32),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            content,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: isDark ? Colors.white70 : Colors.black87,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportPage(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111111) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF222222) : const Color(0xFFE5E5EA),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Need More Help?',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 32),
          _buildContactCard(
            isDark: isDark,
            icon: Icons.email_rounded,
            title: 'Email Support',
            subtitle: 'support@aurexa.app',
            color: AppTheme.accentBlue,
          ),
          const SizedBox(height: 16),
          _buildContactCard(
            isDark: isDark,
            icon: Icons.chat_bubble_rounded,
            title: 'Live Chat',
            subtitle: 'Available 24/7 for premium users',
            color: AppTheme.neonGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF333333) : const Color(0xFFEAEAEA),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white38 : Colors.black38),
        ],
      ),
    );
  }
}
