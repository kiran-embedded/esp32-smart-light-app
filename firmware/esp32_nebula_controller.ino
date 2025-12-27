/*
 * NEBULA CORE – COMPLETE SYSTEM (PRO LED PATTERNS)
 * ------------------------------------------------
 * GREEN: Server Heartbeat (Brief blip every 2s) -> System OK
 * RED:   Double-Flash Alert (Blip-Blip... Pause) -> Error/No Internet
 * BLUE:  Instant Flash -> Switch Activity
 * * PINS:
 * Red: 19, Green: 16, Blue: 17
 */

#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include <ESPmDNS.h>
#include <WiFiUdp.h>
#include <ArduinoOTA.h>

#include "addons/TokenHelper.h"
#include "addons/RTDBHelper.h"

/* ================= CONFIGURATION ================= */
// TODO: Replace with your actual WiFi Credentials
#define WIFI_SSID "YOUR_WIFI_SSID"
#define WIFI_PASS "YOUR_WIFI_PASSWORD"

// OTA Credentials
#define OTA_HOSTNAME "Nebula-Core-ESP32"
#define OTA_PASSWORD "YOUR_OTA_PASSWORD"

// TODO: Replace with your actual Firebase Project Credentials
#define API_KEY      "YOUR_FIREBASE_API_KEY"
#define DATABASE_URL "https://your-project-id.firebaseio.com"

/* ================= PIN DEFINITIONS ================= */
// Power Control
#define RELAY1 26
#define RELAY2 27
#define RELAY3 25
#define RELAY4 33
#define VOLTAGE_SENSOR 34

// RGB Status LED (Common Cathode)
#define LED_PIN_RED   19
#define LED_PIN_GREEN 16
#define LED_PIN_BLUE  17

/* ================= AC CALIBRATION ================= */
#define ADC_MAX 4095.0
#define VREF 3.3
float calibrationFactor = 313.3; 

/* ================= RMS & SMOOTHING ================= */
#define P2P_THRESHOLD 60
#define RMS_THRESHOLD 0.020
#define SMOOTHING_ALPHA 0.1 

/* ================= TELEMETRY SETTINGS ================= */
#define REPORT_INTERVAL 10000     // 10 Seconds normal interval
#define VOLTAGE_DELTA 3.0         // 3 Volts change

/* ================= LED TIMING CONFIG ================= */
#define BLINK_FAST    200
#define BLINK_MEDIUM  400
#define BLINK_SLOW    700
#define FLASH_DUR     100

/* ================= OBJECTS & GLOBALS ================= */
FirebaseData fbTele;
FirebaseData fbStream;
FirebaseAuth auth;
FirebaseConfig config;

String deviceId;
bool relayState[4] = {0, 0, 0, 0};
bool updateRelays = false;    // Trigger hardware update
bool forceTelemetry = false;  // Trigger immediate upload

volatile float sharedVoltage = 0.0;

unsigned long lastTelemetryTime = 0;
float lastReportedVoltage = 0;
unsigned long lastStreamKeepAlive = 0;

// LED State Variables
enum SystemState {
  STATE_IDLE,
  STATE_WIFI_CONNECTING,
  STATE_WIFI_CONNECTED,
  STATE_FIREBASE_CONNECTING,
  STATE_FIREBASE_CONNECTED,
  STATE_FIREBASE_DISCONNECTED,
  STATE_OTA_UPDATING 
};

SystemState currentLedState = STATE_IDLE;
unsigned long lastBlinkTime = 0;
bool blinkState = false; 
bool isFlashing = false;
bool isOTAActive = false; 
unsigned long flashStartTime = 0;

/* ================= LED SYSTEM FUNCTIONS ================= */

// Helper: Set RGB Color (One at a time)
void setRGB(bool r, bool g, bool b) {
  digitalWrite(LED_PIN_RED, r);
  digitalWrite(LED_PIN_GREEN, g);
  digitalWrite(LED_PIN_BLUE, b);
}

