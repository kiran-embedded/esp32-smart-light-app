/*
 * -----------------------------------------------------------------------------
 * NEBULA CORE – 4-CHANNEL SMART SWITCH (PURE CLOUD EDITION)
 * VERSION: v3.2.0-ULTRA-FAST
 * -----------------------------------------------------------------------------
 * SYSTEM: ESP32 Dual-Core (Firebase RTDB Managed)
 * FEATURES: Instant Callback Relay Engine, Hardened Recovery, Cloud-Synced
 * STRIPPED: All Security, PIR, Voltage, and Buzzer logic removed for speed.
 * -----------------------------------------------------------------------------
 */

#include <ArduinoOTA.h>
#include <ESPmDNS.h>
#include <Firebase_ESP_Client.h>
#include <WiFi.h>
#include <time.h>

#include "addons/RTDBHelper.h"
#include "addons/TokenHelper.h"

/* ================= CONFIGURATION ================= */
#define WIFI_SSID "Kerala_Vision"
#define WIFI_PASS "chandrasekharan0039"
#define OTA_HOSTNAME "Nebula-Core-ESP32"
#define OTA_PASSWORD "nebula2024"
#define API_KEY "AIzaSyA9zs6xhRcEwwGLO6cI417b2FO52PiXaxs"
#define DATABASE_URL "https://nebula-smartpowergrid-default-rtdb.asia-southeast1.firebasedatabase.app"

/* ================= PIN DEFINITIONS ================= */
#define RELAY1 26
#define RELAY2 27
#define RELAY3 25
#define RELAY4 33

#define LED_PIN_RED 19
#define LED_PIN_GREEN 13 
#define LED_PIN_BLUE 17

/* ================= CONSTANTS ================= */
#define MIN_FREE_HEAP 20000
#define MAX_FRAG_PERCENT 50
#define RECOVERY_COOLDOWN_MS 30000 
#define RELAY_CMD_DEBOUNCE_MS 300 
#define TELEMETRY_INTERVAL_MS 2500

/* ================= GLOBALS ================= */
FirebaseData fbTele;
FirebaseData fbStream;
FirebaseData fbStatus;
FirebaseAuth auth;
FirebaseConfig config;

bool isOTAActive = false;
bool isInternetLive = false;
bool fbConnected = false;
String deviceId = "79215788";

bool relayState[4] = {0, 0, 0, 0};
bool invertedLogic[4] = {1, 1, 1, 1}; // Default to 1 (true) for Active-LOW relays

bool forceTelemetry = false;
unsigned long lastTelemetryTime = 0;

String pathTele, pathCmds;

// Recovery & Debounce State
unsigned long lastRecoveryTime = 0;
int lowHeapCount = 0;
unsigned long lastCommandTime = 0;   
unsigned long lastHeartbeatTime = 0; 
unsigned long wifiOfflineSince = 0; 
bool initialSyncDone = false; 

/* ================= LED ENGINE ================= */
void initLEDs() {
  pinMode(LED_PIN_RED, OUTPUT);
  pinMode(LED_PIN_GREEN, OUTPUT);
  pinMode(LED_PIN_BLUE, OUTPUT);
}

void animateLEDs() {
  unsigned long now = millis();
  int targetColor = 0; // 0=off, 1=RED, 2=GREEN, 3=BLUE

  if (isOTAActive) {
    targetColor = ((now / 100) % 2 == 0) ? 1 : 3;
  } else {
    if (WiFi.status() != WL_CONNECTED) {
      targetColor = ((now / 1000) % 2 == 0) ? 1 : 0;
    } else if (!Firebase.ready()) {
      if ((now / 1500) % 2 == 0) targetColor = 1;
    } else {
      unsigned long cycle = now % 2000;
      if (cycle < 80 || (cycle > 250 && cycle < 330)) targetColor = 2;
    }
  }

  digitalWrite(LED_PIN_RED, (targetColor == 1) ? HIGH : LOW);
  digitalWrite(LED_PIN_GREEN, (targetColor == 2) ? HIGH : LOW);
  digitalWrite(LED_PIN_BLUE, (targetColor == 3) ? HIGH : LOW);
}

