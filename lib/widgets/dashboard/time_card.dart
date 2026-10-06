import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../core/ui/responsive_layout.dart';

class TimeCard extends ConsumerWidget {
  const TimeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authService = ref.watch(authServiceProvider);

    // Get current user first name
    final userName = authService.currentUser?.displayName?.split(' ').first ?? "User";

    // Format current date
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, MMMM dd').format(now);

    return Container(
      height: 180.h,
      decoration: BoxDecoration(
        color: const Color(0xFF090F0C).withOpacity(0.65),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: const Color(0x3D00FF66), width: 0.8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.r),
        child: Stack(
          children: [
            // Soft planet glow in bottom-right corner
            Positioned(
              bottom: -25.h,
              right: -25.w,
              child: Container(
                width: 90.w,
                height: 90.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      theme.colorScheme.primary.withOpacity(0.15),
                      theme.colorScheme.primary.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
            // Card Content
            Padding(
              padding: EdgeInsets.all(16.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back,',
                    style: GoogleFonts.outfit(
                      fontSize: 12.sp,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                  Text(
                    userName,
                    style: GoogleFonts.outfit(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  // Short green underline decoration
                  Container(
                    width: 24.w,
                    height: 1.8.h,
                    margin: EdgeInsets.only(top: 4.h),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(1.r),
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.primary.withOpacity(0.2),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Digital clock row
                  StreamBuilder(
                    stream: Stream.periodic(const Duration(seconds: 5)),
                    builder: (context, snapshot) {
                      final nowTime = DateTime.now();
                      final hourStr = DateFormat('hh').format(nowTime);
                      final minStr = DateFormat('mm').format(nowTime);
                      final ampm = DateFormat('a').format(nowTime);
                      
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          // Hours (White)
                          Text(
                            hourStr,
                            style: GoogleFonts.outfit(
                              fontSize: 38.sp,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: theme.colorScheme.primary.withOpacity(0.2),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ),
                          // Colon (Green)
                          Text(
                            ":",
                            style: GoogleFonts.outfit(
                              fontSize: 38.sp,
                              fontWeight: FontWeight.w900,
                              color: theme.colorScheme.primary,
                              shadows: [
                                Shadow(
                                  color: theme.colorScheme.primary.withOpacity(0.6),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                          ),
                          // Minutes (White)
                          Text(
                            minStr,
                            style: GoogleFonts.outfit(
                              fontSize: 38.sp,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: theme.colorScheme.primary.withOpacity(0.2),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6.r),
                              border: Border.all(color: theme.colorScheme.primary.withOpacity(0.5), width: 0.6),
                            ),
                            child: Text(
                              ampm,
                              style: GoogleFonts.outfit(
                                  fontSize: 8.sp,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const Spacer(),
                  // Calendar Pill
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF040705).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(color: Colors.white.withOpacity(0.04), width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_month_rounded,
                          color: theme.colorScheme.primary.withOpacity(0.8),
                          size: 13.sp,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          dateStr,
                          style: GoogleFonts.outfit(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
