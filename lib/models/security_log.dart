class SecurityLog {
  final String id;
  final String sensor;
  final int timestamp;

  SecurityLog({
    required this.id,
    required this.sensor,
    required this.timestamp,
  });

  factory SecurityLog.fromMap(String id, Map<dynamic, dynamic> map) {
    return SecurityLog(
      id: id,
      sensor: map['sensor'] ?? 'Unknown',
      timestamp: map['timestamp'] ?? 0,
    );
  }
}
