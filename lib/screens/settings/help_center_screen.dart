import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../widgets/common/core_app_bar.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: Colors.black, // True AMOLED
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 110)),

              _buildBookletLabel(context, "QUICK-START BOOKLET"),

              _buildBriefCard(
                context,
                "CONTROLS",
                "Tap nodes to toggle. Long-press to rename. Manual overrides expire in 15 mins.",
                Icons.bolt_rounded,
                theme.colorScheme.primary, // Theme primary
                delayMs: 100,
              ),

              _buildBriefCard(
                context,
                "SECURITY",
                "LDR: Dark-only. SCHEDULE: Time-only. HYBRID: Dark + Time-active.",
                Icons.shield_rounded,
                Colors.orangeAccent,
                delayMs: 200,
              ),

              _buildBriefCard(
                context,
                "TUNING",
                "FAST (1-hit). BALANCED (2-hits/15s). STRICT (3-hits/10s). Avoid ghost triggers.",
                Icons.psychology_rounded,
                Colors.lightGreenAccent,
                delayMs: 300,
              ),

              _buildBriefCard(
                context,
                "AUDITS",
                "Tap the siren icon for chronological breach mapping and forensic timestamps.",
                Icons.fingerprint_rounded,
                Colors.redAccent,
                delayMs: 400,
              ),

              _buildBriefCard(
                context,
                "RELIABILITY",
                "Boot-Guard (15s stabilization). Hardware Clock (Offline persistence). Batched data.",
                Icons.auto_awesome_mosaic_rounded,
                theme.colorScheme.secondary,
                delayMs: 500,
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),

          // Top Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: CoreAppBar(
              title: Text(
                "HELP CENTER",
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: theme.colorScheme.onSurface,
                  size: 18,
                ),
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookletLabel(BuildContext context, String text) {
    final theme = Theme.of(context);
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.primary,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 30,
              height: 2,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),
    );
  }

  Widget _buildBriefCard(
    BuildContext context,
    String title,
    String content,
    IconData icon,
    Color color, {
    int delayMs = 0,
  }) {
    final theme = Theme.of(context);
    
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF111111), // Clean dark grey for amoled contrast
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF222222), width: 1.0),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
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
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      content,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: Colors.white60,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ).animate(delay: delayMs.ms).fadeIn(duration: 500.ms, curve: Curves.easeOut).slideY(begin: 0.1, curve: Curves.easeOutCubic),
    );
  }
}
