import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../widgets/common/aurexa_app_bar.dart';
import '../../../providers/theme_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../main_screen.dart';
import 'greeting_section.dart';
import 'status_bubbles.dart';
import 'quick_actions.dart';
import 'home_switch_grid.dart';

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == AppThemeMode.dark;

    return Stack(
      children: [
        // Soft mint / sky ambient blobs (matches screenshot)
        if (!isDark) ...[
          Positioned(
            top: -40,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.neonGreen.withValues(alpha: 0.22),
                    AppTheme.neonGreen.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF93C5FD).withValues(alpha: 0.28),
                    const Color(0xFF93C5FD).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ],
        Column(
          children: [
            AurexaAppBar(
              actions: [
                _RoundIconButton(
                  isDark: isDark,
                  icon: isDark
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                  onTap: () =>
                      ref.read(themeProvider.notifier).toggleTheme(),
                ),
              ],
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final h = constraints.maxHeight;
                  final padH = 16.0;
                  final gap = (h * 0.015).clamp(8.0, 16.0);

                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: padH),
                    child: Column(
                      children: [
                        SizedBox(height: gap),
                        GreetingSection(),
                        SizedBox(height: gap * 1.2),
                        const StatusBubbles(),
                        SizedBox(height: gap * 1.2),
                        const Expanded(child: HomeSwitchGrid()),
                        SizedBox(height: gap * 1.2),
                        const QuickActions(),
                        SizedBox(height: gap * 1.5),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final VoidCallback onTap;

  const _RoundIconButton({
    required this.isDark,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark ? const Color(0xFF111111) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.07),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: isDark ? Colors.white : Colors.black87,
          size: 18,
        ),
      ),
    );
  }
}
