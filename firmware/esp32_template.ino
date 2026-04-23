/*
 * =============================================================================
 * NEBULA CORE – ESP32 HUB FIRMWARE TEMPLATE
 * VERSION: v2.0.0 TEMPLATE (Skeleton)
 * =============================================================================
 * THIS IS A CLEAN TEMPLATE. Fill in YOUR credentials below.
 * See FIREBASE_DATA_MAP.md for all data paths explained.
 * =============================================================================
 */

#include <ArduinoOTA.h>
#include <ESPmDNS.h>
#include <Firebase_ESP_Client.h>
#include <WiFi.h>
#include <esp_task_wdt.h>
#include <time.h>

#include "addons/RTDBHelper.h"
#include "addons/TokenHelper.h"

/* =================  YOUR CONFIGURATION  ================= */
/* ⚠️  FILL IN YOUR OWN CREDENTIALS BELOW                  */
/* ======================================================== */

#define WIFI_SSID "YOUR_WIFI_NAME"
#define WIFI_PASS "YOUR_WIFI_PASSWORD"
#define OTA_HOSTNAME "Nebula-Core-ESP32"
#define OTA_PASSWORD "YOUR_OTA_PASSWORD"
#define API_KEY "YOUR_FIREBASE_API_KEY"
#define DATABASE_URL "https://YOUR_PROJECT.firebasedatabase.app"

/* Your unique device ID (must match the app) */
String deviceId = "YOUR_DEVICE_ID";

/* =================  PIN DEFINITIONS  ================= */
/* Change these to match YOUR wiring                     */
/* ===================================================== */

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

/* =================  CONSTANTS  ================= */
#define ADC_MAX 4095.0
#define VREF 3.3
float calibrationFactor = 313.3;
#define P2P_THRESHOLD 60
#define RMS_THRESHOLD 0.020
#define SMOOTHING_ALPHA 0.1
#define MANUAL_LOCKOUT_MS 8000
#define DEADMAN_TIMEOUT_MS 600000
#define MIN_FREE_HEAP 20000
#define MAX_FRAG_PERCENT 50
#define RECOVERY_COOLDOWN_MS 30000
#define RELAY_CMD_DEBOUNCE_MS 2000

/* =================  GLOBALS  ================= */
FirebaseData fbTele, fbStream, fbSensors, fbStatus;
FirebaseAuth auth;
FirebaseConfig config;

bool isOTAActive = false;
bool isInternetLive = false;
bool fbConnected = false;

bool relayState[7] = {0, 0, 0, 0, 0, 0, 0};
bool invertedLogic[7] = {0, 0, 0, 0, 0, 0, 0};
unsigned long autoTriggerTime[7] = {0};
bool isNeuralTriggered[7] = {false};
unsigned long manualOverrideTime[7] = {0};

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
bool isArmed = true;
bool isBuzzerMuted = false;
bool isAutoGlobalEnabled = false;
int globalLdrThreshold = 50;
bool isEcoMode = false;
int reportInterval = 2500;
int securityMode = 2;
int globalMotionMode = -1;

String pathTele, pathLogs, pathCmds, pathSensors;
bool isPanicActive = false;
bool buzzerPending = false;
unsigned long buzzerStartTime = 0;
int buzzerDuration = 200;
unsigned long lastPanicPulse = 0;
bool safetyTripped = false;
unsigned long lastCloudActivity = 0;
unsigned long lastRecoveryTime = 0;
int lowHeapCount = 0;
unsigned long lastCommandTime = 0;
unsigned long lastHeartbeatTime = 0;
bool initialSyncDone = false;
bool isActivityFlashing = false;
unsigned long activityStart = 0;
unsigned long blueLedOffTime = 0;

