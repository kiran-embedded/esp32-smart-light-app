/*
 * -----------------------------------------------------------------------------
 * NEBULA CORE – SATELLITE SENSOR NODE (INDUSTRIAL MINIMAL)
 * VERSION: v2.1.0-STABLE
 * -----------------------------------------------------------------------------
 * ARCH: ESP8266 (1MB Flash Compatible)
 * FIXES: WiFi auto-reconnect, Firebase token fallback, periodic force-push,
 *        reliable PIR detection with proper state tracking.
 * -----------------------------------------------------------------------------
 */

#define FIREBASE_DISABLE_CA_CERT
#define FIREBASE_DISABLE_GCP
#define FIREBASE_DISABLE_FIRESTORE
#define FIREBASE_DISABLE_FUNCTIONS
#define FIREBASE_DISABLE_MESSAGING
#define FIREBASE_DISABLE_STORAGE
#define FIREBASE_DISABLE_EXTERNAL_CLIENT

#include <ArduinoOTA.h>
#include <ESP8266WiFi.h>
#include <Firebase_ESP_Client.h>
#include <time.h>

/* ================= CONFIGURATION ================= */
#define WIFI_SSID "Kerala_Vision"
#define WIFI_PASS "chandrasekharan0039"
#define OTA_HOSTNAME "Nebula-Satellite-GOLD"
#define OTA_PASSWORD "nebula2024"
#define API_KEY "AIzaSyA9zs6xhRcEwwGLO6cI417b2FO52PiXaxs"
#define DATABASE_URL                                                           \
  "nebula-smartpowergrid-default-rtdb.asia-southeast1.firebasedatabase.app"
#define DEVICE_ID "79215788"

#define STATUS_LED LED_BUILTIN
const uint8_t PIR_PINS[4] = {5, 4, 14, 12};

/* ================= LOGIC CONSTANTS ================= */
int REQUIRED_PULSES = 2;
unsigned long WINDOW_TIME = 15000;
unsigned long HOLD_TIME = 3000;
unsigned long MIN_GAP = 2000;
int highValidTimeArr[4] = {150, 150, 150, 150};

struct PirZone {
  unsigned long firstPulseTime;
  int lastPirState;
  int pulseCount;
  unsigned long lastPulseTime;
  unsigned long highStart;
  unsigned long detectedTime;
  bool motionDetected;
};
PirZone zones[4];

FirebaseData fbData, fbStream, fbStatus;
FirebaseAuth auth;
FirebaseConfig config;
bool isFirebaseReady = false;

// --- Neural Link Globals ---
uint8_t pirRelayMask[4] = {1, 2, 4, 8}; 
unsigned long PIR_ON_DURATION = 60000;
bool isArmed = true;
bool isLdrSecurityEnabled = false;
int LDR_NIGHT_THRESHOLD = 30;
bool activePeriods[5] = {true, true, true, true, true}; // morning, afternoon, evening, night, midnight

unsigned long pirAutoOffTimer[7] = {0, 0, 0, 0, 0, 0, 0};
bool relayState[7] = {false, false, false, false, false, false, false};

// LED Engine
int pendingPulses = 0;
unsigned long lastLedAction = 0;
unsigned long hbStart = 0;

// WiFi reconnect state
unsigned long lastForcePush = 0;
unsigned long lastTokenCheck = 0;
bool wasConnected = false;

// Precomputed Firebase Paths
String basePath;
String pathStatus;
String pathPanic;
String pathRelays[7];
String pathPIRs[4];

void triggerLedPulse(int count) { pendingPulses = count * 2; }

void animateLED() {
  unsigned long now = millis();
  if (pendingPulses > 0) {
    if (now - lastLedAction > 80) {
      digitalWrite(STATUS_LED, !digitalRead(STATUS_LED));
      lastLedAction = now;
      pendingPulses--;
    }
  } else {
    if (now - lastLedAction > 2000) {
      digitalWrite(STATUS_LED, LOW);
      hbStart = now;
      lastLedAction = now;
    }
    if (hbStart > 0 && now - hbStart > 150) {
      digitalWrite(STATUS_LED, HIGH);
      hbStart = 0;
    }
  }
}

void tokenStatusCallback(TokenInfo info) {
  if (info.status == token_status_ready)
    isFirebaseReady = true;
}

