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

    buffer.write('''
/*
 * NEBULA CORE – COMPLETE SYSTEM (SERVER RACK EDITION)
 * ------------------------------------------------
 * Optimized for High-End Power Management & Safety
 */

#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include <WiFiUdp.h>
#include <ArduinoOTA.h>

#include "addons/TokenHelper.h"
#include "addons/RTDBHelper.h"

#define WIFI_SSID "$wifiSsid"
#define WIFI_PASS "$wifiPassword"

#define API_KEY      "$firebaseApiKey"
#define DATABASE_URL "$firebaseDatabaseUrl"

''');

    for (int i = 0; i < devices.length; i++) {
      buffer.writeln('#define RELAY${i + 1} ${devices[i].gpioPin}');
    }

    buffer.write('''
#define VOLTAGE_SENSOR 34
#define LED_PIN_RED   19
#define LED_PIN_GREEN 16
#define LED_PIN_BLUE  17

#define ADC_MAX 4095.0
#define VREF 3.3
float calibrationFactor = 313.3; 

#define REPORT_INTERVAL 10000
#define VOLTAGE_DELTA 3.0

FirebaseData fbTele;
FirebaseData fbStream;
FirebaseAuth auth;
FirebaseConfig config;

String deviceId;
bool relayState[$totalRelays] = {0};
bool updateRelays = false;    
bool forceTelemetry = false;  

volatile float sharedVoltage = 0.0;
unsigned long lastTelemetryTime = 0;
float lastReportedVoltage = 0;
volatile bool isInternetLive = false; 

// --- DEADMAN SAFETY VARIABLES ---
bool safetyTripped = false;
unsigned long lastActivity = 0;

void initLEDs() {
  pinMode(LED_PIN_RED, OUTPUT);
  pinMode(LED_PIN_GREEN, OUTPUT);
  pinMode(LED_PIN_BLUE, OUTPUT);
  digitalWrite(LED_PIN_RED, LOW);
  digitalWrite(LED_PIN_GREEN, LOW);
  digitalWrite(LED_PIN_BLUE, LOW);
}

void applyRelays() {
''');

    for (int i = 0; i < devices.length; i++) {
      buffer.writeln(
        '  digitalWrite(RELAY${i + 1}, relayState[$i] ? HIGH : LOW);',
      );
    }

    buffer.write('''
  lastActivity = millis();
}

void connectivityTask(void *pvParameters) {
  for (;;) {
    int delayTime = 8000;
    if (WiFi.status() != WL_CONNECTED) {
      isInternetLive = false;
      delayTime = 1000;
    } else if (!isInternetLive) {
      WiFiClient client;
      client.setTimeout(1500);
      if (client.connect("8.8.8.8", 53)) {
        isInternetLive = true;
        client.stop();
      } else {
        delayTime = 3000;
      }
    }
    vTaskDelay(delayTime / portTICK_PERIOD_MS);
  }
}

void voltageTask(void *pvParameters) {
  float adcOffset = 0;
  long sum = 0;
  for (int i = 0; i < 500; i++) sum += analogRead(VOLTAGE_SENSOR);
  adcOffset = sum / 500.0;
  float localVoltage = 0;

  for (;;) {
    double rmsSum = 0; int rmsCount = 0;
    int rmsMin = 4095; int rmsMax = 0;
    unsigned long burstStart = millis();
    while (millis() - burstStart < 40) {
      int raw = analogRead(VOLTAGE_SENSOR);
      if (raw < rmsMin) rmsMin = raw;
      if (raw > rmsMax) rmsMax = raw;
      float v = (raw - adcOffset) * (VREF / ADC_MAX);
      rmsSum += v * v;
      rmsCount++;
    }
    if (rmsCount > 0) {
      int p2p = rmsMax - rmsMin;
      float rms = sqrt(rmsSum / rmsCount);
      float instVoltage = 0.0;
      if (p2p >= 60 && rms >= 0.020) instVoltage = rms * calibrationFactor;
      if (localVoltage == 0) localVoltage = instVoltage;
      else localVoltage = (instVoltage * 0.1) + (localVoltage * 0.9);
      if (localVoltage < 5.0) localVoltage = 0.0;
      sharedVoltage = localVoltage;
    }
    vTaskDelay(100 / portTICK_PERIOD_MS);
  }
}

void streamCallback(FirebaseStream data) {
  isInternetLive = true;
  String path = data.dataPath();
  if (path == "/") {
    FirebaseJson *json = data.jsonObjectPtr();
    FirebaseJsonData d;
''');

    for (int i = 0; i < devices.length; i++) {
      buffer.writeln(
        '    if (json->get(d, "relay${i + 1}")) relayState[$i] = d.intValue;',
      );
    }

    buffer.write('''
  } else {
    int intVal = data.intData();
''');

    for (int i = 0; i < devices.length; i++) {
      buffer.writeln(
        '    if (path == "/relay${i + 1}") relayState[$i] = intVal;',
      );
    }

    buffer.write('''
  }
  updateRelays = true;
  forceTelemetry = true; 
}

void setup() {
  Serial.begin(115200);
''');

    for (int i = 0; i < devices.length; i++) {
      buffer.writeln('  pinMode(RELAY${i + 1}, OUTPUT);');
      buffer.writeln('  digitalWrite(RELAY${i + 1}, LOW);');
    }

    buffer.write('''
  initLEDs();
  WiFi.begin(WIFI_SSID, WIFI_PASS);
  while (WiFi.status() != WL_CONNECTED) delay(100);
  
  deviceId = String((uint32_t)ESP.getEfuseMac(), HEX);
  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;
  Firebase.begin(&config, &auth);
  Firebase.RTDB.beginStream(&fbStream, ("/devices/" + deviceId + "/commands").c_str());
  Firebase.RTDB.setStreamCallback(&fbStream, streamCallback, NULL);
  
  xTaskCreatePinnedToCore(connectivityTask, "ConnTask", 2048, NULL, 1, NULL, 0);
  xTaskCreatePinnedToCore(voltageTask, "VoltageTask", 10000, NULL, 1, NULL, 0);
  lastActivity = millis();
}

void loop() {
  if (updateRelays) { applyRelays(); updateRelays = false; }
  
  if (forceTelemetry || (millis() - lastTelemetryTime > REPORT_INTERVAL)) {
    if (Firebase.ready()) {
      FirebaseJson j;
''');

    for (int i = 0; i < devices.length; i++) {
      buffer.writeln('      j.set("relay${i + 1}", relayState[$i]);');
    }

    buffer.write('''
      j.set("voltage", sharedVoltage);
      if (Firebase.RTDB.updateNode(&fbTele, ("/devices/" + deviceId + "/telemetry").c_str(), &j)) {
        lastTelemetryTime = millis();
        forceTelemetry = false;
      }
    }
  }

  // --- DEADMAN SAFETY ENGINE ---
  if (!isInternetLive && (millis() - lastActivity > 60000)) {
    if (!safetyTripped) {
      for (int i = 0; i < $totalRelays; i++) relayState[i] = false;
      updateRelays = true;
      safetyTripped = true;
    }
  } else {
    safetyTripped = false;
  }
  delay(5);
}
''');

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
          }
        }
      }
    }
    buffer.writeln('}');
  }
}
