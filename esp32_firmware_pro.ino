/*
 * NEBULA CORE – COMPLETE SYSTEM (CLOUD-ONLY EDITION)
 * VERSION: v1.6.5-ULTIMATE-PRO-GOLD
 * ------------------------------------------------
 * STATUS LED LOGIC:
 * PRIORITY 1: OTA Update (Red/Blue Strobe).
 * PRIORITY 2: Data Flash (Blue) -> Overrides Status.
 * PRIORITY 3: Status (Green=OK, Red=No Network).
 *
 * FEATURES ADDED OVER SOLID BASE:
 * - Broadcast ESP-NOW (MAC-agnostic mesh)
 * - Proactive 4-zone PIR discovery on boot
 * - Real-time sensor telemetry to security/sensors
 * - Master LDR sync from heartbeat + motion
 * - LDR-gated Neural automation (no daylight triggers)
 * - Individual timer priority (App slider > global pirTimer)
 * - Standalone LDR-based relay automation
 * - Individual calibration path parsing (sensitivity/debounce)
 * - Rule-compliant JSON security logs
 * - testMesh simulation command
 * - Hub MAC / isNight / ch telemetry
 */

#include <ArduinoOTA.h>
#include <ESPmDNS.h>
#include <Firebase_ESP_Client.h>
#include <WiFi.h>
#include <WiFiUdp.h>
#include <esp_now.h>
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
#define MANUAL_LOCKOUT_MS 5000
#define DEADMAN_TIMEOUT_MS 120000
#define LED_PULSE_MS 100

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

int pirTimer = 60;
int autoTimeMode[7] = {0, 0, 0, 0, 0, 0, 0};
int mapPIR[5] = {0, 0, 0, 0, 0};
int pirDetectionCount[5] = {2, 2, 2, 2, 2};
int pirDebounce[5] = {200, 200, 200, 200, 200};

bool activePeriods[5] = {true, true, true, true, true};
const char *periodNames[5] = {"morning", "afternoon", "evening", "night",
                              "midnight"};
std::map<String, int> sensorMode;
unsigned long lastPanicPulse = 0;
bool buzzerPending = false;
unsigned long buzzerStartTime = 0;
int buzzerDuration = 200;

std::map<String, int> sensorDebounce;
std::map<String, int> sensorSensitivity;
std::map<String, int> sensorHitCounter;
std::map<String, unsigned long> lastTriggerTimeMap;

bool updateRelays = false;
bool forceTelemetry = false;
volatile float sharedVoltage = 0.0;
unsigned long lastTelemetryTime = 0;
float lastReportedVoltage = 0;
bool isArmed = true;
bool isBuzzerMuted = false;
bool isLdrSecurityEnabled = false;
bool isAutoGlobalEnabled = true;
unsigned long blueLedOffTime = 0;
int globalLdrThreshold = 50;
bool isEcoMode = false;
int reportInterval = 8000;

String pathTele, pathEvents, pathCmds, pathSensors;
bool isActivityFlashing = false;
unsigned long activityStart = 0;
bool isPanicActive = false;
bool buzzerPending = false;
unsigned long buzzerStartTime = 0;
int buzzerDuration = 200;
unsigned long lastPanicPulse = 0;
bool safetyTripped = false;
unsigned long lastCloudActivity = 0;

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
}

void triggerHardware() {
  updateRelays = true;
  applyRelays();
  updateRelays = false;
}

