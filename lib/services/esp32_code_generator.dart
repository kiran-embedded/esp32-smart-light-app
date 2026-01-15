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

    // Use user's preferred robust firmware template + WebServer additions
    buffer.write('''
/*
 * NEBULA CORE – HYBRID SYSTEM (PRO LED + DIRECT HTTP + HOTSPOT)
 * ---------------------------------------------------
 * GREEN: Server Heartbeat (Brief blip every 2s) -> System OK
 * RED:   Double-Flash Alert -> Error/No Internet
 * BLUE:  Instant Flash -> Switch Activity
 * WHITE: Web Server Request
 * YELLOW: Access Point (Hotspot) Mode Active
 */

#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include <WebServer.h>
#include <ESPmDNS.h>
#include <WiFiUdp.h>
#include <ArduinoOTA.h>

#include "addons/TokenHelper.h"
#include "addons/RTDBHelper.h"

/* ================= CONFIGURATION ================= */
#define WIFI_SSID "$wifiSsid"
#define WIFI_PASS "$wifiPassword"

// Emergency Hotspot Config
#define AP_SSID    "Nebula-Core-ESP32"
#define AP_PASS    "nebula123"

// OTA Credentials
#define OTA_HOSTNAME "Nebula-Core-ESP32"
#define OTA_PASSWORD "admin"

// Firebase
#define API_KEY      "$firebaseApiKey"
#define DATABASE_URL "$firebaseDatabaseUrl"

/* ================= PIN DEFINITIONS ================= */
''');

    for (int i = 0; i < devices.length; i++) {
      buffer.writeln('#define RELAY${i + 1} ${devices[i].gpioPin}');
    }

    buffer.write('''
#define VOLTAGE_SENSOR 34

// RGB Status LED (Common Cathode)
#define LED_PIN_RED   19
#define LED_PIN_GREEN 16
#define LED_PIN_BLUE  17

/* ================= AC CALIBRATION ================= */
#define ADC_MAX 4095.0
#define VREF 3.3
float calibrationFactor = 313.3; 

/* ================= RMS & SMOOTHING ================= */
#define P2P_THRESHOLD 60
#define RMS_THRESHOLD 0.020
#define SMOOTHING_ALPHA 0.1 

/* ================= TELEMETRY SETTINGS ================= */
#define REPORT_INTERVAL 10000     // 10 Seconds normal interval
#define VOLTAGE_DELTA 3.0         // 3 Volts change

/* ================= LED TIMING CONFIG ================= */
#define BLINK_FAST    200
#define BLINK_MEDIUM  400
#define BLINK_SLOW    700
#define FLASH_DUR     100

/* ================= OBJECTS & GLOBALS ================= */
FirebaseData fbTele;
FirebaseData fbStream;
FirebaseAuth auth;
FirebaseConfig config;
WebServer server(80); // Direct HTTP Server

String deviceId;
bool relayState[$totalRelays] = {${List.filled(totalRelays, '0').join(', ')}};
bool updateRelays = false;    // Trigger hardware update
bool forceTelemetry = false;  // Trigger immediate upload
bool isAPMode = false;        // Track if AP mode is active

volatile float sharedVoltage = 0.0;

unsigned long lastTelemetryTime = 0;
float lastReportedVoltage = 0;
unsigned long lastStreamKeepAlive = 0;

// LED State Variables
enum SystemState {
  STATE_IDLE,
  STATE_WIFI_CONNECTING,
  STATE_WIFI_CONNECTED,
  STATE_AP_MODE,
  STATE_FIREBASE_CONNECTING,
  STATE_FIREBASE_CONNECTED,
  STATE_FIREBASE_DISCONNECTED,
  STATE_OTA_UPDATING 
};

SystemState currentLedState = STATE_IDLE;
unsigned long lastBlinkTime = 0;
bool blinkState = false; 
bool isFlashing = false;
bool isOTAActive = false; 
unsigned long flashStartTime = 0;

/* ================= LED SYSTEM FUNCTIONS ================= */

// Helper: Set RGB Color (One at a time)
void setRGB(bool r, bool g, bool b) {
  digitalWrite(LED_PIN_RED, r);
  digitalWrite(LED_PIN_GREEN, g);
  digitalWrite(LED_PIN_BLUE, b);
}

// Trigger: Call this on user interaction
void triggerActivityLED() {
  if (isOTAActive) return; 
  isFlashing = true;
  flashStartTime = millis();
  // INSTANT WHITE FLASH for LOCAL / BLUE for CLOUD
  if (isAPMode) setRGB(HIGH, HIGH, HIGH);
  else setRGB(LOW, LOW, HIGH); 
}

// Logic: Determine current system status
void updateSystemState() {
  if (isOTAActive) {
    currentLedState = STATE_OTA_UPDATING;
    return;
  }
  
  if (WiFi.getMode() & WIFI_AP) {
    currentLedState = STATE_AP_MODE;
    return;
  }

  if (WiFi.status() != WL_CONNECTED) {
    currentLedState = STATE_WIFI_CONNECTING;
  }
  else if (Firebase.ready()) {
    currentLedState = STATE_FIREBASE_CONNECTED;
  } 
  else if (auth.token.uid == "") {
     currentLedState = STATE_FIREBASE_CONNECTING;
  }
  else {
    currentLedState = STATE_FIREBASE_DISCONNECTED;
  }
}

// Logic: Drive the LED based on status
void loopLED() {
  unsigned long currentMillis = millis();
  updateSystemState();

  // 1. OTA Override -> FAST RED STROBE (Warning: Updating)
  if (currentLedState == STATE_OTA_UPDATING) {
    if ((currentMillis % 100) < 50) setRGB(HIGH, LOW, LOW);
    else setRGB(LOW, LOW, LOW);
    return;
  }

  // 2. Activity Flash Override -> SOLID BLUE/WHITE
  if (isFlashing) {
    if (currentMillis - flashStartTime >= FLASH_DUR) {
      isFlashing = false; 
    } else {
      if (isAPMode) setRGB(HIGH, HIGH, HIGH);
      else setRGB(LOW, LOW, HIGH); 
      return; 
    }
  }

  // 3. Base State Animation
  switch (currentLedState) {
    case STATE_WIFI_CONNECTING: // Blue Fast Blink
      if (currentMillis - lastBlinkTime >= BLINK_FAST) {
        lastBlinkTime = currentMillis;
        blinkState = !blinkState;
        setRGB(LOW, LOW, blinkState ? HIGH : LOW);
      }
      break;

    case STATE_AP_MODE: // YELLOW (Red+Green) Heartbeat
      if ((currentMillis % 2000) < 100) {
        setRGB(HIGH, HIGH, LOW); 
      } else {
        setRGB(LOW, LOW, LOW);  
      }
      break;

    case STATE_FIREBASE_CONNECTING: // Blue Medium Blink
      if (currentMillis - lastBlinkTime >= BLINK_MEDIUM) {
        lastBlinkTime = currentMillis;
        blinkState = !blinkState;
        setRGB(LOW, LOW, blinkState ? HIGH : LOW);
      }
      break;

    case STATE_FIREBASE_CONNECTED: // GREEN HEARTBEAT
      // Blips Green ON for 100ms every 2000ms (System OK)
      if ((currentMillis % 2000) < 100) {
        setRGB(LOW, HIGH, LOW); 
      } else {
        setRGB(LOW, LOW, LOW);  
      }
      break;

    case STATE_FIREBASE_DISCONNECTED: // RED DOUBLE-FLASH ALERT
      // Pattern: Blip (100ms) - Off (100ms) - Blip (100ms) - Off (700ms)
      // Cycle = 1000ms
      {
        unsigned long mod = currentMillis % 1000;
        if (mod < 100 || (mod > 200 && mod < 300)) {
          setRGB(HIGH, LOW, LOW); // Red ON
        } else {
          setRGB(LOW, LOW, LOW);  // Red OFF
        }
      }
      break;

    default: 
      setRGB(LOW, LOW, LOW); // Off
      break;
  }
}

/* ================= HARDWARE CONTROL ================= */
void applyRelays() {
  digitalWrite(RELAY1, relayState[0] ? LOW : HIGH);
  digitalWrite(RELAY2, relayState[1] ? LOW : HIGH);
  digitalWrite(RELAY3, relayState[2] ? LOW : HIGH);
  digitalWrite(RELAY4, relayState[3] ? LOW : HIGH);
}

/* ================= WEB SERVER HANDLERS ================= */
void handleRoot() {
  server.send(200, "text/plain", "NEBULA CORE CONTROLLER ONLINE");
}

void handleStatus() {
  StaticJsonDocument<512> doc;
  doc["deviceId"] = deviceId;
  doc["voltage"] = sharedVoltage;
  doc["uptime"] = millis() / 1000;
  doc["mode"] = isAPMode ? "hotspot" : "cloud";
  
  JsonArray relays = doc.createNestedArray("relays");
  for (int i = 0; i < $totalRelays; i++) {
    relays.add(relayState[i]);
  }
  
  String response;
  serializeJson(doc, response);
  server.send(200, "application/json", response);
}

void handleSet() {
  if (server.hasArg("relay") && server.hasArg("state")) {
    int r = server.arg("relay").toInt();
    int s = server.arg("state").toInt();
    
    if (r >= 1 && r <= $totalRelays) {
      relayState[r-1] = (s == 1); // 1 = ON
      updateRelays = true;
      
      // Update Firebase too if possible
      forceTelemetry = true;
      triggerActivityLED();
      
      server.send(200, "text/plain", "OK");
    } else {
      server.send(400, "text/plain", "Invalid Relay");
    }
  } else {
    server.send(400, "text/plain", "Missing args");
  }
}

/* ================= STREAM CALLBACK ================= */
void streamCallback(FirebaseStream data) {
  lastStreamKeepAlive = millis(); 
  String path = data.dataPath();
  Serial.printf("⚡ CMD: %s\\n", path.c_str());

  if (path == "/") {
    FirebaseJson *json = data.jsonObjectPtr();
    FirebaseJsonData d;
    if (json->get(d, "relay1")) relayState[0] = d.intValue;
    if (json->get(d, "relay2")) relayState[1] = d.intValue;
    if (json->get(d, "relay3")) relayState[2] = d.intValue;
    if (json->get(d, "relay4")) relayState[3] = d.intValue;
  } 
  else {
    int intVal = data.intData();
    if (path == "/relay1") relayState[0] = intVal;
    if (path == "/relay2") relayState[1] = intVal;
    if (path == "/relay3") relayState[2] = intVal;
    if (path == "/relay4") relayState[3] = intVal;
  }

  updateRelays = true;
  forceTelemetry = true; 
  triggerActivityLED();
}

void streamTimeoutCallback(bool timeout) {
  if (timeout) Serial.println("⚠️ Stream Timeout");
}

/* ================= CORE 0: BURST VOLTAGE TASK ================= */
void voltageTask(void * pvParameters) {
  float adcOffset = 0;
  long sum = 0;
  
  // Calibration
  for (int i = 0; i < 500; i++) sum += analogRead(VOLTAGE_SENSOR);
  adcOffset = sum / 500.0;

  float localVoltage = 0;

  for (;;) {
    double rmsSum = 0;
    int rmsCount = 0;
    int rmsMin = 4095;
    int rmsMax = 0;
    
    // Read 40ms Burst
    unsigned long burstStart = millis();
    while (millis() - burstStart < 40) {
      int raw = analogRead(VOLTAGE_SENSOR);
      if (raw < rmsMin) rmsMin = raw;
      if (raw > rmsMax) rmsMax = raw;
      
      float v = (raw - adcOffset) * (VREF / ADC_MAX);
      rmsSum += v * v;
      rmsCount++;
    }

    // Math
    if (rmsCount > 0) {
      int p2p = rmsMax - rmsMin;
      float rms = sqrt(rmsSum / rmsCount);
      float instVoltage = 0.0;

      if (p2p >= P2P_THRESHOLD && rms >= RMS_THRESHOLD) {
        instVoltage = rms * calibrationFactor;
      }
      
      if (localVoltage == 0) localVoltage = instVoltage;
      else localVoltage = (instVoltage * SMOOTHING_ALPHA) + (localVoltage * (1.0 - SMOOTHING_ALPHA));

      if (localVoltage < 5.0) localVoltage = 0.0;
      sharedVoltage = localVoltage;
    }

    // Sleep 100ms
    vTaskDelay(100 / portTICK_PERIOD_MS);
  }
}

/* ================= SETUP ================= */
void setup() {
  Serial.begin(115200);
  
  // Init Power Pins
  pinMode(RELAY1, OUTPUT);
  pinMode(RELAY2, OUTPUT);
  pinMode(RELAY3, OUTPUT);
  pinMode(RELAY4, OUTPUT);
  
  digitalWrite(RELAY1, HIGH);
  digitalWrite(RELAY2, HIGH);
  digitalWrite(RELAY3, HIGH);
  digitalWrite(RELAY4, HIGH);

  // Init LED Pins
  pinMode(LED_PIN_RED, OUTPUT);
  pinMode(LED_PIN_GREEN, OUTPUT);
  pinMode(LED_PIN_BLUE, OUTPUT);

  // LED Test
  setRGB(HIGH, LOW, LOW); delay(200); // R
  setRGB(LOW, HIGH, LOW); delay(200); // G
  setRGB(LOW, LOW, HIGH); delay(200); // B
  setRGB(LOW, LOW, LOW);

  analogReadResolution(12);
  analogSetAttenuation(ADC_11db);

  // --- WIFI CONFIG (HYBRID) ---
  WiFi.mode(WIFI_AP_STA); // Multimode: Connect to router + Stay available as AP
  WiFi.setSleep(false); 
  WiFi.setAutoReconnect(true); 
  WiFi.persistent(true);       
  
  // Start AP first for immediate availability
  WiFi.softAP(AP_SSID, AP_PASS);
  Serial.println("Hotspot Started: " AP_SSID);
  Serial.print("AP IP Address: ");
  Serial.println(WiFi.softAPIP());

  // Connect to STA
  WiFi.begin(WIFI_SSID, WIFI_PASS);
  
  Serial.print("Connecting to WiFi");
  unsigned long startAttempt = millis();
  while (WiFi.status() != WL_CONNECTED && millis() - startAttempt < 10000) {
    loopLED(); 
    delay(100); 
    Serial.print(".");
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\\n✅ WiFi Connected");
    Serial.print("Local IP: ");
    Serial.println(WiFi.localIP());
  } else {
    Serial.println("\\n⚠️ WiFi Timeout - Using AP Mode only");
    isAPMode = true;
  }

  deviceId = String((uint32_t)ESP.getEfuseMac(), HEX);

  // --- mDNS (nebula.local) ---
  if (MDNS.begin("nebula")) {
    Serial.println("mDNS responder started (nebula.local)");
  }

  // --- HTTP SERVER ---
  server.on("/", handleRoot);
  server.on("/status", handleStatus);
  server.on("/set", handleSet);
  server.begin();
  Serial.println("HTTP Server Started");

  // --- OTA SETUP ---
  ArduinoOTA.setHostname(OTA_HOSTNAME);
  ArduinoOTA.setPassword(OTA_PASSWORD);
  ArduinoOTA.onStart([]() { isOTAActive = true; setRGB(HIGH, LOW, LOW); }); 
  ArduinoOTA.onEnd([]() { isOTAActive = false; setRGB(LOW, HIGH, LOW); }); 
  ArduinoOTA.begin();

  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;
  config.token_status_callback = tokenStatusCallback;
  
  fbStream.setResponseSize(1024); 

  Firebase.signUp(&config, &auth, "", "");
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);

  if (!Firebase.RTDB.beginStream(&fbStream, ("/devices/" + deviceId + "/commands").c_str())) {
    Serial.printf("❌ Stream Start Failed: %s\\n", fbStream.errorReason().c_str());
  } else {
    Serial.println("✅ Stream Listening...");
  }
  
  Firebase.RTDB.setStreamCallback(&fbStream, streamCallback, streamTimeoutCallback);

  xTaskCreatePinnedToCore(voltageTask, "VoltageTask", 10000, NULL, 1, NULL, 0);
  
  lastStreamKeepAlive = millis();
}

/* ================= LOOP (CORE 1) ================= */
void loop() {
  ArduinoOTA.handle();
  server.handleClient(); // Handle HTTP
  loopLED();

  if (updateRelays) {
    applyRelays();
    updateRelays = false;
  }

  // WATCHDOG & AUTO-HEALING
  static unsigned long lastCheck = 0;
  if (millis() - lastCheck > 20000) { 
    lastCheck = millis();

    // 1. Efficient WiFi Reconnection
    if (WiFi.status() != WL_CONNECTED && !isAPMode) {
      Serial.println("⚠️ WiFi Lost. Initiating fresh connection...");
      WiFi.disconnect();
      WiFi.begin(WIFI_SSID, WIFI_PASS); 
    }
  }

  // TELEMETRY
  static unsigned long lastTeleCheck = 0;
  if (millis() - lastTeleCheck > 100) {
    lastTeleCheck = millis();

    float currentV = sharedVoltage;
    bool timeExpired = (millis() - lastTelemetryTime > REPORT_INTERVAL);
    bool significantChange = (abs(currentV - lastReportedVoltage) > VOLTAGE_DELTA);

    if (forceTelemetry || timeExpired || significantChange) {
      if (Firebase.ready()) {
        FirebaseJson j;
        j.set("relay1", relayState[0]);
        j.set("relay2", relayState[1]);
        j.set("relay3", relayState[2]);
        j.set("relay4", relayState[3]);
        j.set("voltage", currentV);
        
        forceTelemetry = false;

        if (Firebase.RTDB.updateNode(&fbTele, ("/devices/" + deviceId + "/telemetry").c_str(), &j)) {
          Serial.printf("📤 Telemetry Sent (V: %.1f)\\n", currentV);
          lastTelemetryTime = millis();
          lastReportedVoltage = currentV;
        }
      }
    }
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
