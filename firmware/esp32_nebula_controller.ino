/*
 * AUREXA CORE – COMPLETE SYSTEM (CLOUD-ONLY EDITION)
 * VERSION: v2.1.0 (ULTRA-FAST, DUAL-CORE, ANTI-CRASH, RELAYS ONLY)
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
#include <time.h>
#include <sntp.h>

/* ================= CONFIGURATION ================= */
#define WIFI_SSID "Kerala_Vision"
#define WIFI_PASS "chandrasekharan0039"

// OTA Credentials
#define OTA_HOSTNAME "Aurexa-Core-ESP32"
#define OTA_PASSWORD "aurexa2024"

#define API_KEY "AIzaSyA9zs6xhRcEwwGLO6cI417b2FO52PiXaxs"
#define DATABASE_URL "https://nebula-smartpowergrid-default-rtdb.asia-southeast1.firebasedatabase.app"

/* ================= PIN DEFINITIONS ================= */
#define RELAY1 26
#define RELAY2 27
#define RELAY3 25
#define RELAY4 33
#define RELAY5 32
#define RELAY6 14
#define RELAY7 23

#define LED_PIN_RED 19
#define LED_PIN_GREEN 16
#define LED_PIN_BLUE 17

/* ================= DYNAMIC MODES ================= */
bool isEcoMode = false;
int reportInterval = 4000;
uint32_t tele_id = 0;

/* ================= GLOBALS & CACHED STRINGS ================= */
FirebaseData fbTele;
FirebaseData fbStream;
FirebaseAuth auth;
FirebaseConfig config;
String deviceId = "79215788";

// PRE-ALLOCATED PATHS (Crucial to stop Heap Fragmentation / Random Restarts)
String pathTele;
String pathCmds;
String pathMac;

bool relayState[7] = {0, 0, 0, 0, 0, 0, 0};
bool invertedLogic[7] = {0, 0, 0, 0, 0, 0, 0};
volatile bool updateRelays = false; 
bool forceTelemetry = false;
unsigned long lastTelemetryTime = 0;

bool isInternetLive = false;
bool isOTAActive = false;
bool isActivityFlashing = false;
unsigned long activityStart = 0;
unsigned long lastCloudActivity = 0;

/* ================= SCHEDULING & SAFETY ================= */
String globalSchedulesRaw = "";
unsigned long offlineStartTime = 0;
bool wasOffline = false;
int lastCheckedMinute = -1;

// Task Handles
TaskHandle_t NetworkTaskHandle;
TaskHandle_t HardwareTaskHandle;

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
        targetColor = 1; // Red blink
    } else {
      unsigned long cycle = now % (isEcoMode ? 4000 : 2000);
      if (cycle < 80)
        targetColor = 3; // Blue Strobe
      else if (cycle > 250 && cycle < 330)
        targetColor = 3; // Blue Strobe
    }
  }
  digitalWrite(LED_PIN_RED, (targetColor == 1) ? HIGH : LOW);
  digitalWrite(LED_PIN_GREEN, (targetColor == 2) ? HIGH : LOW);
  digitalWrite(LED_PIN_BLUE, (targetColor == 3) ? HIGH : LOW);
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

