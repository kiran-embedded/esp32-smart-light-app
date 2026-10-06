import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../providers/live_info_provider.dart';
import '../../../providers/auth_provider.dart';

class TimeGreetingCard extends ConsumerWidget {
  const TimeGreetingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveInfo = ref.watch(liveInfoProvider);
    final time = liveInfo.currentTime;

    final String greeting = _getGreeting(time.hour);
    final String timeStr = DateFormat('hh:mm').format(time);
    final String amPm = DateFormat('a').format(time);
    final String dateStr = DateFormat('EEEE, MMM dd').format(time);

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.0),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E293B), // Dark blue/slate
            Color(0xFF0F172A), // Darker slate
            Color(0xFF2E1065), // Deep purple hint
          ],
          stops: [0.0, 0.5, 1.0],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Side: Greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting,',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                Consumer(
                  builder: (context, ref, child) {
                    final authService = ref.watch(authServiceProvider);
                    final userName = authService.currentUser?.displayName?.split(' ').first ?? 'User';
                    return Text(
                      userName,
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  '"Small controls,\na smarter tomorrow."',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Colors.white54,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          
          // Right Side: Date and Time
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateStr,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    timeStr,
                    style: GoogleFonts.outfit(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    amPm,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getGreeting(int hour) {
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }
}