/* ================= STABILITY ENGINES ================= */
void softRecoveryEngine() {
  unsigned long now = millis();
  if (now - lastRecoveryTime < RECOVERY_COOLDOWN_MS) return;
  lastRecoveryTime = now;
  lowHeapCount = 0;

  Serial.println("⚠️ SOFT RECOVERY. Resetting network stack...");

  Firebase.RTDB.endStream(&fbStream);
  
  // Advanced Disconnect Sequence
  WiFi.disconnect(true, true);
  delay(500);
  WiFi.begin(WIFI_SSID, WIFI_PASS);

  unsigned long wifiStart = millis();
  while (WiFi.status() != WL_CONNECTED && millis() - wifiStart < 8000) {
    delay(100);
    animateLEDs();
  }

  if (WiFi.status() == WL_CONNECTED) {
    Firebase.RTDB.beginStream(&fbStream, pathCmds.c_str());
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
    if (WiFi.status() == WL_CONNECTED) {
      isInternetLive = true;
      fbConnected = Firebase.ready();
      vTaskDelay(5000 / portTICK_PERIOD_MS);
    } else {
      isInternetLive = false;
      fbConnected = false;
      // We DO NOT call WiFi.reconnect() here. 
      // Spamming reconnect() resets the internal modem state machine and prevents connection.
      // The native ESP-IDF WiFi.setAutoReconnect(true) handles this in the background perfectly.
      Serial.println("⚠️ WiFi Offline. Awaiting native background reconnect...");
      vTaskDelay(5000 / portTICK_PERIOD_MS); 
    }
  }
}

/* ================= HARDWARE CONTROL ================= */
void applyRelays() {
  int pins[] = {RELAY1, RELAY2, RELAY3, RELAY4};
  for (int i = 0; i < 4; i++) {
    bool target = (relayState[i] != invertedLogic[i]);
    digitalWrite(pins[i], target ? HIGH : LOW);
  }

  lastCommandTime = millis();
  Serial.printf("⚡ Relays: [%d %d %d %d]\n", relayState[0], relayState[1], relayState[2], relayState[3]);
}

/* ================= COMMAND STREAM CALLBACK ================= */
void streamCallback(FirebaseStream data) {
  isInternetLive = true;
  fbConnected = true;
  String path = data.dataPath();
  bool wasRelayUpdated = false;

  if (path == "/") {
    FirebaseJson *json = data.jsonObjectPtr();
    FirebaseJsonData d;
    for (int i = 0; i < 4; i++) {
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
      if (json->get(d, k)) invertedLogic[i] = d.boolValue;
    }

    if (!initialSyncDone) {
      initialSyncDone = true;
      Serial.println("📡 Initial sync completed.");
    }
  } else {
    if (path.startsWith("/relay")) {
      int idx = path.substring(6).toInt() - 1;
      if (idx >= 0 && idx < 4) {
        bool val = (data.intData() > 0 || data.boolData() || data.stringData() == "true");
        if (relayState[idx] != val) {
          relayState[idx] = val;
          wasRelayUpdated = true;
        }
      }
    } else if (path.startsWith("/invert")) {
      int idx = path.substring(7).toInt() - 1;
      if (idx >= 0 && idx < 4) {
        invertedLogic[idx] = data.boolData();
        wasRelayUpdated = true; 
      }
    }
  }

  // ⭐ SPEED OPTIMIZATION: Apply directly in callback for zero loop-polling latency
  if (wasRelayUpdated) {
    applyRelays();
    forceTelemetry = true;
  }
}

void streamTimeoutCallback(bool timeout) {
  if (timeout) {
    Serial.println("⚠️ Stream timeout detected.");
  }
}

