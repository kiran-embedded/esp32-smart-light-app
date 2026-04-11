/*
 * NEBULA CORE – COMPLETE SYSTEM (CLOUD-ONLY EDITION)
 * VERSION: v1.6.5-ULTIMATE-PRO-GOLD
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
#include <esp_task_wdt.h>
#include <map>
#include <set>
#include <time.h>

#include "addons/RTDBHelper.h"
#include "addons/TokenHelper.h"

/* ================= CONFIGURATION ================= */
#define WIFI_SSID "Kerala_Vision"
#define WIFI_PASS "chandrasekharan0039"
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
#define BUZZER_PIN 13

#define LED_PIN_RED 19
#define LED_PIN_GREEN 16
#define LED_PIN_BLUE 17

/* ================= CONSTANTS ================= */
#define ADC_MAX 4095.0
#define VREF 3.3
float calibrationFactor = 313.3;
#define P2P_THRESHOLD 60
#define RMS_THRESHOLD 0.020
#define SMOOTHING_ALPHA 0.1
#define DEADMAN_TIMEOUT_MS 120000
#define LED_PULSE_MS 100
#define MANUAL_LOCKOUT_TIMEOUT_MS 900000 // 15-Minute Priority Lockout

/* ================= GLOBALS ================= */
FirebaseData fbTele;
FirebaseData fbStream;
FirebaseAuth auth;
FirebaseConfig config;

bool isOTAActive = false;
bool isInternetLive = false;
String deviceId = "79215788";

bool relayState[7] = {0, 0, 0, 0, 0, 0, 0};
bool invertedLogic[7] = {0, 0, 0, 0, 0, 0, 0};
String autoSensor[7] = {"", "", "", "", "", "", ""};
int autoDuration[7] = {0, 0, 0, 0, 0, 0, 0};
int autoThreshold[7] = {0, 0, 0, 0, 0, 0, 0};
bool autoActive[7] = {false, false, false, false, false, false, false};
unsigned long autoTriggerTime[7] = {0, 0, 0, 0, 0, 0, 0};
bool isNeuralTriggered[7] = {false, false, false, false, false, false, false};
unsigned long manualOverrideTime[7] = {0, 0, 0, 0, 0, 0, 0};
int relayPriority[7] = {0, 0, 0, 0, 0, 0, 0}; // 0: Auto, 1: Motion, 2: Manual

int pirTimer = 60;
int autoTimeMode[7] = {0, 0, 0, 0, 0, 0, 0};
int mapPIR[5] = {0, 0, 0, 0, 0};
int pirDetectionCount[5] = {1, 1, 1, 1, 1};
int pirDebounce[5] = {200, 200, 200, 200, 200};

bool activePeriods[5] = {true, true, true, true, true};
const char *periodNames[5] = {"morning", "afternoon", "evening", "night",
                              "midnight"};

std::map<String, int> sensorDebounce;
std::map<String, int> sensorSensitivity;
std::map<String, int> sensorHitCounter;
std::map<String, int> sensorMode;
std::map<String, unsigned long> lastTriggerTimeMap;

bool updateRelays = false;
bool forceTelemetry = false;
volatile float sharedVoltage = 0.0;
unsigned long lastTelemetryTime = 0;
float lastReportedVoltage = 0;
bool isArmed = false;
bool isBuzzerMuted = false;
bool isAutoGlobalEnabled = true;
unsigned long blueLedOffTime = 0;
int globalLdrThreshold = 50;
int globalLdrValue = 0;
int securityMode = 2; // 0: LDR, 1: Schedule, 2: Hybrid
bool ldrValid = false;
unsigned long lastLdrUpdate = 0;
bool isEcoMode = false;
int reportInterval = 8000;
unsigned long systemInitTime = 0;

String pathTele, pathCmds, pathSensors;
bool isActivityFlashing = false;
unsigned long activityStart = 0;
bool isPanicActive = false;
bool isPanicResume = false;
std::map<String, int> motionBatchCounter;
std::map<String, unsigned long> motionBatchStartTime;
unsigned long lastLogTime = 0;
bool safetyTripped = false;
unsigned long lastCloudActivity = 0;
int systemEventCount = 0;

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
}

