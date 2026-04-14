/*
 * -----------------------------------------------------------------------------
 * NEBULA CORE – INDUSTRIAL HUB FIRMWARE (PURE CLOUD EDITION)
 * VERSION: v2.0.0-STABLE-RELEASE
 * -----------------------------------------------------------------------------
 * SYSTEM: ESP32 Dual-Core (Firebase RTDB Managed)
 * FEATURES: Non-Blocking Relay Engine, Hardened Recovery, Cloud-Synced
 * Automation. FIXES: RED-GREEN blink loop, switch state echo, watchdog crashes,
 *        deadman over-kill, neural path automation, connectivity stability.
 * -----------------------------------------------------------------------------
 */

#include <ArduinoOTA.h>
#include <ESPmDNS.h>
#include <Firebase_ESP_Client.h>
#include <WiFi.h>
#include <esp_task_wdt.h>
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
#define MANUAL_LOCKOUT_MS 8000
#define DEADMAN_TIMEOUT_MS 600000 // 10 minutes (was 2 min – too aggressive)
#define LED_PULSE_MS 100
#define MIN_FREE_HEAP 20000
#define MAX_FRAG_PERCENT 50
#define RECOVERY_COOLDOWN_MS 30000 // Min 30s between soft recoveries
#define RELAY_CMD_DEBOUNCE_MS 2000 // Suppress telemetry echo after command

/* ================= GLOBALS ================= */
FirebaseData fbTele;
FirebaseData fbStream;
FirebaseData fbSensors;
FirebaseData fbStatus;
FirebaseAuth auth;
FirebaseConfig config;

bool isOTAActive = false;
bool isInternetLive = false;
bool fbConnected = false;
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
int mapPIR[5] = {0, 0, 0, 0, 0};
int pirSensitivity[5] = {80, 80, 80, 80, 80};
int pirDebounce[5] = {200, 200, 200, 200, 200};

bool activePeriods[5] = {true, true, true, true, true};
const char *periodNames[5] = {"morning", "afternoon", "evening", "night",
                              "midnight"};

bool updateRelays = false;
bool forceTelemetry = false;
volatile float sharedVoltage = 0.0;
unsigned long lastTelemetryTime = 0;
float lastReportedVoltage = 0;
bool isArmed = true;
bool isBuzzerMuted = false;
bool isLdrSecurityEnabled = false;
bool isAutoGlobalEnabled = false;
unsigned long blueLedOffTime = 0;
int globalLdrThreshold = 50;
bool isEcoMode = false;
int reportInterval = 2500;
int securityMode = 2;
int masterLightLevel = 0;
int globalMotionMode =
    -1; // -1: disabled, 0: Always, 4: Night-Only (synced from app)

String pathTele, pathLogs, pathCmds, pathSensors;
bool isActivityFlashing = false;
unsigned long activityStart = 0;
bool isPanicActive = false;
bool buzzerPending = false;
unsigned long buzzerStartTime = 0;
int buzzerDuration = 200;
unsigned long lastPanicPulse = 0;
bool safetyTripped = false;
unsigned long lastCloudActivity = 0;

// Recovery & Debounce State
unsigned long lastRecoveryTime = 0;
int lowHeapCount = 0;
unsigned long lastCommandTime = 0;   // Suppress telemetry echo after command
unsigned long lastHeartbeatTime = 0; // Independent heartbeat timer
bool initialSyncDone = false;        // Track first stream sync

/* ================= LED ENGINE ================= */
void initLEDs() {
  pinMode(LED_PIN_RED, OUTPUT);
  pinMode(LED_PIN_GREEN, OUTPUT);
  pinMode(LED_PIN_BLUE, OUTPUT);
}

