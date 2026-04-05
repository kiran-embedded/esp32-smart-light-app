import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/haptic_service.dart';
import '../../core/ui/responsive_layout.dart';
import 'pixel_led_border.dart';

class PremiumAppBar extends ConsumerStatefulWidget {
  final Widget title;
  final Widget? trailing;
  final double height;
  final Color backgroundColor;
  final VoidCallback? onTrailingTap;
  final double glowIntensity; // 0.0–1.0 reactive glow

  const PremiumAppBar({
    super.key,
    required this.title,
    this.trailing,
    this.height = 65,
    this.backgroundColor = Colors.black,
    this.onTrailingTap,
    this.glowIntensity = 0.5,
  });

  @override
  ConsumerState<PremiumAppBar> createState() => _PremiumAppBarState();
}

class _PremiumAppBarState extends ConsumerState<PremiumAppBar> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topPadding = MediaQuery.of(context).padding.top;
    final themeColors = [
      theme.colorScheme.primary,
      theme.colorScheme.secondary,
      theme.colorScheme.tertiary,
      theme.colorScheme.primary,
    ];

    return RepaintBoundary(
      child: PixelLedBorder(
        borderRadius: 35.r,
        strokeWidth: 0.5,
        colors: themeColors,
        duration: const Duration(seconds: 4),
        child: Container(
          height: widget.height + topPadding,
          padding: EdgeInsets.only(top: topPadding),
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(35.r)),
            border: Border(
              bottom: BorderSide(
                color: Colors.transparent,
                width: 0,
              ), // Border handled by PixelLedBorder now
            ),
            boxShadow: const [],
          ),
          child: SizedBox(
            height: widget.height,
            child: Stack(
              children: [
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(child: widget.title),
                        if (widget.trailing != null) ...[
                          SizedBox(width: 16.w),
                          GestureDetector(
                            onTap: () {
                              if (widget.onTrailingTap != null) {
                                HapticService.medium();
                                widget.onTrailingTap!();
                              }
                            },
                            child: widget.trailing!,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
