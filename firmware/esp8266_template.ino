/*
 * =============================================================================
 * NEBULA CORE – ESP8266 SATELLITE TEMPLATE
 * VERSION: v2.1.0 TEMPLATE (Skeleton)
 * =============================================================================
 * THIS IS A CLEAN TEMPLATE. Fill in YOUR credentials below.
 * See FIREBASE_DATA_MAP.md for all data paths explained.
 * =============================================================================
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

/* =================  YOUR CONFIGURATION  ================= */
/* ⚠️  FILL IN YOUR OWN CREDENTIALS BELOW                  */
/* ======================================================== */

#define WIFI_SSID "YOUR_WIFI_NAME"
#define WIFI_PASS "YOUR_WIFI_PASSWORD"
#define OTA_HOSTNAME "Nebula-Satellite"
#define OTA_PASSWORD "YOUR_OTA_PASSWORD"
#define API_KEY "YOUR_FIREBASE_API_KEY"
#define DATABASE_URL "YOUR_PROJECT.firebasedatabase.app"
#define DEVICE_ID "YOUR_DEVICE_ID"

/* =================  PIN DEFINITIONS  ================= */
/* Change these to match YOUR wiring                     */
/* ===================================================== */

#define STATUS_LED LED_BUILTIN
const uint8_t PIR_PINS[4] = {5, 4, 14, 12}; // D1, D2, D5, D6

/* =================  DETECTION TUNING  ================= */
int REQUIRED_PULSES = 2;
unsigned long WINDOW_TIME = 15000;
unsigned long HOLD_TIME = 3000;
unsigned long MIN_GAP = 2000;
unsigned long HIGH_VALID_TIME = 150;

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

int pendingPulses = 0;
unsigned long lastLedAction = 0;
unsigned long hbStart = 0;
unsigned long lastWiFiCheck = 0;
unsigned long lastForcePush = 0;
unsigned long lastTokenCheck = 0;
bool wasConnected = false;

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
  if (p == F("/pulses"))
    REQUIRED_PULSES = data.intData();
  else if (p == F("/window"))
    WINDOW_TIME = data.intData();
  else if (p == F("/hold"))
    HOLD_TIME = data.intData();
  else if (p == F("/gap"))
    MIN_GAP = data.intData();
  else if (p == F("/valid"))
    HIGH_VALID_TIME = data.intData();
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
  p += F("/satellite/config");
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

  // WiFi auto-reconnect
  if (now - lastWiFiCheck > 10000) {
    lastWiFiCheck = now;
    if (WiFi.status() != WL_CONNECTED) {
      WiFi.disconnect();
      delay(500);
      WiFi.begin(WIFI_SSID, WIFI_PASS);
      unsigned long w = millis();
      while (WiFi.status() != WL_CONNECTED && millis() - w < 8000) {
        delay(200);
        yield();
      }
      if (WiFi.status() == WL_CONNECTED && !wasConnected) {
        configTime(19800, 0, "pool.ntp.org");
        initFirebase();
        wasConnected = true;
        triggerLedPulse(3);
      }
    }
  }

  // Firebase token fallback
  if (!isFirebaseReady && now - lastTokenCheck > 30000) {
    lastTokenCheck = now;
    if (Firebase.ready()) {
      isFirebaseReady = true;
      triggerLedPulse(5);
    }
  }

  // PIR Processing
  for (int i = 0; i < 4; i++) {
    int pir = digitalRead(PIR_PINS[i]);
    PirZone &z = zones[i];
    if (pir == HIGH) {
      if (z.highStart == 0)
        z.highStart = now;
    } else
      z.highStart = 0;
    if (z.highStart > 0 && (now - z.highStart >= HIGH_VALID_TIME)) {
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
        (now - z.lastPulseTime > WINDOW_TIME))
      z.pulseCount = 0;
  }

  // Firebase Push
  static uint8_t lastMask = 0xFF;
  static int lastLdr = -1;
  static unsigned long lastUpdate = 0;
  static int lastStates[4] = {-1, -1, -1, -1};
  uint8_t currentMask = 0;
  for (int i = 0; i < 4; i++)
    if (zones[i].motionDetected)
      currentMask |= (1 << i);
  int currentLdr = map(analogRead(A0), 0, 1024, 0, 100);

  bool shouldPush =
      (currentMask != lastMask || abs(currentLdr - lastLdr) > 10 ||
       now - lastUpdate > 20000);
  if (isFirebaseReady && shouldPush) {
    lastMask = currentMask;
    lastLdr = currentLdr;
    lastUpdate = now;
    triggerLedPulse(2);
    for (int i = 0; i < 4; i++) {
      int st = (currentMask & (1 << i)) != 0 ? 1 : 0;
      if (st != lastStates[i]) {
        lastStates[i] = st;
        FirebaseJson z;
        z.set(F("status"), st == 1);
        z.set(F("lightLevel"), currentLdr);
        if (st == 1)
          z.set(F("lastTriggered"), (int)time(NULL));
        String p = F("devices/");
        p += DEVICE_ID;
        p += F("/security/sensors/PIR");
        p += (i + 1);
        Firebase.RTDB.updateNodeAsync(&fbData, p, &z);
      }
    }
    FirebaseJson s;
    s.set(F("online"), true);
    s.set(F("lastSeen"), (int)time(NULL));
    s.set(F("signal"), WiFi.RSSI());
    s.set(F("version"), F("v2.1.0"));
    String p2 = F("devices/");
    p2 += DEVICE_ID;
    p2 += F("/satellite/status");
    Firebase.RTDB.updateNodeAsync(&fbStatus, p2, &s);
  }

  // Force heartbeat every 30s
  if (isFirebaseReady && now - lastForcePush > 30000) {
    lastForcePush = now;
    FirebaseJson s;
    s.set(F("online"), true);
    s.set(F("lastSeen"), (int)time(NULL));
    s.set(F("signal"), WiFi.RSSI());
    String p2 = F("devices/");
    p2 += DEVICE_ID;
    p2 += F("/satellite/status");
    Firebase.RTDB.updateNodeAsync(&fbStatus, p2, &s);
  }
}
