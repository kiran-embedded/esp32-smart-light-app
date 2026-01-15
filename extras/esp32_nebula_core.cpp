/*
 * NEBULA CORE - Complete ESP32 Firmware
 * -------------------------------------
 * Features:
 * 1. Relay Control (GPIO 2) - Managed via MQTT
 * 2. AC Voltage Sensing (GPIO 34) - Reported to Firebase
 * 3. Real-time Telemetry (Voltage/Current) -> Firebase RTDB
 * 4. WiFi / MQTT / Firebase Auto-Reconnect
 */

#include <WiFi.h>
#include <PubSubClient.h>
#include <Firebase_ESP_Client.h>
#include <ArduinoJson.h>

// Helpers for Firebase
#include "addons/TokenHelper.h"
#include "addons/RTDBHelper.h"

// --- CONFIGURATION ---
const char* ssid = "Kerala_Vision";
const char* password = "chandrasekharan0039";

// MQTT Settings (matches app defaults)
const char* mqtt_server = "broker.emqx.io"; // Example broker
const int mqtt_port = 1883;
const char* mqtt_topic_set = "nebula/switch/1/set";
const char* mqtt_topic_state = "nebula/switch/1/state";

// Firebase Credentials
#define API_KEY "AIzaSyA9zs6xhRcEwwGLO6cI417b2FO52PiXaxs"
#define DATABASE_URL "https://nebula-smartpowergrid-default-rtdb.asia-southeast1.firebasedatabase.app"

// Hardware Pins
#define RELAY_PIN 2            // Integrated LED / First Relay
#define VOLTAGE_SENSOR_PIN 34  // Analog Input (Connect ZMPT101B Out)

// --- OBJECTS ---
WiFiClient espClient;
PubSubClient mqttClient(espClient);
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

// Timers
unsigned long lastTelemetryMillis = 0;
const long telemetryInterval = 5000; // 5 seconds

// --- AC VOLTAGE CALCULATION ---
float getACVoltage() {
  int sensorValue = 0;
  long sum = 0;
  int samples = 500;
  
  // Basic Peak-to-Peak calculation
  int minVal = 4095;
  int maxVal = 0;
  
  for (int i = 0; i < samples; i++) {
    sensorValue = analogRead(VOLTAGE_SENSOR_PIN);
    if (sensorValue > maxVal) maxVal = sensorValue;
    if (sensorValue < minVal) minVal = sensorValue;
    delayMicroseconds(100);
  }
  
  // Convert to Voltage (Calibration required for your specific sensor)
  float peakToPeak = (maxVal - minVal) * (3.3 / 4095.0);
  float rmsVoltage = (peakToPeak / 2.0) * 0.707 * 100.0; // Scaled for 230V range
  
  if (rmsVoltage < 10.0) rmsVoltage = 0; // Filter noise
  return rmsVoltage;
}

// --- MQTT CALLBACK ---
void callback(char* topic, byte* payload, unsigned int length) {
  String message = "";
  for (int i = 0; i < length; i++) message += (char)payload[i];

  Serial.print("Message arrived [");
  Serial.print(topic);
  Serial.print("] ");
  Serial.println(message);

  if (String(topic) == mqtt_topic_set) {
    if (message == "ON") {
      digitalWrite(RELAY_PIN, HIGH);
      mqttClient.publish(mqtt_topic_state, "ON");
    } else if (message == "OFF") {
      digitalWrite(RELAY_PIN, LOW);
      mqttClient.publish(mqtt_topic_state, "OFF");
    }
  }
}

// --- RECONNECT LOGIC ---
void reconnect() {
  while (!mqttClient.connected()) {
    Serial.print("Attempting MQTT connection...");
    if (mqttClient.connect("NebulaESP32Client")) {
      Serial.println("connected");
      mqttClient.subscribe(mqtt_topic_set);
    } else {
      Serial.print("failed, rc=");
      Serial.print(mqttClient.state());
      Serial.println(" try again in 5 seconds");
      delay(5000);
    }
  }
}

void setup() {
  Serial.begin(115200);
  
  // GPIO Setup
  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, LOW);
  analogReadResolution(12);

  // WiFi Setup
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi connected");

  // MQTT Setup
  mqttClient.setServer(mqtt_server, mqtt_port);
  mqttClient.setCallback(callback);

  // Firebase Setup
  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;
  if (Firebase.signUp(&config, &auth, "", "")) {
    Serial.println("Firebase SignUp OK");
  }
  config.token_status_callback = tokenStatusCallback;
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);
}

void loop() {
  if (!mqttClient.connected()) reconnect();
  mqttClient.loop();

  // Telemetry Loop
  if (millis() - lastTelemetryMillis > telemetryInterval) {
    lastTelemetryMillis = millis();
    
    float voltage = getACVoltage();
    float current = random(50, 200) / 100.0; // Simulated Current

    // Send to Firebase
    FirebaseJson json;
    json.set("voltage", voltage);
    json.set("current_amp", current);
    
    if (Firebase.ready()) {
      Serial.print("Sending telemetry... ");
      if (Firebase.RTDB.setJSON(&fbdo, "sensors", &json)) {
        Serial.println("Sent!");
      } else {
        Serial.println(fbdo.errorReason());
      }
    }
  }
}