void animateLEDs() {
  unsigned long now = millis();
  if (blueLedOffTime > 0 && now > blueLedOffTime) {
    digitalWrite(LED_PIN_BLUE, LOW);
    blueLedOffTime = 0;
  }
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
    if (WiFi.status() != WL_CONNECTED) {
      targetColor = ((now / 200) % 2 == 0) ? 2 : 3;
    } else if (!isInternetLive) {
      if ((now / 1500) % 2 == 0)
        targetColor = 1;
    } else {
      unsigned long cycle = now % (isEcoMode ? 4000 : 2000);
      if (cycle < 80 || (cycle > 250 && cycle < 330))
        targetColor = 2;
    }
  }

  digitalWrite(LED_PIN_RED, (targetColor == 1) ? HIGH : LOW);
  digitalWrite(LED_PIN_GREEN, (targetColor == 2) ? HIGH : LOW);
  if (blueLedOffTime > 0 && now < blueLedOffTime)
    digitalWrite(LED_PIN_BLUE, HIGH);
  else
    digitalWrite(LED_PIN_BLUE, (targetColor == 3) ? HIGH : LOW);

  if (isPanicActive) {
    if (now - lastPanicPulse > 500) {
      triggerBuzzer(250);
      lastPanicPulse = now;
    }
  } else {
    digitalWrite(BUZZER_PIN, LOW);
  }
  if (buzzerPending) {
    if (now - buzzerStartTime < buzzerDuration) {
      if (!isBuzzerMuted)
        digitalWrite(BUZZER_PIN, HIGH);
    } else {
      digitalWrite(BUZZER_PIN, LOW);
      buzzerPending = false;
    }
  }
}

void triggerBuzzer(int ms) {
  if (isBuzzerMuted && !isPanicActive)
    return;
  buzzerPending = true;
  buzzerStartTime = millis();
  buzzerDuration = ms;
  digitalWrite(BUZZER_PIN, HIGH);
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
  long sum = 0;
  for (int i = 0; i < 500; i++)
    sum += analogRead(VOLTAGE_SENSOR);
  float adcOffset = sum / 500.0;
  float localVoltage = 0;

  for (;;) {
    double rmsSum = 0;
    int rmsCount = 0;
    int rmsMin = 4095, rmsMax = 0;
    unsigned long burstStart = millis();
    while (millis() - burstStart < 20) {
      int raw = analogRead(VOLTAGE_SENSOR);
      if (raw < rmsMin)
        rmsMin = raw;
      if (raw > rmsMax)
        rmsMax = raw;
      float v = (raw - adcOffset) * (VREF / ADC_MAX);
      rmsSum += v * v;
      rmsCount++;
      yield();
    }
    if (rmsCount > 0) {
      int p2p = rmsMax - rmsMin;
      float rms = sqrt(rmsSum / rmsCount);
      float instVoltage = (p2p >= P2P_THRESHOLD && rms >= RMS_THRESHOLD)
                              ? (rms * calibrationFactor)
                              : 0.0;
      localVoltage = (localVoltage == 0)
                         ? instVoltage
                         : (instVoltage * SMOOTHING_ALPHA) +
                               (localVoltage * (1.0 - SMOOTHING_ALPHA));
      sharedVoltage = (localVoltage < 5.0) ? 0.0 : localVoltage;
    }
    vTaskDelay((isEcoMode ? 200 : 100) / portTICK_PERIOD_MS);
  }
}

/* ================= HARDWARE CONTROL ================= */
void applyRelays() {
  int pins[] = {RELAY1, RELAY2, RELAY3, RELAY4, RELAY5, RELAY6, RELAY7};
  for (int i = 0; i < 7; i++) {
    bool target = (relayState[i] != invertedLogic[i]);
    digitalWrite(pins[i], target ? HIGH : LOW);
  }
  forceTelemetry = true;
}

void triggerHardware() {
  updateRelays = true;
  applyRelays();
  updateRelays = false;
}