/* =================  LED ENGINE  ================= */
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
  int c = 0;
  if (isOTAActive) {
    c = ((now / 100) % 2 == 0) ? 1 : 3;
  } else if (isActivityFlashing) {
    if (now - activityStart < 80)
      c = 3;
    else
      isActivityFlashing = false;
  }

  if (c == 0 && !isActivityFlashing && !isOTAActive) {
    if (WiFi.status() != WL_CONNECTED)
      c = ((now / 1000) % 2 == 0) ? 1 : 0;
    else if (!Firebase.ready()) {
      if ((now / 1500) % 2 == 0)
        c = 1;
    } else {
      unsigned long cy = now % (isEcoMode ? 4000 : 2000);
      if (cy < 80 || (cy > 250 && cy < 330))
        c = 2;
    }
  }
  digitalWrite(LED_PIN_RED, (c == 1) ? HIGH : LOW);
  digitalWrite(LED_PIN_GREEN, (c == 2) ? HIGH : LOW);
  if (blueLedOffTime > 0 && now < blueLedOffTime)
    digitalWrite(LED_PIN_BLUE, HIGH);
  else
    digitalWrite(LED_PIN_BLUE, (c == 3) ? HIGH : LOW);

  if (isPanicActive && now - lastPanicPulse > 500) {
    triggerBuzzer(250);
    lastPanicPulse = now;
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

/* =================  STABILITY  ================= */
void softRecoveryEngine() {
  if (millis() - lastRecoveryTime < RECOVERY_COOLDOWN_MS)
    return;
  lastRecoveryTime = millis();
  lowHeapCount = 0;
  Serial.println("⚠️ SOFT RECOVERY");
  Firebase.RTDB.endStream(&fbStream);
  Firebase.RTDB.endStream(&fbSensors);
  WiFi.disconnect(true);
  delay(500);
  WiFi.begin(WIFI_SSID, WIFI_PASS);
  unsigned long w = millis();
  while (WiFi.status() != WL_CONNECTED && millis() - w < 8000) {
    delay(100);
    animateLEDs();
    esp_task_wdt_reset();
  }
  if (WiFi.status() == WL_CONNECTED) {
    Firebase.RTDB.beginStream(&fbStream, pathCmds.c_str());
    Firebase.RTDB.beginStream(&fbSensors, pathSensors.c_str());
  }
}

void cpuMemoryHealthCheck() {
  uint32_t h = ESP.getFreeHeap();
  uint32_t m = ESP.getMaxAllocHeap();
  float f = 100.0 * (1.0 - ((float)m / h));
  if (h < MIN_FREE_HEAP || f > MAX_FRAG_PERCENT) {
    lowHeapCount++;
    if (lowHeapCount >= 3)
      softRecoveryEngine();
  } else
    lowHeapCount = 0;
}

/* =================  BACKGROUND TASKS  ================= */
void connectivityTask(void *p) {
  for (;;) {
    if (WiFi.status() != WL_CONNECTED) {
      isInternetLive = false;
      fbConnected = false;
      WiFi.disconnect(true);
      delay(1000);
      WiFi.begin(WIFI_SSID, WIFI_PASS);
      unsigned long w = millis();
      while (WiFi.status() != WL_CONNECTED && millis() - w < 10000)
        delay(200);
      if (WiFi.status() == WL_CONNECTED)
        lastCloudActivity = millis();
      vTaskDelay(5000 / portTICK_PERIOD_MS);
    } else {
      isInternetLive = true;
      fbConnected = Firebase.ready();
      if (fbConnected)
        lastCloudActivity = millis();
      vTaskDelay((isEcoMode ? 15000 : 8000) / portTICK_PERIOD_MS);
    }
  }
}

void voltageTask(void *p) {
  long sum = 0;
  for (int i = 0; i < 500; i++)
    sum += analogRead(VOLTAGE_SENSOR);
  float adcOff = sum / 500.0;
  float lV = 0;
  for (;;) {
    double rs = 0;
    int rc = 0, mn = 4095, mx = 0;
    unsigned long bs = millis();
    while (millis() - bs < 20) {
      int r = analogRead(VOLTAGE_SENSOR);
      if (r < mn)
        mn = r;
      if (r > mx)
        mx = r;
      float v = (r - adcOff) * (VREF / ADC_MAX);
      rs += v * v;
      rc++;
      yield();
    }
    if (rc > 0) {
      int p2 = mx - mn;
      float rm = sqrt(rs / rc);
      float iv = (p2 >= P2P_THRESHOLD && rm >= RMS_THRESHOLD)
                     ? (rm * calibrationFactor)
                     : 0.0;
      lV = (lV == 0) ? iv
                     : (iv * SMOOTHING_ALPHA) + (lV * (1.0 - SMOOTHING_ALPHA));
      sharedVoltage = (lV < 5.0) ? 0.0 : lV;
    }
    vTaskDelay((isEcoMode ? 250 : 150) / portTICK_PERIOD_MS);
  }
}

/* =================  HARDWARE  ================= */
void applyRelays() {
  esp_task_wdt_reset();
  int pins[] = {RELAY1, RELAY2, RELAY3, RELAY4, RELAY5, RELAY6, RELAY7};
  for (int i = 0; i < 7; i++)
    digitalWrite(pins[i], (relayState[i] != invertedLogic[i]) ? HIGH : LOW);
  lastCommandTime = millis();
  isActivityFlashing = true;
  activityStart = millis();
}

/* =================  HELPERS  ================= */
int getCurrentPeriodIdx() {
  struct tm t;
  if (!getLocalTime(&t))
    return -1;
  int h = t.tm_hour;
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

/* =================  SENSOR CALLBACK  ================= */
void sensorCallback(FirebaseStream data) {
  String path = data.dataPath();
  lastCloudActivity = millis();
  if (path == "/")
    return;
  int pIdx = -1;
  if (path.startsWith("/PIR"))
    pIdx = path.substring(4).toInt() - 1;
  if (pIdx >= 0 && pIdx < 4) {
    FirebaseJson *json = data.jsonObjectPtr();
    FirebaseJsonData d;
    bool motion = false;
    int ldr = 0;
    if (json->get(d, "status"))
      motion = d.boolValue;
    if (json->get(d, "lightLevel"))
      ldr = d.intValue;
    if (motion) {
      unsigned long now = millis();
      int curP = getCurrentPeriodIdx();
      bool isSch = (curP == -1 || activePeriods[curP]);
      bool isDk = (ldr <= globalLdrThreshold);
      bool isAct = false;
      if (securityMode == 0)
        isAct = isDk;
      else if (securityMode == 1)
        isAct = isSch;
      else if (securityMode == 2)
        isAct = (isDk || isSch);
      else
        isAct = true;
      if (isAutoGlobalEnabled && isAct) {
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
      if (isArmed && isAct) {
        triggerBuzzer(400);
        FirebaseJson bl;
        bl.set("sensor", "PIR" + String(pIdx + 1));
        bl.set("timestamp", (int)time(NULL));
        Firebase.RTDB.pushJSONAsync(&fbTele, pathLogs.c_str(), &bl);
      }
    }
  }
}

/* =================  COMMAND CALLBACK  ================= */
void streamCallback(FirebaseStream data) {
  isInternetLive = true;
  fbConnected = true;
  lastCloudActivity = millis();
  String path = data.dataPath();
  bool wu = false;
  if (path == "/") {
    FirebaseJson *json = data.jsonObjectPtr();
    FirebaseJsonData d;
    for (int i = 0; i < 7; i++) {
      char k[10];
      snprintf(k, sizeof(k), "relay%d", i + 1);
      if (json->get(d, k)) {
        bool v = (d.boolValue || d.intValue > 0 || d.stringValue == "true");
        if (relayState[i] != v) {
          relayState[i] = v;
          wu = true;
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
      isAutoGlobalEnabled = (globalMotionMode >= 0);
    }
    for (int i = 1; i <= 4; i++) {
      char k[16], s[48], db[48];
      sprintf(k, "mapPIR%d", i);
      sprintf(s, "security/calibration/PIR%d/sensitivity", i);
      sprintf(db, "security/calibration/PIR%d/debounce", i);
      if (json->get(d, k))
        mapPIR[i - 1] = d.intValue;
      if (json->get(d, s))
        pirSensitivity[i - 1] = d.intValue;
      if (json->get(d, db))
        pirDebounce[i - 1] = d.intValue;
    }
    for (int i = 0; i < 5; i++) {
      char pk[32];
      sprintf(pk, "security/activePeriods/%s", periodNames[i]);
      if (json->get(d, pk))
        activePeriods[i] = d.boolValue;
    }
    if (!initialSyncDone) {
      initialSyncDone = true;
      Serial.printf("📡 Synced: auto=%d armed=%d mode=%d\n",
                    isAutoGlobalEnabled, isArmed, securityMode);
    }
  } else {
    if (path.startsWith("/relay")) {
      int i = path.substring(6).toInt() - 1;
      if (i >= 0 && i < 7) {
        bool v = (data.intData() > 0 || data.boolData() ||
                  data.stringData() == "true");
        if (relayState[i] != v) {
          relayState[i] = v;
          wu = true;
        }
      }
    } else if (path == "/isArmed")
      isArmed = data.boolData();
    else if (path == "/security/securityMode")
      securityMode = data.intData();
    else if (path == "/globalMotionMode") {
      globalMotionMode = data.intData();
      isAutoGlobalEnabled = (globalMotionMode >= 0);
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
      int i = path.substring(7).toInt() - 1;
      if (i >= 0 && i < 5)
        mapPIR[i] = data.intData();
    } else if (path.startsWith("/security/activePeriods/")) {
      String p = path.substring(23);
      for (int i = 0; i < 5; i++) {
        if (p == periodNames[i]) {
          activePeriods[i] = data.boolData();
          break;
        }
      }
    } else if (path.startsWith("/security/calibration/PIR")) {
      int i = path.substring(24, 25).toInt() - 1;
      if (i >= 0 && i < 4) {
        if (path.endsWith("/sensitivity"))
          pirSensitivity[i] = data.intData();
        else if (path.endsWith("/debounce"))
          pirDebounce[i] = data.intData();
      }
    } else if (path.startsWith("/invert")) {
      int i = path.substring(7).toInt() - 1;
      if (i >= 0 && i < 7) {
        invertedLogic[i] = data.boolData();
        wu = true;
      }
    }
  }
  if (wu) {
    unsigned long now = millis();
    for (int i = 0; i < 7; i++)
      manualOverrideTime[i] = now;
    updateRelays = true;
    forceTelemetry = true;
  }
}

void streamTimeoutCallback(bool t) {
  if (t)
    Serial.println("⚠️ Stream timeout");
}

/* =================  SETUP  ================= */
void setup() {
  Serial.begin(115200);
  delay(100);
  Serial.println("\n🚀 NEBULA CORE TEMPLATE v2.0.0");
  initLEDs();
  int pins[] = {RELAY1, RELAY2, RELAY3, RELAY4, RELAY5, RELAY6, RELAY7};
  for (int i = 0; i < 7; i++) {
    pinMode(pins[i], OUTPUT);
    digitalWrite(pins[i], LOW);
  }
  pinMode(BUZZER_PIN, OUTPUT);

  WiFi.mode(WIFI_STA);
  WiFi.setSleep(false);
  WiFi.begin(WIFI_SSID, WIFI_PASS);
  pathTele = "devices/" + deviceId + "/telemetry";
  pathLogs = "devices/" + deviceId + "/security/logs";
  pathCmds = "devices/" + deviceId + "/commands";
  pathSensors = "devices/" + deviceId + "/security/sensors";
  unsigned long st = millis();
  while (WiFi.status() != WL_CONNECTED && millis() - st < 15000) {
    delay(50);
    animateLEDs();
  }
  if (WiFi.status() == WL_CONNECTED)
    configTime(19800, 0, "pool.ntp.org");
  xTaskCreatePinnedToCore(connectivityTask, "Conn", 4096, NULL, 1, NULL, 0);

  ArduinoOTA.setHostname(OTA_HOSTNAME);
  ArduinoOTA.setPassword(OTA_PASSWORD);
  ArduinoOTA.onStart([] { isOTAActive = true; });
  ArduinoOTA.onEnd([] { isOTAActive = false; });
  ArduinoOTA.begin();

  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;
  config.token_status_callback = tokenStatusCallback;
  Firebase.signUp(&config, &auth, "", "");
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);
  unsigned long fw = millis();
  while (!Firebase.ready() && millis() - fw < 5000) {
    delay(100);
    animateLEDs();
  }

  Firebase.RTDB.beginStream(&fbStream, pathCmds.c_str());
  Firebase.RTDB.setStreamCallback(&fbStream, streamCallback,
                                  streamTimeoutCallback);
  Firebase.RTDB.beginStream(&fbSensors, pathSensors.c_str());
  Firebase.RTDB.setStreamCallback(&fbSensors, sensorCallback,
                                  streamTimeoutCallback);

  esp_task_wdt_config_t wc = {.timeout_ms = 30000,
                              .idle_core_mask = (1 << portNUM_PROCESSORS) - 1,
                              .trigger_panic = true};
  esp_task_wdt_init(&wc);
  xTaskCreatePinnedToCore(voltageTask, "Volt", 5120, NULL, 1, NULL, 0);
  lastCloudActivity = millis();
  lastHeartbeatTime = millis();
  Serial.println("✅ READY");
}

/* =================  LOOP  ================= */
void loop() {
  animateLEDs();
  ArduinoOTA.handle();
  esp_task_wdt_reset();
  static unsigned long lastHC = 0;
  if (millis() - lastHC > 5000) {
    lastHC = millis();
    cpuMemoryHealthCheck();
  }
  if (updateRelays) {
    applyRelays();
    updateRelays = false;
  }

  unsigned long now = millis();

  // Telemetry (with echo suppression)
  static unsigned long lastTC = 0;
  if (now - lastTC > (unsigned long)(isEcoMode ? 3000 : 800)) {
    lastTC = now;
    if ((forceTelemetry ||
         (now - lastTelemetryTime > (unsigned long)reportInterval)) &&
        (now - lastCommandTime >= RELAY_CMD_DEBOUNCE_MS)) {
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

  // Heartbeat (independent, every 10s)
  if (now - lastHeartbeatTime > 10000) {
    lastHeartbeatTime = now;
    if (Firebase.ready()) {
      FirebaseJson s;
      s.set("online", true);
      s.set("lastSeen", (int)time(NULL));
      s.set("heap", (int)ESP.getFreeHeap());
      s.set("rssi", (int)WiFi.RSSI());
      s.set("version", "v2.0.0");
      Firebase.RTDB.updateNodeAsync(
          &fbStatus, ("devices/" + deviceId + "/status").c_str(), &s);
    }
  }

  // Auto-OFF timers
  for (int i = 0; i < 7; i++) {
    if (!relayState[i]) {
      autoTriggerTime[i] = 0;
      isNeuralTriggered[i] = false;
      continue;
    }
    unsigned long dur =
        isNeuralTriggered[i] ? ((unsigned long)pirTimer * 1000UL) : 0;
    if (dur > 0 && autoTriggerTime[i] > 0 && (now - autoTriggerTime[i] > dur)) {
      relayState[i] = 0;
      autoTriggerTime[i] = 0;
      isNeuralTriggered[i] = false;
      updateRelays = true;
      forceTelemetry = true;
    }
  }

  // Deadman (neural relays only)
  if (now - lastCloudActivity > DEADMAN_TIMEOUT_MS) {
    if (!safetyTripped) {
      for (int i = 0; i < 7; i++) {
        if (isNeuralTriggered[i]) {
          relayState[i] = 0;
          isNeuralTriggered[i] = false;
        }
      }
      updateRelays = true;
      safetyTripped = true;
    }
  } else
    safetyTripped = false;

  delay(isEcoMode ? 10 : 2);
}
