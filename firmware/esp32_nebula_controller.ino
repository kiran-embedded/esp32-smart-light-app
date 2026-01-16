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

// Activity Flash Variables
bool isActivityFlashing = false;
unsigned long activityStart = 0;
const int FLASH_DURATION = 80; // Increased to 80ms for better visibility

/* ================= LED ENGINE (STRICT SINGLE-COLOR) ================= */

void initLEDs() {
  // Pure Digital Output - No PWM
  pinMode(LED_PIN_RED, OUTPUT);
  pinMode(LED_PIN_GREEN, OUTPUT);
  pinMode(LED_PIN_BLUE, OUTPUT);

  // Start OFF
  digitalWrite(LED_PIN_RED, LOW);
  digitalWrite(LED_PIN_GREEN, LOW);
  digitalWrite(LED_PIN_BLUE, LOW);
}

// Trigger: Call this to simulate a data packet flash
void triggerActivityLED() {
  isActivityFlashing = true;
  activityStart = millis();
}

// Main Animation Loop - Strict One-Hot Logic
void animateLEDs() {
  unsigned long now = millis();

  // COLOR ID DEFINITIONS:
  // 0 = OFF
  // 1 = RED
  // 2 = GREEN
  // 3 = BLUE
  int targetColor = 0;

  // --- PHASE 1: LOGIC DECISION ---

  // PRIORITY 1: OTA UPDATE (Highest)
  if (isOTAActive) {
    // Strobe between RED (1) and BLUE (3) every 100ms
    targetColor = ((now / 100) % 2 == 0) ? 1 : 3;
  }

  // PRIORITY 2: DATA ACTIVITY (Overrides Status)
  else if (isActivityFlashing) {
    if (now - activityStart < FLASH_DURATION) {
      targetColor = 3; // Force BLUE
    } else {
      isActivityFlashing = false;
    }
  }

  // PRIORITY 3: SYSTEM STATUS (Run only if no override active)
  if (targetColor == 0 && !isActivityFlashing && !isOTAActive) {

    // 3a. Determine System State
    if (WiFi.status() != WL_CONNECTED) {
      currentSystemState = STATE_NO_WIFI;
      // We don't set isInternetLive here, the task handles it
    }
    // Check global flag set by the Connectivity Task
    else if (!isInternetLive) {
      currentSystemState = STATE_NO_INTERNET;
    } else {
      currentSystemState = STATE_OK;
    }

    // 3b. Select Color based on State Pattern
    switch (currentSystemState) {
    case STATE_NO_WIFI:
      // Red Slow Blink (500ms ON / 500ms OFF) - Searching for Modem
      if ((now / 500) % 2 == 0)
        targetColor = 1;
      break;

    case STATE_NO_INTERNET:
      // Red Triple Flash (Route Error)
      // Modified for higher visibility (Option A)
      // Flash (250ms) - Gap (150ms) - Flash (250ms) - Gap (150ms) - Flash
      // (250ms) - Long Pause
      {
        unsigned long cycle = now % 1500;
        if (cycle < 250)
          targetColor = 1;
        else if (cycle > 400 && cycle < 650)
          targetColor = 1;
        else if (cycle > 800 && cycle < 1050)
          targetColor = 1;
      }
      break;

    case STATE_OK:
      // Green Heartbeat (Blip-Blip... Pause)
      {
        unsigned long cycle = now % 2500;
        if (cycle < 80)
          targetColor = 2;
        else if (cycle > 250 && cycle < 330)
          targetColor = 2;
      }
      break;

    default:
      break;
    }
  }

  // --- PHASE 2: HARDWARE EXECUTION ---
  digitalWrite(LED_PIN_RED, (targetColor == 1) ? HIGH : LOW);
  digitalWrite(LED_PIN_GREEN, (targetColor == 2) ? HIGH : LOW);
  digitalWrite(LED_PIN_BLUE, (targetColor == 3) ? HIGH : LOW);
}

