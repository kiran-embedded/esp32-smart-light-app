/*
 * NEBULA CORE – SOVEREIGN SATELLITE KERNEL (ESP8266)
 * VERSION: v1.6.6-PRO-SOVEREIGN
 * --------------------------------------------
 * SENSORS: 4x PIR Zones, 1x LDR (Telemetry)
 * PROTOCOL: ESP-NOW (Industrial Mesh)
 * HARDENING: Hardware Watchdog, Proactive RAM Guard, Self-Healing Sync
 */

#include <ArduinoOTA.h>
#include <ESP8266WiFi.h>
#include <espnow.h>

/* ================= CONFIGURATION ================= */
// 1. HUB ESP32 MAC ADDRESS (Target)
uint8_t receiverAddress[] = {0x88, 0x57, 0x21, 0x79, 0xD5, 0x01};

// 2. NETWORK PARAMETERS
#define ROUTER_SSID "Kerala_Vision"
#define ROUTER_PASS "chandrasekharan0039"
#define OTA_HOSTNAME "Nebula-Sovereign-S1"

// 3. INDUSTRIAL PINOUT (NodeMCU Layout)
#define PIR1_PIN 5  // D1
#define PIR2_PIN 4  // D2
#define PIR3_PIN 14 // D5 (Hallway)
#define PIR4_PIN 12 // D6 (Entry)
#define LDR_PIN A0  // Analog Telemetry

// 4. TIMING ENGINE
#define HEARTBEAT_INTERVAL 15000 // 15s Vitality Sync
#define EVENT_LOCKOUT 600        // 600ms Debounce (Local)

/* ================= DATA STRUCTURE ================= */
typedef struct struct_message {
  char sensorId[16];
  bool motion;
  int lightLevel;
} struct_message;

struct_message myData;
bool lastStates[4] = {false, false, false, false};

/* ================= GLOBALS ================= */
unsigned long lastHeartbeat = 0;
unsigned long lastTriggerTime[4] = {0, 0, 0, 0};
int commFailCount = 0;

/* ================= Callbacks ================= */
void onDataSent(uint8_t *mac, uint8_t status) {
  if (status != 0) {
    commFailCount++;
  } else {
    commFailCount = 0;
  }
}

/* ================= SETUP ================= */
void setup() {
  Serial.begin(115200);
  delay(200);

  // 🛡️ INDUSTRIAL WATCHDOG (8s)
  ESP.wdtEnable(WDTO_8S);

  pinMode(PIR1_PIN, INPUT);
  pinMode(PIR2_PIN, INPUT);
  pinMode(PIR3_PIN, INPUT);
  pinMode(PIR4_PIN, INPUT);

  WiFi.mode(WIFI_STA);
  WiFi.begin(ROUTER_SSID, ROUTER_PASS);

  // High-Speed Channel Sync (Critical for ESP-NOW)
  unsigned long start = millis();
  while (WiFi.status() != WL_CONNECTED && millis() - start < 5000) {
    delay(100);
    ESP.wdtFeed();
  }

  int32_t channel = (WiFi.status() == WL_CONNECTED) ? WiFi.channel() : 1;
  wifi_promiscuous_enable(1);
  wifi_set_channel(channel);
  wifi_promiscuous_enable(0);

  if (esp_now_init() != 0) {
    ESP.restart();
  }

  esp_now_set_self_role(ESP_NOW_ROLE_CONTROLLER);
  esp_now_register_send_cb(onDataSent);
  esp_now_add_peer(receiverAddress, ESP_NOW_ROLE_SLAVE, channel, NULL, 0);

  ArduinoOTA.setHostname(OTA_HOSTNAME);
  ArduinoOTA.begin();

  Serial.printf("⚡ SOVEREIGN SAT ONLINE | CH: %d | WDT: ENABLED\n", channel);
}

/* ================= LOOP (Supervised) ================= */
void loop() {
  ESP.wdtFeed();
  ArduinoOTA.handle();
  unsigned long now = millis();

  int ldrPercent = map(analogRead(LDR_PIN), 0, 1024, 0, 100);
  int pirPins[] = {PIR1_PIN, PIR2_PIN, PIR3_PIN, PIR4_PIN};
  bool stateChanged = false;

  for (int i = 0; i < 4; i++) {
    bool currentMotion = digitalRead(pirPins[i]);

    if (currentMotion != lastStates[i]) {
      if (now - lastTriggerTime[i] > EVENT_LOCKOUT) {
        snprintf(myData.sensorId, 16, "PIR%d", i + 1);
        myData.motion = currentMotion;
        myData.lightLevel = ldrPercent;

        esp_now_send(receiverAddress, (uint8_t *)&myData, sizeof(myData));

        lastStates[i] = currentMotion;
        lastTriggerTime[i] = now;
        stateChanged = true;

        Serial.printf("📡 Mesh Push: %s | %s\n", myData.sensorId,
                      currentMotion ? "MOTION" : "CLEAR");
      }
    }
  }

  // Industrial Heartbeat (Maintain Hub Vitality)
  if (!stateChanged && (now - lastHeartbeat > HEARTBEAT_INTERVAL)) {
    strcpy(myData.sensorId, "SAT_NODE_1");
    myData.motion = false;
    myData.lightLevel = ldrPercent;
    esp_now_send(receiverAddress, (uint8_t *)&myData, sizeof(myData));
    lastHeartbeat = now;
  }

  // 🛡️ PROACTIVE STABILITY GUARD
  if (commFailCount > 20 || ESP.getFreeHeap() < 5000) {
    ESP.restart();
  }

  yield();
}
