/*
 * NEBULA CORE – COMPLETE SYSTEM (SERVER RACK EDITION)
 * ------------------------------------------------
 * STATUS LED LOGIC (STRICT ONE-HOT COLOR MODE):
 * ------------------------------------------------
 * This engine uses a single active-color variable to ensure
 * it is PHYSICALLY IMPOSSIBLE for two colors to mix.
 * * OPTIMIZATION UPDATE:
 * 1. Connectivity Task is now LAZY (Only pings when suspected down).
 * 2. Reduced Task Stack Size (2048 bytes).
 * 3. Dynamic polling interval (3s when broken, 8s when healthy).
 * * * PRIORITY 1: OTA Update (Red/Blue Strobe).
 * PRIORITY 2: Data Flash (Blue) -> Overrides Status.
 * PRIORITY 3: Status (Green/Red) -> Background State.
 * * * HARDWARE PINS:
 * Red: 19, Green: 16, Blue: 17
 */

#include <ArduinoOTA.h>
#include <ESPmDNS.h>
#include <Firebase_ESP_Client.h>
#include <WebServer.h> // Local Mode
#include <WiFi.h>
#include <WiFiUdp.h>

#include "addons/RTDBHelper.h"
#include "addons/TokenHelper.h"

/* ================= CONFIGURATION ================= */
#define WIFI_SSID "YOUR_WIFI_SSID"
#define WIFI_PASS "YOUR_WIFI_PASSWORD"

// OTA Credentials
#define OTA_HOSTNAME "Nebula-Core-ESP32"
#define OTA_PASSWORD "YOUR_OTA_PASSWORD"

#define API_KEY "YOUR_FIREBASE_API_KEY"
#define DATABASE_URL "https://YOUR_PROJECT_ID-default-rtdb.firebasedatabase.app"

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
WebServer server(80); // Local Web Server

String deviceId;
bool relayState[4] = {0, 0, 0, 0};
bool updateRelays = false;
bool forceTelemetry = false;

volatile float sharedVoltage = 0.0;
unsigned long lastTelemetryTime = 0;
float lastReportedVoltage = 0;
unsigned long lastStreamKeepAlive = 0;

// Network Health Flag (Optimistic init, updated by connectivityTask)
volatile bool isInternetLive = false;

// LED System Variables
enum SystemState {
  STATE_BOOTING,
  STATE_NO_WIFI,     // Modem Off / Connection Lost
  STATE_NO_INTERNET, // WiFi Connected but No Route/Server
  STATE_OK,          // Everything Perfect
  STATE_OTA          // Firmware Update
};

SystemState currentSystemState = STATE_BOOTING;
bool isOTAActive = false;

// Mode Management
enum OperationMode { MODE_LOCAL, MODE_CLOUD };
OperationMode currentMode = MODE_LOCAL; // Default to LOCAL

// Activity Flash Variables
bool isActivityFlashing = false;
unsigned long activityStart = 0;
const int FLASH_DURATION = 80;

// --- DEADMAN SAFETY VARIABLES ---
bool safetyTripped = false;
bool cloudSuspended = false;
unsigned long lastLocalActivity = 0;

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

      // DUAL COLOR LOGIC
      // CLOUD MODE = GREEN HEARTBEAT
      if (currentMode == MODE_CLOUD) {
        if (cycle < 80)
          targetColor = 2; // Green
        else if (cycle > 250 && cycle < 330)
          targetColor = 2; // Green
      }
      // LOCAL MODE = BLUE DOUBLE BLINK
      else {
        if (cycle < 80)
          targetColor = 3; // Blue
        else if (cycle > 250 && cycle < 330)
          targetColor = 3; // Blue
      }
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
  Serial.printf("Relay Command: %d %d %d %d\n", relayState[0], relayState[1],
                relayState[2], relayState[3]);
  digitalWrite(RELAY1, relayState[0] ? HIGH : LOW);
  digitalWrite(RELAY2, relayState[1] ? HIGH : LOW);
  digitalWrite(RELAY3, relayState[2] ? HIGH : LOW);
  digitalWrite(RELAY4, relayState[3] ? HIGH : LOW);
}

