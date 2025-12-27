import '../models/switch_device.dart';

class Esp32CodeGenerator {
  static String generateFirmware({
    required List<SwitchDevice> devices,
    required String wifiSsid,
    required String wifiPassword,
    required String mqttBroker,
    required int mqttPort,
  }) {
    final buffer = StringBuffer();

    // Header
    buffer.writeln('#include <WiFi.h>');
    buffer.writeln('#include <PubSubClient.h>');
    buffer.writeln('#include <ArduinoJson.h>');
    buffer.writeln('#include <time.h>');
    buffer.writeln('');
    buffer.writeln('// NEBULA CORE - Auto-generated ESP32 Firmware');
    buffer.writeln('// Generated for ${devices.length} switch(es)');
    buffer.writeln('');

    // WiFi credentials
    buffer.writeln('const char* ssid = "$wifiSsid";');
    buffer.writeln('const char* password = "$wifiPassword";');
    buffer.writeln('');

    // MQTT settings
    buffer.writeln('const char* mqtt_server = "$mqttBroker";');
    buffer.writeln('const int mqtt_port = $mqttPort;');
    buffer.writeln('');

    // WiFi and MQTT clients
    buffer.writeln('WiFiClient espClient;');
    buffer.writeln('PubSubClient client(espClient);');
    buffer.writeln('');

    // GPIO pins
    buffer.writeln('// GPIO Pin Definitions');
    for (final device in devices) {
      buffer.writeln(
        'const int GPIO_${device.id.toUpperCase()} = ${device.gpioPin};',
      );
    }
    buffer.writeln('');

    // Device states
    buffer.writeln('// Device States');
    for (final device in devices) {
      buffer.writeln('bool state_${device.id} = false;');
    }
    buffer.writeln('');

    // Setup function
    buffer.writeln('void setup() {');
    buffer.writeln('  Serial.begin(115200);');
    buffer.writeln('  ');
    buffer.writeln('  // Initialize GPIO pins');
    for (final device in devices) {
      buffer.writeln('  pinMode(GPIO_${device.id.toUpperCase()}, OUTPUT);');
      buffer.writeln('  digitalWrite(GPIO_${device.id.toUpperCase()}, LOW);');
    }
    buffer.writeln('  ');
    buffer.writeln('  // Connect to WiFi');
    buffer.writeln('  WiFi.begin(ssid, password);');
    buffer.writeln('  while (WiFi.status() != WL_CONNECTED) {');
    buffer.writeln('    delay(500);');
    buffer.writeln('    Serial.print(".");');
    buffer.writeln('  }');
    buffer.writeln('  Serial.println("WiFi connected");');
    buffer.writeln('  ');
    buffer.writeln('  // Setup MQTT');
    buffer.writeln('  client.setServer(mqtt_server, mqtt_port);');
    buffer.writeln('  client.setCallback(callback);');
    buffer.writeln('  ');
    buffer.writeln('  // Connect to MQTT');
    buffer.writeln('  reconnect();');
    buffer.writeln('  ');
    buffer.writeln('  // Subscribe to topics');
    for (final device in devices) {
      buffer.writeln('  client.subscribe("${device.mqttTopic}/set");');
    }
    buffer.writeln('}');
    buffer.writeln('');

    // Loop function
    buffer.writeln('void loop() {');
    buffer.writeln('  if (!client.connected()) {');
    buffer.writeln('    reconnect();');
    buffer.writeln('  }');
    buffer.writeln('  client.loop();');
    buffer.writeln('  ');
    buffer.writeln('  // Check schedules');
    _generateScheduleCode(buffer, devices);
    buffer.writeln('  ');
    buffer.writeln('  delay(100);');
    buffer.writeln('}');
    buffer.writeln('');

    // MQTT callback
    buffer.writeln(
      'void callback(char* topic, byte* payload, unsigned int length) {',
    );
    buffer.writeln('  String message = "";');
    buffer.writeln('  for (int i = 0; i < length; i++) {');
    buffer.writeln('    message += (char)payload[i];');
    buffer.writeln('  }');
    buffer.writeln('  ');
    buffer.writeln('  // Parse and handle messages');
    for (final device in devices) {
      buffer.writeln('  if (String(topic) == "${device.mqttTopic}/set") {');
      buffer.writeln('    if (message == "ON") {');
      buffer.writeln(
        '      digitalWrite(GPIO_${device.id.toUpperCase()}, HIGH);',
      );
      buffer.writeln('      state_${device.id} = true;');
      buffer.writeln(
        '      client.publish("${device.mqttTopic}/state", "ON");',
      );
      buffer.writeln('    } else if (message == "OFF") {');
      buffer.writeln(
        '      digitalWrite(GPIO_${device.id.toUpperCase()}, LOW);',
      );
      buffer.writeln('      state_${device.id} = false;');
      buffer.writeln(
        '      client.publish("${device.mqttTopic}/state", "OFF");',
      );
      buffer.writeln('    }');
      buffer.writeln('  }');
    }
    buffer.writeln('}');
    buffer.writeln('');

    // Reconnect function
    buffer.writeln('void reconnect() {');
    buffer.writeln('  while (!client.connected()) {');
    buffer.writeln('    if (client.connect("ESP32Client")) {');
    buffer.writeln('      Serial.println("MQTT connected");');
    buffer.writeln('    } else {');
    buffer.writeln('      delay(5000);');
    buffer.writeln('    }');
    buffer.writeln('  }');
    buffer.writeln('}');
    buffer.writeln('');

    // Schedule checking function
    _generateScheduleFunction(buffer, devices);

    return buffer.toString();
  }