void configStreamCallback(FirebaseStream data) {
  triggerLedPulse(4);
  String p = data.dataPath();
  
  if (p == F("/")) {
    FirebaseJson *json = data.jsonObjectPtr();
    FirebaseJsonData d;
    if (json->get(d, "mapPIR1")) pirRelayMask[0] = d.intValue;
    if (json->get(d, "mapPIR2")) pirRelayMask[1] = d.intValue;
    if (json->get(d, "mapPIR3")) pirRelayMask[2] = d.intValue;
    if (json->get(d, "mapPIR4")) pirRelayMask[3] = d.intValue;
    if (json->get(d, "pirTimer")) PIR_ON_DURATION = (unsigned long)d.intValue * 1000;
    if (json->get(d, "ldrThreshold")) LDR_NIGHT_THRESHOLD = d.intValue;
    
    // Relay State Sync
    for(int r=0; r<7; r++) {
      String rKey = "relay" + String(r+1);
      if (json->get(d, rKey)) relayState[r] = (d.intValue > 0 || d.boolValue || d.stringValue == "true");
    }
    
    // Security config (App syncs these to commands stream)
    if (json->get(d, "isArmed")) isArmed = d.boolValue;
    if (json->get(d, "ldrSecurity")) isLdrSecurityEnabled = d.boolValue;

    if (json->get(d, "security/activePeriods/morning")) activePeriods[0] = d.boolValue;
    if (json->get(d, "security/activePeriods/afternoon")) activePeriods[1] = d.boolValue;
    if (json->get(d, "security/activePeriods/evening")) activePeriods[2] = d.boolValue;
    if (json->get(d, "security/activePeriods/night")) activePeriods[3] = d.boolValue;
    if (json->get(d, "security/activePeriods/midnight")) activePeriods[4] = d.boolValue;

    for (int i=1; i<=4; i++) {
        char key[64];
        sprintf(key, "security/calibration/PIR%d/debounce", i);
        if (json->get(d, key)) highValidTimeArr[i-1] = d.intValue;
    }
  } else {
    int intV = data.intData();
    if (p == F("/mapPIR1")) pirRelayMask[0] = intV;
    else if (p == F("/mapPIR2")) pirRelayMask[1] = intV;
    else if (p == F("/mapPIR3")) pirRelayMask[2] = intV;
    else if (p == F("/mapPIR4")) pirRelayMask[3] = intV;
    else if (p == F("/pirTimer")) PIR_ON_DURATION = (unsigned long)intV * 1000;
    else if (p == F("/ldrThreshold")) LDR_NIGHT_THRESHOLD = intV;
    else if (p.startsWith(F("/relay"))) {
      int rIdx = p.substring(6).toInt() - 1;
      if (rIdx >= 0 && rIdx < 7) relayState[rIdx] = (data.intData() > 0 || data.boolData() || data.stringData() == "true");
    }
    else if (p.startsWith(F("/security/activePeriods/"))) {
       if (p.endsWith(F("morning"))) activePeriods[0] = data.boolData();
       else if (p.endsWith(F("afternoon"))) activePeriods[1] = data.boolData();
       else if (p.endsWith(F("evening"))) activePeriods[2] = data.boolData();
       else if (p.endsWith(F("night"))) activePeriods[3] = data.boolData();
       else if (p.endsWith(F("midnight"))) activePeriods[4] = data.boolData();
    }
    else if (p.indexOf(F("/calibration/PIR")) != -1 && p.endsWith(F("/debounce"))) {
       int pirIdx = p.substring(p.indexOf(F("PIR")) + 3, p.indexOf(F("PIR")) + 4).toInt() - 1;
       if (pirIdx >= 0 && pirIdx < 4) highValidTimeArr[pirIdx] = intV;
    }
    
    if (p.indexOf(F("isArmed")) != -1) isArmed = data.boolData();
    if (p.indexOf(F("ldrSecurity")) != -1) isLdrSecurityEnabled = data.boolData();
  }
}

void initFirebase() {
  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;
  config.token_status_callback = tokenStatusCallback;
  Firebase.signUp(&config, &auth, "", "");
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);

  String p = F("devices/");
  p += DEVICE_ID;
  p += F("/commands");
  Firebase.RTDB.beginStream(&fbStream, p);
  Firebase.RTDB.setStreamCallback(&fbStream, configStreamCallback,
                                  [](bool t) {});
}