/* ================= PRIORITY LOGIC ================= */
bool canUpdateRelay(int idx, int newPriority) {
  if (newPriority >= relayPriority[idx])
    return true;
  if (millis() - manualOverrideTime[idx] > MANUAL_LOCKOUT_TIMEOUT_MS)
    return true;
  return false;
}

void applyRelayUpdate(int idx, int state, int priority) {
  if (canUpdateRelay(idx, priority)) {
    relayState[idx] = state;
    relayPriority[idx] = priority;
    if (priority == 2)
      manualOverrideTime[idx] = millis();
    updateRelays = true;
    forceTelemetry = true;

    // Relay Acknowledgement (Status Node)
    String statusPath =
        "devices/" + deviceId + "/status/relays/r" + String(idx + 1);
    Firebase.RTDB.setIntAsync(&fbTele, statusPath.c_str(), state);
  }
}

/* ================= STREAM CALLBACK ================= */
void logEvent(String type, String sensor = "", String details = "") {
  if (millis() - lastLogTime < 200)
    return;
  lastLogTime = millis();
  String path = "devices/" + deviceId + "/events";
  FirebaseJson event;
  event.set("type", type);
  if (sensor != "")
    event.set("sensor", sensor);
  if (details != "")
    event.set("details", details);
  double ts =
      (time(nullptr) > 1000000) ? (double)time(nullptr) : (double)millis();
  event.set("timestamp", ts);
  Firebase.RTDB.pushJSONAsync(&fbTele, path.c_str(), &event);

  systemEventCount++;
  if (systemEventCount > 200) {
    Firebase.RTDB.deleteNodeAsync(&fbTele, path.c_str());
    systemEventCount = 0;
  }
}

