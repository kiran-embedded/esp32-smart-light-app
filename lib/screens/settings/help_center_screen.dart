import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/ui/responsive_layout.dart';
import '../../widgets/common/premium_app_bar.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              const PremiumAppBar(title: Text("HELP CENTER")),
              SliverToBoxAdapter(child: SizedBox(height: 100.h)),

              _buildSection(
                context,
                "🛡️ SECURITY SYSTEM",
                "Nebula Core uses a Neural Grid of PIR sensors to guard your habitat. Arm the system from the Security Hub to receive critical siren alarms.",
              ),

              _buildSection(
                context,
                "⚡ NEURAL AUTOMATION",
                "Enable 'Neural Light' in the Security Hub. When any motion is detected, all habitat relays will turn ON for 10 minutes automatically—even if the app is closed.",
              ),

              _buildSection(
                context,
                "🎙️ VOICE ASSISTANT",
                "Tap the Robo or use the bottom pill to speak commands. Try:\n• 'Turn on Switch 1'\n• 'Arm security'\n• 'Switch to Dark theme'",
              ),

              _buildSection(
                context,
                "🧠 ADVANCED AI",
                "Nebula AI is a local Quantum intelligence. Ask it math, code, or trivia questions. It runs 100% on-device for total privacy.",
              ),

              _buildSection(
                context,
                "💾 SYSTEM RESET",
                "If controls feel laggy, tap 'Reset Connection' in Settings. This clears stale Firebase sockets and restores low-latency logic.",
              ),

              SliverToBoxAdapter(child: SizedBox(height: 50.h)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.horizontalPadding,
        vertical: 12,
      ),
      sliver: SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.cyanAccent,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                content,
                style: GoogleFonts.outfit(
                  fontSize: 13.sp,
                  color: Colors.white70,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ).animate().fadeIn().slideY(begin: 0.2),
    );
  }
}
