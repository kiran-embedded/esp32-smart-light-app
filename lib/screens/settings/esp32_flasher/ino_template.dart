const String aurexaInoTemplate = r'''/*
 * -----------------------------------------------------------------------------
 * AUREXA CORE – SMART SWITCH (PURE CLOUD EDITION)
 * -----------------------------------------------------------------------------
 * SYSTEM: ESP32 Dual-Core (Firebase RTDB Managed)
 * FEATURES: Instant Callback Relay Engine, Hardened Recovery, Cloud-Synced, HTTP OTA
 * -----------------------------------------------------------------------------
 */

#include <ArduinoOTA.h>
#include <ESPmDNS.h>
#include <Firebase_ESP_Client.h>
#include <WiFi.h>
#include <time.h>
#include <WebServer.h>
#include <Update.h>

#include "addons/RTDBHelper.h"
#include "addons/TokenHelper.h"

/* ================= CONFIGURATION ================= */
#define WIFI_SSID "{{WIFI_SSID}}"
#define WIFI_PASS "{{WIFI_PASS}}"
#define OTA_HOSTNAME "Aurexa-Core-ESP32"
#define OTA_PASSWORD "aurexa2024"
#define API_KEY "{{API_KEY}}"
#define DATABASE_URL "{{DATABASE_URL}}"

/* ================= PIN DEFINITIONS ================= */
#define RELAY1 26
#define RELAY2 27
#define RELAY3 25
#define RELAY4 33
// Add more relay pins if RELAY_COUNT > 4

#define LED_PIN_RED 19
#define LED_PIN_GREEN 13 
#define LED_PIN_BLUE 17

/* ================= CONSTANTS ================= */
#define MIN_FREE_HEAP 20000
#define MAX_FRAG_PERCENT 50
#define RECOVERY_COOLDOWN_MS 30000 
#define RELAY_CMD_DEBOUNCE_MS 300 
#define TELEMETRY_INTERVAL_MS 2500
#define RELAY_COUNT {{RELAY_COUNT}}

/* ================= GLOBALS ================= */
FirebaseData fbTele;
FirebaseData fbStream;
FirebaseData fbStatus;
FirebaseAuth auth;
FirebaseConfig config;

WebServer server(80); // HTTP Server for App OTA Flasher

bool isOTAActive = false;
bool isInternetLive = false;
bool fbConnected = false;
String deviceId = "{{DEVICE_ID}}";

bool relayState[RELAY_COUNT] = {0};
bool invertedLogic[RELAY_COUNT] = {0}; // Will be populated from Firebase

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

/* ================= HTTP OTA UPDATER ================= */
void setupOTA() {
  server.on("/", HTTP_GET, []() {
    server.sendHeader("Connection", "close");
    server.send(200, "text/html", "<h1>Aurexa Core Online</h1><p>Use the Aurexa app to flash firmware via OTA.</p>");
  });

  server.on("/update", HTTP_POST, []() {
    server.sendHeader("Connection", "close");
    server.send(200, "text/plain", (Update.hasError()) ? "FAIL" : "OK");
    ESP.restart();
  }, []() {
    HTTPUpload& upload = server.upload();
    if (upload.status == UPLOAD_FILE_START) {
      Serial.printf("Update: %s\n", upload.filename.c_str());
      isOTAActive = true;
      if (!Update.begin(UPDATE_SIZE_UNKNOWN)) { 
        Update.printError(Serial);
      }
    } else if (upload.status == UPLOAD_FILE_WRITE) {
      if (Update.write(upload.buf, upload.currentSize) != upload.currentSize) {
        Update.printError(Serial);
      }
    } else if (upload.status == UPLOAD_FILE_END) {
      if (Update.end(true)) {
        Serial.printf("Update Success: %uB\n", upload.totalSize);
      } else {
        Update.printError(Serial);
      }
      isOTAActive = false;
    }
  });
  server.begin();
  Serial.println("HTTP OTA Server started.");
}

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
      if (cycle < 80 || (cycle > 250 && cycle < 330)) targetColor = 3;
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
      Serial.println("⚠️ WiFi Offline. Awaiting native background reconnect...");
      vTaskDelay(5000 / portTICK_PERIOD_MS); 
    }
  }
}

/* ================= HARDWARE CONTROL ================= */
void applyRelays() {
  // Add more pins based on RELAY_COUNT in real scenario
  int pins[] = {RELAY1, RELAY2, RELAY3, RELAY4}; 
  for (int i = 0; i < RELAY_COUNT && i < 4; i++) {
    bool target = (relayState[i] != invertedLogic[i]);
    digitalWrite(pins[i], target ? HIGH : LOW);
  }

  lastCommandTime = millis();
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
    for (int i = 0; i < RELAY_COUNT; i++) {
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
      if (idx >= 0 && idx < RELAY_COUNT) {
        bool val = (data.intData() > 0 || data.boolData() || data.stringData() == "true");
        if (relayState[idx] != val) {
          relayState[idx] = val;
          wasRelayUpdated = true;
        }
      }
    } else if (path.startsWith("/invert")) {
      int idx = path.substring(7).toInt() - 1;
      if (idx >= 0 && idx < RELAY_COUNT) {
        invertedLogic[idx] = data.boolData();
        wasRelayUpdated = true; 
      }
    }
  }

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
  Serial.println("\n🚀 AUREXA CORE booting...");
  initLEDs();

  int pins[] = {RELAY1, RELAY2, RELAY3, RELAY4};
  for (int i = 0; i < RELAY_COUNT && i < 4; i++) {
    digitalWrite(pins[i], HIGH); 
    pinMode(pins[i], OUTPUT);
    digitalWrite(pins[i], HIGH);
    invertedLogic[i] = 1; // default to active low
  }

  WiFi.disconnect(true, true);
  delay(100);
  
  WiFi.mode(WIFI_STA);
  WiFi.setSleep(false); 
  WiFi.setAutoReconnect(true);
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
    setupOTA(); // Start the HTTP OTA Server
  } else {
    Serial.println("❌ WiFi failed on boot.");
  }

  xTaskCreatePinnedToCore(connectivityTask, "ConnTask", 4096, NULL, 1, NULL, 0);

  // Standard IDE OTA Setup
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

  // Setup onDisconnect for Presence
  Firebase.RTDB.onDisconnectAsync(&fbStatus, ("devices/" + deviceId + "/status/online").c_str(), false);

  lastHeartbeatTime = millis();
  Serial.println("✅ SYSTEM READY.");
}

/* ================= LOOP ================= */
void loop() {
  animateLEDs(); 
  ArduinoOTA.handle(); 
  server.handleClient(); // Handle App HTTP OTA Uploads

  unsigned long now = millis();

  if (WiFi.status() != WL_CONNECTED) {
    if (wifiOfflineSince == 0) wifiOfflineSince = now;
    else if (now - wifiOfflineSince > 15000) {
      Serial.println("⚠️ WiFi offline. Attempting non-blocking reconnect...");
      WiFi.disconnect();
      WiFi.begin(WIFI_SSID, WIFI_PASS);
      wifiOfflineSince = now;
    }
  } else {
    wifiOfflineSince = 0; 
  }

  static unsigned long lastHealthCheck = 0;
  if (now - lastHealthCheck > 5000) {
    lastHealthCheck = now;
    cpuMemoryHealthCheck();
  }

  static unsigned long lastTeleCheck = 0;
  if (now - lastTeleCheck > 800) {
    lastTeleCheck = now;
    bool echoSuppressed = (now - lastCommandTime < RELAY_CMD_DEBOUNCE_MS);
    if ((forceTelemetry || (now - lastTelemetryTime > TELEMETRY_INTERVAL_MS)) && !echoSuppressed) {
      if (Firebase.ready() && fbConnected) {
        FirebaseJson j;
        for (int i = 0; i < RELAY_COUNT; i++) {
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

  if (now - lastHeartbeatTime > 15000) { 
    lastHeartbeatTime = now;
    if (Firebase.ready()) {
      FirebaseJson stat;
      stat.set("online", true);
      stat.set("lastSeen", (int)(time(NULL)));
      stat.set("uptime", (int)(now / 1000));
      stat.set("heap", (int)ESP.getFreeHeap());
      stat.set("rssi", (int)WiFi.RSSI());
      stat.set("version", "v3.2.0-AUREXA");
      stat.set("local_ip", WiFi.localIP().toString().c_str());
      Firebase.RTDB.updateNodeAsync(&fbStatus, ("devices/" + deviceId + "/status").c_str(), &stat);
    }
  }

  vTaskDelay(pdMS_TO_TICKS(2));
}
''';
