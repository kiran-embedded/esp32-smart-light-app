/*
 * NEBULA CORE - ESP32 Firebase Integration Sample
 * This code sends voltage and current data to Firebase Realtime Database.
 * The Flutter app listens to the "sensors" node to display live info.
 */

#include <Arduino.h>
#include <WiFi.h>
#include <Firebase_ESP_Client.h>

// Provide the token generation process info.
#include "addons/TokenHelper.h"
// Provide the RTDB payload printing info and other helper functions.
#include "addons/RTDBHelper.h"

// 1. WiFi Credentials
#define WIFI_SSID "YOUR_WIFI_SSID"
#define WIFI_PASSWORD "YOUR_WIFI_PASSWORD"

// 2. Firebase Credentials
// Get these from your Firebase Console -> Project Settings -> Service accounts -> Database secrets
#define API_KEY "YOUR_FIREBASE_API_KEY"
#define DATABASE_URL "YOUR_DATABASE_URL" 

// Define Firebase Data object
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

unsigned long sendDataPrevMillis = 0;
bool signupOK = false;

void setup() {
  Serial.begin(115200);

  // WiFi Connection
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to Wi-Fi");
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(300);
  }
  Serial.println();
  Serial.print("Connected with IP: ");
  Serial.println(WiFi.localIP());
  Serial.println();

  // Firebase Setup
  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;

  // Sign up or log in
  if (Firebase.signUp(&config, &auth, "", "")) {
    Serial.println("Firebase SignUp OK");
    signupOK = true;
  } else {
    Serial.printf("%s\n", config.signer.signupError.message.c_str());
  }

  // Assign the callback function for the long running token generation task
  config.token_status_callback = tokenStatusCallback; 
  
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);
}

void loop() {
  // Send data every 5 seconds
  if (Firebase.ready() && signupOK && (millis() - sendDataPrevMillis > 5000 || sendDataPrevMillis == 0)) {
    sendDataPrevMillis = millis();

    // Simulated Sensor Data (Replace with real sensor readings)
    float voltage = 230.5 + (random(-10, 10) / 10.0);
    float current = 1.2 + (random(-2, 2) / 10.0);

    // Create JSON object for sensor data
    FirebaseJson json;
    json.set("voltage", voltage);
    json.set("current_amp", current);
    json.set("last_updated", String(millis()));

    // Push data to "sensors" node
    Serial.printf("Pushing to Firebase... %s\n", Firebase.RTDB.setJSON(&fbdo, "sensors", &json) ? "ok" : fbdo.errorReason().c_str());
  }
}