  static String generateFirebaseFirmware({
    required List<SwitchDevice> devices,
    required String wifiSsid,
    required String wifiPassword,
    required String firebaseApiKey,
    required String firebaseDatabaseUrl,
    String? deviceId,
  }) {
    final buffer = StringBuffer();
    final totalRelays = devices.length;

    buffer.writeln('/*');
    buffer.writeln(
      ' * NEBULA CORE – ESP32 $totalRelays-Relay (Firebase Control)',
    );
    buffer.writeln(' * --------------------------------------------');
    buffer.writeln(' * App  → Firebase (commands)');
    buffer.writeln(' * ESP32 → Firebase (telemetry)');
    buffer.writeln(' * Auto-generated for $totalRelays switch(es)');
    buffer.writeln(' */');
    buffer.writeln('');
    buffer.writeln('#include <WiFi.h>');
    buffer.writeln('#include <Firebase_ESP_Client.h>');
    buffer.writeln('#include <ArduinoJson.h>');
    buffer.writeln('');
    buffer.writeln('#include "addons/TokenHelper.h"');
    buffer.writeln('#include "addons/RTDBHelper.h"');
    buffer.writeln('');
    buffer.writeln('// ================== WIFI ==================');
    buffer.writeln('#define WIFI_SSID "$wifiSsid"');
    buffer.writeln('#define WIFI_PASS "$wifiPassword"');
    buffer.writeln('');
    buffer.writeln('// ================== FIREBASE ==================');
    buffer.writeln('#define API_KEY "$firebaseApiKey"');
    buffer.writeln('#define DATABASE_URL "$firebaseDatabaseUrl"');
    buffer.writeln('');
    buffer.writeln('// ================== PINS ==================');
    for (int i = 0; i < devices.length; i++) {
      buffer.writeln('#define RELAY${i + 1} ${devices[i].gpioPin}');
    }
    buffer.writeln('#define VOLTAGE_SENSOR 34');
    buffer.writeln('');
    buffer.writeln('// ================== OBJECTS ==================');
    buffer.writeln('FirebaseData fbdo;');
    buffer.writeln('FirebaseData fbStream;');
    buffer.writeln('FirebaseAuth auth;');
    buffer.writeln('FirebaseConfig config;');
    buffer.writeln('');
    buffer.writeln('String deviceId;');
    buffer.writeln(
      'bool relayState[$totalRelays] = {${List.filled(totalRelays, '0').join(', ')}};',
    );
    buffer.writeln('');
    buffer.writeln('unsigned long lastTelemetry = 0;');
    buffer.writeln('const unsigned long telemetryInterval = 5000;');
    buffer.writeln('');
    buffer.writeln('// ================== WIFI ==================');
    buffer.writeln('void connectWiFi() {');
    buffer.writeln('  if (WiFi.status() == WL_CONNECTED) return;');
    buffer.writeln('  WiFi.begin(WIFI_SSID, WIFI_PASS);');
    buffer.writeln('  while (WiFi.status() != WL_CONNECTED) delay(300);');
    buffer.writeln('}');
    buffer.writeln('');
    buffer.writeln(
      '// ================== VOLTAGE (OPTIONAL) ==================',
    );
    buffer.writeln('float readACVoltage() {');
    buffer.writeln('  int minV = 4095, maxV = 0;');
    buffer.writeln('  for (int i = 0; i < 600; i++) {');
    buffer.writeln('    int v = analogRead(VOLTAGE_SENSOR);');
    buffer.writeln('    minV = min(minV, v);');
    buffer.writeln('    maxV = max(maxV, v);');
    buffer.writeln('    delayMicroseconds(120);');
    buffer.writeln('  }');
    buffer.writeln('  float ptp = (maxV - minV) * (3.3 / 4095.0);');
    buffer.writeln('  float rms = (ptp / 2.0) * 0.707 * 100.0;');
    buffer.writeln('  if (rms < 10) rms = 0;');
    buffer.writeln('  return rms;');
    buffer.writeln('}');
    buffer.writeln('');
    buffer.writeln('// ================== FIREBASE STREAM ==================');
    buffer.writeln('void startFirebaseStream() {');
    buffer.writeln('  String path = "/devices/" + deviceId + "/commands";');
    buffer.writeln('  Firebase.RTDB.beginStream(&fbStream, path.c_str());');
    buffer.writeln('  Serial.println("Firebase command stream started");');
    buffer.writeln('}');
    buffer.writeln('');
    buffer.writeln('// ================== HANDLE COMMANDS ==================');
    buffer.writeln('void handleFirebaseCommands() {');
    buffer.writeln('  if (!Firebase.RTDB.readStream(&fbStream)) return;');
    buffer.writeln('  if (!fbStream.streamAvailable()) return;');
    buffer.writeln('');
    buffer.writeln('  String path = fbStream.dataPath();');
    buffer.writeln('  Serial.print("CMD ");');
    buffer.writeln('  Serial.print(path);');
    buffer.writeln('  Serial.print(" -> ");');
    buffer.writeln('');
    buffer.writeln('  // FULL SYNC');
    buffer.writeln('  if (path == "/") {');
    buffer.writeln('    FirebaseJson &json = fbStream.jsonObject();');
    buffer.writeln('    FirebaseJsonData d;');
    for (int i = 0; i < totalRelays; i++) {
      buffer.writeln(
        '    if (json.get(d, "relay${devices[i].id}")) relayState[$i] = d.intValue;',
      );
    }
    buffer.writeln('    Serial.println("FULL SYNC");');
    buffer.writeln('  }');
    buffer.writeln('  // SINGLE RELAY');
    buffer.writeln('  else {');
    buffer.writeln('    int v = fbStream.intData();');
    buffer.writeln('    Serial.println(v);');
    for (int i = 0; i < totalRelays; i++) {
      buffer.writeln(
        '    if (path == "/relay${devices[i].id}") relayState[$i] = v;',
      );
    }
    buffer.writeln('  }');
    buffer.writeln('');
    for (int i = 0; i < totalRelays; i++) {
      buffer.writeln('  digitalWrite(RELAY${i + 1}, relayState[$i]);');
    }
    buffer.writeln('');
    buffer.writeln('  FirebaseJson out;');
    for (int i = 0; i < totalRelays; i++) {
      buffer.writeln('  out.set("relay${devices[i].id}", relayState[$i]);');
    }
    buffer.writeln('');
    buffer.writeln('  String tPath = "/devices/" + deviceId + "/telemetry";');
    buffer.writeln('  Firebase.RTDB.updateNode(&fbdo, tPath.c_str(), &out);');
    buffer.writeln('}');
    buffer.writeln('');
    buffer.writeln('// ================== SETUP ==================');
    buffer.writeln('void setup() {');
    buffer.writeln('  Serial.begin(115200);');
    buffer.writeln('  deviceId = String((uint32_t)ESP.getEfuseMac(), HEX);');
    buffer.writeln('');
    for (int i = 0; i < totalRelays; i++) {
      buffer.writeln('  pinMode(RELAY${i + 1}, OUTPUT);');
      buffer.writeln('  digitalWrite(RELAY${i + 1}, LOW);');
    }
    buffer.writeln('');
    buffer.writeln('  analogReadResolution(12);');
    buffer.writeln('  connectWiFi();');
    buffer.writeln('');
    buffer.writeln('  config.api_key = API_KEY;');
    buffer.writeln('  config.database_url = DATABASE_URL;');
    buffer.writeln('  config.token_status_callback = tokenStatusCallback;');
    buffer.writeln('');
    buffer.writeln('  Firebase.signUp(&config, &auth, "", "");');
    buffer.writeln('  Firebase.begin(&config, &auth);');
    buffer.writeln('  Firebase.reconnectWiFi(true);');
    buffer.writeln('');
    buffer.writeln('  startFirebaseStream();');
    buffer.writeln(
      '  Serial.println("NEBULA CORE $totalRelays-RELAY (Firebase) READY 🚀");',
    );
    buffer.writeln('}');
    buffer.writeln('');
    buffer.writeln('// ================== LOOP ==================');
    buffer.writeln('void loop() {');
    buffer.writeln('  if (WiFi.status() != WL_CONNECTED) connectWiFi();');
    buffer.writeln('');
    buffer.writeln('  if (Firebase.ready()) {');
    buffer.writeln('    handleFirebaseCommands();');
    buffer.writeln('');
    buffer.writeln('    if (millis() - lastTelemetry > telemetryInterval) {');
    buffer.writeln('      lastTelemetry = millis();');
    buffer.writeln('');
    buffer.writeln('      FirebaseJson j;');
    for (int i = 0; i < totalRelays; i++) {
      buffer.writeln('      j.set("relay${devices[i].id}", relayState[$i]);');
    }
    buffer.writeln('      j.set("voltage_ac", readACVoltage());');
    buffer.writeln('');
    buffer.writeln('      String p = "/devices/" + deviceId + "/telemetry";');
    buffer.writeln('      Firebase.RTDB.updateNode(&fbdo, p.c_str(), &j);');
    buffer.writeln('    }');
    buffer.writeln('  }');
    buffer.writeln('}');

    return buffer.toString();
  }