/* ================= SETUP ================= */
void setup() {
  Serial.begin(115200);
  delay(100);
  Serial.println("\n🚀 NEBULA CORE v3.2.0-ULTRA-FAST booting...");
  initLEDs();

  int pins[] = {RELAY1, RELAY2, RELAY3, RELAY4};
  for (int i = 0; i < 4; i++) {
    // Write HIGH before setting OUTPUT to prevent JD-VCC optocoupler glitch
    digitalWrite(pins[i], HIGH); 
    pinMode(pins[i], OUTPUT);
    digitalWrite(pins[i], HIGH); // Keep Active-LOW relays OFF during boot/WiFi connection
  }

  // Advanced WiFi Reset Sequence
  WiFi.disconnect(true, true); // Flushes out dirty modem states
  delay(100);
  
  WiFi.mode(WIFI_STA);
  WiFi.setSleep(false); 
  WiFi.setAutoReconnect(true); // Let ESP-IDF handle drops natively
  WiFi.begin(WIFI_SSID, WIFI_PASS);

  pathTele = "devices/" + deviceId + "/telemetry";
  pathCmds = "devices/" + deviceId + "/commands";

  unsigned long startT = millis();
  while (WiFi.status() != WL_CONNECTED && millis() - startT < 15000) {
    delay(50);
    animateLEDs();
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.printf("✅ WiFi connected. IP: %s\n", WiFi.localIP().toString().c_str());
    configTime(19800, 0, "pool.ntp.org");
  } else {
    Serial.println("❌ WiFi failed on boot. Native Auto-Reconnect will continue in background.");
  }

  xTaskCreatePinnedToCore(connectivityTask, "ConnTask", 4096, NULL, 1, NULL, 0);

  ArduinoOTA.setHostname(OTA_HOSTNAME);
  ArduinoOTA.setPassword(OTA_PASSWORD);
  ArduinoOTA.onStart([]() { isOTAActive = true; });
  ArduinoOTA.onEnd([]() { isOTAActive = false; });
  ArduinoOTA.begin();
  
  unsigned long fbWait = millis();
  while (!Firebase.ready() && millis() - fbWait < 5000) {
    delay(100);
    animateLEDs();
  }

  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;
  config.token_status_callback = tokenStatusCallback;
  Firebase.signUp(&config, &auth, "", "");
  Firebase.begin(&config, &auth);

  Firebase.RTDB.beginStream(&fbStream, pathCmds.c_str());
  Firebase.RTDB.setStreamCallback(&fbStream, streamCallback, streamTimeoutCallback);

  lastHeartbeatTime = millis();
  Serial.println("✅ SYSTEM READY.");
}

/* ================= LOOP ================= */
void loop() {
  animateLEDs(); 
  ArduinoOTA.handle(); 

  unsigned long now = millis();

  // --- 🛡️ SOFTWARE WATCHDOG & WIFI FAILSAFE ---
  if (WiFi.status() != WL_CONNECTED) {
    if (wifiOfflineSince == 0) wifiOfflineSince = now;
    else if (now - wifiOfflineSince > 60000) {
      Serial.println("🚨 CRITICAL: WiFi dead for 60s. Forcing hardware reboot!");
      ESP.restart();
    }
  } else {
    wifiOfflineSince = 0; 
  }

  // Memory health check (runs every 5 seconds)
  static unsigned long lastHealthCheck = 0;
  if (now - lastHealthCheck > 5000) {
    lastHealthCheck = now;
    cpuMemoryHealthCheck();
  }

  // ---- TELEMETRY PUSH ----
  static unsigned long lastTeleCheck = 0;
  if (now - lastTeleCheck > 800) {
    lastTeleCheck = now;

    // Fast 300ms echo suppression
    bool echoSuppressed = (now - lastCommandTime < RELAY_CMD_DEBOUNCE_MS);

    if ((forceTelemetry || (now - lastTelemetryTime > TELEMETRY_INTERVAL_MS)) && !echoSuppressed) {
      if (Firebase.ready() && fbConnected) {
        FirebaseJson j;
        for (int i = 0; i < 4; i++) {
          char k[8];
          sprintf(k, "relay%d", i + 1);
          j.set(k, relayState[i]);
        }
        j.set("heap", (int)ESP.getFreeHeap());
        j.set("rssi", (int)WiFi.RSSI());
        j.set("uptime", (int)(now / 1000));
        
        if (Firebase.RTDB.updateNodeAsync(&fbTele, pathTele.c_str(), &j)) {
          lastTelemetryTime = now;
          forceTelemetry = false;
        }
      }
    }
  }

  // ---- HEARTBEAT PUSH ----
  if (now - lastHeartbeatTime > 15000) { // Every 15 seconds
    lastHeartbeatTime = now;
    if (Firebase.ready()) {
      FirebaseJson stat;
      stat.set("online", true);
      stat.set("lastSeen", (int)(time(NULL)));
      stat.set("uptime", (int)(now / 1000));
      stat.set("heap", (int)ESP.getFreeHeap());
      stat.set("rssi", (int)WiFi.RSSI());
      stat.set("version", "v3.2.0-ULTRA-FAST");
      Firebase.RTDB.updateNodeAsync(&fbStatus, ("devices/" + deviceId + "/status").c_str(), &stat);
    }
  }

  // Rock solid FreeRTOS execution spacing
  vTaskDelay(pdMS_TO_TICKS(2));
}