/* ================= STREAM CALLBACK ================= */
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
    if (json->get(d, "relay1")) {
      if (relayState[0] != (bool)d.intValue) {
        relayState[0] = d.intValue;
        wasRelayUpdated = true;
      }
    }
    if (json->get(d, "relay2")) {
      if (relayState[1] != (bool)d.intValue) {
        relayState[1] = d.intValue;
        wasRelayUpdated = true;
      }
    }
    if (json->get(d, "relay3")) {
      if (relayState[2] != (bool)d.intValue) {
        relayState[2] = d.intValue;
        wasRelayUpdated = true;
      }
    }
    if (json->get(d, "relay4")) {
      if (relayState[3] != (bool)d.intValue) {
        relayState[3] = d.intValue;
        wasRelayUpdated = true;
      }
    }
    if (json->get(d, "relay5")) {
      if (relayState[4] != (bool)d.intValue) {
        relayState[4] = d.intValue;
        wasRelayUpdated = true;
      }
    }
    if (json->get(d, "relay6")) {
      if (relayState[5] != (bool)d.intValue) {
        relayState[5] = d.intValue;
        wasRelayUpdated = true;
      }
    }
    if (json->get(d, "relay7")) {
      if (relayState[6] != (bool)d.intValue) {
        relayState[6] = d.intValue;
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
    }
    if (json->get(d, "isArmed") || json->get(d, "security/isArmed")) {
      isArmed = d.boolValue;
      if (!isArmed)
        Firebase.RTDB.deleteNode(
            &fbTele,
            ("devices/" + deviceId + "/security/activeBreaches").c_str());
    }
    if (json->get(d, "buzzerMute"))
      isBuzzerMuted = d.boolValue;
    if (json->get(d, "ldrThreshold"))
      globalLdrThreshold = d.intValue;
    if (json->get(d, "ldrSecurity"))
      isLdrSecurityEnabled = d.boolValue;
    if (json->get(d, "pirTimer"))
      pirTimer = d.intValue;

    if (json->get(d, "autoGlobal") || json->get(d, "autoLightOnMotion") ||
        json->get(d, "security/autoGlobal") ||
        json->get(d, "security/autoLightOnMotion"))
      isAutoGlobalEnabled = d.boolValue;

    for (int i = 1; i <= 4; i++) {
      char key[16], sKey[48], dKey[48], mKey[48];
      sprintf(key, "mapPIR%d", i);
      sprintf(sKey, "security/calibration/PIR%d/detection_count", i);
      sprintf(dKey, "security/calibration/PIR%d/debounce", i);
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
      FirebaseJson testLog;
      testLog.set("sensor", "PIR1-TEST");
      testLog.set("timestamp", (int)time(NULL));
      Firebase.RTDB.pushJSONAsync(&fbTele, pathEvents.c_str(), &testLog);
    }
  } else {
    // === INDIVIDUAL PATH UPDATES ===
    if (path.startsWith("/relay")) {
      int idx = path.substring(6).toInt() - 1;
      if (idx >= 0 && idx < 7) {
        if (relayState[idx] != (bool)data.intData()) {
          relayState[idx] = data.intData();
          wasRelayUpdated = true;
        }
      }
    } else if (path == "/isArmed" || path == "/security/isArmed") {
      isArmed = data.boolData();
      if (!isArmed)
        Firebase.RTDB.deleteNode(
            &fbTele,
            ("devices/" + deviceId + "/security/activeBreaches").c_str());
    } else if (path == "/panic" || path == "/security/panic") {
      isPanicActive = data.boolData();
      if (isPanicActive)
        triggerBuzzer(1000);
    } else if (path == "/buzzerMute" || path == "/security/buzzerMute") {
      isBuzzerMuted = data.boolData();
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
    } else if (path.startsWith("/mapPIR")) {
      int pIdx = path.substring(7).toInt() - 1;
      if (pIdx >= 0 && pIdx < 4)
        mapPIR[pIdx] = data.intData();
    } else if (path == "/pirTimer" || path == "/security/pirTimer") {
      pirTimer = data.intData();
    } else if (path == "/ldrThreshold" || path == "/security/ldrThreshold") {
      globalLdrThreshold = data.intData();
    } else if (path == "/ldrSecurity" || path == "/security/ldrSecurity") {
      isLdrSecurityEnabled = data.boolData();
    } else if (path == "/autoGlobal" || path == "/security/autoGlobal" ||
               path == "/autoLightOnMotion" ||
               path == "/security/autoLightOnMotion") {
      isAutoGlobalEnabled = data.boolData();
    } else if (path == "/ecoMode") {
      isEcoMode = data.boolData();
    }
  }

  if (wasRelayUpdated) {
    unsigned long lockout_now = millis();
    for (int i = 0; i < 7; i++)
      manualOverrideTime[i] = lockout_now;
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
  pathEvents = "devices/" + deviceId + "/events";
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
    // 🔊 Boot hardware test beeps
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

  // 🛰 BROADCAST ESP-NOW (MAC-agnostic mesh)
  if (esp_now_init() == ESP_OK) {
    esp_now_register_recv_cb(OnDataRecv);
    esp_now_peer_info_t peerInfo = {};
    memset(peerInfo.peer_addr, 0xFF, 6);
    peerInfo.channel = 0;
    peerInfo.encrypt = false;
    esp_now_add_peer(&peerInfo);
  }
  xTaskCreatePinnedToCore(voltageTask, "VoltageTask", 5120, NULL, 1, NULL, 0);

  // 📡 OTA DIAGNOSTICS
  Serial.print("📡 HUB MAC: ");
  Serial.println(WiFi.macAddress());
  Firebase.RTDB.setStringAsync(&fbTele, (pathTele + "/hubMac").c_str(),
                               WiFi.macAddress());

  // 🛡️ PROACTIVE 4-ZONE DISCOVERY (Force-create sensor slots)
  Firebase.RTDB.setBoolAsync(
      &fbTele, ("devices/" + deviceId + "/security/bootSignal").c_str(), true);
  for (int i = 1; i <= 4; i++) {
    String p = "PIR" + String(i);
    FirebaseJson initData;
    initData.set("status", false);
    initData.set("lightLevel", 0);
    Firebase.RTDB.setJSONAsync(&fbTele, (pathSensors + "/" + p).c_str(),
                               &initData);
    FirebaseJson disc;
    disc.set("name", p);
    Firebase.RTDB.updateNodeAsync(
        &fbTele,
        ("devices/" + deviceId + "/security/discovery/pending/" + p).c_str(),
        &disc);
  }
  Firebase.RTDB.setIntAsync(
      &fbTele, ("devices/" + deviceId + "/security/masterLDR").c_str(), 0);

  // === WATCHDOG INITIALIZATION (v3.0.0 Compatible) ===
  esp_task_wdt_config_t twdt_config = {
      .timeout_ms = 30000,
      .idle_core_mask = (1 << portNUM_PROCESSORS) - 1,
      .trigger_panic = true,
  };
  esp_task_wdt_init(&twdt_config);
  esp_task_wdt_add(NULL);

  Firebase.RTDB.deleteNode(
      &fbTele, ("devices/" + deviceId + "/security/activeBreaches").c_str());
  Firebase.RTDB.deleteNode(&fbTele, pathEvents.c_str());

  Serial.println("✅ SYSTEM READY.");
  lastCloudActivity = millis();
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
  int curP = getCurrentPeriodIdx();
  bool isScheduled = (curP == -1 || activePeriods[curP]);

  int debounceVal = 800;
  if (sensorDebounce.count(sid))
    debounceVal = sensorDebounce[sid];
  int pIdx = (sid.startsWith("PIR") && sid.length() >= 4)
                 ? (sid.substring(3).toInt() - 1)
                 : -1;
  if (pIdx >= 0 && pIdx < 4)
    debounceVal = pirDebounce[pIdx];

  // SOFTWARE DEBOUNCE
  if (incomingData.motion &&
      (now - lastTriggerTimeMap[sid] < (unsigned long)debounceVal)) {
    meshDataPending = false;
    return;
  }

  // 🛡️ VERBOSE DEBUGGING
  Serial.printf("📡 Hub Mesh: ID=%s | Motion=%d | LDR=%d\n", sid.c_str(),
                incomingData.motion, incomingData.lightLevel);
  Firebase.RTDB.setStringAsync(&fbTele, (pathTele + "/lastNode").c_str(), sid);
  Firebase.RTDB.setIntAsync(&fbTele, (pathTele + "/lastNodeLdr").c_str(),
                            incomingData.lightLevel);

  // 🛡️ AUTO-DISCOVERY (Announce to App if new)
  static std::set<String> discoveredSensors;
  if (discoveredSensors.find(sid) == discoveredSensors.end()) {
    FirebaseJson disc;
    disc.set("name", sid);
    Firebase.RTDB.updateNodeAsync(
        &fbTele,
        ("devices/" + deviceId + "/security/discovery/pending/" + sid).c_str(),
        &disc);
    discoveredSensors.insert(sid);
  }

  // 🛡️ REAL-TIME SENSOR TELEMETRY (For App Dynamic UI)
  FirebaseJson sensorData;
  sensorData.set("status", incomingData.motion);
  sensorData.set("lightLevel", incomingData.lightLevel);
  if (incomingData.motion)
    sensorData.set("lastTriggered", (int)time(NULL));
  Firebase.RTDB.setJSONAsync(&fbTele, (pathSensors + "/" + sid).c_str(),
                             &sensorData);

  // 🌓 Update Master LDR (Heartbeat + Motion)
  if (sid.startsWith("PIR") || sid == "NODE_GOLD") {
    Firebase.RTDB.setIntAsync(
        &fbTele, ("devices/" + deviceId + "/security/masterLDR").c_str(),
        incomingData.lightLevel);
  }

  if (incomingData.motion) {
    // 🎯 SENSITIVITY CALIBRATION
    int reqHits = 2;
    if (pIdx >= 0 && pIdx < 4)
      reqHits = pirDetectionCount[pIdx];

    sensorHitCounter[sid]++;
    lastTriggerTimeMap[sid] = now;

    if (sensorHitCounter[sid] >= reqHits) {
      // 🌓 Mode Validation
      int mode = 2; // Default Hybrid
      if (sensorMode.count(sid))
        mode = sensorMode[sid];

      bool isLdrOk = (incomingData.lightLevel <= globalLdrThreshold);
      bool isTimeOk = isScheduled;
      bool canTrigger = false;

      if (mode == 0)
        canTrigger = isLdrOk;
      else if (mode == 1)
        canTrigger = isTimeOk;
      else
        canTrigger = (isLdrOk && isTimeOk);

      if (!canTrigger) {
        sensorHitCounter[sid] = 0;
        meshDataPending = false;
        return;
      }
      Serial.printf("📡 Hub Received: %s | Motion: %d | Hits: %d/%d\n",
                    sid.c_str(), incomingData.motion, sensorHitCounter[sid],
                    reqHits);

      // 🧠 NEURAL HUB AUTOMATION (LDR Gated)
      if (isAutoGlobalEnabled &&
          (incomingData.lightLevel <= globalLdrThreshold)) {
        if (pIdx >= 0 && pIdx < 4) {
          int mask = mapPIR[pIdx];
          for (int r = 0; r < 7; r++) {
            if (now - manualOverrideTime[r] < MANUAL_LOCKOUT_MS)
              continue;
            if ((mask & (1 << r)) != 0) {
              relayState[r] = 1;
              autoTriggerTime[r] = now;
              isNeuralTriggered[r] = true;
              updateRelays = true;
            }
          }
        }
      }

      // 🛡 SECURITY ALARM LOGIC (Rule-Compliant JSON Logs)
      if (isArmed && isScheduled) {
        if (!isLdrSecurityEnabled ||
            incomingData.lightLevel <= globalLdrThreshold) {
          triggerBuzzer(400);
          FirebaseJson breachLog;
          breachLog.set("sensor", sid);
          breachLog.set("timestamp", (int)time(NULL));
          Firebase.RTDB.pushJSONAsync(&fbTele, pathEvents.c_str(), &breachLog);

          // 🚨 ACTIVE BREACH AGGREGATION
          Firebase.RTDB.setBoolAsync(
              &fbTele,
              ("devices/" + deviceId + "/security/activeBreaches/" + sid)
                  .c_str(),
              true);
        }
      }
      sensorHitCounter[sid] = 0;
    }
  } else {
    sensorHitCounter[sid] = 0;
  }

  // 🛡️ STANDALONE LDR AUTOMATION ENGINE
  for (int r = 0; r < 7; r++) {
    if (autoActive[r] && autoSensor[r] == "ldr") {
      if (incomingData.lightLevel <= autoThreshold[r]) {
        if (!relayState[r]) {
          relayState[r] = 1;
          autoTriggerTime[r] = millis();
          updateRelays = true;
        }
      } else {
        if (relayState[r]) {
          relayState[r] = 0;
          updateRelays = true;
        }
      }
    }
  }

  meshDataPending = false;
}

