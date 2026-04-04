/*
 * NEBULA CORE – COMPLETE SYSTEM (CLOUD-ONLY EDITION)
 * VERSION: v1.3.0
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
#include <esp_now.h>

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
#define RELAY1 26
#define RELAY2 27
#define RELAY3 25
#define RELAY4 33
#define RELAY5 32
#define RELAY6 14
#define VOLTAGE_SENSOR 34
#define PIR_PIN 13    // PIR Motion Sensor input
#define BUZZER_PIN 12 // Piezo Buzzer for Alerts

#define LED_PIN_RED 19
#define LED_PIN_GREEN 16
#define LED_PIN_BLUE 17

/* ================= AC CALIBRATION ================= */
#define ADC_MAX 4095.0
#define VREF 3.3
float calibrationFactor = 313.3;

#define P2P_THRESHOLD 60
#define RMS_THRESHOLD 0.020
#define SMOOTHING_ALPHA 0.1

/* ================= DYNAMIC MODES ================= */
bool isEcoMode = false;
int reportInterval = 8000; // Default 8s

/* ================= GLOBALS ================= */
FirebaseData fbTele;
FirebaseData fbStream;
FirebaseAuth auth;
FirebaseConfig config;

String deviceId = "79215788";
bool relayState[6] = {0, 0, 0, 0, 0, 0};
bool updateRelays = false;
bool forceTelemetry = false;

volatile float sharedVoltage = 0.0;
unsigned long lastTelemetryTime = 0;
float lastReportedVoltage = 0;
unsigned long lastPIRTrigger = 0;
const int PIR_COOLDOWN = 5000; // 5 second cooldown
bool lastPIRState = false;
bool isArmed = true; // Security system state (Cloud controlled)

volatile bool isInternetLive = false;
bool isOTAActive = false;
bool isActivityFlashing = false;
unsigned long activityStart = 0;

// --- DEADMAN SAFETY VARIABLES ---
bool safetyTripped = false;
unsigned long lastCloudActivity = 0;
#define DEADMAN_TIMEOUT_MS 120000 // 2 minutes without cloud comms trips safety

/* ================= MESH STRUCTURE ================= */
typedef struct struct_message {
  char sensorId[16];
  bool motion;
  int lightLevel;
} struct_message;

struct_message incomingData;
volatile bool meshDataPending = false;

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
        targetColor = 1; // Red Blink
    } else {
      // Green Heartbeat
      unsigned long cycle = now % (isEcoMode ? 4000 : 2000); // Slower in Eco
      if (cycle < 80)
        targetColor = 2;
      else if (cycle > 250 && cycle < 330)
        targetColor = 2;
    }
  }

  digitalWrite(LED_PIN_RED, (targetColor == 1) ? HIGH : LOW);
  digitalWrite(LED_PIN_GREEN, (targetColor == 2) ? HIGH : LOW);
  digitalWrite(LED_PIN_BLUE, (targetColor == 3) ? HIGH : LOW);
}

/* ================= BACKGROUND TASKS ================= */
void connectivityTask(void *pvParameters) {
  for (;;) {
    int delayTime = isEcoMode ? 15000 : 8000;

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
    // eco mode delays
    vTaskDelay((isEcoMode ? 200 : 100) / portTICK_PERIOD_MS);
  }
}

/* ================= HARDWARE CONTROL ================= */
void applyRelays() {
  Serial.printf("Relay CMD: %d %d %d %d %d %d\n", relayState[0], relayState[1],
                relayState[2], relayState[3], relayState[4], relayState[5]);
  digitalWrite(RELAY1, relayState[0] ? HIGH : LOW);
  digitalWrite(RELAY2, relayState[1] ? HIGH : LOW);
  digitalWrite(RELAY3, relayState[2] ? HIGH : LOW);
  digitalWrite(RELAY4, relayState[3] ? HIGH : LOW);
  digitalWrite(RELAY5, relayState[4] ? HIGH : LOW);
  digitalWrite(RELAY6, relayState[5] ? HIGH : LOW);
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
    if (json->get(d, "relay1"))
      relayState[0] = d.intValue;
    if (json->get(d, "relay2"))
      relayState[1] = d.intValue;
    if (json->get(d, "relay3"))
      relayState[2] = d.intValue;
    if (json->get(d, "relay4"))
      relayState[3] = d.intValue;
    if (json->get(d, "relay5"))
      relayState[4] = d.intValue;
    if (json->get(d, "relay6"))
      relayState[5] = d.intValue;
    if (json->get(d, "ecoMode"))
      isEcoMode = d.boolValue;
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
    if (path == "/relay5")
      relayState[4] = intVal;
    if (path == "/relay6")
      relayState[5] = intVal;
    if (path == "/ecoMode") {
      isEcoMode = data.boolData();
      Serial.printf("MODE CHANGED: %s\n", isEcoMode ? "ECO" : "PERFORMANCE");
    }
    if (path == "/security/isArmed") {
      isArmed = data.boolData();
      Serial.printf("SECURITY %s\n", isArmed ? "ARMED" : "DISARMED");
    }
  }

  // Adjust telemetry timings based on mode
  reportInterval = isEcoMode ? 15000 : 4000;

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

