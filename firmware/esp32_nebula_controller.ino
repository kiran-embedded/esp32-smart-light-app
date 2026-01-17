/*
 * NEBULA CORE – COMPLETE SYSTEM (SERVER RACK EDITION)
 * ------------------------------------------------
 * STATUS LED LOGIC (STRICT ONE-HOT COLOR MODE):
 * ------------------------------------------------
 * This engine uses a single active-color variable to ensure
 * it is PHYSICALLY IMPOSSIBLE for two colors to mix.
 *
 * * * HARDWARE PINS:
 * Red: 19, Green: 16, Blue: 17
 * Relays: 26, 27, 25, 33
 */

#include <ArduinoOTA.h>
#include <ESPmDNS.h>
#include <Firebase_ESP_Client.h>
#include <WiFi.h>
#include <WiFiUdp.h>

#include "addons/RTDBHelper.h"
#include "addons/TokenHelper.h"

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
// Power Control
#define RELAY1 26
#define RELAY2 27
#define RELAY3 25
#define RELAY4 33
#define VOLTAGE_SENSOR 34

// RGB Status LED (Common Cathode - Active HIGH)
#define LED_PIN_RED 19
#define LED_PIN_GREEN 16
#define LED_PIN_BLUE 17

/* ================= AC CALIBRATION ================= */
#define ADC_MAX 4095.0
#define VREF 3.3
float calibrationFactor = 313.3;

/* ================= RMS & SMOOTHING ================= */
#define P2P_THRESHOLD 60
#define RMS_THRESHOLD 0.020
#define SMOOTHING_ALPHA 0.1

/* ================= TELEMETRY SETTINGS ================= */
#define REPORT_INTERVAL 10000 // 10 Seconds normal interval
#define VOLTAGE_DELTA 3.0     // 3 Volts change

/* ================= OBJECTS & GLOBALS ================= */
FirebaseData fbTele;
FirebaseData fbStream;
FirebaseAuth auth;
FirebaseConfig config;

String deviceId;
bool relayState[4] = {0, 0, 0, 0};
bool updateRelays = false;
bool forceTelemetry = false;

volatile float sharedVoltage = 0.0;
unsigned long lastTelemetryTime = 0;
float lastReportedVoltage = 0;
unsigned long lastStreamKeepAlive = 0;

// Network Health Flag
volatile bool isInternetLive = false;

// LED System Variables
enum SystemState {
  STATE_BOOTING,
  STATE_NO_WIFI,
  STATE_NO_INTERNET,
  STATE_OK,
  STATE_OTA
};

SystemState currentSystemState = STATE_BOOTING;
bool isOTAActive = false;

// Activity Flash Variables
bool isActivityFlashing = false;
unsigned long activityStart = 0;
const int FLASH_DURATION = 80;

// --- DEADMAN SAFETY VARIABLES ---
bool safetyTripped = false;
unsigned long lastActivity = 0;

/* ================= LED ENGINE (STRICT SINGLE-COLOR) ================= */

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
  int targetColor = 0;

  if (isOTAActive) {
    targetColor = ((now / 100) % 2 == 0) ? 1 : 3;
  } else if (isActivityFlashing) {
    if (now - activityStart < FLASH_DURATION) {
      targetColor = 3;
    } else {
      isActivityFlashing = false;
    }
  }

  if (targetColor == 0 && !isActivityFlashing && !isOTAActive) {
    if (WiFi.status() != WL_CONNECTED) {
      currentSystemState = STATE_NO_WIFI;
    } else if (!isInternetLive) {
      currentSystemState = STATE_NO_INTERNET;
    } else {
      currentSystemState = STATE_OK;
    }

    switch (currentSystemState) {
    case STATE_NO_WIFI:
      if ((now / 500) % 2 == 0)
        targetColor = 1;
      break;

    case STATE_NO_INTERNET: {
      unsigned long cycle = now % 1500;
      if (cycle < 250)
        targetColor = 1;
      else if (cycle > 400 && cycle < 650)
        targetColor = 1;
      else if (cycle > 800 && cycle < 1050)
        targetColor = 1;
    } break;

    case STATE_OK: {
      unsigned long cycle = now % 2500;
      if (cycle < 80)
        targetColor = 2; // Green heartbeat
      else if (cycle > 250 && cycle < 330)
        targetColor = 2;
    } break;

    default:
      break;
    }
  }

  digitalWrite(LED_PIN_RED, (targetColor == 1) ? HIGH : LOW);
  digitalWrite(LED_PIN_GREEN, (targetColor == 2) ? HIGH : LOW);
  digitalWrite(LED_PIN_BLUE, (targetColor == 3) ? HIGH : LOW);
}