void setup() {
  pinMode(STATUS_LED, OUTPUT);
  digitalWrite(STATUS_LED, HIGH);

  for (int i = 0; i < 4; i++) {
    pinMode(PIR_PINS[i], INPUT);
    zones[i] = {0, LOW, 0, 0, 0, 0, false};
  }

  WiFi.mode(WIFI_STA);
  WiFi.setAutoReconnect(true);
  WiFi.persistent(true);
  WiFi.begin(WIFI_SSID, WIFI_PASS);

  unsigned long start = millis();
  while (WiFi.status() != WL_CONNECTED && millis() - start < 15000) {
    delay(100);
    yield();
  }

  if (WiFi.status() == WL_CONNECTED) {
    wasConnected = true;
    configTime(19800, 0, "pool.ntp.org");
    basePath = "devices/" + String(DEVICE_ID);
    pathStatus = basePath + "/security/nodeActive";
    pathPanic = basePath + "/commands/panic";
    for(int i=0; i<7; i++) pathRelays[i] = basePath + "/commands/relay" + String(i+1);
    for(int i=0; i<4; i++) pathPIRs[i] = basePath + "/security/sensors/PIR" + String(i+1);
    
    // Set minimal SSL buffer sizes to save memory on ESP8266
    fbData.setBSSLBufferSize(2048, 1024);
    fbStream.setBSSLBufferSize(2048, 1024);
    fbStatus.setBSSLBufferSize(2048, 1024);
    
    initFirebase();
  }

  ArduinoOTA.setHostname(OTA_HOSTNAME);
  ArduinoOTA.setPassword(OTA_PASSWORD);
  ArduinoOTA.begin();
}