/* ================= BACKGROUND TASKS ================= */

// TASK: Connectivity Checker (OPTIMIZED)
// Advisory + Lazy: Only pings heavily when system is suspected DOWN.
// When UP, it relies on Telemetry success to stay asleep.
void connectivityTask(void *pvParameters) {
  for (;;) {
    int delayTime = 8000; // Updated to 8s (faster detection) per user request

    if (WiFi.status() != WL_CONNECTED) {
      isInternetLive = false;
      delayTime = 1000; // Check often if WiFi is disconnected
    }
    // Only perform heavy TCP Ping if we suspect Internet is DOWN
    else if (!isInternetLive) {
      WiFiClient client;
      client.setTimeout(1500); // 1.5s timeout is plenty for 8.8.8.8

      if (client.connect("8.8.8.8", 53)) {
        isInternetLive = true;
        client.stop();
      } else {
        // Still broken? Check again soon.
        delayTime = 3000;
      }
    }
    // If isInternetLive is TRUE, we skip the ping and sleep for 8s (was 15s).
    // We trust the main loop (Telemetry) to set isInternetLive=false if it
    // fails.

    vTaskDelay(delayTime / portTICK_PERIOD_MS);
  }
}

// TASK: Voltage Sensor
// Runs continuously to sample AC voltage
void voltageTask(void *pvParameters) {
  float adcOffset = 0;
  long sum = 0;
  // Calibration
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
  digitalWrite(RELAY1, relayState[0] ? LOW : HIGH);
  digitalWrite(RELAY2, relayState[1] ? LOW : HIGH);
  digitalWrite(RELAY3, relayState[2] ? LOW : HIGH);
  digitalWrite(RELAY4, relayState[3] ? LOW : HIGH);
}

/* ================= STREAM CALLBACK ================= */
void streamCallback(FirebaseStream data) {
  lastStreamKeepAlive = millis();

  // If we receive data, the link is definitely alive
  isInternetLive = true;

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
    // Stream failed -> Suspect Internet Down
    isInternetLive = false;
  }
}

/* ================= LOCAL WEB SERVER HANDLERS ================= */
void handleStatus() {
  // Return JSON status for app discovery and state polling
  String json = "{";
  json += "\"deviceId\":\"" + deviceId + "\",";
  json += "\"voltage\":" + String(sharedVoltage, 1) + ",";
  json += "\"relay1\":" + String(relayState[0] ? 1 : 0) + ",";
  json += "\"relay2\":" + String(relayState[1] ? 1 : 0) + ",";
  json += "\"relay3\":" + String(relayState[2] ? 1 : 0) + ",";
  json += "\"relay4\":" + String(relayState[3] ? 1 : 0);
  json += "}";
  server.send(200, "application/json", json);
}

void handleSet() {
  if (server.hasArg("relay") && server.hasArg("state")) {
    int r = server.arg("relay").toInt();
    int s = server.arg("state").toInt(); // 1 = ON, 0 = OFF (from app)

    if (r >= 1 && r <= 4) {
      relayState[r - 1] = (s == 1);

      updateRelays = true;
      forceTelemetry = true; // Sync to cloud if possible
      triggerActivityLED();

      server.send(200, "text/plain", "OK");
    } else {
      server.send(400, "text/plain", "Invalid Relay");
    }
  } else {
    server.send(400, "text/plain", "Missing args");
  }
}

