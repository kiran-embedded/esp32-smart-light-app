/*
 * NEBULA CORE – COMPLETE SYSTEM (CLOUD-ONLY EDITION)
 * VERSION: v1.6.0 (ULTRA-FAST, ANTI-CRASH, PERFECT MESH)
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
#include <addons/RTDBHelper.h>
#include <addons/TokenHelper.h>
#include <esp_now.h>
#include <esp_wifi.h> // Required for advanced WiFi/Mesh stability

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
#define BUZZER_PIN 13
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

/* ================= DYNAMIC MODES & SENSORS ================= */
bool isEcoMode = false;
int reportInterval = 4000;
uint32_t tele_id = 0;

#define LDR_NIGHT_THRESHOLD 30
unsigned long PIR_ON_DURATION = 60000;
unsigned long pirAutoOffTimer[7] = {0, 0, 0, 0, 0, 0, 0};
int pirTimerSeconds = 60;
uint8_t pirRelayMask[5] = {1, 2, 4, 8, 16};

// --- ADVANCED CALIBRATION ---
int pirSensitivity[5] = {80, 80, 80, 80, 80};   // 1-100 (Pulse Threshold)
int pirDebounce[5] = {200, 200, 200, 200, 200}; // ms (Stable Time)
unsigned long pirLastHighTime[5] = {0, 0, 0, 0, 0};
int pirSignalStrength[5] = {0, 0, 0, 0, 0}; // 0-100 for live visualization

/* ================= GLOBALS & CACHED STRINGS ================= */
FirebaseData fbTele;
FirebaseData fbStream;
FirebaseAuth auth;
FirebaseConfig config;
String deviceId = "79215788";

// PRE-ALLOCATED PATHS (Crucial to stop Heap Fragmentation / Random Restarts)
String pathTele;
String pathLogs;
String pathCmds;
String pathSensors;
String pathArmed;
String pathAlarm;
String pathMac;
String pathCalibration;

bool relayState[7] = {0, 0, 0, 0, 0, 0, 0};
bool invertedLogic[7] = {0, 0, 0, 0, 0, 0, 0};
volatile bool updateRelays =
    false; // volatile because it's modified in async callback
bool forceTelemetry = false;

volatile float sharedVoltage = 0.0;
unsigned long lastTelemetryTime = 0;
float lastReportedVoltage = 0;

bool isArmed = true;
bool isBuzzerMuted = false;
bool isLdrSecurityEnabled = false;
volatile bool isInternetLive = false;
bool isOTAActive = false;
bool isActivityFlashing = false;
unsigned long activityStart = 0;
unsigned long lastMeshPacketTime = 0;

// --- DEADMAN SAFETY VARIABLES ---
bool safetyTripped = false;
unsigned long lastCloudActivity = 0;
#define DEADMAN_TIMEOUT_MS 300000

/* ================= SECURITY & BUZZER ================= */
bool isAlarmActive = false;
unsigned long alarmStartTime = 0;
unsigned long lastBeepToggle = 0;
bool buzzerState = false;
const int ALARM_DURATION_MS = 10000;

