class GeofenceRule {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radius;
  final bool triggerOnEnter;
  final bool triggerOnExit;
  final String targetNode; // 'relay1', 'ecoMode', etc.
  final bool targetState;
  final bool isEnabled;
  final String? startTime; // Format: "HH:mm"
  final String? stopTime; // Format: "HH:mm"

  GeofenceRule({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.radius = 150.0,
    this.triggerOnEnter = true,
    this.triggerOnExit = false,
    required this.targetNode,
    required this.targetState,
    this.isEnabled = true,
    this.startTime,
    this.stopTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'triggerOnEnter': triggerOnEnter,
      'triggerOnExit': triggerOnExit,
      'targetNode': targetNode,
      'targetState': targetState,
      'isEnabled': isEnabled,
      'startTime': startTime,
      'stopTime': stopTime,
    };
  }

  factory GeofenceRule.fromJson(Map<String, dynamic> json) {
    return GeofenceRule(
      id: json['id'],
      name: json['name'] ?? 'Geofence Rule',
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      radius: json['radius']?.toDouble() ?? 150.0,
      triggerOnEnter: json['triggerOnEnter'] ?? true,
      triggerOnExit: json['triggerOnExit'] ?? false,
      targetNode: json['targetNode'] ?? 'relay1',
      targetState: json['targetState'] ?? true,
      isEnabled: json['isEnabled'] ?? true,
      startTime: json['startTime'],
      stopTime: json['stopTime'],
    );
  }

  GeofenceRule copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    double? radius,
    bool? triggerOnEnter,
    bool? triggerOnExit,
    String? targetNode,
    bool? targetState,
    bool? isEnabled,
    String? startTime,
    String? stopTime,
  }) {
    return GeofenceRule(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radius: radius ?? this.radius,
      triggerOnEnter: triggerOnEnter ?? this.triggerOnEnter,
      triggerOnExit: triggerOnExit ?? this.triggerOnExit,
      targetNode: targetNode ?? this.targetNode,
      targetState: targetState ?? this.targetState,
      isEnabled: isEnabled ?? this.isEnabled,
      startTime: startTime ?? this.startTime,
      stopTime: stopTime ?? this.stopTime,
    );
  }
}