// Trigger: Call this on user interaction
void triggerActivityLED() {
  if (isOTAActive) return; 
  isFlashing = true;
  flashStartTime = millis();
  // INSTANT BLUE FLASH
  setRGB(LOW, LOW, HIGH); 
}

// Logic: Determine current system status
void updateSystemState() {
  if (isOTAActive) {
    currentLedState = STATE_OTA_UPDATING;
    return;
  }
  
  if (WiFi.status() != WL_CONNECTED) {
    currentLedState = STATE_WIFI_CONNECTING;
  }
  else if (Firebase.ready()) {
    currentLedState = STATE_FIREBASE_CONNECTED;
  } 
  else if (auth.token.uid == "") {
     currentLedState = STATE_FIREBASE_CONNECTING;
  }
  else {
    currentLedState = STATE_FIREBASE_DISCONNECTED;
  }
}

// Logic: Drive the LED based on status
void loopLED() {
  unsigned long currentMillis = millis();
  updateSystemState();

  // 1. OTA Override -> FAST RED STROBE (Warning: Updating)
  if (currentLedState == STATE_OTA_UPDATING) {
    if ((currentMillis % 100) < 50) setRGB(HIGH, LOW, LOW);
    else setRGB(LOW, LOW, LOW);
    return;
  }

  // 2. Activity Flash Override -> SOLID BLUE
  if (isFlashing) {
    if (currentMillis - flashStartTime >= FLASH_DUR) {
      isFlashing = false; 
    } else {
      setRGB(LOW, LOW, HIGH); 
      return; 
    }
  }

  // 3. Base State Animation
  switch (currentLedState) {
    case STATE_WIFI_CONNECTING: // Blue Fast Blink
      if (currentMillis - lastBlinkTime >= BLINK_FAST) {
        lastBlinkTime = currentMillis;
        blinkState = !blinkState;
        setRGB(LOW, LOW, blinkState ? HIGH : LOW);
      }
      break;

    case STATE_FIREBASE_CONNECTING: // Blue Medium Blink
      if (currentMillis - lastBlinkTime >= BLINK_MEDIUM) {
        lastBlinkTime = currentMillis;
        blinkState = !blinkState;
        setRGB(LOW, LOW, blinkState ? HIGH : LOW);
      }
      break;

    case STATE_FIREBASE_CONNECTED: // GREEN HEARTBEAT
      // Blips Green ON for 100ms every 2000ms (System OK)
      if ((currentMillis % 2000) < 100) {
        setRGB(LOW, HIGH, LOW); 
      } else {
        setRGB(LOW, LOW, LOW);  
      }
      break;

    case STATE_FIREBASE_DISCONNECTED: // RED DOUBLE-FLASH ALERT
      // Pattern: Blip (100ms) - Off (100ms) - Blip (100ms) - Off (700ms)
      // Cycle = 1000ms
      {
        unsigned long mod = currentMillis % 1000;
        if (mod < 100 || (mod > 200 && mod < 300)) {
          setRGB(HIGH, LOW, LOW); // Red ON
        } else {
          setRGB(LOW, LOW, LOW);  // Red OFF
        }
      }
      break;

    default: 
      setRGB(LOW, LOW, LOW); // Off
      break;
  }
}

/* ================= HARDWARE CONTROL ================= */
void applyRelays() {
  digitalWrite(RELAY1, relayState[0] ? LOW : HIGH);
  digitalWrite(RELAY2, relayState[1] ? LOW : HIGH);
  digitalWrite(RELAY3, relayState[2] ? LOW : HIGH);
  digitalWrite(RELAY4, relayState[3] ? LOW : HIGH);
}