/* ================= ESP-NOW CALLBACK ================= */
void OnDataRecv(const uint8_t *mac, const uint8_t *data, int len) {
  memcpy(&incomingData, data, sizeof(incomingData));
  Serial.printf("🛰 MESH RECV: %s | Motion: %d | LDR: %d\n",
                incomingData.sensorId, incomingData.motion,
                incomingData.lightLevel);
  meshDataPending = true;
}

/* ================= SETUP ================= */
void setup() {
  Serial.begin(115200);

  pinMode(RELAY1, OUTPUT);
  pinMode(RELAY2, OUTPUT);
  pinMode(RELAY3, OUTPUT);
  pinMode(RELAY4, OUTPUT);
  pinMode(RELAY5, OUTPUT);
  pinMode(RELAY6, OUTPUT);

  digitalWrite(RELAY1, LOW);
  digitalWrite(RELAY2, LOW);
  digitalWrite(RELAY3, LOW);
  digitalWrite(RELAY4, LOW);
  digitalWrite(RELAY5, LOW);
  digitalWrite(RELAY6, LOW);
  applyRelays();

  pinMode(PIR_PIN, INPUT); // Initialize PIR pin
  pinMode(BUZZER_PIN, OUTPUT);
  digitalWrite(BUZZER_PIN, LOW);

  initLEDs();

  analogReadResolution(12);
  analogSetAttenuation(ADC_11db);

  WiFi.mode(WIFI_STA);
  WiFi.setAutoReconnect(true); // VERY IMPORTANT FOR AUTO RECONNECT
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

  ArduinoOTA.setHostname(OTA_HOSTNAME);
  ArduinoOTA.setPassword(OTA_PASSWORD);
  ArduinoOTA.onStart([]() { isOTAActive = true; });
  ArduinoOTA.onEnd([]() {
    isOTAActive = false;
    triggerActivityLED();
    ESP.restart(); // Ensure valid state after OTA
  });
  ArduinoOTA.begin();

  MDNS.addService("nebula", "tcp", 80);

  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;
  config.token_status_callback = tokenStatusCallback;
  fbStream.setResponseSize(1024);

  Firebase.signUp(&config, &auth, "", "");
  Firebase.begin(&config, &auth);
  // FIREBASE RECONNECT PARAMS
  Firebase.reconnectWiFi(true);

  Firebase.RTDB.beginStream(&fbStream,
                            ("devices/" + deviceId + "/commands").c_str());
  Firebase.RTDB.setStreamCallback(&fbStream, streamCallback,
                                  streamTimeoutCallback);

  // --- INITIALIZE SECURITY STATE ---
  FirebaseJson initSensor;
  initSensor.set("status", false);
  initSensor.set("lastTriggered", 0);
  initSensor.set("lightLevel", 0);
  Firebase.RTDB.updateNode(
      &fbTele, ("devices/" + deviceId + "/security/sensors/kitchen").c_str(),
      &initSensor);
  Firebase.RTDB.setBool(
      &fbTele, ("devices/" + deviceId + "/security/isArmed").c_str(), isArmed);

  // --- ESP-NOW SETUP ---
  if (esp_now_init() == ESP_OK) {
    esp_now_register_recv_cb(OnDataRecv);
    Serial.println("🔗 ESP-NOW Bridge Initialized");
  }

  xTaskCreatePinnedToCore(voltageTask, "VoltageTask", 10000, NULL, 1, NULL, 0);

  lastCloudActivity = millis();
}

