import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../widgets/common/pixel_led_border.dart';

class HelpSupportScreen extends ConsumerWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          "Help & Support",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: RepaintBoundary(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // How to Use Section
              _buildSectionHeader(context, "How to Use Nebula"),
              const SizedBox(height: 12),
              _buildExpandableTile(
                context,
                "Getting Started",
                "1. Power On: Connect your ESP32 device to a power source.\n2. Wi-Fi Sync: Ensure your phone is connected to the internet. The app will automatically sync with your configured Firebase switches.\n3. Indicators: The glowing border around the dashboard indicates system status.",
                1,
              ),
              _buildExpandableTile(
                context,
                "Using Voice Control",
                "Features a built-in smart assistant.\n\n• Tap the mic icon on the bottom bar.\n• Say commands like 'Turn on kitchen lights', 'Switch off relay 1', or 'Toggle fan'.\n• The assistant will speak back to confirm your action.",
                2,
              ),
              _buildExpandableTile(
                context,
                "Troubleshooting",
                "• Switch Not Responding: Check your internet connection or use the 'Retry' button.\n• Offline: Ensure your phone and ESP32 are connected to the network.\n• Reset: In rare cases, restart the ESP32 device.",
                3,
              ),
              _buildExpandableTile(
                context,
                "Firebase Setup Guide",
                "1. Project Creation: Visit console.firebase.google.com and create a project.\n2. Add App: Register an Android/iOS app to get the configuration.\n3. Realtime Database: Enable it and set rules to { \".read\": true, \".write\": true } for testing.\n4. Config Import: Copy the Database URL and API keys into the Nebula Setup screen.",
                4,
              ),
              _buildExpandableTile(
                context,
                "Schedules & Timers",
                "You can now automate your home!\n\n• Tap the Gear icon in the Switches tab.\n• Click '+' to add a new schedule.\n• Pick the switch, time, and days of the week.\n• The app will automatically sync this to the cloud.",
                5,
              ),
              const SizedBox(height: 30),
              // Contact & Socials
              _buildSectionHeader(context, "Contact & Resources"),
              const SizedBox(height: 16),
              _buildContactCard(
                context,
                title: "GitHub Repository",
                subtitle: "View source code & documentation",
                icon: Icons.code,
                color: Colors.purpleAccent,
                onTap: () => launchUrl(
                  Uri.parse(
                    "https://github.com/kiran-embedded/esp32-smart-light-app",
                  ),
                  mode: LaunchMode.externalApplication,
                ),
              ).animate().fadeIn(delay: 500.ms),
              const SizedBox(height: 12),
              _buildContactCard(
                context,
                title: "Email Support",
                subtitle: "kiran.cybergrid@gmail.com",
                icon: Icons.email_rounded,
                color: const Color(0xFF00FFC2),
                onTap: () => launchUrl(
                  Uri.parse(
                    "mailto:kiran.cybergrid@gmail.com?subject=Nebula App Support",
                  ),
                  mode: LaunchMode.externalApplication,
                ),
              ).animate().fadeIn(delay: 600.ms),
              const SizedBox(height: 40),
              Center(
                child: Text(
                  "Nebula Core © 2026",
                  style: GoogleFonts.outfit(
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
          color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
        ),
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildExpandableTile(
    BuildContext context,
    String title,
    String content,
    int index,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.onSurface.withOpacity(0.1),
            width: 0.5,
          ),
        ),
        child: Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            title: Text(
              title,
              style: GoogleFonts.roboto(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                child: Text(
                  content,
                  style: GoogleFonts.roboto(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                    height: 1.5,
                  ),
                ),
              ),
            ],
            iconColor: theme.colorScheme.primary,
            collapsedIconColor: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: (index * 50).ms);
  }

  Widget _buildContactCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: PixelLedBorder(
        colors: [
          color.withOpacity(0.5),
          Colors.transparent,
          color.withOpacity(0.5),
          Colors.transparent,
        ],
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurface.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: theme.colorScheme.onSurface.withOpacity(0.3),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}
