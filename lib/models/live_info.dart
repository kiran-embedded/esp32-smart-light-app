class LiveInfo {
  final DateTime currentTime;
  final String weatherIcon;
  final double temperature;
  final String weatherDescription;
  final double acVoltage;
  final double current;
  final int teleId;
  final List<int> signals; // Signal strength for PIR1-P5

  LiveInfo({
    required this.currentTime,
    required this.weatherIcon,
    required this.temperature,
    required this.weatherDescription,
    required this.acVoltage,
    required this.current,
    this.teleId = 0,
    this.signals = const [0, 0, 0, 0, 0],
  });

  LiveInfo copyWith({
    DateTime? currentTime,
    String? weatherIcon,
    double? temperature,
    String? weatherDescription,
    double? acVoltage,
    double? current,
    int? teleId,
    List<int>? signals,
  }) {
    return LiveInfo(
      currentTime: currentTime ?? this.currentTime,
      weatherIcon: weatherIcon ?? this.weatherIcon,
      temperature: temperature ?? this.temperature,
      weatherDescription: weatherDescription ?? this.weatherDescription,
      acVoltage: acVoltage ?? this.acVoltage,
      current: current ?? this.current,
      teleId: teleId ?? this.teleId,
      signals: signals ?? this.signals,
    );
  }
}