void streamCallback(FirebaseStream data) {
  digitalWrite(LED_PIN_BLUE, HIGH);
  blueLedOffTime = millis() + LED_PULSE_MS;
  isInternetLive = true;
  lastCloudActivity = millis();
  String path = data.dataPath();
  bool wasRelayUpdated = false;

  if (path == "/") {
    FirebaseJson *json = data.jsonObjectPtr();
    FirebaseJsonData d;
    for (int i = 0; i < 7; i++) {
      char rKey[16], pKey[16];
      sprintf(rKey, "relay%d", i + 1);
      sprintf(pKey, "prio%d", i + 1);
      int newState = -1;
      int newPrio = -1;

      if (json->get(d, rKey))
        newState = d.intValue;
      if (json->get(d, pKey))
        newPrio = d.intValue;

      if (newState != -1) {
        if (newPrio == -1)
          newPrio = 2; // Default to Manual if not specified
        applyRelayUpdate(i, newState, newPrio);
        wasRelayUpdated = true;
      }
    }

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
    if (json->get(d, "panic")) {
      isPanicActive = d.boolValue;
      if (isPanicActive)
        triggerBuzzer(1000);
      else
        Firebase.RTDB.deleteNodeAsync(
            &fbTele,
            ("devices/" + deviceId + "/security/activeBreaches").c_str());
    }
    if (json->get(d, "security/securityMode"))
      securityMode = d.intValue;
    if (json->get(d, "isArmed") || json->get(d, "security/isArmed")) {
      isArmed = d.boolValue;
      if (!isArmed)
        Firebase.RTDB.deleteNodeAsync(
            &fbTele,
            ("devices/" + deviceId + "/security/activeBreaches").c_str());
    }
    if (json->get(d, "buzzerMute"))
      isBuzzerMuted = d.boolValue;
    if (json->get(d, "ldrThreshold"))
      globalLdrThreshold = d.intValue;
    if (json->get(d, "pirTimer"))
      pirTimer = d.intValue;

    if (json->get(d, "security/masterLDR")) {
      globalLdrValue = d.intValue;
      ldrValid = true;
      lastLdrUpdate = millis();
    }

    if (json->get(d, "autoGlobal") || json->get(d, "autoLightOnMotion") ||
        json->get(d, "security/autoGlobal") ||
        json->get(d, "security/autoLightOnMotion"))
      isAutoGlobalEnabled = d.boolValue;

    for (int i = 1; i <= 4; i++) {
      char key[16], sKey[48], dKey[48];
      sprintf(key, "mapPIR%d", i);
      sprintf(sKey, "security/calibration/PIR%d/detection_count", i);
      sprintf(dKey, "security/calibration/PIR%d/debounce", i);
      char mKey[48];
      sprintf(mKey, "security/calibration/PIR%d/mode", i);
      if (json->get(d, key))
        mapPIR[i - 1] = d.intValue;
      if (json->get(d, sKey))
        pirDetectionCount[i - 1] = d.intValue;
      if (json->get(d, dKey))
        pirDebounce[i - 1] = d.intValue;
      if (json->get(d, mKey))
        sensorMode["PIR" + String(i)] = d.intValue;
    }
    for (int i = 0; i < 5; i++) {
      char pKey[32];
      sprintf(pKey, "security/activePeriods/%s", periodNames[i]);
      if (json->get(d, pKey))
        activePeriods[i] = d.boolValue;
      if (json->get(d, periodNames[i]))
        activePeriods[i] = d.boolValue;
    }
    for (int i = 1; i <= 7; i++) {
      char sKey[16], dKey[16], tKey[16], aKey[16], mKey[16];
      sprintf(sKey, "auto_r%d_sen", i);
      sprintf(dKey, "auto_r%d_dur", i);
      sprintf(tKey, "auto_r%d_thr", i);
      sprintf(aKey, "auto_r%d_act", i);
      sprintf(mKey, "auto_r%d_tm", i);
      if (json->get(d, sKey))
        autoSensor[i - 1] = d.stringValue;
      if (json->get(d, dKey))
        autoDuration[i - 1] = d.intValue;
      if (json->get(d, tKey))
        autoThreshold[i - 1] = d.intValue;
      if (json->get(d, aKey))
        autoActive[i - 1] = d.boolValue;
      if (json->get(d, mKey))
        autoTimeMode[i - 1] = d.intValue;
    }

    // 🧪 TEST MESH SIMULATION
    if (json->get(d, "testMesh") && d.boolValue) {
      strcpy(incomingData.sensorId, "PIR1");
      incomingData.motion = true;
      incomingData.lightLevel = 45;
      meshDataPending = true;
      Firebase.RTDB.setBoolAsync(&fbTele, (pathCmds + "/testMesh").c_str(),
                                 false);
    }
  } else {
    // === INDIVIDUAL PATH UPDATES ===
    if (path.startsWith("/relay")) {
      int idx = path.substring(6).toInt() - 1;
      if (idx >= 0 && idx < 7) {
        applyRelayUpdate(idx, data.intData(), 2);
      }
    } else if (path == "/isArmed") {
      isArmed = data.boolData();
    } else if (path == "/buzzerMute") {
      isBuzzerMuted = data.boolData();
    } else if (path == "/ldrThreshold") {
      globalLdrThreshold = data.intData();
    } else if (path == "/autoGlobal" || path == "/autoLightOnMotion") {
      isAutoGlobalEnabled = data.boolData();
    } else if (path == "/panic" || path == "/security/panic") {
      isPanicActive = data.boolData();
      if (isPanicActive)
        triggerBuzzer(1000);
      else
        Firebase.RTDB.deleteNodeAsync(
            &fbTele,
            ("devices/" + deviceId + "/security/activeBreaches").c_str());
    } else if (path.startsWith("/security/calibration/PIR")) {
      int pIdx = path.substring(25, 26).toInt() - 1;
      if (pIdx >= 0 && pIdx < 4) {
        if (path.endsWith("/detection_count"))
          pirDetectionCount[pIdx] = data.intData();
        else if (path.endsWith("/debounce"))
          pirDebounce[pIdx] = data.intData();
        else if (path.endsWith("/mode"))
          sensorMode["PIR" + String(pIdx + 1)] = data.intData();
      }
    } else if (path == "/security/securityMode") {
      securityMode = data.intData();
    } else if (path.startsWith("/security/activePeriods/")) {
      String period = path.substring(24);
      for (int i = 0; i < 5; i++) {
        if (period == periodNames[i]) {
          activePeriods[i] = data.boolData();
          break;
        }
      }
    }
  }

  triggerHardware();
  lastTelemetryTime = millis() - reportInterval + 500;
  triggerActivityLED();
}

