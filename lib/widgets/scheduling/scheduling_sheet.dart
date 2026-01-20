import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/switch_schedule.dart';
import '../../providers/switch_schedule_provider.dart';
import '../../providers/switch_provider.dart';
import '../../widgets/common/frosted_glass.dart';
import '../../services/haptic_service.dart';

class SchedulingSheet extends ConsumerStatefulWidget {
  const SchedulingSheet({super.key});

  @override
  ConsumerState<SchedulingSheet> createState() => _SchedulingSheetState();
}

class _SchedulingSheetState extends ConsumerState<SchedulingSheet> {
  @override
  Widget build(BuildContext context) {
    final schedules = ref.watch(switchScheduleProvider);
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SCHEDULES',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: theme.colorScheme.primary,
                  ),
                ),
                IconButton(
                  onPressed: () => _showAddScheduleDialog(context),
                  icon: Icon(
                    Icons.add_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Expanded(
            child: schedules.isEmpty
                ? _buildEmptyState(theme)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    itemCount: schedules.length,
                    itemBuilder: (context, index) {
                      final schedule = schedules[index];
                      return _buildScheduleTile(context, schedule, theme);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timer_outlined,
            size: 64,
            color: Colors.white.withOpacity(0.1),
          ),
          const SizedBox(height: 16),
          Text(
            'No schedules found',
            style: GoogleFonts.outfit(
              color: Colors.white.withOpacity(0.3),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleTile(
    BuildContext context,
    SwitchSchedule schedule,
    ThemeData theme,
  ) {
    final switches = ref.watch(switchDevicesProvider);
    final targetSwitch = switches.firstWhere(
      (s) => s.id == schedule.relayId,
      orElse: () => switches.first,
    );

    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: FrostedGlass(
        radius: BorderRadius.circular(20),
        padding: const EdgeInsets.all(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        child: Row(
          children: [
            // Time Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${schedule.hour.toString().padLeft(2, '0')}:${schedule.minute.toString().padLeft(2, '0')}',
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: schedule.targetState
                              ? Colors.green.withOpacity(0.2)
                              : Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          schedule.targetState ? 'ON' : 'OFF',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: schedule.targetState
                                ? Colors.greenAccent
                                : Colors.redAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    targetSwitch.nickname ?? targetSwitch.name,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Day selector indicators
                  Row(
                    children: List.generate(7, (i) {
                      final isSelected = schedule.days.contains(i + 1);
                      return Container(
                        margin: const EdgeInsets.only(right: 6),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? theme.colorScheme.primary.withOpacity(0.2)
                              : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : Colors.white10,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            days[i],
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : Colors.white24,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            // Switch & Actions
            Column(
              children: [
                Switch(
                  value: schedule.isEnabled,
                  activeColor: theme.colorScheme.primary,
                  onChanged: (val) {
                    ref
                        .read(switchScheduleProvider.notifier)
                        .updateSchedule(schedule.copyWith(isEnabled: val));
                    HapticService.selection();
                  },
                ),
                IconButton(
                  onPressed: () {
                    ref
                        .read(switchScheduleProvider.notifier)
                        .deleteSchedule(schedule.id);
                    HapticService.heavy();
                  },
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideX(begin: 0.1, end: 0);
  }

  void _showAddScheduleDialog(BuildContext context) async {
    final switches = ref.read(switchDevicesProvider);

    String selectedRelay = switches.first.id;
    bool targetState = true;
    TimeOfDay selectedTime = TimeOfDay.now();
    List<int> selectedDays = [1, 2, 3, 4, 5, 6, 7];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF121212),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Colors.white12),
          ),
          title: Text(
            'New Schedule',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Switch Selector
                Text(
                  'Select Switch',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Colors.white54,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedRelay,
                      dropdownColor: const Color(0xFF1E1E1E),
                      items: switches
                          .map(
                            (s) => DropdownMenuItem(
                              value: s.id,
                              child: Text(s.nickname ?? s.name),
                            ),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => selectedRelay = val!),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Time Selector
                Text(
                  'Time',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Colors.white54,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (time != null) setState(() => selectedTime = time);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          selectedTime.format(context),
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Icon(Icons.access_time_rounded),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Target State
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Action', style: GoogleFonts.outfit(fontSize: 14)),
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('ON'),
                          selected: targetState,
                          onSelected: (val) =>
                              setState(() => targetState = true),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('OFF'),
                          selected: !targetState,
                          onSelected: (val) =>
                              setState(() => targetState = false),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Days selector
                Text(
                  'Repeat Days',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Colors.white54,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(7, (index) {
                    final day = index + 1;
                    final isSelected = selectedDays.contains(day);
                    return ChoiceChip(
                      label: Text(['M', 'T', 'W', 'T', 'F', 'S', 'S'][index]),
                      selected: isSelected,
                      onSelected: (val) {
                        setState(() {
                          if (val)
                            selectedDays.add(day);
                          else if (selectedDays.length > 1)
                            selectedDays.remove(day);
                        });
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final schedule = SwitchSchedule(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  relayId: selectedRelay,
                  targetNode:
                      selectedRelay, // Sync targetNode with selectedRelay
                  hour: selectedTime.hour,
                  minute: selectedTime.minute,
                  days: selectedDays..sort(),
                  targetState: targetState,
                );
                ref.read(switchScheduleProvider.notifier).addSchedule(schedule);
                Navigator.pop(ctx);
                HapticService.heavy();
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
