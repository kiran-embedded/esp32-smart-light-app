import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/switch_device.dart';
import '../common/frosted_glass.dart';

class ScheduleDialog extends ConsumerStatefulWidget {
  final SwitchDevice device;
  final Schedule? existingSchedule;

  const ScheduleDialog({
    super.key,
    required this.device,
    this.existingSchedule,
  });

  @override
  ConsumerState<ScheduleDialog> createState() => _ScheduleDialogState();
}

class _ScheduleDialogState extends ConsumerState<ScheduleDialog> {
  late ScheduleType _type;
  late List<int> _selectedDays;
  late TimeOfDay _startTime;
  TimeOfDay? _endTime;
  bool _isEnabled = true;

  @override
  void initState() {
    super.initState();
    if (widget.existingSchedule != null) {
      final schedule = widget.existingSchedule!;
      _type = schedule.type;
      _selectedDays = List.from(schedule.days);
      _startTime = TimeOfDay.fromDateTime(schedule.startTime);
      _endTime = schedule.endTime != null
          ? TimeOfDay.fromDateTime(schedule.endTime!)
          : null;
      _isEnabled = schedule.isEnabled;
    } else {
      _type = ScheduleType.daily;
      _selectedDays = List.generate(7, (i) => i);
      _startTime = const TimeOfDay(hour: 8, minute: 0);
    }
  }

  Future<void> _selectStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  Future<void> _selectEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? _startTime,
    );
    if (picked != null) {
      setState(() => _endTime = picked);
    }
  }

  void _toggleDay(int day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
    });
  }

  void _saveSchedule() {
    final now = DateTime.now();
    final startDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      _startTime.hour,
      _startTime.minute,
    );

    DateTime? endDateTime;
    if (_endTime != null) {
      endDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        _endTime!.hour,
        _endTime!.minute,
      );
    }

    final schedule = Schedule(
      id:
          widget.existingSchedule?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      type: _type,
      days: _selectedDays,
      startTime: startDateTime,
      endTime: endDateTime,
      isEnabled: _isEnabled,
      isOneTime: _type == ScheduleType.oneTime,
    );

    Navigator.of(context).pop(schedule);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Dialog(
      backgroundColor: Colors.transparent,
      child: FrostedGlass(
        padding: const EdgeInsets.all(24),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
          width: 1.2,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Schedule ${widget.device.name}',
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),
              // Schedule Type
              Text('Type', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              SegmentedButton<ScheduleType>(
                segments: const [
                  ButtonSegment(
                    value: ScheduleType.oneTime,
                    label: Text('One-time'),
                  ),
                  ButtonSegment(
                    value: ScheduleType.daily,
                    label: Text('Daily'),
                  ),
                  ButtonSegment(
                    value: ScheduleType.custom,
                    label: Text('Custom'),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (Set<ScheduleType> newSelection) {
                  setState(() => _type = newSelection.first);
                },
              ),
              const SizedBox(height: 24),
              // Days (for custom)
              if (_type == ScheduleType.custom) ...[
                Text('Days', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: List.generate(7, (index) {
                    final isSelected = _selectedDays.contains(index);
                    return FilterChip(
                      label: Text(days[index]),
                      selected: isSelected,
                      onSelected: (_) => _toggleDay(index),
                    );
                  }),
                ),
                const SizedBox(height: 24),
              ],
              // Start Time
              Text('Start Time', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              ListTile(
                title: Text(_startTime.format(context)),
                trailing: const Icon(Icons.access_time),
                onTap: _selectStartTime,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 16),
              // End Time (optional)
              Text('End Time (Optional)', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              ListTile(
                title: Text(_endTime?.format(context) ?? 'Not set'),
                trailing: const Icon(Icons.access_time),
                onTap: _selectEndTime,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 24),
              // Enable Toggle
              SwitchListTile(
                title: const Text('Enable Schedule'),
                value: _isEnabled,
                onChanged: (value) => setState(() => _isEnabled = value),
              ),
              const SizedBox(height: 24),
              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _saveSchedule,
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
