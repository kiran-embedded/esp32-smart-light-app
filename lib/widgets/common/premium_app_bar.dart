import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/haptic_service.dart';

class PremiumAppBar extends ConsumerWidget {
  final Widget title;
  final Widget? trailing;
  final double height;
  final Color backgroundColor;
  final VoidCallback? onTrailingTap;

  const PremiumAppBar({
    super.key,
    required this.title,
    this.trailing,
    this.height = 65,
    this.backgroundColor = Colors.black,
    this.onTrailingTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      height: height + topPadding,
      padding: EdgeInsets.only(top: topPadding),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(35), // Even smoother
        ),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.primary.withOpacity(0.4),
            width: 0.5, // Razor sharp
          ),
        ),
        boxShadow: [
          // Outer Glow/Shadow
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.2),
            blurRadius: 35,
            offset: const Offset(0, 10),
            spreadRadius: -8,
          ),
          // Deep Base Shadow
          BoxShadow(
            color: Colors.black.withOpacity(0.9),
            blurRadius: 25,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            // Content
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: title),
                    if (trailing != null) ...[
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () {
                          if (onTrailingTap != null) {
                            HapticService.medium();
                            onTrailingTap!();
                          }
                        },
                        child: trailing!,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Subtle shine/gloss at top edge
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 1,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0),
                      Colors.white.withOpacity(0.08),
                      Colors.white.withOpacity(0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