/* ================= STREAM CALLBACK ================= */
void streamCallback(FirebaseStream data) {
  lastStreamKeepAlive = millis();
  isInternetLive = true;

  // STRICT MODE: Ignore Cloud commands if in LOCAL mode
  // STRICT MODE: Ignore Firebase commands if in LOCAL mode
  if (currentMode == MODE_LOCAL) {
    return;
  }

  String path = data.dataPath();
  Serial.printf("⚡ CMD: %s\n", path.c_str());

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
  if (timeout) {
    Serial.println("⚠️ Stream Timeout");
    isInternetLive = false;
  }
}

/* ================= LOCAL WEB SERVER HANDLERS ================= */
void handleStatus() {
  String modeStr = (currentMode == MODE_CLOUD) ? "CLOUD" : "LOCAL";
  String json = "{";
  json += "\"deviceId\":\"" + deviceId + "\",";
  json += "\"mode\":\"" + modeStr + "\",";
  json += "\"voltage\":" + String(sharedVoltage, 1) + ",";
  json += "\"relay1\":" + String(relayState[0] ? 1 : 0) + ",";
  json += "\"relay2\":" + String(relayState[1] ? 1 : 0) + ",";
  json += "\"relay3\":" + String(relayState[2] ? 1 : 0) + ",";
  json += "\"relay4\":" + String(relayState[3] ? 1 : 0);
  json += "}";
  server.send(200, "application/json", json);
}

void handleMode() {
  if (server.hasArg("value")) {
    String val = server.arg("value");
    if (val == "CLOUD") {
      currentMode = MODE_CLOUD;
      // Force immediate telemetry push when entering Cloud mode
      forceTelemetry = true;
    } else if (val == "LOCAL") {
      currentMode = MODE_LOCAL;
      // Firebase REMAIN ACTIVE (Safe Mode)
    }
    server.send(200, "text/plain",
                (currentMode == MODE_CLOUD) ? "CLOUD" : "LOCAL");
    triggerActivityLED();
  } else {
    server.send(400, "text/plain", "Missing value");
  }
}

void handleRelay() {
  if (server.hasArg("ch") && server.hasArg("state")) {
    int r = server.arg("ch").toInt();
    int s = server.arg("state").toInt();

    // STRICT MODE: Only accept Local commands when in LOCAL mode
    if (currentMode != MODE_LOCAL) {
      server.send(403, "text/plain", "Mode is CLOUD - Ignoring local");
      return;
    }

    if (r >= 1 && r <= 4) {
      relayState[r - 1] = (s == 1);

      // Update activity timestamp for Deadman Safety
      lastLocalActivity = millis();

      applyRelays(); // ✅ INSTANT TRIGGER - No waiting for loop
      forceTelemetry = true;
      triggerActivityLED();

      server.send(200, "text/plain", "OK");
    } else {
      server.send(400, "text/plain", "Invalid Relay");
    }
  } else {
    server.send(400, "text/plain", "Missing args");
  }
}

