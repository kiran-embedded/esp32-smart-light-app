class LiveInfo {
  final DateTime currentTime;
  final String weatherIcon;
  final double temperature;
  final String weatherDescription;
  final double acVoltage;
  final double current;
  final bool isDeviceOnline;
  final DateTime? deviceLastSeen;

  LiveInfo({
    required this.currentTime,
    required this.weatherIcon,
    required this.temperature,
    required this.weatherDescription,
    required this.acVoltage,
    required this.current,
    this.isDeviceOnline = false,
    this.deviceLastSeen,
  });

  LiveInfo copyWith({
    DateTime? currentTime,
    String? weatherIcon,
    double? temperature,
    String? weatherDescription,
    double? acVoltage,
    double? current,
    bool? isDeviceOnline,
    DateTime? deviceLastSeen,
  }) {
    return LiveInfo(
      currentTime: currentTime ?? this.currentTime,
      weatherIcon: weatherIcon ?? this.weatherIcon,
      temperature: temperature ?? this.temperature,
      weatherDescription: weatherDescription ?? this.weatherDescription,
      acVoltage: acVoltage ?? this.acVoltage,
      current: current ?? this.current,
      isDeviceOnline: isDeviceOnline ?? this.isDeviceOnline,
      deviceLastSeen: deviceLastSeen ?? this.deviceLastSeen,
    );
  }
}
