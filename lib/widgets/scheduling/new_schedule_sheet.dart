import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/switch_provider.dart';
import '../../providers/switch_schedule_provider.dart';
import '../../models/switch_schedule.dart';
import '../../services/haptic_service.dart';

class NewScheduleSheet extends ConsumerStatefulWidget {
  final SwitchSchedule? schedule;

  const NewScheduleSheet({super.key, this.schedule});

  @override
  ConsumerState<NewScheduleSheet> createState() => _NewScheduleSheetState();
}

class _NewScheduleSheetState extends ConsumerState<NewScheduleSheet> {
  String? _selectedDeviceId;
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _targetState = true;
  List<int> _selectedDays = [1, 2, 3, 4, 5, 6, 7]; // 1=Mon...7=Sun
  bool _isEveryday = true;

  @override
  void initState() {
    super.initState();
    
    if (widget.schedule != null) {
      _selectedDeviceId = widget.schedule!.relayId;
      _selectedTime = TimeOfDay(hour: widget.schedule!.hour, minute: widget.schedule!.minute);
      _targetState = widget.schedule!.targetState;
      _selectedDays = List.from(widget.schedule!.days);
      _isEveryday = _selectedDays.length == 7;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final devices = ref.read(switchDevicesProvider);
      if (devices.isNotEmpty && _selectedDeviceId == null) {
        setState(() => _selectedDeviceId = devices.first.id);
      }
    });
  }

  void _saveSchedule() {
    if (_selectedDeviceId == null) return;
    
    final newSchedule = SwitchSchedule(
      id: widget.schedule?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      relayId: _selectedDeviceId!,
      targetNode: _selectedDeviceId!, // Usually same as relayId unless specified
      hour: _selectedTime.hour,
      minute: _selectedTime.minute,
      targetState: _targetState,
      days: _selectedDays..sort(),
      isEnabled: widget.schedule?.isEnabled ?? true,
    );

    if (widget.schedule != null) {
      ref.read(switchScheduleProvider.notifier).updateSchedule(newSchedule);
    } else {
      ref.read(switchScheduleProvider.notifier).addSchedule(newSchedule);
    }
    
    Navigator.pop(context);
    HapticService.heavy();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final devices = ref.watch(switchDevicesProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111111) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with wave background and badges
            Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF181818) : const Color(0xFFF9FAFB),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'New ',
                                    style: GoogleFonts.outfit(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? Colors.white : Colors.black,
                                      height: 1.1,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Schedule',
                                    style: GoogleFonts.outfit(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.neonGreen,
                                      height: 1.1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Automate today for a smarter tomorrow',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Small Controls Badge
                      Transform.rotate(
                        angle: 0.1,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.neonGreen.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.neonGreen.withOpacity(0.3)),
                          ),
                          child: Text(
                            'Small Controls\nBig Comfort',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.neonGreen,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Step 1: Select Device
                    _buildSectionHeader('Step 1', 'Select Device', 'Choose the device you want to control', isDark),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: devices.length,
                        itemBuilder: (context, index) {
                          final device = devices[index];
                          final isSelected = _selectedDeviceId == device.id;
                          return GestureDetector(
                            onTap: () {
                              HapticService.selection();
                              setState(() => _selectedDeviceId = device.id);
                            },
                            child: Container(
                              width: 90,
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.neonGreen.withOpacity(0.1)
                                    : (isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F4F6)),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected ? AppTheme.neonGreen : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.lightbulb_outline,
                                    color: isSelected ? AppTheme.neonGreen : (isDark ? Colors.white54 : Colors.black54),
                                    size: 28,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    device.name,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                      color: isSelected
                                          ? (isDark ? Colors.white : Colors.black)
                                          : (isDark ? Colors.white70 : Colors.black87),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Step 2: Set Time
                    _buildSectionHeader('Step 2', 'Set Time', 'Choose when the action should run', isDark),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: _selectedTime,
                          builder: (context, child) {
                            return Theme(
                              data: theme.copyWith(
                                colorScheme: isDark
                                    ? ColorScheme.dark(
                                        primary: AppTheme.neonGreen,
                                        onPrimary: Colors.black,
                                        surface: const Color(0xFF1E1E1E),
                                        onSurface: Colors.white,
                                      )
                                    : const ColorScheme.light(
                                        primary: AppTheme.neonGreen,
                                        onPrimary: Colors.white,
                                        surface: Colors.white,
                                        onSurface: Colors.black,
                                      ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (time != null) {
                          setState(() => _selectedTime = time);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            _selectedTime.format(context),
                            style: GoogleFonts.outfit(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Step 3: Choose Action
                    _buildSectionHeader('Step 3', 'Choose Action', 'What should happen at this time?', isDark),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              HapticService.selection();
                              setState(() => _targetState = true);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: _targetState
                                    ? AppTheme.neonGreen
                                    : (isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F4F6)),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Text(
                                  'Turn ON',
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: _targetState
                                        ? Colors.black
                                        : (isDark ? Colors.white : Colors.black),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              HapticService.selection();
                              setState(() => _targetState = false);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: !_targetState
                                    ? Colors.redAccent
                                    : (isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F4F6)),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Text(
                                  'Turn OFF',
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: !_targetState
                                        ? Colors.white
                                        : (isDark ? Colors.white : Colors.black),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Step 4: Repeat Days
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionHeader('Step 4', 'Repeat Days', 'Select the days to repeat', isDark),
                        Row(
                          children: [
                            Text(
                              'Everyday',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Switch(
                              value: _isEveryday,
                              activeColor: AppTheme.neonGreen,
                              onChanged: (val) {
                                HapticService.selection();
                                setState(() {
                                  _isEveryday = val;
                                  if (val) {
                                    _selectedDays = [1, 2, 3, 4, 5, 6, 7];
                                  } else {
                                    _selectedDays = [];
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].asMap().entries.map((entry) {
                        final idx = entry.key;
                        final dayStr = entry.value;
                        final dayNum = idx + 1;
                        final isSelected = _selectedDays.contains(dayNum);
                        
                        return GestureDetector(
                          onTap: () {
                            HapticService.selection();
                            setState(() {
                              if (isSelected) {
                                _selectedDays.remove(dayNum);
                                _isEveryday = _selectedDays.length == 7;
                              } else {
                                _selectedDays.add(dayNum);
                                _isEveryday = _selectedDays.length == 7;
                              }
                            });
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? AppTheme.neonGreen
                                  : (isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F4F6)),
                            ),
                            child: Center(
                              child: Text(
                                dayStr,
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.black
                                      : (isDark ? Colors.white54 : Colors.black54),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),

                    // Confirm Button
                    GestureDetector(
                      onTap: _saveSchedule,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          color: AppTheme.neonGreen,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.neonGreen.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'Confirm Schedule',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String step, String title, String subtitle, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.neonGreen.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                step,
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.neonGreen,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
        ),
      ],
    );
  }
}
