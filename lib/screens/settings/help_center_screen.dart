import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../widgets/common/premium_app_bar.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Background Elements (Subtle Booklet Aesthetic)
            Positioned(
              top: -80,
              left: -80,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.cyanAccent.withOpacity(0.04),
                ),
              ),
            ),

            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(child: SizedBox(height: 100)),

                _buildBookletLabel("QUICK-START BOOKLET"),

                _buildBriefCard(
                  "⚡ CONTROLS",
                  "Tap nodes to toggle. Long-press to rename. Manual overrides expire in 15 mins.",
                  Icons.bolt_rounded,
                  Colors.cyanAccent,
                ),

                _buildBriefCard(
                  "🛡️ SECURITY",
                  "LDR: Dark-only. SCHEDULE: Time-only. HYBRID: Dark + Time-active.",
                  Icons.shield_rounded,
                  Colors.orangeAccent,
                ),

                _buildBriefCard(
                  "🧠 TUNING",
                  "FAST (1-hit). BALANCED (2-hits/15s). STRICT (3-hits/10s). Avoid ghost triggers.",
                  Icons.psychology_rounded,
                  Colors.lightGreenAccent,
                ),

                _buildBriefCard(
                  "🚨 AUDITS",
                  "Tap the siren icon for chronological breach mapping and forensic timestamps.",
                  Icons.fingerprint_rounded,
                  Colors.redAccent,
                ),

                _buildBriefCard(
                  "🔋 RELIABILITY",
                  "Boot-Guard (15s stabilization). Hardware Clock (Offline persistence). Batched data.",
                  Icons.auto_awesome_mosaic_rounded,
                  Colors.white38,
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),

            // Top Bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: PremiumAppBar(
                title: Text(
                  "USE BOOKLET",
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                    color: Colors.white,
                  ),
                ),
                leading: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookletLabel(String text) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: Colors.white24,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 30,
              height: 2,
              color: Colors.cyanAccent.withOpacity(0.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBriefCard(
    String title,
    String content,
    IconData icon,
    Color color,
  ) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 20, 20, 20),
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F0F),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.04)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Colors.white70,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      content,
                      style: GoogleFonts.outfit(
                        fontSize: 11.5,
                        color: Colors.white24,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
    );
  }
}
