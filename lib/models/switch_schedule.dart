import 'package:flutter/material.dart';

class SwitchSchedule {
  final String id;
  final String relayId;
  final int hour;
  final int minute;
  final List<int> days; // 1 = Mon, 7 = Sun
  final bool targetState;
  final String targetNode; // 'relay1', 'relay2', 'relay3', 'relay4', 'ecoMode'
  final bool isEnabled;

  SwitchSchedule({
    required this.id,
    required this.relayId,
    required this.hour,
    required this.minute,
    required this.days,
    required this.targetState,
    this.targetNode = 'relay1',
    this.isEnabled = true,
  });

  SwitchSchedule copyWith({
    String? id,
    String? relayId,
    int? hour,
    int? minute,
    List<int>? days,
    bool? targetState,
    String? targetNode,
    bool? isEnabled,
  }) {
    return SwitchSchedule(
      id: id ?? this.id,
      relayId: relayId ?? this.relayId,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      days: days ?? this.days,
      targetState: targetState ?? this.targetState,
      targetNode: targetNode ?? this.targetNode,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'relayId': relayId,
      'hour': hour,
      'minute': minute,
      'days': days,
      'targetState': targetState,
      'targetNode': targetNode,
      'isEnabled': isEnabled,
    };
  }

  factory SwitchSchedule.fromJson(Map<String, dynamic> json) {
    return SwitchSchedule(
      id: json['id'] as String,
      relayId: json['relayId'] as String,
      hour: (json['hour'] as num).toInt(),
      minute: (json['minute'] as num).toInt(),
      days: List<int>.from(json['days'] ?? []),
      targetState: json['targetState'] as bool,
      targetNode:
          json['targetNode'] as String? ??
          json['relayId'] as String? ??
          'relay1',
      isEnabled: json['isEnabled'] as bool? ?? true,
    );
  }

  TimeOfDay get time => TimeOfDay(hour: hour, minute: minute);
}