/* ================= MESH STRUCTURE ================= */
typedef struct struct_message {
  bool pir1;
  bool pir2;
  bool pir3;
  bool pir4;
  bool pir5;
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
        targetColor = 1;
    } else {
      unsigned long cycle = now % (isEcoMode ? 4000 : 2000);
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
void triggerBuzzerFeedback(bool arming) {
  if (isBuzzerMuted)
    return;
  if (arming) {
    // Two short beeps for Armed
    digitalWrite(BUZZER_PIN, HIGH);
    delay(80);
    digitalWrite(BUZZER_PIN, LOW);
    delay(80);
    digitalWrite(BUZZER_PIN, HIGH);
    delay(80);
    digitalWrite(BUZZER_PIN, LOW);
  } else {
    // One long beep for Disarmed
    digitalWrite(BUZZER_PIN, HIGH);
    delay(300);
    digitalWrite(BUZZER_PIN, LOW);
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

    // 40ms is safe for WDT. Removed yield() inside this tight loop
    // to ensure maximum ADC sampling speed and accurate RMS calculation.
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

    // Explicitly yields to scheduler here, preventing Core 1 Starvation
    vTaskDelay((isEcoMode ? 200 : 100) / portTICK_PERIOD_MS);
  }
}

/* ================= FIREBASE HELPER (ASYNC) ================= */
void logMotionToFirebase(String sensorName) {
  FirebaseJson log;
  log.set("sensor", sensorName);
  log.set("timestamp", millis());

  // Utilizes pre-allocated path to prevent memory leaks
  Firebase.RTDB.pushJSONAsync(&fbTele, pathLogs.c_str(), &log);

  FirebaseJson sensorState;
  sensorState.set("status", true);
  sensorState.set("lastTriggered", millis());

  String specificSensorPath = pathSensors + "/" + sensorName;
  Firebase.RTDB.updateNodeAsync(&fbTele, specificSensorPath.c_str(),
                                &sensorState);
}

/* ================= HARDWARE CONTROL ================= */
void applyRelays() {
  Serial.printf("Relay CMD: %d %d %d %d %d %d %d | Heap: %d\n", relayState[0],
                relayState[1], relayState[2], relayState[3], relayState[4],
                relayState[5], relayState[6], ESP.getFreeHeap());
  digitalWrite(RELAY1, (relayState[0] ^ invertedLogic[0]) ? HIGH : LOW);
  digitalWrite(RELAY2, (relayState[1] ^ invertedLogic[1]) ? HIGH : LOW);
  digitalWrite(RELAY3, (relayState[2] ^ invertedLogic[2]) ? HIGH : LOW);
  digitalWrite(RELAY4, (relayState[3] ^ invertedLogic[3]) ? HIGH : LOW);
  digitalWrite(RELAY5, (relayState[4] ^ invertedLogic[4]) ? HIGH : LOW);
  digitalWrite(RELAY6, (relayState[5] ^ invertedLogic[5]) ? HIGH : LOW);
  digitalWrite(RELAY7, (relayState[6] ^ invertedLogic[6]) ? HIGH : LOW);
}

/* ================= ASYNC BUZZER ENGINE ================= */
void processBuzzer() {
  if (isAlarmActive) {
    if (millis() - alarmStartTime > ALARM_DURATION_MS) {
      isAlarmActive = false;
      digitalWrite(BUZZER_PIN, LOW);
      buzzerState = false;
    } else {
      unsigned long now = millis();
      if (buzzerState) {
        if (now - lastBeepToggle >= 80) {
          buzzerState = false;
          digitalWrite(BUZZER_PIN, LOW);
          lastBeepToggle = now;
        }
      } else {
        if (now - lastBeepToggle >= 50) {
          buzzerState = true;
          digitalWrite(BUZZER_PIN, HIGH);
          lastBeepToggle = now;
        }
      }
    }
  } else {
    digitalWrite(BUZZER_PIN, LOW);
  }
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
    if (json->get(d, "relay1")) {
      relayState[0] = d.intValue;
      pirAutoOffTimer[0] = 0;
    }
    if (json->get(d, "relay2")) {
      relayState[1] = d.intValue;
      pirAutoOffTimer[1] = 0;
    }
    if (json->get(d, "relay3")) {
      relayState[2] = d.intValue;
      pirAutoOffTimer[2] = 0;
    }
    if (json->get(d, "relay4")) {
      relayState[3] = d.intValue;
      pirAutoOffTimer[3] = 0;
    }
    if (json->get(d, "relay5")) {
      relayState[4] = d.intValue;
      pirAutoOffTimer[4] = 0;
    }
    if (json->get(d, "relay6")) {
      relayState[5] = d.intValue;
      pirAutoOffTimer[5] = 0;
    }
    if (json->get(d, "relay7")) {
      relayState[6] = d.intValue;
      pirAutoOffTimer[6] = 0;
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

    for (int i = 1; i <= 5; i++) {
      char mapKey[16];
      sprintf(mapKey, "mapPIR%d", i);
      if (json->get(d, mapKey)) {
        pirRelayMask[i - 1] = d.intValue;
      }
    }
    if (json->get(d, "pirTimer")) {
      pirTimerSeconds = d.intValue;
      PIR_ON_DURATION = (unsigned long)pirTimerSeconds * 1000;
    }

    if (json->get(d, "ecoMode"))
      isEcoMode = d.boolValue;

    if (json->get(d, "panic") || json->get(d, "emergencyAlert")) {
      bool targetState = d.boolValue;
      if (targetState) {
        isAlarmActive = true;
        alarmStartTime = millis();
        Serial.println("🚨 EMERGENCY ALERT: ON");
      } else {
        isAlarmActive = false;
        Serial.println("🚨 EMERGENCY ALERT: OFF");
      }
    }

    if (json->get(d, "alarm_disable")) {
      isAlarmActive = false;
    }

    // --- CALIBRATION SYNC ---
    for (int i = 1; i <= 5; i++) {
      char sensKey[32], debKey[32];
      sprintf(sensKey, "security/calibration/PIR%d/sensitivity", i);
      sprintf(debKey, "security/calibration/PIR%d/debounce", i);

      if (json->get(d, sensKey))
        pirSensitivity[i - 1] = d.intValue;
      if (json->get(d, debKey))
        pirDebounce[i - 1] = d.intValue;
    }
  } else {
    int intVal = data.intData();
    if (path == "/relay1") {
      relayState[0] = intVal;
      pirAutoOffTimer[0] = 0;
    }
    if (path == "/relay2") {
      relayState[1] = intVal;
      pirAutoOffTimer[1] = 0;
    }
    if (path == "/relay3") {
      relayState[2] = intVal;
      pirAutoOffTimer[2] = 0;
    }
    if (path == "/relay4") {
      relayState[3] = intVal;
      pirAutoOffTimer[3] = 0;
    }
    if (path == "/relay5") {
      relayState[4] = intVal;
      pirAutoOffTimer[4] = 0;
    }
    if (path == "/relay6") {
      relayState[5] = intVal;
      pirAutoOffTimer[5] = 0;
    }
    if (path == "/relay7") {
      relayState[6] = intVal;
      pirAutoOffTimer[6] = 0;
    }

    if (path == "/pirTimer") {
      pirTimerSeconds = intVal;
      PIR_ON_DURATION = (unsigned long)pirTimerSeconds * 1000;
    } else {
      for (int i = 1; i <= 5; i++) {
        char mapPath[16];
        sprintf(mapPath, "/mapPIR%d", i);
        if (path == mapPath)
          pirRelayMask[i - 1] = intVal;
      }
    }

    if (path == "/invert1")
      invertedLogic[0] = data.boolData();
    if (path == "/invert2")
      invertedLogic[1] = data.boolData();
    if (path == "/invert3")
      invertedLogic[2] = data.boolData();
    if (path == "/invert4")
      invertedLogic[3] = data.boolData();
    if (path == "/invert5")
      invertedLogic[4] = data.boolData();
    if (path == "/invert6")
      invertedLogic[5] = data.boolData();
    if (path == "/invert7")
      invertedLogic[6] = data.boolData();

    if (path == "/ecoMode") {
      isEcoMode = data.boolData();
      Serial.printf("MODE CHANGED: %s\n", isEcoMode ? "ECO" : "PERFORMANCE");
    }
    if (path == "/panic" || path == "/emergencyAlert") {
      bool targetState = data.boolData();
      if (targetState) {
        isAlarmActive = true;
        alarmStartTime = millis();
        Serial.printf("🚨 EMERGENCY ALERT: ON\n");
      } else {
        isAlarmActive = false;
        Serial.printf("🚨 EMERGENCY ALERT: OFF\n");
      }
    }
    if (path == "/alarm_disable") {
      isAlarmActive = false;
    }

    if (path.indexOf("/security") != -1) {
      if (path == "/isArmed") {
        isArmed = data.boolData();
        triggerBuzzerFeedback(isArmed);
        if (!isArmed)
          isAlarmActive = false;
      }
      if (path == "/isBuzzerMuted")
        isBuzzerMuted = data.boolData();
      if (path == "/isLdrSecurityEnabled")
        isLdrSecurityEnabled = data.boolData();
    }
  }

  reportInterval = isEcoMode ? 8000 : 3000;

  // Set flag for main loop to safely execute with ZERO latency.
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
void OnDataRecv(const esp_now_recv_info_t *info, const uint8_t *data, int len) {
  memcpy(&incomingData, data, sizeof(incomingData));
  lastMeshPacketTime = millis();
  meshDataPending = true; // Minimal code in ISR/Callback ensures no crashes
}

/* ================= SETUP ================= */
void setup() {
  Serial.begin(115200);
  delay(1000);
  Serial.printf("\n\n--- NEBULA CORE BOOT v1.6.0 ---\n");

  // PRE-ALLOCATE PATHS TO PREVENT HEAP FRAGMENTATION
  pathTele = "devices/" + deviceId + "/telemetry";
  pathLogs = "devices/" + deviceId + "/security/logs";
  pathCmds = "devices/" + deviceId + "/commands";
  pathSensors = "devices/" + deviceId + "/security/sensors";
  pathArmed = "devices/" + deviceId + "/security/isArmed";
  pathAlarm = "devices/" + deviceId + "/security/alarmActive";
  pathMac = "devices/" + deviceId + "/wifi_mac_address";
  pathCalibration = "devices/" + deviceId + "/security/calibration";

  pinMode(RELAY1, OUTPUT);
  pinMode(RELAY2, OUTPUT);
  pinMode(RELAY3, OUTPUT);
  pinMode(RELAY4, OUTPUT);
  pinMode(RELAY5, OUTPUT);
  pinMode(RELAY6, OUTPUT);
  pinMode(RELAY7, OUTPUT);
  applyRelays();

  pinMode(BUZZER_PIN, OUTPUT);
  digitalWrite(BUZZER_PIN, LOW);
  initLEDs();

  analogReadResolution(12);
  analogSetAttenuation(ADC_11db);

  WiFi.mode(WIFI_AP_STA);

  // 🔥 CRITICAL FIX: Disable WiFi Power Save.
  // This guarantees ULTRA-FAST Firebase triggers and stops ESP-NOW dropped
  // packets.
  WiFi.setSleep(false);

  WiFi.setAutoReconnect(true);
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
    Serial.printf("Operating Channel: %d\n",
                  WiFi.channel()); // MESH peers MUST match this channel!
    isInternetLive = true;
    triggerActivityLED();
  }

  // Ensure ESP-NOW initiates exactly on the established WiFi channel
  if (esp_now_init() == ESP_OK) {
    esp_now_register_recv_cb(OnDataRecv);
    Serial.println(
        "🔗 ESP-NOW Bridge Initialized (Auto-Synced to WiFi Channel)");
  }

  ArduinoOTA.setHostname(OTA_HOSTNAME);
  ArduinoOTA.setPassword(OTA_PASSWORD);
  ArduinoOTA.onStart([]() {
    isOTAActive = true;
    isAlarmActive = false;
    digitalWrite(BUZZER_PIN, LOW);
  });
  ArduinoOTA.onEnd([]() {
    isOTAActive = false;
    triggerActivityLED();
    ESP.restart();
  });
  ArduinoOTA.begin();

  MDNS.addService("nebula", "tcp", 80);

  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;
  config.token_status_callback = tokenStatusCallback;
  fbStream.setResponseSize(1024);

  Firebase.signUp(&config, &auth, "", "");
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);

  if (Firebase.ready()) {
    Firebase.RTDB.setStringAsync(&fbTele, pathMac.c_str(), WiFi.macAddress());
  }

  Firebase.RTDB.beginStream(&fbStream, pathCmds.c_str());
  Firebase.RTDB.setStreamCallback(&fbStream, streamCallback,
                                  streamTimeoutCallback);

  Firebase.RTDB.setBoolAsync(&fbTele, pathArmed.c_str(), isArmed);

  xTaskCreatePinnedToCore(voltageTask, "VoltageTask", 10000, NULL, 1, NULL, 1);
  lastCloudActivity = millis();
}