/* ================= BACKGROUND TASKS ================= */

void connectivityTask(void *pvParameters) {
  for (;;) {
    int delayTime = 8000;
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
    vTaskDelay(100 / portTICK_PERIOD_MS);
  }
}

/* ================= HARDWARE CONTROL ================= */
void applyRelays() {
  digitalWrite(RELAY1, relayState[0] ? HIGH : LOW);
  digitalWrite(RELAY2, relayState[1] ? HIGH : LOW);
  digitalWrite(RELAY3, relayState[2] ? HIGH : LOW);
  digitalWrite(RELAY4, relayState[3] ? HIGH : LOW);
  lastActivity = millis(); // Reset safety timer on hardware change
}

/* ================= STREAM CALLBACK ================= */
void streamCallback(FirebaseStream data) {
  isInternetLive = true;
  String path = data.dataPath();

  if (path == "/") {
    FirebaseJson *json = data.jsonObjectPtr();
    FirebaseJsonData d;
    if (json->get(d, "relay1"))
      relayState[0] = d.intValue;
    if (json->get(d, "relay2"))
      relayState[1] = d.intValue;
    if (json->get(d, "relay3"))
      relayState[2] = d.intValue;
    if (json->get(d, "relay4"))
      relayState[3] = d.intValue;
  } else {
    int intVal = data.intData();
    if (path == "/relay1")
      relayState[0] = intVal;
    if (path == "/relay2")
      relayState[1] = intVal;
    if (path == "/relay3")
      relayState[2] = intVal;
    if (path == "/relay4")
      relayState[3] = intVal;
  }

  updateRelays = true;
  forceTelemetry = true;
  triggerActivityLED();
}

void streamTimeoutCallback(bool timeout) {
  if (timeout)
    isInternetLive = false;
}

/* ================= SETUP ================= */
void setup() {
  Serial.begin(115200);

  pinMode(RELAY1, OUTPUT);
  pinMode(RELAY2, OUTPUT);
  pinMode(RELAY3, OUTPUT);
  pinMode(RELAY4, OUTPUT);

  digitalWrite(RELAY1, LOW);
  digitalWrite(RELAY2, LOW);
  digitalWrite(RELAY3, LOW);
  digitalWrite(RELAY4, LOW);

  initLEDs();

  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASS);

  unsigned long startAttempt = millis();
  while (WiFi.status() != WL_CONNECTED) {
    animateLEDs();
    if (millis() - startAttempt > 20000)
      break;
    delay(10);
  }

  deviceId = String((uint32_t)ESP.getEfuseMac(), HEX);

  ArduinoOTA.setHostname(OTA_HOSTNAME);
  ArduinoOTA.setPassword(OTA_PASSWORD);
  ArduinoOTA.onStart([]() { isOTAActive = true; });
  ArduinoOTA.onEnd([]() { isOTAActive = false; });
  ArduinoOTA.begin();

  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);

  Firebase.RTDB.beginStream(&fbStream,
                            ("/devices/" + deviceId + "/commands").c_str());
  Firebase.RTDB.setStreamCallback(&fbStream, streamCallback,
                                  streamTimeoutCallback);

  xTaskCreatePinnedToCore(connectivityTask, "ConnTask", 2048, NULL, 1, NULL, 0);
  xTaskCreatePinnedToCore(voltageTask, "VoltageTask", 10000, NULL, 1, NULL, 0);

  lastActivity = millis();
}

/* ================= LOOP ================= */
void loop() {
  animateLEDs();
  ArduinoOTA.handle();

  if (updateRelays) {
    applyRelays();
    updateRelays = false;
  }

  // Telemetry Loop
  if (forceTelemetry || (millis() - lastTelemetryTime > REPORT_INTERVAL)) {
    if (Firebase.ready()) {
      FirebaseJson j;
      j.set("relay1", relayState[0]);
      j.set("relay2", relayState[1]);
      j.set("relay3", relayState[2]);
      j.set("relay4", relayState[3]);
      j.set("voltage", sharedVoltage);
      if (Firebase.RTDB.updateNode(
              &fbTele, ("/devices/" + deviceId + "/telemetry").c_str(), &j)) {
        lastTelemetryTime = millis();
        forceTelemetry = false;
      }
    }
  }

  // --- DEADMAN SAFETY ENGINE ---
  if (!isInternetLive && (millis() - lastActivity > 60000)) {
    if (!safetyTripped) {
      Serial.println("⛔ SAFETY TRIP: System Offline. Powering OFF.");
      for (int i = 0; i < 4; i++)
        relayState[i] = false;
      updateRelays = true;
      safetyTripped = true;
    }
  } else {
    safetyTripped = false;
  }

  delay(5);
}