/* ================= LOOP ================= */
void loop() {
  animateLEDs();
  ArduinoOTA.handle();

  if (updateRelays) {
    applyRelays();
    updateRelays = false;
  }

  // --- WIFI AUTO RECONNECT (Second Layer Defense) ---
  static unsigned long lastWiFiCheck = 0;
  if (millis() - lastWiFiCheck > 20000) {
    lastWiFiCheck = millis();
    if (WiFi.status() != WL_CONNECTED) {
      Serial.println("⚠ WiFi Reconnecting...");
      WiFi.disconnect();
      WiFi.begin(WIFI_SSID, WIFI_PASS);
    }
  }

  // --- TELEMETRY / HEARTBEAT ---
  static unsigned long lastTeleCheck = 0;
  if (millis() - lastTeleCheck > (isEcoMode ? 2000 : 500)) { // Polling throttle
    lastTeleCheck = millis();
    float currentV = sharedVoltage;
    bool timeExpired = (millis() - lastTelemetryTime > reportInterval);
    bool significantChange = (abs(currentV - lastReportedVoltage) > 3.0);

    if (forceTelemetry || timeExpired || significantChange) {
      if (Firebase.ready() && isInternetLive) {
        FirebaseJson j;
        j.set("relay1", relayState[0]);
        j.set("relay2", relayState[1]);
        j.set("relay3", relayState[2]);
        j.set("relay4", relayState[3]);
        j.set("relay5", relayState[4]);
        j.set("relay6", relayState[5]);
        j.set("voltage", currentV);
        j.set("ecoMode", isEcoMode);
        j.set("lastSeen", millis());
        forceTelemetry = false;

        if (Firebase.RTDB.updateNode(
                &fbTele, ("devices/" + deviceId + "/telemetry").c_str(), &j)) {
          lastTelemetryTime = millis();
          lastReportedVoltage = currentV;
          lastCloudActivity = millis(); // Refresh deadman
        } else {
          isInternetLive = false; // Fallback sync
        }
      }
    }
  }

  // --- PIR SECURITY LOGIC (ARMED ONLY) ---
  int pirState = digitalRead(PIR_PIN);
  if (isArmed && pirState == HIGH) {
    if (millis() - lastPIRTrigger > PIR_COOLDOWN) {
      // 1. Hardware Fallback (Local Alert)
      digitalWrite(BUZZER_PIN, HIGH);
      delay(200);
      digitalWrite(BUZZER_PIN, LOW);

      if (Firebase.ready() && isInternetLive) {
        FirebaseJson sensorData;
        sensorData.set("status", true);
        sensorData.set("lastTriggered", millis());

        if (Firebase.RTDB.updateNode(
                &fbTele,
                ("devices/" + deviceId + "/security/sensors/kitchen").c_str(),
                &sensorData)) {
          Serial.println("🚨 MOTION DETECTED: Kitchen (ARMED)");
          lastPIRTrigger = millis();
          triggerActivityLED();

          // Add to log structure
          FirebaseJson log;
          log.set("sensor", "Kitchen");
          log.set("timestamp", millis());
          Firebase.RTDB.pushJSON(
              &fbTele, ("/devices/" + deviceId + "/security/logs").c_str(),
              &log);
        }
      } else {
        // OFFLINE FALLBACK: Direct Buzzer Alarm
        Serial.println("⚠️ OFFLINE ALERT: Motion Detected!");
        for (int i = 0; i < 3; i++) {
          digitalWrite(BUZZER_PIN, HIGH);
          delay(100);
          digitalWrite(BUZZER_PIN, LOW);
          delay(100);
        }
        lastPIRTrigger = millis();
      }
    }
  } else if (lastPIRState == HIGH && pirState == LOW) {
    if (Firebase.ready() && isInternetLive) {
      Firebase.RTDB.setBool(
          &fbTele,
          ("devices/" + deviceId + "/security/sensors/kitchen/status").c_str(),
          false);
    }
  }
  lastPIRState = pirState;

  // --- DEADMAN'S SWITCH LOGIC ---
  if (millis() - lastCloudActivity > DEADMAN_TIMEOUT_MS) {
    if (!safetyTripped) {
      Serial.println("⛔ DEADMAN TRIP: No Cloud Contact for 2 mins. Halting.");
      relayState[0] = false;
      relayState[1] = false;
      relayState[2] = false;
      relayState[3] = false;
      relayState[4] = false;
      relayState[5] = false;
      applyRelays();
      safetyTripped = true;
    }

    // Auto Reset if Deadman is tripped for 5 minutes
    if (millis() - lastCloudActivity > (DEADMAN_TIMEOUT_MS + 300000)) {
      Serial.println("☢ DEADMAN REBOOT!");
      ESP.restart();
    }
  } else {
    safetyTripped = false;
  }

  // --- MESH BRIDGE FORWARDING ---
  if (meshDataPending) {
    if (isArmed && Firebase.ready() && isInternetLive) {
      FirebaseJson meshJson;
      meshJson.set("status", incomingData.motion);
      meshJson.set("lightLevel", incomingData.lightLevel);
      meshJson.set("lastTriggered", millis());

      String nodePath = "devices/" + deviceId + "/security/sensors/" +
                        String(incomingData.sensorId);
      if (Firebase.RTDB.updateNode(&fbTele, nodePath.c_str(), &meshJson)) {
        if (incomingData.motion) {
          triggerActivityLED();
          // Push log for history
          FirebaseJson log;
          log.set("sensor", incomingData.sensorId);
          log.set("timestamp", millis());
          Firebase.RTDB.pushJSON(
              &fbTele, ("/devices/" + deviceId + "/security/logs").c_str(),
              &log);
        }
      }
    }
    meshDataPending = false;
  }

  delay(isEcoMode ? 50 : 5); // Conserve processor when in Eco mode
}