/* ================= STREAM CALLBACK ================= */
void streamCallback(FirebaseStream data) {
  lastStreamKeepAlive = millis(); 
  String path = data.dataPath();
  Serial.printf("⚡ CMD: %s\n", path.c_str());

  if (path == "/") {
    FirebaseJson *json = data.jsonObjectPtr();
    FirebaseJsonData d;
    if (json->get(d, "relay1")) relayState[0] = d.intValue;
    if (json->get(d, "relay2")) relayState[1] = d.intValue;
    if (json->get(d, "relay3")) relayState[2] = d.intValue;
    if (json->get(d, "relay4")) relayState[3] = d.intValue;
  } 
  else {
    int intVal = data.intData();
    if (path == "/relay1") relayState[0] = intVal;
    if (path == "/relay2") relayState[1] = intVal;
    if (path == "/relay3") relayState[2] = intVal;
    if (path == "/relay4") relayState[3] = intVal;
  }

  // 1. Trigger Hardware Update
  updateRelays = true;
  
  // 2. Trigger IMMEDIATE Telemetry
  forceTelemetry = true; 

  // 3. Trigger LED Flash
  triggerActivityLED();
}

void streamTimeoutCallback(bool timeout) {
  if (timeout) Serial.println("⚠️ Stream Timeout");
}

/* ================= CORE 0: BURST VOLTAGE TASK ================= */
void voltageTask(void * pvParameters) {
  float adcOffset = 0;
  long sum = 0;
  
  // Calibration
  for (int i = 0; i < 500; i++) sum += analogRead(VOLTAGE_SENSOR);
  adcOffset = sum / 500.0;

  float localVoltage = 0;

  for (;;) {
    double rmsSum = 0;
    int rmsCount = 0;
    int rmsMin = 4095;
    int rmsMax = 0;
    
    // Read 40ms Burst
    unsigned long burstStart = millis();
    while (millis() - burstStart < 40) {
      int raw = analogRead(VOLTAGE_SENSOR);
      if (raw < rmsMin) rmsMin = raw;
      if (raw > rmsMax) rmsMax = raw;
      
      float v = (raw - adcOffset) * (VREF / ADC_MAX);
      rmsSum += v * v;
      rmsCount++;
    }

    // Math
    if (rmsCount > 0) {
      int p2p = rmsMax - rmsMin;
      float rms = sqrt(rmsSum / rmsCount);
      float instVoltage = 0.0;

      if (p2p >= P2P_THRESHOLD && rms >= RMS_THRESHOLD) {
        instVoltage = rms * calibrationFactor;
      }
      
      if (localVoltage == 0) localVoltage = instVoltage;
      else localVoltage = (instVoltage * SMOOTHING_ALPHA) + (localVoltage * (1.0 - SMOOTHING_ALPHA));

      if (localVoltage < 5.0) localVoltage = 0.0;
      sharedVoltage = localVoltage;
    }

    // Sleep 100ms
    vTaskDelay(100 / portTICK_PERIOD_MS);
  }
}

