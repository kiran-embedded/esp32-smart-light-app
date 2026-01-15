class AppConstants {
  // Animation durations
  static const Duration introAnimationDuration = Duration(milliseconds: 1300);
  static const Duration shortAnimationDuration = Duration(milliseconds: 300);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 500);
  static const Duration longAnimationDuration = Duration(milliseconds: 800);

  // Robo animation
  static const double roboFloatAmplitude = 8.0;
  static const double roboFloatSpeed = 0.003;
  static const double roboSwayAmplitude = 3.0;
  static const double roboSwaySpeed = 0.002;
  static const Duration roboBlinkInterval = Duration(seconds: 3);
  static const Duration roboBlinkDuration = Duration(milliseconds: 200);

  // Grid layout
  static const int gridColumns = 2;
  static const double gridSpacing = 16.0;
  static const double tileBorderRadius = 24.0;
  static const double tilePadding = 20.0;

  // Glassmorphism
  static const double glassBlur = 20.0;
  static const double glassOpacity = 0.15;

  // Colors
  static const int neonCyan = 0xFF00FFFF;
  static const int neonBlue = 0xFF0080FF;
  static const int electricCyan = 0xFF00FAFF;
  static const int softViolet = 0xFFBB86FC;
  static const int deepSpaceNavy = 0xFF0A0E21;
  static const int deepSpacePurple = 0xFF1A0B2E;
  static const int darkGraphite = 0xFF1A1A1A;
  static const int glossyBlack = 0xFF000000;

  // MQTT
  static const String mqttBroker = 'broker.hivemq.com';
  static const int mqttPort = 1883;
  static const String mqttClientId = 'nebula_core_app';

  // ESP32
  static const String defaultDeviceId = '79215788';
  static const int defaultGpioPin = 2;
  static const String defaultWifiSsid = 'YOUR_WIFI_SSID';
  static const String defaultWifiPassword = 'YOUR_WIFI_PASSWORD';

  // ESP32 GPIO Pin Management
  // Safe GPIO pins - Recommended for general use (green)
  static const List<int> safeGpioPins = [
    2,
    4,
    5,
    12,
    13,
    14,
    15,
    16,
    17,
    18,
    19,
    21,
    22,
    23,
    25,
    26,
    27,
    32,
    33,
  ];

  // Caution GPIO pins - Can be used but have special functions (yellow)
  static const List<int> cautionGpioPins = [
    0, // Boot mode selection (pulled up)
    2, // On-board LED, Boot mode selection
    34, 35, 36, 39, // Input only pins (ADC)
  ];

  // Unsafe/Reserved GPIO pins - Avoid using (red)
  static const List<int> unsafeGpioPins = [
    1, // Serial TX (USB)
    3, // Serial RX (USB)
    6, 7, 8, 9, 10, 11, // Flash memory (SPI)
  ];

  // GPIO Pin Descriptions
  static const Map<int, String> gpioPinDescriptions = {
    0: 'Boot Button (pulled up)',
    1: '⚠️ UART0 TX (Serial)',
    2: 'On-board LED / Touch2',
    3: '⚠️ UART0 RX (Serial)',
    4: 'General Purpose',
    5: 'General Purpose',
    6: '🚫 Flash SPI CLK',
    7: '🚫 Flash SPI D0',
    8: '🚫 Flash SPI D1',
    9: '🚫 Flash SPI D2',
    10: '🚫 Flash SPI D3',
    11: '🚫 Flash SPI CMD',
    12: 'HSPI MISO / Touch5',
    13: 'HSPI MOSI / Touch4',
    14: 'HSPI CLK / Touch6',
    15: 'HSPI CS / Touch3',
    16: 'General Purpose',
    17: 'General Purpose',
    18: 'VSPI CLK',
    19: 'VSPI MISO',
    21: 'I2C SDA',
    22: 'I2C SCL',
    23: 'VSPI MOSI',
    25: 'DAC1 / ADC2_8',
    26: 'DAC2 / ADC2_9',
    27: 'Touch7 / ADC2_7',
    32: 'Touch9 / ADC1_4',
    33: 'Touch8 / ADC1_5',
    34: '📥 Input Only / ADC1_6',
    35: '📥 Input Only / ADC1_7',
    36: '📥 Input Only / ADC1_0',
    39: '📥 Input Only / ADC1_3',
  };

  // Firebase Paths
  static const String firebaseDevicesPath = 'devices';
  static const String firebaseSwitchesPath = 'switches';
  static const String firebaseTelemetryPath = 'telemetry';
  static const String firebaseCommandsPath = 'commands';
}
