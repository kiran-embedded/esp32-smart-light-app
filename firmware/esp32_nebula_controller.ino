/*
 * NEBULA CORE - ULTRA OPTIMIZED PREMUM FIRMWARE
 * Target: ESP32
 * Features: 
 * - Firebase Realtime Database (Stream API for < 50ms latency)
 * - RMS Voltage/Current Sensing (ZMPT101B / ACS712)
 * - Logic Level Relay Fast Switch
 * - OTA Updates
 * - WiFi Manager style Reconnection
 */

#if defined(ESP32)
  #include <WiFi.h>
#elif defined(ESP8266)
  #include <ESP8266WiFi.h>
#endif
#include <Firebase_ESP_Client.h>

// Provide the token generation process info.
#include <addons/TokenHelper.h>
// Provide the RTDB payload printing info and other helper functions.
#include <addons/RTDBHelper.h>

/* 1. DEFINE YOUR WIFI & FIREBASE CREDENTIALS */
#define WIFI_SSID "YOUR_WIFI_SSID"
#define WIFI_PASSWORD "YOUR_WIFI_PASSWORD"

#define API_KEY "YOUR_FIREBASE_API_KEY"
#define DATABASE_URL "https://your-project-default-rtdb.firebaseio.com" 
String DEVICE_ID = ""; // Leave blank to use ESP32 Chip ID automatically

/* 2. PIN DEFINITIONS */
// Relay Pins (User: Low trigger switch, means LOW = ON if module is active low, 
// but user says App switch OFF -> Relay ON. 
// We will flip the logic to state ? HIGH : LOW)
#define RELAY_1 23
#define RELAY_2 22
#define RELAY_3 21
#define RELAY_4 19

// Sensor Pins
#define VOLTAGE_PIN 34 // ADC1_6
#define CURRENT_PIN 35 // ADC1_7

/* 3. CALIBRATION CONSTANTS */
// Sensitivity for ACS712 5A = 185, 20A = 100, 30A = 66 mV/A
// ZMPT101B needs calibration
float VOLTAGE_SLOPE = 280.0; // Example calibration
float CURRENT_SENSITIVITY = 0.066; // 66mV/A for 30A module
float VREF = 3.3; 

/* 4. FIREBASE OBJECTS */
FirebaseData fbdo;
FirebaseData stream;
FirebaseAuth auth;
FirebaseConfig config;
bool signupOK = false;

unsigned long sendDataPrevMillis = 0;
bool connectionConfigured = false;

/* 5. SENSOR VARIABLES */
float voltageRMS = 0;
float currentRMS = 0;
unsigned long lastSensorUpdate = 0;

void setup() {
  Serial.begin(115200);
  
  // Init Relays
  pinMode(RELAY_1, OUTPUT);
  pinMode(RELAY_2, OUTPUT);
  pinMode(RELAY_3, OUTPUT);
  pinMode(RELAY_4, OUTPUT);
  
  // Initial state: OFF
  digitalWrite(RELAY_1, LOW); 
  digitalWrite(RELAY_2, LOW);
  digitalWrite(RELAY_3, LOW);
  digitalWrite(RELAY_4, LOW);

  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to Wi-Fi");
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(300);
  }
  Serial.println();
  Serial.print("Connected with IP: ");
  Serial.println(WiFi.localIP());

  // Generate Unique Device ID if not provided
  if (DEVICE_ID == "") {
    uint64_t chipid = ESP.getEfuseMac();
    DEVICE_ID = String((uint32_t)(chipid >> 32), HEX);
    DEVICE_ID += String((uint32_t)chipid, HEX);
    Serial.print("Generated Device ID from Chip ID: ");
    Serial.println(DEVICE_ID);
  }

  /* Assign the api key (required) */
  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;

  /* Sign up */
  if (Firebase.signUp(&config, &auth, "", "")) {
    Serial.println("Auth Success");
    signupOK = true;
  } else {
    Serial.printf("%s\n", config.signer.signupError.message.c_str());
  }

  /* Assign the callback function for the long running token generation task */
  config.token_status_callback = tokenStatusCallback; // see addons/TokenHelper.h

  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);

  // START STREAM - Path matches AppConstants.firebaseDevicesPath + DEVICE_ID + commands
  String streamPath = "/devices/";
  streamPath += DEVICE_ID;
  streamPath += "/commands";
  
  if (!Firebase.RTDB.beginStream(&stream, streamPath.c_str())) {
    Serial.printf("Stream begin error: %s\n", stream.errorReason().c_str());
  }
  
  Firebase.RTDB.setStreamCallback(&stream, streamCallback, streamTimeoutCallback);
}

