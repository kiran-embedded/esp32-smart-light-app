class SwitchHistoryEvent {
  final String id;
  final String relayId;
  final String? relayName; // Optional: fallback to manual resolution if null
  final bool state;
  final DateTime timestamp;
  final String triggeredBy; // 'app', 'voice', 'scheduler', 'manual'

  SwitchHistoryEvent({
    required this.id,
    required this.relayId,
    this.relayName,
    required this.state,
    required this.timestamp,
    this.triggeredBy = 'app',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'relayId': relayId,
      'relayName': relayName,
      'state': state,
      'timestamp': timestamp.toIso8601String(),
      'triggeredBy': triggeredBy,
    };
  }

  factory SwitchHistoryEvent.fromJson(Map<String, dynamic> json) {
    return SwitchHistoryEvent(
      id: json['id'] as String,
      relayId: json['relayId'] as String,
      relayName: json['relayName'] as String?,
      state: json['state'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
      triggeredBy: json['triggeredBy'] as String? ?? 'app',
    );
  }
}
