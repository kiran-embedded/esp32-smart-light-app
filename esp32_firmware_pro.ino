/*
 * NEBULA CORE – COMPLETE SYSTEM (CLOUD-ONLY EDITION)
 * VERSION: v1.3.0
 * ------------------------------------------------
 * STATUS LED LOGIC:
 * PRIORITY 1: OTA Update (Red/Blue Strobe).
 * PRIORITY 2: Data Flash (Blue) -> Overrides Status.
 * PRIORITY 3: Status (Green=OK, Red=No Network).
 */

#include <ArduinoOTA.h>
#include <ESPmDNS.h>
#include <Firebase_ESP_Client.h>
#include <WiFi.h>
#include <WiFiUdp.h>
#include <esp_now.h>
#include <map>
#include <time.h>

#include "addons/RTDBHelper.h"
#include "addons/TokenHelper.h"

/* ================= CONFIGURATION ================= */
#define WIFI_SSID "Kerala_Vision"
#define WIFI_PASS "chandrasekharan0039"

// OTA Credentials
#define OTA_HOSTNAME "Nebula-Core-ESP32"
#define OTA_PASSWORD "nebula2024"

#define API_KEY "AIzaSyA9zs6xhRcEwwGLO6cI417b2FO52PiXaxs"
#define DATABASE_URL                                                           \
  "https://"                                                                   \
  "nebula-smartpowergrid-default-rtdb.asia-southeast1.firebasedatabase.app"

/* ================= PIN DEFINITIONS ================= */
#define RELAY1 26
#define RELAY2 27
#define RELAY3 25
#define RELAY4 33
#define RELAY5 32
#define RELAY6 14
#define RELAY7 23
#define VOLTAGE_SENSOR 34
#define BUZZER_PIN 12 // Piezo Buzzer for Alerts

#define LED_PIN_RED 19
#define LED_PIN_GREEN 16
#define LED_PIN_BLUE 17

/* ================= AC CALIBRATION ================= */
#define ADC_MAX 4095.0
#define VREF 3.3
float calibrationFactor = 313.3;

#define P2P_THRESHOLD 60
#define RMS_THRESHOLD 0.020
#define SMOOTHING_ALPHA 0.1

/* ================= DYNAMIC MODES ================= */
bool isEcoMode = false;
int reportInterval = 8000; // Default 8s

/* ================= GLOBALS ================= */
FirebaseData fbTele;
FirebaseData fbStream;
FirebaseAuth auth;
FirebaseConfig config;

String deviceId = "79215788";
bool relayState[7] = {0, 0, 0, 0, 0, 0, 0};
bool invertedLogic[7] = {0, 0, 0, 0, 0, 0, 0};

// --- DYNAMIC AUTOMATION ENGINE ---
String autoSensor[7] = {"", "", "", "", "", "", ""};
int autoDuration[7] = {0, 0, 0, 0, 0, 0, 0};
int autoThreshold[7] = {0, 0, 0, 0, 0, 0, 0};
bool autoActive[7] = {false, false, false, false, false, false, false};
unsigned long autoTriggerTime[7] = {0, 0, 0, 0, 0, 0, 0};
int autoTimeMode[7] = {0, 0, 0, 0,
                       0, 0, 0}; // 0: All, 1: Morning, 2: Day, 3: Midnight
std::map<String, bool> sensorAlarmEnabled;
std::map<String, int> sensorTriggerCount;
unsigned long lastSensorSync = 0;

bool updateRelays = false;
bool forceTelemetry = false;

volatile float sharedVoltage = 0.0;
unsigned long lastTelemetryTime = 0;
float lastReportedVoltage = 0;
unsigned long lastPIRTrigger = 0;
bool isArmed = true; // Security system state (Cloud controlled)

volatile bool isInternetLive = false;
bool isOTAActive = false;
bool isActivityFlashing = false;
unsigned long activityStart = 0;

