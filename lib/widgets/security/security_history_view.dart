import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/security_log.dart';

class SecurityHistoryView extends StatelessWidget {
  final List<SecurityLog> logs;

  // Cache DateFormat instances
  static final DateFormat _timeFormat = DateFormat('hh:mm a');
  static final DateFormat _dateFormat = DateFormat('MMM dd');

  const SecurityHistoryView({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Text(
            'No activity logs yet',
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final log = logs[index];
        final dateTime = DateTime.fromMillisecondsSinceEpoch(log.timestamp);
        final time = _timeFormat.format(dateTime);
        final date = _dateFormat.format(dateTime);

        return RepaintBoundary(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.history_rounded,
                  color: Colors.cyanAccent,
                  size: 20,
                ),
                title: Text(
                  'Motion in ${log.sensor}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      time,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      date,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }, childCount: logs.length),
    );
  }
}
