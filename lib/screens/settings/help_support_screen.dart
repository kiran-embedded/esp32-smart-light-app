import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/esp32_code_generator.dart';
import '../../core/constants/app_constants.dart';
import '../../services/file_service.dart';
import '../../providers/switch_provider.dart';

class HelpSupportScreen extends ConsumerWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F), // Deep premium black
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // PREMIUM HERO HEADER
          SliverAppBar(
            expandedHeight: 220,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF0F0F0F),
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                "Help & Support",
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Gradient background
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF1A1A1A), Color(0xFF0F0F0F)],
                      ),
                    ),
                  ),
                  // Subtle animated pulses
                  Positioned(
                    top: -50,
                    right: -50,
                    child:
                        Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: theme.colorScheme.primary.withOpacity(
                                  0.05,
                                ),
                              ),
                            )
                            .animate(onPlay: (c) => c.repeat())
                            .scale(
                              begin: const Offset(1, 1),
                              end: const Offset(1.5, 1.5),
                              duration: 4.seconds,
                              curve: Curves.easeInOut,
                            )
                            .fadeOut(duration: 4.seconds),
                  ),
                  Center(
                    child: Icon(
                      Icons.help_outline_rounded,
                      size: 80,
                      color: Colors.white.withOpacity(0.1),
                    ).animate().scale(duration: 800.ms).fadeIn(),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // QUICK RESOURCES GRID
                  _buildSectionHeader(context, "Quick Resources"),
                  const SizedBox(height: 12),
                  _buildResourceGrid(context, ref),

                  const SizedBox(height: 30),

                  // DETAILED GUIDES
                  _buildSectionHeader(context, "Tutorials & Guides"),
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

                  const SizedBox(height: 50),

                  // FOOTER
                  Center(
                    child: Column(
                      children: [
                        Text(
                          "Nebula Core © 2026",
                          style: GoogleFonts.outfit(
                            color: Colors.white.withOpacity(0.2),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "v1.2.0+19 • Production Stable",
                          style: GoogleFonts.outfit(
                            color: Colors.white.withOpacity(0.1),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.4),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title.toUpperCase(),
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.0,
            color: Colors.white.withOpacity(0.4),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1, end: 0);
  }

  Widget _buildResourceGrid(BuildContext context, WidgetRef ref) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: [
        _buildGridCard(
          context,
          "GitHub",
          "Source Code",
          Icons.code,
          Colors.purpleAccent,
          () => launchUrl(
            Uri.parse(
              "https://github.com/kiran-embedded/esp32-smart-light-app",
            ),
            mode: LaunchMode.externalApplication,
          ),
        ),
        _buildGridCard(
          context,
          "Email",
          "Get Support",
          Icons.email_rounded,
          const Color(0xFF00FFC2),
          () => launchUrl(
            Uri.parse(
              "mailto:kiran.cybergrid@gmail.com?subject=Nebula App Support",
            ),
            mode: LaunchMode.externalApplication,
          ),
        ),
        _buildGridCard(
          context,
          "Firmware",
          "C++ Templates",
          Icons.memory_rounded,
          Colors.orangeAccent,
          () => _showEsp32FirmwareDialog(context, ref),
        ),
        _buildGridCard(
          context,
          "Telegram",
          "Live Chat",
          Icons.send_rounded,
          Colors.blueAccent,
          () => launchUrl(
            Uri.parse("https://t.me/+918592910039"),
            mode: LaunchMode.externalApplication,
          ),
        ),
      ],
    );
  }

  Widget _buildGridCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withOpacity(0.06), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.03),
              blurRadius: 20,
              spreadRadius: -10,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.15), width: 1),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Colors.white.withOpacity(0.95),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.35),
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack).fadeIn();
  }

  Widget _buildExpandableTile(
    BuildContext context,
    String title,
    String content,
    int index,
  ) {
    return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withOpacity(0.05),
                width: 0.5,
              ),
            ),
            child: Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                title: Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(
                      content,
                      style: GoogleFonts.outfit(
                        color: Colors.white.withOpacity(0.6),
                        height: 1.5,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
                iconColor: Colors.white.withOpacity(0.5),
                collapsedIconColor: Colors.white.withOpacity(0.2),
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 500.ms, delay: (index * 80).ms)
        .slideY(begin: 0.1, end: 0);
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
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(
          'ESP32 Firmware',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "This code is optimized for Cloud-Only mode. Copy it to your Arduino IDE.",
                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      code,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: Color(0xFF00FFC2),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(color: Colors.white38),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00FFC2),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              final fileService = FileService();
              await fileService.copyToClipboard(code);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Code copied to clipboard'),
                    backgroundColor: Color(0xFF00FFC2),
                  ),
                );
                Navigator.of(context).pop();
              }
            },
            child: const Text('Copy Code'),
          ),
        ],
      ),
    );
  }
}