/* ================= LOOP ================= */
void loop() {
  animateLEDs();
  ArduinoOTA.handle();
  if (updateRelays) {
    applyRelays();
    updateRelays = false;
  }

  static unsigned long lastWiFiCheck = 0;
  if (millis() - lastWiFiCheck > 20000) {
    lastWiFiCheck = millis();
    if (WiFi.status() != WL_CONNECTED)
      WiFi.reconnect();
  }

  static unsigned long lastTeleCheck = 0;
  if (millis() - lastTeleCheck > (isEcoMode ? 2000 : 500)) {
    lastTeleCheck = millis();
    if (forceTelemetry || (millis() - lastTelemetryTime > reportInterval)) {
      if (Firebase.ready() && isInternetLive) {
        FirebaseJson j;
        for (int i = 0; i < 7; i++) {
          char k[8];
          sprintf(k, "relay%d", i + 1);
          j.set(k, relayState[i]);
        }
        j.set("voltage", sharedVoltage);
        j.set("heap", (int)ESP.getFreeHeap());
        j.set("isNight", incomingData.lightLevel < globalLdrThreshold);
        j.set("ch", (int)WiFi.channel());
        if (Firebase.RTDB.updateNodeAsync(&fbTele, pathTele.c_str(), &j)) {
          lastTelemetryTime = millis();
          lastCloudActivity = millis();
          forceTelemetry = false;
        }
      }
    }
  }

  // ⏱ AUTOMATION TIMER ENGINE (Individual Priority)
  for (int i = 0; i < 7; i++) {
    if (relayState[i] == 0) {
      autoTriggerTime[i] = 0;
      isNeuralTriggered[i] = false;
      continue;
    }
    // Individual App timer takes priority; fallback to global pirTimer
    unsigned long dur =
        (autoDuration[i] > 0)
            ? ((unsigned long)autoDuration[i] * 1000UL)
            : (isNeuralTriggered[i] ? ((unsigned long)pirTimer * 1000UL) : 0);
    if (dur > 0 && autoTriggerTime[i] > 0 &&
        (millis() - autoTriggerTime[i] > dur)) {
      relayState[i] = 0;
      autoTriggerTime[i] = 0;
      isNeuralTriggered[i] = false;
      updateRelays = true;
      forceTelemetry = true;
    }
  }

  processMeshData();

  // DEADMAN'S SWITCH
  if (millis() - lastCloudActivity > DEADMAN_TIMEOUT_MS) {
    if (!safetyTripped) {
      for (int i = 0; i < 7; i++)
        relayState[i] = 0;
      updateRelays = true;
      safetyTripped = true;
    }
  } else {
    safetyTripped = false;
  }

  delay(isEcoMode ? 10 : 2);
}