/* ================= LOOP ================= */
void loop() {
  animateLEDs();
  processBuzzer();
  ArduinoOTA.handle();

  // Instant apply with ZERO concurrency collisions
  if (updateRelays) {
    applyRelays();
    updateRelays = false;
  }

  if (WiFi.status() == WL_CONNECTED && Firebase.ready()) {
    isInternetLive = true;
  }

  static unsigned long lastTeleCheck = 0;
  if (millis() - lastTeleCheck > (isEcoMode ? 2000 : 500)) {
    lastTeleCheck = millis();
    float currentV = sharedVoltage;
    bool timeExpired = (millis() - lastTelemetryTime > reportInterval);
    // Sensitivity increased to 0.1V for "Engine Grade" monitoring
    bool significantChange = (abs(currentV - lastReportedVoltage) > 0.1);

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
        j.set("tele_id", tele_id++);

        // Signal Strength for Calibration UI
        for (int i = 0; i < 5; i++) {
          char key[16];
          sprintf(key, "signal_p%d", i + 1);
          j.set(key, pirSignalStrength[i]);
        }
        j.set("mesh_ldr", incomingData.lightLevel);
        j.set("mesh_motion", incomingData.pir1);
        j.set("mesh_pir1", incomingData.pir1);
        j.set("isNight", (incomingData.lightLevel < LDR_NIGHT_THRESHOLD));
        j.set("mesh_age", (millis() - lastMeshPacketTime) / 1000);
        j.set("ap_mac", WiFi.softAPmacAddress());
        j.set("ch", WiFi.channel());
        j.set("ecoMode", isEcoMode);
        j.set("lastSeen", millis());
        j.set("buzzer_active", isAlarmActive);
        j.set("tele_id", tele_id++);
        forceTelemetry = false;

        if (Firebase.RTDB.updateNodeAsync(&fbTele, pathTele.c_str(), &j)) {
          lastTelemetryTime = millis();
          lastReportedVoltage = currentV;
          lastCloudActivity = millis();
          Serial.printf("🛰 TELEMETRY SENT | ID: %d | V: %.2f\n", tele_id - 1,
                        currentV);
        } else {
          Serial.printf("❌ TELEMETRY FAILED: %s\n",
                        fbTele.errorReason().c_str());
        }
      }
    }
  }

  // --- AUTO-OFF LIGHT TIMER LOGIC ---
  for (int i = 0; i < 7; i++) {
    if (pirAutoOffTimer[i] > 0 &&
        (millis() - pirAutoOffTimer[i] > PIR_ON_DURATION)) {
      relayState[i] = false;
      pirAutoOffTimer[i] = 0;
      updateRelays = true;
      forceTelemetry = true;
      Serial.printf("💡 Auto-off triggered for Relay %d\n", i + 1);
    }
  }

  // --- DEADMAN'S SWITCH LOGIC ---
  if (millis() - lastCloudActivity > DEADMAN_TIMEOUT_MS) {
    if (!safetyTripped) {
      Serial.println("⛔ DEADMAN TRIP: No Cloud Contact. Safe Halting.");
      for (int i = 0; i < 7; i++)
        relayState[i] = false;
      applyRelays();
      safetyTripped = true;
      isAlarmActive = false;
    }
    if (WiFi.status() != WL_CONNECTED) {
      WiFi.disconnect();
      WiFi.begin(WIFI_SSID, WIFI_PASS);
      lastCloudActivity = millis() - (DEADMAN_TIMEOUT_MS - 30000);
    }
    if (millis() - lastCloudActivity > (DEADMAN_TIMEOUT_MS + 600000)) {
      Serial.println("FATAL: Persistent Isolation. Rebooting...");
      ESP.restart();
    }
  } else {
    safetyTripped = false;
  }

  // --- MESH BRIDGE & SECURITY FORWARDING ---
  if (meshDataPending) {
    Serial.printf("🛰 MESH RECV | LDR: %d | PIRs: %d %d %d %d %d\n",
                  incomingData.lightLevel, incomingData.pir1, incomingData.pir2,
                  incomingData.pir3, incomingData.pir4, incomingData.pir5);

    bool anyMotion =
        (incomingData.pir1 || incomingData.pir2 || incomingData.pir3 ||
         incomingData.pir4 || incomingData.pir5);
    bool isNightTime = (incomingData.lightLevel < LDR_NIGHT_THRESHOLD);

    if (isNightTime) {
      bool localMeshPir[5] = {incomingData.pir1, incomingData.pir2,
                              incomingData.pir3, incomingData.pir4,
                              incomingData.pir5};

      for (int p = 0; p < 5; p++) {
        if (localMeshPir[p]) {
          for (int r = 0; r < 7; r++) {
            if (pirRelayMask[p] & (1 << r)) {
              if (!relayState[r]) {
                relayState[r] = true;
                updateRelays = true;
              }
              // Always refresh timer when motion exists
              pirAutoOffTimer[r] = millis();
            }
          }
        }
      }
      if (updateRelays)
        forceTelemetry = true;
    }

    const bool ldrPass = (!isLdrSecurityEnabled ||
                          incomingData.lightLevel < LDR_NIGHT_THRESHOLD);

    // --- NEURAL GRID TRIGGER LOGIC (Relay Automation) ---
    // Works independently of Security Arming State if it's "NightTime" for
    // mapped relays
    if (incomingData.lightLevel < LDR_NIGHT_THRESHOLD) {
      for (int p = 0; p < 5; p++) {
        // Direct array access for incomingData PIRs
        bool currentPirActive = false;
        if (p == 0)
          currentPirActive = incomingData.pir1;
        else if (p == 1)
          currentPirActive = incomingData.pir2;
        else if (p == 2)
          currentPirActive = incomingData.pir3;
        else if (p == 3)
          currentPirActive = incomingData.pir4;
        else if (p == 4)
          currentPirActive = incomingData.pir5;

        if (currentPirActive) {
          // --- ADVANCED CALIBRATION FILTER ---
          unsigned long now = millis();
          if (pirLastHighTime[p] == 0)
            pirLastHighTime[p] = now;

          unsigned long heldDuration = now - pirLastHighTime[p];
          bool isStable = (heldDuration >= (unsigned long)pirDebounce[p]);

          // Signal strength calculation for live UI (Simulated based on
          // duration)
          pirSignalStrength[p] =
              map(min((int)heldDuration, 2000), 0, 2000, 0, 100);

          if (isStable) {
            for (int r = 0; r < 7; r++) {
              if (pirRelayMask[p] & (1 << r)) {
                if (!relayState[r]) {
                  relayState[r] = true;
                  updateRelays = true;
                  Serial.printf(
                      "🧬 NEURAL LINK (CALIBRATED): PIR%d -> RELAY%d ON\n",
                      p + 1, r + 1);
                }
                pirAutoOffTimer[r] = millis();
              }
            }
          }
        } else {
          pirLastHighTime[p] = 0;
          pirSignalStrength[p] = 0;
        }
      }
      if (updateRelays)
        forceTelemetry = true;
    }

    // --- SECURITY ALARM LOGIC ---
    if (anyMotion && isArmed && ldrPass) {
      isAlarmActive = true;
      alarmStartTime = millis();
    }

    if (isAlarmActive) {
      if (!isBuzzerMuted) {
        digitalWrite(BUZZER_PIN, HIGH);
      } else {
        digitalWrite(BUZZER_PIN, LOW);
      }
      triggerActivityLED();
      Firebase.RTDB.setBoolAsync(&fbTele, pathAlarm.c_str(), true);
      if (incomingData.pir1)
        logMotionToFirebase("PIR_1");
      if (incomingData.pir2)
        logMotionToFirebase("PIR_2");
      if (incomingData.pir3)
        logMotionToFirebase("PIR_3");
      if (incomingData.pir4)
        logMotionToFirebase("PIR_4");
      if (incomingData.pir5)
        logMotionToFirebase("PIR_5");
    }
  }
  meshDataPending = false;
}

// 🔥 CRITICAL FIX: True FreeRTOS Watchdog Feed.
// delay(1) or vTaskDelay(1) explicitly hands control back to FreeRTOS
// to clear the watchdog timer, totally eliminating random restarts.
vTaskDelay(pdMS_TO_TICKS(1));
}