void animateLEDs() {
  unsigned long now = millis();
  if (blueLedOffTime > 0 && now > blueLedOffTime) {
    digitalWrite(LED_PIN_BLUE, LOW);
    blueLedOffTime = 0;
  }
  int targetColor = 0; // 0=off, 1=RED, 2=GREEN, 3=BLUE

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
      // WiFi disconnected: slow RED pulse (1s on, 1s off)
      targetColor = ((now / 1000) % 2 == 0) ? 1 : 0;
    } else if (!Firebase.ready()) {
      // WiFi OK but Firebase not ready: slow RED breathe (1.5s cycle)
      if ((now / 1500) % 2 == 0)
        targetColor = 1;
    } else {
      // Fully operational: GREEN double-pulse heartbeat
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
    if (now - buzzerStartTime < (unsigned long)buzzerDuration) {
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

/* ================= STABILITY ENGINES ================= */
void softRecoveryEngine() {
  unsigned long now = millis();
  // Cooldown: prevent rapid-fire recovery
  if (now - lastRecoveryTime < RECOVERY_COOLDOWN_MS)
    return;
  lastRecoveryTime = now;
  lowHeapCount = 0;

  Serial.println("⚠️ SOFT RECOVERY. Resetting network stack...");

  // End streams BEFORE disconnecting WiFi
  Firebase.RTDB.endStream(&fbStream);
  Firebase.RTDB.endStream(&fbSensors);
  WiFi.disconnect(true);
  delay(500);
  WiFi.begin(WIFI_SSID, WIFI_PASS);

  // Wait for WiFi to reconnect BEFORE re-opening streams
  unsigned long wifiStart = millis();
  while (WiFi.status() != WL_CONNECTED && millis() - wifiStart < 8000) {
    delay(100);
    animateLEDs();
    esp_task_wdt_reset();
  }

  if (WiFi.status() == WL_CONNECTED) {
    Firebase.RTDB.beginStream(&fbStream, pathCmds.c_str());
    Firebase.RTDB.beginStream(&fbSensors, pathSensors.c_str());
    Serial.println("✅ Recovery complete. Streams restored.");
  } else {
    Serial.println("❌ Recovery: WiFi failed. Will retry next cycle.");
  }
}

void cpuMemoryHealthCheck() {
  uint32_t freeHeap = ESP.getFreeHeap();
  uint32_t maxBlock = ESP.getMaxAllocHeap();
  float frag = 100.0 * (1.0 - ((float)maxBlock / freeHeap));

  if (freeHeap < MIN_FREE_HEAP || frag > MAX_FRAG_PERCENT) {
    lowHeapCount++;
    // Only trigger recovery after 3 consecutive bad readings
    if (lowHeapCount >= 3) {
      softRecoveryEngine();
    }
  } else {
    lowHeapCount = 0;
  }
}

/* ================= BACKGROUND TASKS ================= */
void connectivityTask(void *pvParameters) {
  for (;;) {
    if (WiFi.status() != WL_CONNECTED) {
      isInternetLive = false;
      fbConnected = false;
      // Auto-reconnect WiFi
      WiFi.disconnect(true);
      delay(1000);
      WiFi.begin(WIFI_SSID, WIFI_PASS);
      unsigned long wt = millis();
      while (WiFi.status() != WL_CONNECTED && millis() - wt < 10000) {
        delay(200);
      }
      if (WiFi.status() == WL_CONNECTED) {
        Serial.println("✅ WiFi reconnected by connectivity task.");
        lastCloudActivity = millis(); // Reset deadman on reconnect
      }
      vTaskDelay(5000 / portTICK_PERIOD_MS);
    } else {
      // Use Firebase.ready() as the real connectivity test
      isInternetLive = true;
      fbConnected = Firebase.ready();
      if (fbConnected) {
        lastCloudActivity = millis(); // Keep deadman alive while connected
      }
      vTaskDelay((isEcoMode ? 15000 : 8000) / portTICK_PERIOD_MS);
    }
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
    vTaskDelay((isEcoMode ? 250 : 150) / portTICK_PERIOD_MS);
  }
}

/* ================= HARDWARE CONTROL ================= */
void applyRelays() {
  // Feed watchdog BEFORE relay application to prevent crash
  esp_task_wdt_reset();

  int pins[] = {RELAY1, RELAY2, RELAY3, RELAY4, RELAY5, RELAY6, RELAY7};
  for (int i = 0; i < 7; i++) {
    bool target = (relayState[i] != invertedLogic[i]);
    digitalWrite(pins[i], target ? HIGH : LOW);
    // NO blocking delay – all relays applied instantly
  }

  // Mark command time to suppress telemetry echo
  lastCommandTime = millis();

  // Flash activity LED
  isActivityFlashing = true;
  activityStart = millis();

  Serial.printf("⚡ Relays: [%d %d %d %d %d %d %d]\n", relayState[0],
                relayState[1], relayState[2], relayState[3], relayState[4],
                relayState[5], relayState[6]);
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

/* ================= SENSOR STREAM CALLBACK ================= */
void sensorCallback(FirebaseStream data) {
  String path = data.dataPath();
  lastCloudActivity = millis();

  if (path == "/")
    return;

  // Expected path: /PIR1, /PIR2, etc.
  int pIdx = -1;
  if (path.startsWith("/PIR")) {
    pIdx = path.substring(4).toInt() - 1;
  }

  if (pIdx >= 0 && pIdx < 4) {
    FirebaseJson *json = data.jsonObjectPtr();
    FirebaseJsonData d;
    bool motion = false;
    int ldr = 0;

    if (json->get(d, "status"))
      motion = d.boolValue;
    if (json->get(d, "lightLevel"))
      ldr = d.intValue;

    Serial.printf("🔍 PIR%d: motion=%d ldr=%d autoGlobal=%d\n", pIdx + 1,
                  motion, ldr, isAutoGlobalEnabled);

    // Automation Logic
    if (motion) {
      unsigned long now = millis();
      int curP = getCurrentPeriodIdx();
      bool isScheduled = (curP == -1 || activePeriods[curP]);
      bool isDark = (ldr <= globalLdrThreshold);

      bool isSecActive = false;
      if (securityMode == 0)
        isSecActive = isDark;
      else if (securityMode == 1)
        isSecActive = isScheduled;
      else if (securityMode == 2)
        isSecActive = (isDark || isScheduled);
      else
        isSecActive = true;

      // Neural Path Automation
      if (isAutoGlobalEnabled && isSecActive) {
        int mask = mapPIR[pIdx];
        Serial.printf("🧠 Neural: PIR%d mask=0x%02X\n", pIdx + 1, mask);
        for (int r = 0; r < 7; r++) {
          if (now - manualOverrideTime[r] < MANUAL_LOCKOUT_MS)
            continue;
          if ((mask & (1 << r)) != 0) {
            relayState[r] = 1;
            autoTriggerTime[r] = now;
            isNeuralTriggered[r] = true;
            updateRelays = true;
            Serial.printf("  → Relay%d ON (neural)\n", r + 1);
          }
        }
      }

      // Security Alarm
      if (isArmed && isSecActive) {
        triggerBuzzer(400);
        FirebaseJson breachLog;
        breachLog.set("sensor", "PIR" + String(pIdx + 1));
        breachLog.set("timestamp", (int)time(NULL));
        Firebase.RTDB.pushJSONAsync(&fbTele, pathLogs.c_str(), &breachLog);
      }
    }
  }
}

/* ================= COMMAND STREAM CALLBACK ================= */
void streamCallback(FirebaseStream data) {
  isInternetLive = true;
  fbConnected = true;
  lastCloudActivity = millis();
  String path = data.dataPath();
  bool wasRelayUpdated = false;

  if (path == "/") {
    FirebaseJson *json = data.jsonObjectPtr();
    FirebaseJsonData d;
    for (int i = 0; i < 7; i++) {
      char k[10];
      snprintf(k, sizeof(k), "relay%d", i + 1);
      if (json->get(d, k)) {
        bool val = (d.boolValue || d.intValue > 0 || d.stringValue == "true");
        if (relayState[i] != val) {
          relayState[i] = val;
          wasRelayUpdated = true;
        }
      }
      snprintf(k, sizeof(k), "invert%d", i + 1);
      if (json->get(d, k))
        invertedLogic[i] = d.boolValue;
    }

    if (json->get(d, "ecoMode"))
      isEcoMode = d.boolValue;
    if (json->get(d, "panic")) {
      isPanicActive = d.boolValue;
      if (isPanicActive)
        triggerBuzzer(1000);
    }
    if (json->get(d, "isArmed"))
      isArmed = d.boolValue;
    if (json->get(d, "buzzerMute"))
      isBuzzerMuted = d.boolValue;
    if (json->get(d, "ldrThreshold"))
      globalLdrThreshold = d.intValue;
    if (json->get(d, "pirTimer"))
      pirTimer = d.intValue;
    if (json->get(d, "security/securityMode"))
      securityMode = d.intValue;
    if (json->get(d, "globalMotionMode")) {
      globalMotionMode = d.intValue;
      isAutoGlobalEnabled = (globalMotionMode >= 0); // Any mode = automation ON
    }

    for (int i = 1; i <= 4; i++) {
      char key[16], sKey[48], dKey[48];
      sprintf(key, "mapPIR%d", i);
      sprintf(sKey, "security/calibration/PIR%d/sensitivity", i);
      sprintf(dKey, "security/calibration/PIR%d/debounce", i);
      if (json->get(d, key))
        mapPIR[i - 1] = d.intValue;
      if (json->get(d, sKey))
        pirSensitivity[i - 1] = d.intValue;
      if (json->get(d, dKey))
        pirDebounce[i - 1] = d.intValue;
    }
    for (int i = 0; i < 5; i++) {
      char pKey[32];
      sprintf(pKey, "security/activePeriods/%s", periodNames[i]);
      if (json->get(d, pKey))
        activePeriods[i] = d.boolValue;
    }

    if (!initialSyncDone) {
      initialSyncDone = true;
      Serial.printf("📡 Initial sync: autoGlobal=%d armed=%d secMode=%d\n",
                    isAutoGlobalEnabled, isArmed, securityMode);
      for (int i = 0; i < 4; i++) {
        Serial.printf("  mapPIR%d = 0x%02X\n", i + 1, mapPIR[i]);
      }
    }
  } else {
    if (path.startsWith("/relay")) {
      int idx = path.substring(6).toInt() - 1;
      if (idx >= 0 && idx < 7) {
        bool val = (data.intData() > 0 || data.boolData() ||
                    data.stringData() == "true");
        if (relayState[idx] != val) {
          relayState[idx] = val;
          wasRelayUpdated = true;
        }
      }
    } else if (path == "/isArmed")
      isArmed = data.boolData();
    else if (path == "/security/securityMode")
      securityMode = data.intData();
    else if (path == "/globalMotionMode") {
      globalMotionMode = data.intData();
      isAutoGlobalEnabled = (globalMotionMode >= 0);
      Serial.printf("🧠 globalMotionMode=%d autoEnabled=%d\n", globalMotionMode,
                    isAutoGlobalEnabled);
    } else if (path == "/pirTimer")
      pirTimer = data.intData();
    else if (path == "/ldrThreshold")
      globalLdrThreshold = data.intData();
    else if (path == "/buzzerMute")
      isBuzzerMuted = data.boolData();
    else if (path == "/panic") {
      isPanicActive = data.boolData();
      if (isPanicActive)
        triggerBuzzer(1000);
    } else if (path == "/ecoMode")
      isEcoMode = data.boolData();
    else if (path.startsWith("/mapPIR")) {
      int idx = path.substring(7).toInt() - 1;
      if (idx >= 0 && idx < 5) {
        mapPIR[idx] = data.intData();
      }
    } else if (path.startsWith("/security/activePeriods/")) {
      String period = path.substring(23); // after "/security/activePeriods/"
      for (int i = 0; i < 5; i++) {
        if (period == periodNames[i]) {
          activePeriods[i] = data.boolData();
          Serial.printf("📅 Period %s = %d\n", periodNames[i],
                        activePeriods[i]);
          break;
        }
      }
    } else if (path.startsWith("/security/calibration/PIR")) {
      // Handle individual calibration updates for sensitivity/debounce
      // path like: /security/calibration/PIR1/sensitivity
      int pIdx = path.substring(24, 25).toInt() - 1;
      if (pIdx >= 0 && pIdx < 4) {
        if (path.endsWith("/sensitivity"))
          pirSensitivity[pIdx] = data.intData();
        else if (path.endsWith("/debounce"))
          pirDebounce[pIdx] = data.intData();
      }
    } else if (path.startsWith("/invert")) {
      int idx = path.substring(7).toInt() - 1;
      if (idx >= 0 && idx < 7) {
        invertedLogic[idx] = data.boolData();
        updateRelays = true; // Reapply relays with new logic
      }
    }
  }

  if (wasRelayUpdated) {
    unsigned long now = millis();
    for (int i = 0; i < 7; i++)
      manualOverrideTime[i] = now;
    updateRelays = true;
    forceTelemetry = true;
  }
}

void streamTimeoutCallback(bool timeout) {
  if (timeout) {
    Serial.println("⚠️ Stream timeout detected.");
    // Don't immediately mark as offline – the connectivity task handles that
  }
}

/* ================= SETUP ================= */
void setup() {
  Serial.begin(115200);
  delay(100);
  Serial.println("\n🚀 NEBULA CORE v2.0.0-STABLE booting...");
  initLEDs();

  pinMode(RELAY1, OUTPUT);
  pinMode(RELAY2, OUTPUT);
  pinMode(RELAY3, OUTPUT);
  pinMode(RELAY4, OUTPUT);
  pinMode(RELAY5, OUTPUT);
  pinMode(RELAY6, OUTPUT);
  pinMode(RELAY7, OUTPUT);
  pinMode(BUZZER_PIN, OUTPUT);

  // All relays OFF on boot
  int pins[] = {RELAY1, RELAY2, RELAY3, RELAY4, RELAY5, RELAY6, RELAY7};
  for (int i = 0; i < 7; i++)
    digitalWrite(pins[i], LOW);

  WiFi.mode(WIFI_STA);
  WiFi.setSleep(false); // Disable WiFi power save for stability
  WiFi.begin(WIFI_SSID, WIFI_PASS);

  pathTele = "devices/" + deviceId + "/telemetry";
  pathLogs = "devices/" + deviceId + "/events";
  pathCmds = "devices/" + deviceId + "/commands";
  pathSensors = "devices/" + deviceId + "/security/sensors";

  unsigned long startT = millis();
  while (WiFi.status() != WL_CONNECTED && millis() - startT < 15000) {
    delay(50);
    animateLEDs();
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.printf("✅ WiFi connected. IP: %s\n",
                  WiFi.localIP().toString().c_str());
    configTime(19800, 0, "pool.ntp.org");
  } else {
    Serial.println("❌ WiFi failed on boot. Connectivity task will retry.");
  }

  // Start connectivity task on Core 0
  xTaskCreatePinnedToCore(connectivityTask, "ConnTask", 4096, NULL, 1, NULL, 0);

  ArduinoOTA.setHostname(OTA_HOSTNAME);
  ArduinoOTA.setPassword(OTA_PASSWORD);
  ArduinoOTA.onStart([]() { isOTAActive = true; });
  ArduinoOTA.onEnd([]() { isOTAActive = false; });
  ArduinoOTA.begin();

  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;
  config.token_status_callback = tokenStatusCallback;
  Firebase.signUp(&config, &auth, "", "");
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);

  // Wait a moment for Firebase token to be ready
  unsigned long fbWait = millis();
  while (!Firebase.ready() && millis() - fbWait < 5000) {
    delay(100);
    animateLEDs();
  }

  Firebase.RTDB.beginStream(&fbStream, pathCmds.c_str());
  Firebase.RTDB.setStreamCallback(&fbStream, streamCallback,
                                  streamTimeoutCallback);

  Firebase.RTDB.beginStream(&fbSensors, pathSensors.c_str());
  Firebase.RTDB.setStreamCallback(&fbSensors, sensorCallback,
                                  streamTimeoutCallback);

  // Watchdog: 30 seconds (generous to handle Firebase operations)
  esp_task_wdt_config_t twdt_config = {.timeout_ms = 30000,
                                       .idle_core_mask =
                                           (1 << portNUM_PROCESSORS) - 1,
                                       .trigger_panic = true};
  esp_task_wdt_init(&twdt_config);

  xTaskCreatePinnedToCore(voltageTask, "VoltageTask", 5120, NULL, 1, NULL, 0);

  lastCloudActivity = millis();
  lastHeartbeatTime = millis();

  Serial.println("✅ SYSTEM READY (v2.0.0-STABLE).");
}

/* ================= LOOP ================= */
void loop() {
  animateLEDs();
  ArduinoOTA.handle();
  esp_task_wdt_reset();

  // Memory health check (runs every 5 seconds, not every loop)
  static unsigned long lastHealthCheck = 0;
  if (millis() - lastHealthCheck > 5000) {
    lastHealthCheck = millis();
    cpuMemoryHealthCheck();
  }

  if (updateRelays) {
    applyRelays();
    updateRelays = false;
  }

  unsigned long now = millis();

  // ---- TELEMETRY PUSH (with echo suppression) ----
  static unsigned long lastTeleCheck = 0;
  if (now - lastTeleCheck > (unsigned long)(isEcoMode ? 3000 : 800)) {
    lastTeleCheck = now;

    // Suppress telemetry push for 2s after a command to prevent echo
    bool echoSuppressed = (now - lastCommandTime < RELAY_CMD_DEBOUNCE_MS);

    if ((forceTelemetry ||
         (now - lastTelemetryTime > (unsigned long)reportInterval)) &&
        !echoSuppressed) {
      if (Firebase.ready() && fbConnected) {
        FirebaseJson j;
        for (int i = 0; i < 7; i++) {
          char k[8];
          sprintf(k, "relay%d", i + 1);
          j.set(k, relayState[i]);
        }
        j.set("voltage", sharedVoltage);
        j.set("heap", (int)ESP.getFreeHeap());
        j.set("rssi", (int)WiFi.RSSI());
        j.set("uptime", (int)(millis() / 1000));
        if (Firebase.RTDB.updateNodeAsync(&fbTele, pathTele.c_str(), &j)) {
          lastTelemetryTime = now;
          forceTelemetry = false;
        }
      }
    }
  }

  // ---- HEARTBEAT PUSH (independent of telemetry, every 10s) ----
  if (now - lastHeartbeatTime > 10000) {
    lastHeartbeatTime = now;
    if (Firebase.ready()) {
      FirebaseJson stat;
      stat.set("online", true);
      stat.set("lastSeen", (int)(time(NULL)));
      stat.set("heap", (int)ESP.getFreeHeap());
      stat.set("rssi", (int)WiFi.RSSI());
      stat.set("version", "v2.0.0");
      Firebase.RTDB.updateNodeAsync(
          &fbStatus, ("devices/" + deviceId + "/status").c_str(), &stat);
    }
  }

  // ---- AUTOMATION TIMERS ----
  for (int i = 0; i < 7; i++) {
    if (relayState[i] == 0) {
      autoTriggerTime[i] = 0;
      isNeuralTriggered[i] = false;
      continue;
    }
    unsigned long dur =
        (autoDuration[i] > 0)
            ? ((unsigned long)autoDuration[i] * 1000UL)
            : (isNeuralTriggered[i] ? ((unsigned long)pirTimer * 1000UL) : 0);
    if (dur > 0 && autoTriggerTime[i] > 0 && (now - autoTriggerTime[i] > dur)) {
      relayState[i] = 0;
      autoTriggerTime[i] = 0;
      isNeuralTriggered[i] = false;
      updateRelays = true;
      forceTelemetry = true;
      Serial.printf("⏱️ Relay%d auto-OFF after %lums\n", i + 1, dur);
    }
  }

  // ---- DEADMAN SAFETY (only neural-triggered relays) ----
  if (now - lastCloudActivity > DEADMAN_TIMEOUT_MS) {
    if (!safetyTripped) {
      Serial.println("⚠️ Deadman: turning OFF neural-triggered relays only.");
      for (int i = 0; i < 7; i++) {
        if (isNeuralTriggered[i]) {
          relayState[i] = 0;
          isNeuralTriggered[i] = false;
        }
      }
      updateRelays = true;
      safetyTripped = true;
    }
  } else {
    safetyTripped = false;
  }

  delay(isEcoMode ? 10 : 2);
}