/* ================= LOCAL SERVER TASK (CORE 0) ================= */
void localServerTask(void *pvParameters) {
  for (;;) {
    server.handleClient();
    vTaskDelay(1 / portTICK_PERIOD_MS);
  }
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
  applyRelays();

  initLEDs();

  analogReadResolution(12);
  analogSetAttenuation(ADC_11db);

  WiFi.mode(WIFI_STA);
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
    xTaskCreatePinnedToCore(connectivityTask, "ConnTask", 2048, NULL, 1, NULL,
                            0);
    triggerActivityLED();
  }

  deviceId = String((uint32_t)ESP.getEfuseMac(), HEX);

  ArduinoOTA.setHostname(OTA_HOSTNAME);
  ArduinoOTA.setPassword(OTA_PASSWORD);
  ArduinoOTA.onStart([]() { isOTAActive = true; });
  ArduinoOTA.onEnd([]() {
    isOTAActive = false;
    triggerActivityLED();
  });
  ArduinoOTA.begin();

  server.on("/status", handleStatus);
  server.on("/relay", handleRelay);
  server.on("/mode", handleMode);
  server.begin();
  MDNS.addService("nebula", "tcp", 80);

  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;
  config.token_status_callback = tokenStatusCallback;
  fbStream.setResponseSize(1024);
  Firebase.signUp(&config, &auth, "", "");
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);

  Firebase.RTDB.beginStream(&fbStream,
                            ("/devices/" + deviceId + "/commands").c_str());
  Firebase.RTDB.setStreamCallback(&fbStream, streamCallback,
                                  streamTimeoutCallback);

  xTaskCreatePinnedToCore(voltageTask, "VoltageTask", 10000, NULL, 1, NULL, 0);
  xTaskCreatePinnedToCore(localServerTask, "ServerTask", 4096, NULL, 3, NULL,
                          0);

  lastStreamKeepAlive = millis();
}

/* ================= LOOP (CORE 1) ================= */
/* ================= LOOP (CORE 1) ================= */
void loop() {
  animateLEDs(); // Back to every loop (Safe)
  ArduinoOTA.handle();

  if (updateRelays) {
    applyRelays();
    updateRelays = false;
  }

  static unsigned long lastWiFiCheck = 0;
  if (millis() - lastWiFiCheck > 20000) {
    lastWiFiCheck = millis();
    if (WiFi.status() != WL_CONNECTED) {
      WiFi.disconnect();
      WiFi.begin(WIFI_SSID, WIFI_PASS);
    }
  }

  static unsigned long lastTeleCheck = 0;
  if (millis() - lastTeleCheck > 100) {
    lastTeleCheck = millis();
    float currentV = sharedVoltage;
    bool timeExpired = (millis() - lastTelemetryTime > REPORT_INTERVAL);
    bool significantChange =
        (abs(currentV - lastReportedVoltage) > VOLTAGE_DELTA);

    // STRICT MODE: Only send telemetry if in CLOUD mode
    if ((forceTelemetry || timeExpired || significantChange) &&
        (currentMode == MODE_CLOUD)) {
      if (Firebase.ready()) {
        FirebaseJson j;
        j.set("relay1", relayState[0]);
        j.set("relay2", relayState[1]);
        j.set("relay3", relayState[2]);
        j.set("relay4", relayState[3]);
        j.set("voltage", currentV);
        forceTelemetry = false;

        if (Firebase.RTDB.updateNode(
                &fbTele, ("/devices/" + deviceId + "/telemetry").c_str(), &j)) {
          lastTelemetryTime = millis();
          lastReportedVoltage = currentV;
          isInternetLive = true;
        } else {
          isInternetLive = false;
        }
      }
    }
  }

  // --- HIGH-END SAFETY ENGINE (DEADMAN SWITCH) ---
  // Conditions: (Internet Down AND Firebase Down) AND (No Local Activity for
  // 60s)
  bool isLocalActive = (millis() - lastLocalActivity < 60000);

  // Back to simple check (Safe)
  bool isCloudActive = (!cloudSuspended && isInternetLive);

  if (!isCloudActive && !isLocalActive) {
    if (!safetyTripped) {
      Serial.println("⛔ SAFETY TRIP: Total Isolation Detected. Powering OFF.");
      relayState[0] = false;
      relayState[1] = false;
      relayState[2] = false;
      relayState[3] = false;
      updateRelays = true;
      safetyTripped = true;
    }
  } else {
    safetyTripped = false;
  }

  delay(5); // Back to simple delay (Safe)
}