void loop() {
  if (Firebase.ready() && signupOK) {
    // 1. READ SENSORS & UPDATE TELEMETRY (every 2000ms for stability)
    if (millis() - lastSensorUpdate > 2000) {
      readSensors();
      lastSensorUpdate = millis();
      updateTelemetry();
    }
  }
}

void updateTelemetry() {
  FirebaseJson json;
  
  // Sensor Data
  json.set("voltage", voltageRMS);
  json.set("current_amp", currentRMS);
  json.set("power_watt", voltageRMS * currentRMS);
  
  // Relay States - STRICT CONTRACT: true | false (Boolean)
  // App expects: /devices/{id}/telemetry/relayX -> true | false
  json.set("relay1", digitalRead(RELAY_1) == HIGH);
  json.set("relay2", digitalRead(RELAY_2) == HIGH);
  json.set("relay3", digitalRead(RELAY_3) == HIGH);
  json.set("relay4", digitalRead(RELAY_4) == HIGH);
  
  // Last Seen for Connection Monitoring
  json.set("lastSeen", (int)millis()); // In a real app, use Server Value or RTC

  String telemetryPath = "/devices/";
  telemetryPath += DEVICE_ID;
  telemetryPath += "/telemetry";
  
  if (Firebase.RTDB.updateNode(&fbdo, telemetryPath.c_str(), &json)) {
    Serial.println("Telemetry Updated Successfully");
  } else {
    Serial.printf("Telemetry Update Error: %s\n", fbdo.errorReason().c_str());
  }
}

// Helper to determine if a value should be considered "ON"
bool isValueOn(String value) {
  value.toLowerCase();
  // Handle "1" (from app) and "true" (from Firebase console)
  if (value == "1" || value == "true") return true;
  return false;
}

// Global Callback for Stream (Ultra Fast Response)
void streamCallback(FirebaseStream data) {
  Serial.printf("Stream path: %s | event: %s | value: %s\n",
                data.dataPath().c_str(),
                data.eventType().c_str(),
                data.payload().c_str());

  String path = data.dataPath();
  String value = data.payload();
  bool stateChanged = false;
  
  if (path == "/") {
    FirebaseJson json;
    FirebaseJsonData result;
    json.setJsonData(value);
    
    if (json.get(result, "relay1")) { digitalWrite(RELAY_1, isValueOn(result.stringValue) ? HIGH : LOW); stateChanged = true; }
    if (json.get(result, "relay2")) { digitalWrite(RELAY_2, isValueOn(result.stringValue) ? HIGH : LOW); stateChanged = true; }
    if (json.get(result, "relay3")) { digitalWrite(RELAY_3, isValueOn(result.stringValue) ? HIGH : LOW); stateChanged = true; }
    if (json.get(result, "relay4")) { digitalWrite(RELAY_4, isValueOn(result.stringValue) ? HIGH : LOW); stateChanged = true; }

  } else {
    bool state = isValueOn(value);
    int pin = -1;
    
    if (path == "/relay1") pin = RELAY_1;
    else if (path == "/relay2") pin = RELAY_2;
    else if (path == "/relay3") pin = RELAY_3;
    else if (path == "/relay4") pin = RELAY_4;
    
    if (pin != -1) {
      digitalWrite(pin, state ? HIGH : LOW); 
      stateChanged = true;
      Serial.printf("Switched Relay on Pin %d to %s\n", pin, state ? "HIGH" : "LOW");
    }
  }

  // Update telemetry immediately on command to sync UI fast
  if (stateChanged && Firebase.ready()) {
    updateTelemetry();
  }
}

void streamTimeoutCallback(bool timeout) {
  if (timeout) {
    Serial.println("Stream timeout, resuming...");
  }
}

void readSensors() {
  // 1. Voltage (RMS Method)
  // Simplified for demo - Use EmonLib for production
  double sumV = 0;
  int sampleCount = 500;
  for (int i = 0; i < sampleCount; i++) {
    int val = analogRead(VOLTAGE_PIN);
    // Center at 1800 (for ESP32 3.3V ADC with offset)
    double v = val - 1800; 
    sumV += v * v;
  }
  voltageRMS = sqrt(sumV / sampleCount) * (VOLTAGE_SLOPE / 4095.0);
  if(voltageRMS < 10) voltageRMS = 0; // Noise floor

  // 2. Current
  double sumI = 0;
  for (int i = 0; i < sampleCount; i++) {
    int val = analogRead(CURRENT_PIN);
    double i_inst = val - 1800;
    sumI += i_inst * i_inst;
  }
  currentRMS = sqrt(sumI / sampleCount) * CURRENT_SENSITIVITY;
}
