import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/haptic_service.dart';
import '../../screens/main/main_screen.dart';
import '../../core/ui/responsive_layout.dart';

class SystemActiveBanner extends ConsumerWidget {
  final bool isSystemActive;

  const SystemActiveBanner({
    super.key,
    required this.isSystemActive,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dotColor = isSystemActive ? theme.colorScheme.primary : Colors.grey;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF090F0C).withOpacity(0.65),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: const Color(0x3D00FF66), width: 0.8),
      ),
      child: Stack(
        children: [
          // Pulse Dot in top-right corner
          Positioned(
            top: 12.h,
            right: 12.w,
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: dotColor.withOpacity(0.6),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(
                  begin: 0.3,
                  end: 1.0,
                  duration: 1200.ms,
                ),
          ),
          
          // Banner content row
          Padding(
            padding: EdgeInsets.all(14.r),
            child: Row(
              children: [
                PulsingRadarIndicator(isActive: isSystemActive),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSystemActive ? 'SYSTEM ACTIVE' : 'SYSTEM DISARMED',
                        style: GoogleFonts.outfit(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w900,
                          color: isSystemActive ? theme.colorScheme.primary : Colors.grey,
                          letterSpacing: 1.0,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        isSystemActive
                            ? 'Everything is running smoothly.'
                            : 'Sensors online. Perimeter is disarmed.',
                        style: GoogleFonts.outfit(
                          fontSize: 9.sp,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    HapticService.selection();
                    // Switch to Security Tab (index 2)
                    ref.read(mainScreenStateProvider.notifier).state = 2;
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF040705).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: Colors.white.withOpacity(0.04), width: 0.8),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'View Details',
                          style: GoogleFonts.outfit(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: theme.colorScheme.primary,
                          size: 10.sp,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Pulsing Radar Dot Indicator
class PulsingRadarIndicator extends StatefulWidget {
  final bool isActive;
  const PulsingRadarIndicator({super.key, this.isActive = true});

  @override
  State<PulsingRadarIndicator> createState() => _PulsingRadarIndicatorState();
}

class _PulsingRadarIndicatorState extends State<PulsingRadarIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.isActive ? theme.colorScheme.primary : Colors.grey.withOpacity(0.5);

    return SizedBox(
      width: 24,
      height: 24,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Outer pulsing ring
              Opacity(
                opacity: (1.0 - _controller.value).clamp(0.0, 1.0),
                child: Container(
                  width: 8 + 16 * _controller.value,
                  height: 8 + 16 * _controller.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withOpacity(0.5), width: 1.5),
                  ),
                ),
              ),
              // Inner pulsing ring
              Opacity(
                opacity: (1.0 - ((_controller.value + 0.5) % 1.0)).clamp(0.0, 1.0),
                child: Container(
                  width: 8 + 16 * ((_controller.value + 0.5) % 1.0),
                  height: 8 + 16 * ((_controller.value + 0.5) % 1.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withOpacity(0.3), width: 1.0),
                  ),
                ),
              ),
              // Center solid dot
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.8),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