// --- DEADMAN SAFETY VARIABLES ---
bool safetyTripped = false;
unsigned long lastCloudActivity = 0;
#define DEADMAN_TIMEOUT_MS 120000 // 2 minutes without cloud comms trips safety

/* ================= MESH STRUCTURE ================= */
typedef struct struct_message {
  char sensorId[16];
  bool motion;
  int lightLevel;
} struct_message;

struct_message incomingData;
volatile bool meshDataPending = false;

/* ================= LED ENGINE ================= */
void initLEDs() {
  pinMode(LED_PIN_RED, OUTPUT);
  pinMode(LED_PIN_GREEN, OUTPUT);
  pinMode(LED_PIN_BLUE, OUTPUT);
  digitalWrite(LED_PIN_RED, LOW);
  digitalWrite(LED_PIN_GREEN, LOW);
  digitalWrite(LED_PIN_BLUE, LOW);
}

void triggerActivityLED() {
  isActivityFlashing = true;
  activityStart = millis();
  lastCloudActivity = millis();
}

void animateLEDs() {
  unsigned long now = millis();
  int targetColor = 0;

  if (isOTAActive) {
    targetColor = ((now / 100) % 2 == 0) ? 1 : 3;
  } else if (isActivityFlashing) {
    if (now - activityStart < 80)
      targetColor = 3;
    else
      isActivityFlashing = false;
  }

  if (targetColor == 0 && !isActivityFlashing && !isOTAActive) {
    if (WiFi.status() != WL_CONNECTED || !isInternetLive) {
      if ((now / 500) % 2 == 0)
        targetColor = 1; // Red Blink
    } else {
      // Green Heartbeat
      unsigned long cycle = now % (isEcoMode ? 4000 : 2000); // Slower in Eco
      if (cycle < 80)
        targetColor = 2;
      else if (cycle > 250 && cycle < 330)
        targetColor = 2;
    }
  }

  digitalWrite(LED_PIN_RED, (targetColor == 1) ? HIGH : LOW);
  digitalWrite(LED_PIN_GREEN, (targetColor == 2) ? HIGH : LOW);
  digitalWrite(LED_PIN_BLUE, (targetColor == 3) ? HIGH : LOW);
}