/* ================= STREAM CALLBACK ================= */
void streamCallback(FirebaseStream data) {
  isInternetLive = true;
  lastCloudActivity = millis();
  String path = data.dataPath();
  Serial.printf("⚡ CLOUD CMD: %s\n", path.c_str());

  if (path == "/") {
    FirebaseJson *json = data.jsonObjectPtr();
    FirebaseJsonData d;
    if (json->get(d, "relay1")) relayState[0] = d.intValue;
    if (json->get(d, "relay2")) relayState[1] = d.intValue;
    if (json->get(d, "relay3")) relayState[2] = d.intValue;
    if (json->get(d, "relay4")) relayState[3] = d.intValue;
    if (json->get(d, "relay5")) relayState[4] = d.intValue;
    if (json->get(d, "relay6")) relayState[5] = d.intValue;
    if (json->get(d, "relay7")) relayState[6] = d.intValue;

    if (json->get(d, "invert1")) invertedLogic[0] = d.boolValue;
    if (json->get(d, "invert2")) invertedLogic[1] = d.boolValue;
    if (json->get(d, "invert3")) invertedLogic[2] = d.boolValue;
    if (json->get(d, "invert4")) invertedLogic[3] = d.boolValue;
    if (json->get(d, "invert5")) invertedLogic[4] = d.boolValue;
    if (json->get(d, "invert6")) invertedLogic[5] = d.boolValue;
    if (json->get(d, "invert7")) invertedLogic[6] = d.boolValue;

    if (json->get(d, "ecoMode")) isEcoMode = d.boolValue;
  } else {
    int intVal = data.intData();
    if (path == "/relay1") relayState[0] = intVal;
    if (path == "/relay2") relayState[1] = intVal;
    if (path == "/relay3") relayState[2] = intVal;
    if (path == "/relay4") relayState[3] = intVal;
    if (path == "/relay5") relayState[4] = intVal;
    if (path == "/relay6") relayState[5] = intVal;
    if (path == "/relay7") relayState[6] = intVal;

    if (path == "/invert1") invertedLogic[0] = data.boolData();
    if (path == "/invert2") invertedLogic[1] = data.boolData();
    if (path == "/invert3") invertedLogic[2] = data.boolData();
    if (path == "/invert4") invertedLogic[3] = data.boolData();
    if (path == "/invert5") invertedLogic[4] = data.boolData();
    if (path == "/invert6") invertedLogic[5] = data.boolData();
    if (path == "/invert7") invertedLogic[6] = data.boolData();

    if (path == "/ecoMode") {
      isEcoMode = data.boolData();
      Serial.printf("MODE CHANGED: %s\n", isEcoMode ? "ECO" : "PERFORMANCE");
    }
    if (path == "/schedules_raw") {
      globalSchedulesRaw = data.stringData();
      Serial.printf("📅 Schedules Loaded: %s\n", globalSchedulesRaw.c_str());
    }
  }

  reportInterval = isEcoMode ? 8000 : 3000;
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

/* ================= TASKS ================= */

// Core 0: Networking & Firebase Task
void networkTask(void *pvParameters) {
  unsigned long lastReconnectAttempt = 0;
  for (;;) {
    ArduinoOTA.handle();

    if (WiFi.status() == WL_CONNECTED) {
      if (Firebase.ready()) {
        isInternetLive = true;
        wasOffline = false;
      } else {
        isInternetLive = false;
      }
    } else {
      isInternetLive = false;
      if (millis() - lastReconnectAttempt > 10000) {
        Serial.println("WiFi disconnected. Attempting high-end recovery...");
        WiFi.disconnect(true);
        vTaskDelay(500 / portTICK_PERIOD_MS);
        WiFi.begin(WIFI_SSID, WIFI_PASS);
        lastReconnectAttempt = millis();
      }
    }

    // Telemetry Engine
    static unsigned long lastTeleCheck = 0;
    if (millis() - lastTeleCheck > (isEcoMode ? 2000 : 500)) {
      lastTeleCheck = millis();
      bool timeExpired = (millis() - lastTelemetryTime > reportInterval);

      if (forceTelemetry || timeExpired) {
        if (Firebase.ready() && isInternetLive) {
          FirebaseJson j;
          j.set("relay1", relayState[0]);
          j.set("relay2", relayState[1]);
          j.set("relay3", relayState[2]);
          j.set("relay4", relayState[3]);
          j.set("relay5", relayState[4]);
          j.set("relay6", relayState[5]);
          j.set("relay7", relayState[6]);
          j.set("tele_id", tele_id++);
          
          j.set("ap_mac", WiFi.softAPmacAddress());
          j.set("ch", WiFi.channel());
          j.set("ecoMode", isEcoMode);
          j.set("lastSeen/.sv", "timestamp");
          
          forceTelemetry = false;

          if (Firebase.RTDB.updateNodeAsync(&fbTele, pathTele.c_str(), &j)) {
            lastTelemetryTime = millis();
            Serial.printf("🛰 TELEMETRY SENT | ID: %d\n", tele_id - 1);
          } else {
            Serial.printf("❌ TELEMETRY FAILED: %s\n", fbTele.errorReason().c_str());
          }
        }
      }
    }
    
    // Give time to WiFi stack
    vTaskDelay(10 / portTICK_PERIOD_MS);
  }
}

// Core 1: Hardware & Real-time Scheduling Engine
void hardwareTask(void *pvParameters) {
  for (;;) {
    animateLEDs();

    // Instant apply with ZERO concurrency collisions
    if (updateRelays) {
      applyRelays();
      updateRelays = false;
    }

    // --- DEAD MAN SAFETY ---
    if (!isInternetLive) {
      if (!wasOffline) {
        wasOffline = true;
        offlineStartTime = millis();
      } else if (millis() - offlineStartTime > 600000) { // 10 minutes (600,000ms)
        bool anyOn = false;
        for (int i = 0; i < 7; i++) {
          if (relayState[i]) {
            relayState[i] = 0;
            anyOn = true;
          }
        }
        if (anyOn) {
           Serial.println("🚨 DEAD MAN SAFETY: Internet offline > 10m. Shutting off all relays.");
           applyRelays();
        }
      }
    }

    // --- NTP SCHEDULER ENGINE ---
    time_t now;
    struct tm timeinfo;
    if (time(&now) && localtime_r(&now, &timeinfo)) {
      if (timeinfo.tm_year > (2020 - 1900)) { // Time is valid
        if (timeinfo.tm_min != lastCheckedMinute) {
          lastCheckedMinute = timeinfo.tm_min;
          
          String raw = globalSchedulesRaw;
          while (raw.length() > 0) {
            int sep = raw.indexOf(';');
            String entry = (sep == -1) ? raw : raw.substring(0, sep);
            raw = (sep == -1) ? "" : raw.substring(sep + 1);
            
            if (entry.length() > 8) {
              int h = entry.substring(0, 2).toInt();
              int m = entry.substring(3, 5).toInt();
              
              if (h == timeinfo.tm_hour && m == timeinfo.tm_min) {
                int p1 = entry.indexOf(':', 6);
                int p2 = entry.indexOf(':', p1 + 1);
                
                if (p1 != -1 && p2 != -1) {
                  String node = entry.substring(6, p1);
                  int tState = entry.substring(p1 + 1, p2).toInt();
                  String daysStr = entry.substring(p2 + 1);
                  
                  int currentDayNum = (timeinfo.tm_wday == 0) ? 7 : timeinfo.tm_wday;
                  bool dayMatch = (daysStr == "0");
                  
                  if (!dayMatch) {
                    String cDay = String(currentDayNum);
                    if (daysStr == cDay || daysStr.startsWith(cDay + ",") || 
                        daysStr.indexOf("," + cDay + ",") != -1 || 
                        daysStr.endsWith("," + cDay)) {
                      dayMatch = true;
                    }
                  }
                  
                  if (dayMatch) {
                    Serial.printf("⏰ SCHEDULE TRIGGER: %s -> %d\n", node.c_str(), tState);
                    if (node == "r1") relayState[0] = tState;
                    else if (node == "r2") relayState[1] = tState;
                    else if (node == "r3") relayState[2] = tState;
                    else if (node == "r4") relayState[3] = tState;
                    else if (node == "r5") relayState[4] = tState;
                    else if (node == "r6") relayState[5] = tState;
                    else if (node == "r7") relayState[6] = tState;
                    updateRelays = true;
                  }
                }
              }
            }
          }
        }
      }
    }

    // Keep loop responsive
    vTaskDelay(20 / portTICK_PERIOD_MS);
  }
}

/* ================= SETUP ================= */
void setup() {
  Serial.begin(115200);
  delay(1000);
  Serial.printf("\n\n--- AUREXA CORE BOOT v2.1.0 (RELAYS ONLY) ---\n");

  // PRE-ALLOCATE PATHS TO PREVENT HEAP FRAGMENTATION
  pathTele = "devices/" + deviceId + "/telemetry";
  pathCmds = "devices/" + deviceId + "/commands";
  pathMac = "devices/" + deviceId + "/wifi_mac_address";

  pinMode(RELAY1, OUTPUT);
  pinMode(RELAY2, OUTPUT);
  pinMode(RELAY3, OUTPUT);
  pinMode(RELAY4, OUTPUT);
  pinMode(RELAY5, OUTPUT);
  pinMode(RELAY6, OUTPUT);
  pinMode(RELAY7, OUTPUT);
  applyRelays();

  initLEDs();

  WiFi.mode(WIFI_AP_STA);

  // 🔥 CRITICAL FIX: Disable WiFi Power Save.
  WiFi.setSleep(false);
  WiFi.setAutoReconnect(true);
  WiFi.persistent(true);
  WiFi.begin(WIFI_SSID, WIFI_PASS);

  unsigned long startAttempt = millis();
  while (WiFi.status() != WL_CONNECTED) {
    animateLEDs();
    if (millis() - startAttempt > 20000) break;
    delay(10);
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n✅ WiFi Connected");
    Serial.printf("Operating Channel: %d\n", WiFi.channel());
    isInternetLive = true;
    triggerActivityLED();
    // Initialize NTP
    configTime(19800, 0, "pool.ntp.org", "time.nist.gov"); // GMT+5:30
    Serial.println("🕰️ NTP Time Configured for +05:30");
  }

  ArduinoOTA.setHostname(OTA_HOSTNAME);
  ArduinoOTA.setPassword(OTA_PASSWORD);
  ArduinoOTA.onStart([]() { isOTAActive = true; });
  ArduinoOTA.onEnd([]() {
    isOTAActive = false;
    triggerActivityLED();
    ESP.restart();
  });
  ArduinoOTA.begin();

  MDNS.addService("aurexa", "tcp", 80);

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
  Firebase.RTDB.setStreamCallback(&fbStream, streamCallback, streamTimeoutCallback);

  // START DUAL CORE TASKS
  // Core 0: Network
  xTaskCreatePinnedToCore(networkTask, "NetworkTask", 10000, NULL, 1, &NetworkTaskHandle, 0);
  // Core 1: Hardware
  xTaskCreatePinnedToCore(hardwareTask, "HardwareTask", 8000, NULL, 1, &HardwareTaskHandle, 1);
}

/* ================= MAIN LOOP ================= */
void loop() {
  // Empty! Everything runs in optimized FreeRTOS tasks now.
  vTaskDelete(NULL);
}