/* ================= SETUP ================= */
void setup() {
  Serial.begin(115200);
  
  // Init Power Pins
  pinMode(RELAY1, OUTPUT);
  pinMode(RELAY2, OUTPUT);
  pinMode(RELAY3, OUTPUT);
  pinMode(RELAY4, OUTPUT);
  
  digitalWrite(RELAY1, HIGH);
  digitalWrite(RELAY2, HIGH);
  digitalWrite(RELAY3, HIGH);
  digitalWrite(RELAY4, HIGH);

  // Init LED Pins
  pinMode(LED_PIN_RED, OUTPUT);
  pinMode(LED_PIN_GREEN, OUTPUT);
  pinMode(LED_PIN_BLUE, OUTPUT);

  // LED Test
  setRGB(HIGH, LOW, LOW); delay(200); // R
  setRGB(LOW, HIGH, LOW); delay(200); // G
  setRGB(LOW, LOW, HIGH); delay(200); // B
  setRGB(LOW, LOW, LOW);

  analogReadResolution(12);
  analogSetAttenuation(ADC_11db);

  // --- WIFI CONFIG (AUTO-HEAL) ---
  WiFi.mode(WIFI_STA);
  // Important: Disable WiFi Sleep to ensure stable connection
  WiFi.setSleep(false); 
  WiFi.setAutoReconnect(true); 
  WiFi.persistent(true);       
  WiFi.begin(WIFI_SSID, WIFI_PASS);
  
  Serial.print("Connecting");
  while (WiFi.status() != WL_CONNECTED) {
    loopLED(); 
    delay(100); 
    Serial.print(".");
  }
  Serial.println("\n✅ WiFi Connected");

  deviceId = String((uint32_t)ESP.getEfuseMac(), HEX);

  // --- OTA SETUP ---
  ArduinoOTA.setHostname(OTA_HOSTNAME);
  ArduinoOTA.setPassword(OTA_PASSWORD);
  ArduinoOTA.onStart([]() { isOTAActive = true; setRGB(HIGH, LOW, LOW); }); 
  ArduinoOTA.onEnd([]() { isOTAActive = false; setRGB(LOW, HIGH, LOW); }); 
  ArduinoOTA.begin();

  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;
  config.token_status_callback = tokenStatusCallback;
  
  fbStream.setResponseSize(1024); 

  Firebase.signUp(&config, &auth, "", "");
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);

  if (!Firebase.RTDB.beginStream(&fbStream, ("/devices/" + deviceId + "/commands").c_str())) {
    Serial.printf("❌ Stream Start Failed: %s\n", fbStream.errorReason().c_str());
  } else {
    Serial.println("✅ Stream Listening...");
  }
  
  Firebase.RTDB.setStreamCallback(&fbStream, streamCallback, streamTimeoutCallback);

  xTaskCreatePinnedToCore(voltageTask, "VoltageTask", 10000, NULL, 1, NULL, 0);
  
  lastStreamKeepAlive = millis();
}

/* ================= LOOP (CORE 1) ================= */
void loop() {
  ArduinoOTA.handle();
  loopLED();

  if (updateRelays) {
    applyRelays();
    updateRelays = false;
  }

  // WATCHDOG & AUTO-HEALING
  static unsigned long lastCheck = 0;
  if (millis() - lastCheck > 20000) { 
    lastCheck = millis();

    // 1. Efficient WiFi Reconnection (Modem Off/On Handling)
    if (WiFi.status() != WL_CONNECTED) {
      Serial.println("⚠️ WiFi Lost. Initiating fresh connection...");
      // Explicitly disconnect to clear any stale state
      WiFi.disconnect();
      // Force a completely fresh connection attempt
      WiFi.begin(WIFI_SSID, WIFI_PASS); 
    }
    // 2. Firebase Reconnect
    else if (!Firebase.ready()) {
       Serial.println("⚠️ Firebase Disconnected. Retrying...");
    }
  }

  // TELEMETRY
  static unsigned long lastTeleCheck = 0;
  if (millis() - lastTeleCheck > 100) {
    lastTeleCheck = millis();

    float currentV = sharedVoltage;
    bool timeExpired = (millis() - lastTelemetryTime > REPORT_INTERVAL);
    bool significantChange = (abs(currentV - lastReportedVoltage) > VOLTAGE_DELTA);

    if (forceTelemetry || timeExpired || significantChange) {
      if (Firebase.ready()) {
        FirebaseJson j;
        j.set("relay1", relayState[0]);
        j.set("relay2", relayState[1]);
        j.set("relay3", relayState[2]);
        j.set("relay4", relayState[3]);
        j.set("voltage", currentV);
        
        forceTelemetry = false;

        if (Firebase.RTDB.updateNode(&fbTele, ("/devices/" + deviceId + "/telemetry").c_str(), &j)) {
          Serial.printf("📤 Telemetry Sent (V: %.1f)\n", currentV);
          lastTelemetryTime = millis();
          lastReportedVoltage = currentV;
        }
      }
    }
  }
  
  delay(5);
}