void loop() {
  ArduinoOTA.handle();
  animateLED();
  unsigned long now = millis();

  // ---- WiFi auto-reconnect state tracking ----
  if (WiFi.status() != WL_CONNECTED) {
    if (wasConnected) {
      wasConnected = false;
    }
  } else {
    if (!wasConnected) {
      wasConnected = true;
      triggerLedPulse(3);
    }
  }

  // ---- Firebase token fallback ----
  if (!isFirebaseReady && now - lastTokenCheck > 30000) {
    lastTokenCheck = now;
    if (Firebase.ready()) {
      isFirebaseReady = true;
      triggerLedPulse(5);
    }
  }

  // ---- PIR Processing ----
  for (int i = 0; i < 4; i++) {
    int pir = digitalRead(PIR_PINS[i]);
    PirZone &z = zones[i];

    if (pir == HIGH) {
      if (z.highStart == 0)
        z.highStart = now;
    } else
      z.highStart = 0;

    if (z.highStart > 0 && (now - z.highStart >= (unsigned long)highValidTimeArr[i])) {
      if (z.lastPirState == LOW) {
        if (!(z.pulseCount > 0 && (now - z.lastPulseTime < MIN_GAP))) {
          if (z.pulseCount == 0)
            z.firstPulseTime = now;
          z.pulseCount++;
          z.lastPulseTime = now;
          if (!z.motionDetected && z.pulseCount >= REQUIRED_PULSES) {
            if (now - z.firstPulseTime <= WINDOW_TIME) {
              z.motionDetected = true;
              z.detectedTime = now;
            } else {
              z.pulseCount = 1;
              z.firstPulseTime = now;
            }
          }
        }
      }
      z.lastPirState = HIGH;
    } else if (pir == LOW)
      z.lastPirState = LOW;

    if (z.motionDetected && (now - z.detectedTime > HOLD_TIME)) {
      z.motionDetected = false;
      z.pulseCount = 0;
    }
    if (!z.motionDetected && z.pulseCount > 0 &&
        (now - z.lastPulseTime > WINDOW_TIME)) {
      z.pulseCount = 0;
    }
  }

  // ---- Firebase Push ----
  static uint8_t lastMask = 0xFF; // Force first push
  static int lastLdr = -1;
  static unsigned long lastUpdate = 0;
  static int lastStates[4] = {-1, -1, -1, -1};

  uint8_t currentMask = 0;
  for (int i = 0; i < 4; i++)
    if (zones[i].motionDetected)
      currentMask |= (1 << i);

  int currentLdr = map(analogRead(A0), 0, 1024, 0, 100);

  bool shouldPush = false;
  if (currentMask != lastMask)
    shouldPush = true;
  if (abs(currentLdr - lastLdr) > 10)
    shouldPush = true;
  if (now - lastUpdate > 20000)
    shouldPush = true; // Force periodic push

  if (isFirebaseReady && shouldPush) {
    // Neural Grid Trigger Logic (Relay Automation)
    bool isNightTime = (currentLdr < LDR_NIGHT_THRESHOLD);
    if (isNightTime) {
      for (int i = 0; i < 4; i++) {
        if (zones[i].motionDetected) {
          // Keep active timer refreshed
          for (int r = 0; r < 7; r++) {
            if (pirRelayMask[i] & (1 << r)) {
              if (!relayState[r]) {
                relayState[r] = true;
                Firebase.RTDB.setIntAsync(&fbData, pathRelays[r], 1);
              }
              pirAutoOffTimer[r] = now;
            }
          }
        }
      }
    }

    // --- NTP Schedule Evaluation ---
    time_t rawtime = time(NULL);
    struct tm* timeinfo = localtime(&rawtime);
    int hour = timeinfo->tm_hour;
    
    bool isTimeActive = true;
    if (timeinfo->tm_year > 100) { // Year > 2000 means NTP synced properly
       if (hour >= 6 && hour < 12) isTimeActive = activePeriods[0];
       else if (hour >= 12 && hour < 17) isTimeActive = activePeriods[1];
       else if (hour >= 17 && hour < 21) isTimeActive = activePeriods[2];
       else if (hour >= 21 || hour < 0) isTimeActive = activePeriods[3];
       else isTimeActive = activePeriods[4];
    }

    const bool ldrPass = (!isLdrSecurityEnabled || isNightTime);
    if (isArmed && ldrPass && isTimeActive && currentMask != 0 && (currentMask != lastMask)) {
        Firebase.RTDB.setBoolAsync(&fbData, pathPanic, true);
    }

    lastMask = currentMask;
    lastLdr = currentLdr;
    lastUpdate = now;
    triggerLedPulse(2);

    for (int i = 0; i < 4; i++) {
      int state = (currentMask & (1 << i)) != 0 ? 1 : 0;
      if (state != lastStates[i]) {
        lastStates[i] = state;
        FirebaseJson zoneData;
        zoneData.set(F("status"), state == 1);
        zoneData.set(F("lightLevel"), currentLdr);
        if (state == 1)
          zoneData.set(F("lastTriggered"), (int)time(NULL));

        Firebase.RTDB.updateNodeAsync(&fbData, pathPIRs[i], &zoneData);
      }
    }

    // Satellite heartbeat
    FirebaseJson status;
    status.set(F("online"), true);
    status.set(F("lastSeen"), (int)time(NULL));
    status.set(F("signal"), WiFi.RSSI());
    status.set(F("version"), F("v2.5.0-NEURAL"));

    // Dev Console Emulated Telegraphs
    for(int i=0; i<4; i++) {
        char key[16];
        sprintf(key, "signal_p%d", i+1);
        status.set(key, zones[i].pulseCount * 15); // simulate spike for visual analyzer
    }

    Firebase.RTDB.updateNodeAsync(&fbStatus, pathStatus, &status);
  }

  // ---- ESP8266 Managed Auto-Off Logic ----
  if (isFirebaseReady) {
      for(int r = 0; r < 7; r++) {
         if (relayState[r] && pirAutoOffTimer[r] > 0 && (now - pirAutoOffTimer[r] > PIR_ON_DURATION)) {
             relayState[r] = false;
             pirAutoOffTimer[r] = 0;
             Firebase.RTDB.setIntAsync(&fbData, pathRelays[r], 0);
         }
      }
  }

  // ---- Force push heartbeat even if no sensor change (every 30s) ----
  if (isFirebaseReady && now - lastForcePush > 30000) {
    lastForcePush = now;
    FirebaseJson status;
    status.set(F("online"), true);
    status.set(F("lastSeen"), (int)time(NULL));
    status.set(F("signal"), WiFi.RSSI());

    Firebase.RTDB.updateNodeAsync(&fbStatus, pathStatus, &status);
  }
}