  static void _generateScheduleCode(
    StringBuffer buffer,
    List<SwitchDevice> devices,
  ) {
    buffer.writeln('  // Schedule execution');
    buffer.writeln('  unsigned long currentMillis = millis();');
    buffer.writeln('  int currentHour = (currentMillis / 3600000) % 24;');
    buffer.writeln('  int currentMinute = (currentMillis / 60000) % 60;');
    buffer.writeln('  int currentDay = (currentMillis / 86400000) % 7;');
    buffer.writeln('  ');
    buffer.writeln('  checkSchedules(currentHour, currentMinute, currentDay);');
  }

  static void _generateScheduleFunction(
    StringBuffer buffer,
    List<SwitchDevice> devices,
  ) {
    buffer.writeln('void checkSchedules(int hour, int minute, int day) {');
    for (final device in devices) {
      if (device.schedules.isNotEmpty) {
        buffer.writeln('  // Schedules for ${device.name}');
        for (final schedule in device.schedules) {
          if (!schedule.isEnabled) continue;

          final startHour = schedule.startTime.hour;
          final startMinute = schedule.startTime.minute;

          if (schedule.type == ScheduleType.daily) {
            buffer.writeln(
              '  if (hour == $startHour && minute == $startMinute) {',
            );
            buffer.writeln(
              '    digitalWrite(GPIO_${device.id.toUpperCase()}, HIGH);',
            );
            buffer.writeln('    state_${device.id} = true;');
            buffer.writeln(
              '    client.publish("${device.mqttTopic}/state", "ON");',
            );
            buffer.writeln('  }');
            if (schedule.endTime != null) {
              final endHour = schedule.endTime!.hour;
              final endMinute = schedule.endTime!.minute;
              buffer.writeln(
                '  if (hour == $endHour && minute == $endMinute) {',
              );
              buffer.writeln(
                '    digitalWrite(GPIO_${device.id.toUpperCase()}, LOW);',
              );
              buffer.writeln('    state_${device.id} = false;');
              buffer.writeln(
                '    client.publish("${device.mqttTopic}/state", "OFF");',
              );
              buffer.writeln('  }');
            }
          } else if (schedule.type == ScheduleType.custom) {
            final daysList = schedule.days
                .map((d) => d.toString())
                .join(' || day == ');
            buffer.writeln(
              '  if ((day == $daysList) && hour == $startHour && minute == $startMinute) {',
            );
            buffer.writeln(
              '    digitalWrite(GPIO_${device.id.toUpperCase()}, HIGH);',
            );
            buffer.writeln('    state_${device.id} = true;');
            buffer.writeln(
              '    client.publish("${device.mqttTopic}/state", "ON");',
            );
            buffer.writeln('  }');
            if (schedule.endTime != null) {
              final endHour = schedule.endTime!.hour;
              final endMinute = schedule.endTime!.minute;
              buffer.writeln(
                '  if ((day == $daysList) && hour == $endHour && minute == $endMinute) {',
              );
              buffer.writeln(
                '    digitalWrite(GPIO_${device.id.toUpperCase()}, LOW);',
              );
              buffer.writeln('    state_${device.id} = false;');
              buffer.writeln(
                '    client.publish("${device.mqttTopic}/state", "OFF");',
              );
              buffer.writeln('  }');
            }
          } else if (schedule.type == ScheduleType.oneTime) {
            final scheduleDate = schedule.startTime;
            buffer.writeln(
              '  // One-time schedule for ${scheduleDate.year}-${scheduleDate.month.toString().padLeft(2, '0')}-${scheduleDate.day.toString().padLeft(2, '0')}',
            );
            buffer.writeln(
              '  // Note: One-time schedules require date tracking - implement separately',
            );
          }
        }
      }
    }
    buffer.writeln('}');
  }
}
