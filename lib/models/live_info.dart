class LiveInfo {
  final DateTime currentTime;
  final String weatherIcon;
  final double temperature;
  final String weatherDescription;
  final double acVoltage;
  final double current;

  LiveInfo({
    required this.currentTime,
    required this.weatherIcon,
    required this.temperature,
    required this.weatherDescription,
    required this.acVoltage,
    required this.current,
  });

  LiveInfo copyWith({
    DateTime? currentTime,
    String? weatherIcon,
    double? temperature,
    String? weatherDescription,
    double? acVoltage,
    double? current,
  }) {
    return LiveInfo(
      currentTime: currentTime ?? this.currentTime,
      weatherIcon: weatherIcon ?? this.weatherIcon,
      temperature: temperature ?? this.temperature,
      weatherDescription: weatherDescription ?? this.weatherDescription,
      acVoltage: acVoltage ?? this.acVoltage,
      current: current ?? this.current,
    );
  }
}