void streamTimeoutCallback(bool timeout) {
  if (timeout)
    isInternetLive = false;
}

/* ================= ESP-NOW CALLBACK ================= */
#if ESP_ARDUINO_VERSION >= ESP_ARDUINO_VERSION_VAL(3, 0, 0)
void OnDataRecv(const esp_now_recv_info *info, const uint8_t *data, int len) {
#else
void OnDataRecv(const uint8_t *mac_addr, const uint8_t *data, int len) {
#endif
  memcpy(&incomingData, data, sizeof(incomingData));
  meshDataPending = true;
}

/* ================= SETUP ================= */
void setup() {
  Serial.begin(115200);
  delay(500);
  initLEDs();

  pinMode(RELAY1, OUTPUT);
  pinMode(RELAY2, OUTPUT);
  pinMode(RELAY3, OUTPUT);
  pinMode(RELAY4, OUTPUT);
  pinMode(RELAY5, OUTPUT);
  pinMode(RELAY6, OUTPUT);
  pinMode(RELAY7, OUTPUT);
  pinMode(BUZZER_PIN, OUTPUT);

  analogReadResolution(12);
  analogSetAttenuation(ADC_11db);

  WiFi.mode(WIFI_STA);
  WiFi.setSleep(false);
  WiFi.setAutoReconnect(true);
  WiFi.begin(WIFI_SSID, WIFI_PASS);

  pathTele = "devices/" + deviceId + "/telemetry";
  pathCmds = "devices/" + deviceId + "/commands";
  pathSensors = "devices/" + deviceId + "/security/sensors";

  unsigned long startT = millis();
  while (WiFi.status() != WL_CONNECTED && millis() - startT < 10000) {
    delay(100);
    animateLEDs();
  }

  if (WiFi.status() == WL_CONNECTED) {
    configTime(19800, 0, "pool.ntp.org");
    xTaskCreatePinnedToCore(connectivityTask, "ConnTask", 2048, NULL, 1, NULL,
                            0);
    systemInitTime = millis();
    for (int i = 0; i < 3; i++) {
      digitalWrite(BUZZER_PIN, HIGH);
      delay(50);
      digitalWrite(BUZZER_PIN, LOW);
      delay(50);
    }
  }

  ArduinoOTA.setHostname(OTA_HOSTNAME);
  ArduinoOTA.setPassword(OTA_PASSWORD);
  ArduinoOTA.begin();

  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;
  config.token_status_callback = tokenStatusCallback;
  Firebase.signUp(&config, &auth, "", "");
  Firebase.begin(&config, &auth);

  Firebase.RTDB.beginStream(&fbStream, pathCmds.c_str());
  Firebase.RTDB.setStreamCallback(&fbStream, streamCallback,
                                  streamTimeoutCallback);

  if (esp_now_init() == ESP_OK) {
    esp_now_register_recv_cb(OnDataRecv);
    esp_now_peer_info_t peerInfo = {};
    memset(peerInfo.peer_addr, 0xFF, 6);
    peerInfo.channel = 0;
    peerInfo.encrypt = false;
    esp_now_add_peer(&peerInfo);
  }
  xTaskCreatePinnedToCore(voltageTask, "VoltageTask", 5120, NULL, 1, NULL, 0);

  Firebase.RTDB.setStringAsync(&fbTele, (pathTele + "/hubMac").c_str(),
                               WiFi.macAddress());

  // === WATCHDOG INITIALIZATION ===
  esp_task_wdt_init(30, true); // 30 second timeout
  esp_task_wdt_add(NULL);      // Add current thread (Main Loop)

  // Presence & Cleanup Nodes
  Firebase.RTDB.setBoolAsync(
      &fbTele, ("devices/" + deviceId + "/status/online").c_str(), true);
  Firebase.RTDB.deleteNodeAsync(&fbTele,
                                ("devices/" + deviceId + "/events").c_str());
  Firebase.RTDB.deleteNodeAsync(
      &fbTele, ("devices/" + deviceId + "/security/activeBreaches").c_str());

  Serial.println("✅ SYSTEM READY.");
}

/* ================= HELPERS ================= */
int getCurrentPeriodIdx() {
  struct tm timeinfo;
  if (!getLocalTime(&timeinfo))
    return -1;
  int h = timeinfo.tm_hour;
  if (h >= 6 && h < 12)
    return 0;
  if (h >= 12 && h < 17)
    return 1;
  if (h >= 17 && h < 20)
    return 2;
  if (h >= 20 && h <= 23)
    return 3;
  return 4;
}

void processMeshData() {
  if (!meshDataPending)
    return;
  unsigned long now = millis();
  String sid = String(incomingData.sensorId);

  // 🛡️ BOOT GUARD (15s stabilization)
  if (now - systemInitTime < 15000) {
    meshDataPending = false;
    return;
  }

  int curP = getCurrentPeriodIdx();
  bool isScheduled = (curP == -1 || activePeriods[curP]);

  // LDR Update & Stale Check
  if (sid.startsWith("PIR") || sid == "NODE_GOLD") {
    globalLdrValue = incomingData.lightLevel;
    ldrValid = true;
    lastLdrUpdate = now;
  }
  if (now - lastLdrUpdate > 60000)
    ldrValid = false;

  // Security Mode Decision (Individual Sensor Privilege)
  bool isDark = !ldrValid || (globalLdrValue <= globalLdrThreshold);
  bool systemActive = false;
  int sMode = (sensorMode.count(sid) > 0) ? sensorMode[sid] : securityMode;

  if (sMode == 0)
    systemActive = isDark;
  else if (sMode == 1)
    systemActive = isScheduled;
  else if (sMode == 2)
    systemActive = isScheduled && isDark;

  int debounceVal = 800;
  int pIdx = (sid.startsWith("PIR") && sid.length() >= 4)
                 ? (sid.substring(3).toInt() - 1)
                 : -1;
  if (pIdx >= 0 && pIdx < 4)
    debounceVal = pirDebounce[pIdx];

  if (incomingData.motion &&
      (now - lastTriggerTimeMap[sid] < (unsigned long)debounceVal)) {
    meshDataPending = false;
    return;
  }

  // Log Telemetry
  FirebaseJson sensorData;
  sensorData.set("status", incomingData.motion);
  sensorData.set("lightLevel", incomingData.lightLevel);
  if (incomingData.motion)
    sensorData.set("lastTriggered", (int)time(NULL));
  Firebase.RTDB.setJSONAsync(&fbTele, (pathSensors + "/" + sid).c_str(),
                             &sensorData);

  if (incomingData.motion) {
    // 🎯 TEMPORAL EVENT COMPRESSION (Batching)
    motionBatchCounter[sid]++;
    if (motionBatchStartTime[sid] == 0)
      motionBatchStartTime[sid] = now;
    if (now - motionBatchStartTime[sid] > 10000) {
      logEvent("motion_batch", sid, String(motionBatchCounter[sid]));
      motionBatchCounter[sid] = 0;
      motionBatchStartTime[sid] = now;
    }

    int reqHits = 1;
    if (pIdx >= 0 && pIdx < 4)
      reqHits = pirDetectionCount[pIdx];

    unsigned long timeSinceLast = now - lastTriggerTimeMap[sid];
    int window = (reqHits >= 3) ? 10000 : 15000;

    if (reqHits > 1 && timeSinceLast > window)
      sensorHitCounter[sid] = 1;
    else
      sensorHitCounter[sid]++;

    lastTriggerTimeMap[sid] = now;

    if (sensorHitCounter[sid] >= reqHits) {
      sensorHitCounter[sid] = 0;
      // Automation
      if (isAutoGlobalEnabled && systemActive) {
        if (pIdx >= 0 && pIdx < 4) {
          int mask = mapPIR[pIdx];
          for (int r = 0; r < 7; r++) {
            if ((mask & (1 << r)) != 0) {
              applyRelayUpdate(r, 1, 1);
              autoTriggerTime[r] = now;
              isNeuralTriggered[r] = true;
            }
          }
        }
      }
      // Alarm (Forensic Push Sequencing)
      if (isArmed && systemActive && !isPanicActive) {
        triggerBuzzer(400);
        String breachPath = "devices/" + deviceId + "/security/activeBreaches";
        FirebaseJson breach;
        breach.set("sensor", sid);
        breach.set("timestamp", (int)time(NULL));
        Firebase.RTDB.pushJSONAsync(&fbTele, breachPath.c_str(), &breach);
        logEvent("security_breach", sid, "Zone Alert");
      }
    }
  } else {
    // 💤 Reset temporal batcher on idle
    motionBatchStartTime[sid] = 0;
    motionBatchCounter[sid] = 0;
  }

  meshDataPending = false;
}

void loop() {
  animateLEDs();
  ArduinoOTA.handle();
  processMeshData();

  // 🏥 Self-Healing Stream Monitor
  if (millis() - lastCloudActivity > 30000) { // Check every 30s
    if (Firebase.ready() && isInternetLive) {
      if (!Firebase.RTDB.readStream(&fbStream)) {
        Serial.println("♻️ Restarting Stream...");
        Firebase.RTDB.beginStream(&fbStream, pathCmds.c_str());
      }
      lastCloudActivity = millis();
    }
  }

  if (updateRelays) {
    applyRelays();
    updateRelays = false;
  }

  static unsigned long lastTeleCheck = 0;
  if (millis() - lastTeleCheck > (isEcoMode ? 2000 : 500)) {
    lastTeleCheck = millis();
    if (forceTelemetry || (millis() - lastTelemetryTime > reportInterval)) {
      if (Firebase.ready() && isInternetLive) {
        FirebaseJson j;
        for (int i = 0; i < 7; i++) {
          char k[16];
          sprintf(k, "relay%d", i + 1);
          j.set(k, relayState[i]);
          sprintf(k, "prio%d", i + 1);
          j.set(k, relayPriority[i]);
        }
        j.set("voltage", sharedVoltage);
        j.set("heap", (int)ESP.getFreeHeap());
        j.set("hubMac", WiFi.macAddress());
        j.set("isNight", globalLdrValue < globalLdrThreshold);
        j.set("lastUpdate", (double)millis());

        // Tiered Status (Safe Summary)
        FirebaseJson status;
        status.set("online", true);
        double ts = (time(nullptr) > 1000000) ? (double)time(nullptr)
                                              : (double)millis();
        status.set("lastSeen", ts);
        status.set("panic", isPanicActive);
        status.set("isArmed", isArmed);
        status.set("ldrValid", ldrValid);
        status.set("rssi", WiFi.RSSI());
        for (int i = 0; i < 7; i++) {
          char k[16];
          sprintf(k, "r%d", i + 1);
          status.set(k, relayState[i]);
        }
        String pathStatusNode = "devices/" + deviceId + "/status";
        Firebase.RTDB.updateNodeAsync(&fbTele, pathStatusNode.c_str(), &status);

        // Full Forensic Telemetry
        if (Firebase.RTDB.updateNodeAsync(&fbTele, pathTele.c_str(), &j)) {
          lastTelemetryTime = millis();
          forceTelemetry = false;
        }
      }
    }
  }

  // Automation Timer Logic
  unsigned long now = millis();
  for (int i = 0; i < 7; i++) {
    if (autoDuration[i] > 0 && isNeuralTriggered[i]) {
      if (now - autoTriggerTime[i] > (unsigned long)autoDuration[i] * 1000) {
        applyRelayUpdate(i, 0, 0);
        isNeuralTriggered[i] = false;
      }
    }
  }

  // 🏥 Self-Healing & Heap Guard (101% Stability)
  if (ESP.getFreeHeap() < 12000) {
    ESP.restart(); // Proactive memory safety
  }

  if (millis() - lastCloudActivity > 45000) {
    if (Firebase.ready() && isInternetLive) {
      Firebase.RTDB.beginStream(&fbStream, pathCmds.c_str());
      lastCloudActivity = millis();
    }
  }

  yield();
  esp_task_wdt_reset();
}