/* ================= SETUP ================= */
void setup() {
  Serial.begin(115200);

  pinMode(RELAY1, OUTPUT);
  pinMode(RELAY2, OUTPUT);
  pinMode(RELAY3, OUTPUT);
  pinMode(RELAY4, OUTPUT);

  digitalWrite(RELAY1, HIGH);
  digitalWrite(RELAY2, HIGH);
  digitalWrite(RELAY3, HIGH);
  digitalWrite(RELAY4, HIGH);

  initLEDs();

  analogReadResolution(12);
  analogSetAttenuation(ADC_11db);

  // --- WIFI CONFIG ---
  WiFi.mode(WIFI_STA);
  WiFi.setAutoReconnect(true);
  WiFi.persistent(true);
  WiFi.begin(WIFI_SSID, WIFI_PASS);

  Serial.print("Connecting to WiFi");

  unsigned long startAttempt = millis();
  while (WiFi.status() != WL_CONNECTED) {
    animateLEDs(); // Visual feedback: Error Blink
    if (millis() - startAttempt > 20000)
      break;
    delay(10);
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n✅ WiFi Connected");
    // Start Optimized Connectivity Checker (Reduced Stack: 2048)
    xTaskCreatePinnedToCore(connectivityTask, "ConnTask", 2048, NULL, 1, NULL,
                            0);
    triggerActivityLED();
  } else {
    Serial.println("\n❌ WiFi Failed (Offline Mode)");
    isInternetLive = false;
  }

  deviceId = String((uint32_t)ESP.getEfuseMac(), HEX);

  // --- OTA SETUP ---
  ArduinoOTA.setHostname(OTA_HOSTNAME);
  ArduinoOTA.setPassword(OTA_PASSWORD);
  ArduinoOTA.onStart([]() { isOTAActive = true; });
  ArduinoOTA.onEnd([]() {
    isOTAActive = false;
    triggerActivityLED();
  });
  ArduinoOTA.begin();

  // --- LOCAL MODE SETUP (WebServer & mDNS) ---
  server.on("/status", handleStatus);
  server.on("/set", handleSet);
  server.begin();
  MDNS.addService("nebula", "tcp", 80); // Advertise for app discovery
  Serial.println("Local Server Started");

  // --- FIREBASE SETUP ---
  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;
  config.token_status_callback = tokenStatusCallback;

  fbStream.setResponseSize(1024);

  Firebase.signUp(&config, &auth, "", "");
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);

  if (!Firebase.RTDB.beginStream(
          &fbStream, ("/devices/" + deviceId + "/commands").c_str())) {
    Serial.printf("❌ Stream Start Failed: %s\n",
                  fbStream.errorReason().c_str());
  }

  Firebase.RTDB.setStreamCallback(&fbStream, streamCallback,
                                  streamTimeoutCallback);

  xTaskCreatePinnedToCore(voltageTask, "VoltageTask", 10000, NULL, 1, NULL, 0);
  lastStreamKeepAlive = millis();
}

/* ================= LOOP (CORE 1) ================= */
void loop() {
  animateLEDs();
  ArduinoOTA.handle();
  server.handleClient(); // Handle Local Requests

  if (updateRelays) {
    applyRelays();
    updateRelays = false;
  }

  // OPTIMIZED WATCHDOG (AUTO-HEAL)
  static unsigned long lastWiFiCheck = 0;
  if (millis() - lastWiFiCheck > 20000) {
    lastWiFiCheck = millis();

    if (WiFi.status() != WL_CONNECTED) {
      Serial.println("⚠️ WiFi Lost. Performing clean reconnect...");
      WiFi.disconnect();
      WiFi.begin(WIFI_SSID, WIFI_PASS);
    }
  }

  // Telemetry
  static unsigned long lastTeleCheck = 0;
  if (millis() - lastTeleCheck > 100) {
    lastTeleCheck = millis();

    float currentV = sharedVoltage;
    bool timeExpired = (millis() - lastTelemetryTime > REPORT_INTERVAL);
    bool significantChange =
        (abs(currentV - lastReportedVoltage) > VOLTAGE_DELTA);

    if (forceTelemetry || timeExpired || significantChange) {
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
          isInternetLive = true; // Confirm live on successful upload
        } else {
          // Upload Failed -> Suspect Internet Down -> Trigger Connectivity Task
          isInternetLive = false;
        }
      }
    }
  }

  delay(5);
}
