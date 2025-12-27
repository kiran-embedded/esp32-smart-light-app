class SwitchDevice {
  final String id;
  final String name;
  final String? nickname;
  final bool isActive;
  final double voltage;
  final bool isPending; // Tracks if command is in flight
  final double current;
  final bool isConnected;
  final String icon;
  final int gpioPin;
  final String mqttTopic;
  final List<Schedule> schedules;

  SwitchDevice({
    required this.id,
    required this.name,
    this.nickname,
    this.isActive = false,
    this.isPending = false,
    this.voltage = 0.0,
    this.current = 0.0,
    this.isConnected = false,
    required this.icon,
    required this.gpioPin,
    required this.mqttTopic,
    this.schedules = const [],
  });

  SwitchDevice copyWith({
    String? id,
    String? name,
    String? nickname,
    bool? isActive,
    bool? isPending,
    double? voltage,
    double? current,
    bool? isConnected,
    String? icon,
    int? gpioPin,
    String? mqttTopic,
    List<Schedule>? schedules,
  }) {
    return SwitchDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      nickname: nickname ?? this.nickname,
      isActive: isActive ?? this.isActive,
      isPending: isPending ?? this.isPending,
      voltage: voltage ?? this.voltage,
      current: current ?? this.current,
      isConnected: isConnected ?? this.isConnected,
      icon: icon ?? this.icon,
      gpioPin: gpioPin ?? this.gpioPin,
      mqttTopic: mqttTopic ?? this.mqttTopic,
      schedules: schedules ?? this.schedules,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nickname': nickname,
      'isActive': isActive,
      'voltage': voltage,
      'current': current,
      'isConnected': isConnected,
      'icon': icon,
      'gpioPin': gpioPin,
      'mqttTopic': mqttTopic,
      'schedules': schedules.map((s) => s.toJson()).toList(),
    };
  }

  factory SwitchDevice.fromJson(Map<String, dynamic> json) {
    return SwitchDevice(
      id: json['id'] as String,
      name: json['name'] as String,
      nickname: json['nickname'] as String?,
      isActive: json['isActive'] as bool? ?? false,
      voltage: (json['voltage'] as num?)?.toDouble() ?? 0.0,
      current: (json['current'] as num?)?.toDouble() ?? 0.0,
      isConnected: json['isConnected'] as bool? ?? false,
      icon: json['icon'] as String,
      gpioPin: json['gpioPin'] as int? ?? 2,
      mqttTopic: json['mqttTopic'] as String,
      schedules:
          (json['schedules'] as List<dynamic>?)
              ?.map((s) => Schedule.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class Schedule {
  final String id;
  final ScheduleType type;
  final List<int> days; // 0 = Monday, 6 = Sunday
  final DateTime startTime;
  final DateTime? endTime;
  final bool isEnabled;
  final bool isOneTime;

  Schedule({
    required this.id,
    required this.type,
    required this.days,
    required this.startTime,
    this.endTime,
    this.isEnabled = true,
    this.isOneTime = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'days': days,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'isEnabled': isEnabled,
      'isOneTime': isOneTime,
    };
  }

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['id'] as String,
      type: ScheduleType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ScheduleType.daily,
      ),
      days: (json['days'] as List<dynamic>).map((d) => d as int).toList(),
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      isEnabled: json['isEnabled'] as bool? ?? true,
      isOneTime: json['isOneTime'] as bool? ?? false,
    );
  }

  Schedule copyWith({
    String? id,
    ScheduleType? type,
    List<int>? days,
    DateTime? startTime,
    DateTime? endTime,
    bool? isEnabled,
    bool? isOneTime,
  }) {
    return Schedule(
      id: id ?? this.id,
      type: type ?? this.type,
      days: days ?? this.days,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isEnabled: isEnabled ?? this.isEnabled,
      isOneTime: isOneTime ?? this.isOneTime,
    );
  }
}

enum ScheduleType { oneTime, daily, custom }