/* ================= BACKGROUND TASKS ================= */
void connectivityTask(void *pvParameters) {
  for (;;) {
    int delayTime = isEcoMode ? 15000 : 8000;

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
  for (int i = 0; i < 500; i++)
    sum += analogRead(VOLTAGE_SENSOR);
  adcOffset = sum / 500.0;
  float localVoltage = 0;

  for (;;) {
    double rmsSum = 0;
    int rmsCount = 0;
    int rmsMin = 4095;
    int rmsMax = 0;

    unsigned long burstStart = millis();
    while (millis() - burstStart < 40) {
      int raw = analogRead(VOLTAGE_SENSOR);
      if (raw < rmsMin)
        rmsMin = raw;
      if (raw > rmsMax)
        rmsMax = raw;
      float v = (raw - adcOffset) * (VREF / ADC_MAX);
      rmsSum += v * v;
      rmsCount++;
    }

    if (rmsCount > 0) {
      int p2p = rmsMax - rmsMin;
      float rms = sqrt(rmsSum / rmsCount);
      float instVoltage = 0.0;
      if (p2p >= P2P_THRESHOLD && rms >= RMS_THRESHOLD) {
        instVoltage = rms * calibrationFactor;
      }
      if (localVoltage == 0)
        localVoltage = instVoltage;
      else
        localVoltage = (instVoltage * SMOOTHING_ALPHA) +
                       (localVoltage * (1.0 - SMOOTHING_ALPHA));

      if (localVoltage < 5.0)
        localVoltage = 0.0;
      sharedVoltage = localVoltage;
    }
    // eco mode delays
    vTaskDelay((isEcoMode ? 200 : 100) / portTICK_PERIOD_MS);
  }
}

/* ================= HARDWARE CONTROL ================= */
void applyRelays() {
  Serial.printf("Relay CMD: %d %d %d %d %d %d %d | INV: %d %d %d %d %d %d %d\n",
                relayState[0], relayState[1], relayState[2], relayState[3],
                relayState[4], relayState[5], relayState[6], invertedLogic[0],
                invertedLogic[1], invertedLogic[2], invertedLogic[3],
                invertedLogic[4], invertedLogic[5], invertedLogic[6]);
  digitalWrite(RELAY1, (relayState[0] != invertedLogic[0]) ? HIGH : LOW);
  digitalWrite(RELAY2, (relayState[1] != invertedLogic[1]) ? HIGH : LOW);
  digitalWrite(RELAY3, (relayState[2] != invertedLogic[2]) ? HIGH : LOW);
  digitalWrite(RELAY4, (relayState[3] != invertedLogic[3]) ? HIGH : LOW);
  digitalWrite(RELAY5, (relayState[4] != invertedLogic[4]) ? HIGH : LOW);
  digitalWrite(RELAY6, (relayState[5] != invertedLogic[5]) ? HIGH : LOW);
  digitalWrite(RELAY7, (relayState[6] != invertedLogic[6]) ? HIGH : LOW);
}

/* ================= STREAM CALLBACK ================= */
void streamCallback(FirebaseStream data) {
  isInternetLive = true;
  lastCloudActivity = millis();

  String path = data.dataPath();
  Serial.printf("⚡ CLOUD CMD: %s\n", path.c_str());

  if (path == "/") {
    FirebaseJson *json = data.jsonObjectPtr();
    FirebaseJsonData d;
    if (json->get(d, "relay1"))
      relayState[0] = d.intValue;
    if (json->get(d, "relay2"))
      relayState[1] = d.intValue;
    if (json->get(d, "relay3"))
      relayState[2] = d.intValue;
    if (json->get(d, "relay4"))
      relayState[3] = d.intValue;
    if (json->get(d, "relay5"))
      relayState[4] = d.intValue;
    if (json->get(d, "relay6"))
      relayState[5] = d.intValue;
    if (json->get(d, "relay7"))
      relayState[6] = d.intValue;
    if (json->get(d, "invert1"))
      invertedLogic[0] = d.boolValue;
    if (json->get(d, "invert2"))
      invertedLogic[1] = d.boolValue;
    if (json->get(d, "invert3"))
      invertedLogic[2] = d.boolValue;
    if (json->get(d, "invert4"))
      invertedLogic[3] = d.boolValue;
    if (json->get(d, "invert5"))
      invertedLogic[4] = d.boolValue;
    if (json->get(d, "invert6"))
      invertedLogic[5] = d.boolValue;
    if (json->get(d, "invert7"))
      invertedLogic[6] = d.boolValue;
    if (json->get(d, "ecoMode"))
      isEcoMode = d.boolValue;

    updateRelays = true; // Root sync instant apply
  } else {
    // Determine type safely based on path PREFIX
    if (path.startsWith("/relay")) {
      int intVal = data.intData();
      if (path == "/relay1")
        relayState[0] = intVal;
      if (path == "/relay2")
        relayState[1] = intVal;
      if (path == "/relay3")
        relayState[2] = intVal;
      if (path == "/relay4")
        relayState[3] = intVal;
      if (path == "/relay5")
        relayState[4] = intVal;
      if (path == "/relay6")
        relayState[5] = intVal;
      if (path == "/relay7")
        relayState[6] = intVal;

      updateRelays = true;
    } else if (path.startsWith("/invert")) {
      bool bVal = data.boolData();
      if (path == "/invert1")
        invertedLogic[0] = bVal;
      if (path == "/invert2")
        invertedLogic[1] = bVal;
      if (path == "/invert3")
        invertedLogic[2] = bVal;
      if (path == "/invert4")
        invertedLogic[3] = bVal;
      if (path == "/invert5")
        invertedLogic[4] = bVal;
      if (path == "/invert6")
        invertedLogic[5] = bVal;
      if (path == "/invert7")
        invertedLogic[6] = bVal;

      updateRelays = true;
    }
    // --- AUTOMATION ENGINE PARSING ---
    else if (path.indexOf("/auto_r") != -1) {
      int rIndex = path.substring(7, 8).toInt() - 1;
      if (rIndex >= 0 && rIndex < 7) {
        if (path.endsWith("_sen"))
          autoSensor[rIndex] = data.stringData();
        else if (path.endsWith("_dur"))
          autoDuration[rIndex] = data.intData();
        else if (path.endsWith("_thr"))
          autoThreshold[rIndex] = data.intData();
        else if (path.endsWith("_act"))
          autoActive[rIndex] = data.boolData();
        else if (path.endsWith("_tm"))
          autoTimeMode[rIndex] = data.intData();
      }
    }

    if (path == "/ecoMode") {
      isEcoMode = data.boolData();
      Serial.printf("MODE CHANGED: %s\n", isEcoMode ? "ECO" : "PERFORMANCE");
    }
    if (path == "/security/isArmed") {
      isArmed = data.boolData();
      Serial.printf("SECURITY %s\n", isArmed ? "ARMED" : "DISARMED");
    }
  }

  // Adjust telemetry timings based on mode
  reportInterval = isEcoMode ? 15000 : 4000;

  updateRelays = true;
  forceTelemetry = true;
  triggerActivityLED();
}

void streamTimeoutCallback(bool timeout) {
  if (timeout) {
    Serial.println("⚠️ Stream Timeout");
    isInternetLive = false;
  }
}

/* ================= ESP-NOW CALLBACK ================= */
void OnDataRecv(const esp_now_recv_info *info, const uint8_t *data, int len) {
  memcpy(&incomingData, data, sizeof(incomingData));
  Serial.printf("🛰 MESH RECV: %s | Motion: %d | LDR: %d\n",
                incomingData.sensorId, incomingData.motion,
                incomingData.lightLevel);
  meshDataPending = true;
}

/* ================= FIREBASE TASK (CORE 0) ================= */
void firebaseTelemetryTask(void *pvParameters) {
  for (;;) {
    // --- WIFI AUTO RECONNECT (Second Layer Defense) ---
    static unsigned long lastWiFiCheck = 0;
    if (millis() - lastWiFiCheck > 20000) {
      lastWiFiCheck = millis();
      if (WiFi.status() != WL_CONNECTED) {
        Serial.println("⚠ WiFi Reconnecting...");
        WiFi.disconnect();
        WiFi.begin(WIFI_SSID, WIFI_PASS);
      }
    }

    // --- TELEMETRY / HEARTBEAT ---
    static unsigned long lastTeleCheck = 0;
    if (millis() - lastTeleCheck >
        (isEcoMode ? 2000 : 500)) { // Polling throttle
      lastTeleCheck = millis();
      float currentV = sharedVoltage;
      bool timeExpired = (millis() - lastTelemetryTime > reportInterval);
      bool significantChange = (abs(currentV - lastReportedVoltage) > 3.0);

      if (forceTelemetry || timeExpired || significantChange) {
        if (Firebase.ready() && isInternetLive) {
          FirebaseJson j;
          j.set("relay1", relayState[0]);
          j.set("relay2", relayState[1]);
          j.set("relay3", relayState[2]);
          j.set("relay4", relayState[3]);
          j.set("relay5", relayState[4]);
          j.set("relay6", relayState[5]);
          j.set("relay7", relayState[6]);
          j.set("voltage", currentV);
          j.set("ecoMode", isEcoMode);
          j.set("lastSeen", millis());
          forceTelemetry = false;

          if (Firebase.RTDB.updateNode(
                  &fbTele, ("devices/" + deviceId + "/telemetry").c_str(),
                  &j)) {
            lastTelemetryTime = millis();
            lastReportedVoltage = currentV;
            lastCloudActivity = millis(); // Refresh deadman
          } else {
            isInternetLive = false; // Fallback sync
          }
        }
      }
    }

    // --- DEADMAN'S SWITCH LOGIC ---
    if (millis() - lastCloudActivity > DEADMAN_TIMEOUT_MS) {
      if (!safetyTripped) {
        Serial.println(
            "⛔ DEADMAN TRIP: No Cloud Contact for 2 mins. Halting.");
        relayState[0] = false;
        relayState[1] = false;
        relayState[2] = false;
        relayState[3] = false;
        relayState[4] = false;
        relayState[5] = false;
        relayState[6] = false;
        updateRelays = true; // Signal Core 1 to toggle relays instantly
        safetyTripped = true;
      }

      // Auto Reset if Deadman is tripped for 5 minutes
      if (millis() - lastCloudActivity > (DEADMAN_TIMEOUT_MS + 300000)) {
        Serial.println("☢ DEADMAN REBOOT!");
        ESP.restart();
      }
    } else {
      safetyTripped = false;
    }

    // --- AUTOMATION ENGINE: AUTO-OFF TIMERS ---
    for (int i = 0; i < 7; i++) {
      if (autoActive[i] && autoDuration[i] > 0 && relayState[i] == 1 &&
          autoTriggerTime[i] > 0) {
        if (millis() - autoTriggerTime[i] >
            (unsigned long)autoDuration[i] * 1000UL) {
          Serial.printf("⏳ AUTOMATION: Auto-Turning OFF Relay %d after %ds\n",
                        i + 1, autoDuration[i]);
          relayState[i] = 0;
          autoTriggerTime[i] = 0;
          updateRelays = true;
        }
      }
    }

    // --- MESH BRIDGE FORWARDING ---
    if (meshDataPending) {
      if (strcmp(incomingData.sensorId, "ping") == 0) {
        // It's a heartbeat from Node
        if (Firebase.ready() && isInternetLive) {
          Firebase.RTDB.setInt(
              &fbTele,
              ("devices/" + deviceId + "/security/nodeActive/lastSeen").c_str(),
              millis());
          Firebase.RTDB.setBool(
              &fbTele,
              ("devices/" + deviceId + "/security/nodeActive/status").c_str(),
              true);
        }
      } else {
        // It's motion data
        if (Firebase.ready() && isInternetLive) {
          FirebaseJson meshJson;
          meshJson.set("status", incomingData.motion);
          meshJson.set("lightLevel", incomingData.lightLevel);
          meshJson.set("lastTriggered", millis());

          String nodePath = "devices/" + deviceId + "/security/sensors/" +
                            String(incomingData.sensorId);

          // Update trigger count locally and sync
          if (incomingData.motion) {
            sensorTriggerCount[incomingData.sensorId]++;
            meshJson.set("triggerCount",
                         sensorTriggerCount[incomingData.sensorId]);
          }

          if (Firebase.RTDB.updateNode(&fbTele, nodePath.c_str(), &meshJson)) {

            // --- AUTOMATION ENGINE: MOTION TRIGGERS ---
            if (incomingData.motion) {
              for (int i = 0; i < 7; i++) {
                if (autoActive[i] &&
                    autoSensor[i] == String(incomingData.sensorId)) {

                  // Time-of-Day Gating
                  bool timeMatch = true;
                  if (autoTimeMode[i] > 0) {
                    struct tm timeinfo;
                    if (getLocalTime(&timeinfo)) {
                      int hour = timeinfo.tm_hour;
                      if (autoTimeMode[i] == 1) { // Morning: 6-12
                        timeMatch = (hour >= 6 && hour < 12);
                      } else if (autoTimeMode[i] == 2) { // Day: 12-18
                        timeMatch = (hour >= 12 && hour < 18);
                      } else if (autoTimeMode[i] == 3) { // Midnight: 18-6
                        timeMatch = (hour >= 18 || hour < 6);
                      }
                    }
                  }

                  if (timeMatch &&
                      incomingData.lightLevel <= autoThreshold[i]) {
                    // Turn ON Relay
                    Serial.printf("⚡ AUTOMATION: %s triggered Relay %d (LDR: "
                                  "%d <= %d)\n",
                                  incomingData.sensorId, i + 1,
                                  incomingData.lightLevel, autoThreshold[i]);
                    relayState[i] = 1;
                    autoTriggerTime[i] = millis();
                    updateRelays = true;
                  }
                }
              }
            }

            // Check if alarm is enabled for THIS specific sensor
            bool alarmGate = true;
            if (sensorAlarmEnabled.find(incomingData.sensorId) !=
                sensorAlarmEnabled.end()) {
              alarmGate = sensorAlarmEnabled[incomingData.sensorId];
            }

            if (incomingData.motion && isArmed && alarmGate) {
              // Local Alert
              digitalWrite(BUZZER_PIN, HIGH);
              delay(200);
              digitalWrite(BUZZER_PIN, LOW);

              triggerActivityLED();
              // Push log for history
              FirebaseJson log;
              log.set("sensor", incomingData.sensorId);
              log.set("timestamp", millis());
              Firebase.RTDB.pushJSON(
                  &fbTele, ("/devices/" + deviceId + "/security/logs").c_str(),
                  &log);
            } else if (incomingData.motion) {
              // Visual only if silenced or disarmed
              triggerActivityLED();
            }
          }
        }
      }
      meshDataPending = false;
    }

    // Sync Sensor States (Alarm Enabled / Trigger Count)
    if (millis() - lastSensorSync > 30000) {
      FirebaseJson sensors;
      if (Firebase.RTDB.getJSON(
              &fbConn, ("devices/" + deviceId + "/security/sensors").c_str(),
              &sensors)) {
        FirebaseJsonData data;
        sensors.get(data, "living/isAlarmEnabled");
        if (data.success)
          sensorAlarmEnabled["living"] = data.boolValue;
        sensors.get(data, "living/triggerCount");
        if (data.success)
          sensorTriggerCount["living"] = data.intValue;

        sensors.get(data, "kitchen/isAlarmEnabled");
        if (data.success)
          sensorAlarmEnabled["kitchen"] = data.boolValue;
        sensors.get(data, "kitchen/triggerCount");
        if (data.success)
          sensorTriggerCount["kitchen"] = data.intValue;

        sensors.get(data, "hallway/isAlarmEnabled");
        if (data.success)
          sensorAlarmEnabled["hallway"] = data.boolValue;
        sensors.get(data, "hallway/triggerCount");
        if (data.success)
          sensorTriggerCount["hallway"] = data.intValue;

        sensors.get(data, "garage/isAlarmEnabled");
        if (data.success)
          sensorAlarmEnabled["garage"] = data.boolValue;
        sensors.get(data, "garage/triggerCount");
        if (data.success)
          sensorTriggerCount["garage"] = data.intValue;

        sensors.get(data, "door/isAlarmEnabled");
        if (data.success)
          sensorAlarmEnabled["door"] = data.boolValue;
        sensors.get(data, "door/triggerCount");
        if (data.success)
          sensorTriggerCount["door"] = data.intValue;

        lastSensorSync = millis();
      }
    }

    vTaskDelay(
        pdMS_TO_TICKS(isEcoMode ? 1000 : 200)); // FreeRTOS non-blocking delay
  }
}

/* ================= SETUP ================= */
void setup() {
  Serial.begin(115200);

  pinMode(RELAY1, OUTPUT);
  pinMode(RELAY2, OUTPUT);
  pinMode(RELAY3, OUTPUT);
  pinMode(RELAY4, OUTPUT);
  pinMode(RELAY5, OUTPUT);
  pinMode(RELAY6, OUTPUT);
  pinMode(RELAY7, OUTPUT);

  digitalWrite(RELAY1, LOW);
  digitalWrite(RELAY2, LOW);
  digitalWrite(RELAY3, LOW);
  digitalWrite(RELAY4, LOW);
  digitalWrite(RELAY5, LOW);
  digitalWrite(RELAY6, LOW);
  digitalWrite(RELAY7, LOW);
  applyRelays();

  pinMode(BUZZER_PIN, OUTPUT);
  digitalWrite(BUZZER_PIN, LOW);

  initLEDs();

  analogReadResolution(12);
  analogSetAttenuation(ADC_11db);

  WiFi.mode(WIFI_STA);
  WiFi.setAutoReconnect(true); // VERY IMPORTANT FOR AUTO RECONNECT
  WiFi.persistent(true);
  WiFi.begin(WIFI_SSID, WIFI_PASS);

  unsigned long startAttempt = millis();
  while (WiFi.status() != WL_CONNECTED) {
    animateLEDs();
    if (millis() - startAttempt > 20000)
      break;
    delay(10);
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n✅ WiFi Connected");

    // Configure Time Sync (NTP)
    configTime(19800, 0, "pool.ntp.org", "time.nist.gov"); // GMT+5:30 (India)

    xTaskCreatePinnedToCore(connectivityTask, "ConnTask", 2048, NULL, 1, NULL,
                            0);
    triggerActivityLED();
  }

  ArduinoOTA.setHostname(OTA_HOSTNAME);
  ArduinoOTA.setPassword(OTA_PASSWORD);
  ArduinoOTA.onStart([]() { isOTAActive = true; });
  ArduinoOTA.onEnd([]() {
    isOTAActive = false;
    triggerActivityLED();
    ESP.restart(); // Ensure valid state after OTA
  });
  ArduinoOTA.begin();

  MDNS.addService("nebula", "tcp", 80);

  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;
  config.token_status_callback = tokenStatusCallback;

  // --- PERFORMANCE BOOSTER CONFIGURATIONS ---
  fbStream.setBSSLBufferSize(2048, 512);
  fbStream.setResponseSize(1024);

  Firebase.signUp(&config, &auth, "", "");
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);

  Firebase.RTDB.beginStream(&fbStream,
                            ("devices/" + deviceId + "/commands").c_str());
  Firebase.RTDB.setStreamCallback(&fbStream, streamCallback,
                                  streamTimeoutCallback);

  // --- INITIALIZE SECURITY STATE ---
  FirebaseJson initSensor;
  initSensor.set("status", false);
  initSensor.set("lastTriggered", 0);
  initSensor.set("lightLevel", 0);
  Firebase.RTDB.updateNode(
      &fbTele, ("devices/" + deviceId + "/security/sensors/kitchen").c_str(),
      &initSensor);
  Firebase.RTDB.setBool(
      &fbTele, ("devices/" + deviceId + "/security/isArmed").c_str(), isArmed);

  // --- ESP-NOW SETUP ---
  if (esp_now_init() == ESP_OK) {
    esp_now_register_recv_cb(OnDataRecv);
    Serial.println("🔗 ESP-NOW Bridge Initialized");
  }

  // --- START DUAL-CORE RTOS TASKS ---
  xTaskCreatePinnedToCore(voltageTask, "VoltageTask", 10000, NULL, 1, NULL, 0);
  xTaskCreatePinnedToCore(firebaseTelemetryTask, "FirebaseTask", 16384, NULL, 1,
                          NULL, 0);

  lastCloudActivity = millis();
}

/* ================= LOOP (CORE 1) ================= */
void loop() {
  animateLEDs();
  ArduinoOTA.handle();

  if (updateRelays) {
    applyRelays();
    updateRelays = false;
  }

  delay(1); // 1ms super-fast polling interval on hardware core
}
