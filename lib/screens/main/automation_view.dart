import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/switch_schedule_provider.dart';
import '../../providers/switch_provider.dart';
import '../../widgets/scheduler/timer_card.dart';
import '../../widgets/scheduling/new_schedule_sheet.dart';
import '../../services/haptic_service.dart';

class AutomationView extends ConsumerStatefulWidget {
  const AutomationView({super.key});

  @override
  ConsumerState<AutomationView> createState() => _AutomationViewState();
}

class _AutomationViewState extends ConsumerState<AutomationView> {
  int _selectedTab = 0; // 0: Scheduled, 1: Countdown, 2: Sunrise/Sunset

  @override
  Widget build(BuildContext context) {
    final schedules = ref.watch(switchScheduleProvider);
    final devices = ref.watch(switchDevicesProvider);
    final topPadding = MediaQuery.of(context).padding.top;

    final activeSchedules = schedules.where((s) => s.isEnabled).toList();
    final inactiveSchedules = schedules.where((s) => !s.isEnabled).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16, topPadding + 16, 16, 140),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                // ─── HEADER CARD ───
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1117),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Clock icon
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.access_time_rounded,
                          color: Colors.white60,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Title
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Timers',
                              style: GoogleFonts.outfit(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Automate your switches\nfor a smarter home',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: Colors.white38,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Right badge
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'SET\nAUTOMATE\nRELAX',
                            textAlign: TextAlign.right,
                            style: GoogleFonts.outfit(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                              color: Colors.white24,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: 36,
                            height: 2,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.05),
                const SizedBox(height: 14),

                // ─── TAB SELECTOR ───
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1117),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Row(
                    children: [
                      _buildTab(0, Icons.access_time_rounded, 'Scheduled'),
                      _buildTab(1, Icons.hourglass_empty_rounded, 'Countdown'),
                      _buildTab(2, Icons.wb_twilight_rounded, 'Sunrise / Sunset'),
                    ],
                  ),
                ).animate().fadeIn(delay: 80.ms, duration: 350.ms),
                const SizedBox(height: 22),

                // ─── CONTENT (Only Scheduled is functional) ───
                if (_selectedTab == 0) ...[
                  // Active Timers
                  if (activeSchedules.isNotEmpty) ...[
                    _buildSectionHeader('Active Timers', '${activeSchedules.length} Active', const Color(0xFF4CAF50)),
                    const SizedBox(height: 12),
                    ...activeSchedules.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final s = entry.value;
                      final device = devices.where((d) => d.id == s.relayId).isNotEmpty
                          ? devices.firstWhere((d) => d.id == s.relayId)
                          : (devices.isNotEmpty ? devices.first : null);
                      return TimerCard(schedule: s)
                          .animate(delay: (idx * 60).ms)
                          .fadeIn(duration: 350.ms)
                          .slideY(begin: 0.05);
                    }),
                    const SizedBox(height: 16),
                  ],

                  // Inactive Timers
                  if (inactiveSchedules.isNotEmpty) ...[
                    _buildSectionHeader('Inactive Timers', '${inactiveSchedules.length} Inactive', Colors.white30),
                    const SizedBox(height: 12),
                    ...inactiveSchedules.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final s = entry.value;
                      final device = devices.where((d) => d.id == s.relayId).isNotEmpty
                          ? devices.firstWhere((d) => d.id == s.relayId)
                          : (devices.isNotEmpty ? devices.first : null);
                      return TimerCard(schedule: s)
                          .animate(delay: (idx * 60).ms)
                          .fadeIn(duration: 350.ms)
                          .slideY(begin: 0.05);
                    }),
                  ],

                  if (schedules.isEmpty)
                    _buildEmptyState(),
                ] else
                  _buildComingSoon(_selectedTab == 1 ? 'Countdown' : 'Sunrise / Sunset'),
              ],
            ),
          ),

          // ─── ADD TIMER FAB ───
          Positioned(
            bottom: 24,
            left: 32,
            right: 32,
            child: GestureDetector(
              onTap: () {
                HapticService.selection();
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const NewScheduleSheet(),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withOpacity(0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Add Timer',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(int index, IconData icon, String label) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticService.selection();
          setState(() => _selectedTab = index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF8B5CF6).withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isSelected ? const Color(0xFF8B5CF6).withOpacity(0.5) : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : Colors.white38,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                    color: isSelected ? Colors.white : Colors.white38,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String badge, Color badgeColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 16,
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: badgeColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            badge,
            style: GoogleFonts.outfit(
              fontSize: 10,
              color: badgeColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.timer_off_rounded, size: 52, color: Colors.white12),
          const SizedBox(height: 14),
          Text(
            'No timers yet',
            style: GoogleFonts.outfit(fontSize: 16, color: Colors.white38, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap "Add Timer" to automate\nyour switches',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 12, color: Colors.white24),
          ),
        ],
      ),
    );
  }

  Widget _buildComingSoon(String feature) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(Icons.construction_rounded, size: 48, color: Colors.white12),
          const SizedBox(height: 14),
          Text(
            '$feature coming soon',
            style: GoogleFonts.outfit(fontSize: 15, color: Colors.white38, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'This feature will be available\nin the next update.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 12, color: Colors.white24),
          ),
        ],
      ),
    );
  }
}
