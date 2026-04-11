/*
 * NEBULA CORE – ULTRA SATELLITE (MULTI-ZONE)
 * VERSION: v1.6.5-ULTIMATE-SATELLITE
 * --------------------------------------------
 * SENSORS: 5x PIR Sensors, 1x LDR Sensor
 * PROTOCOL: ESP-NOW (High-Speed Wireless)
 * TARGET: ESP8266 Hub (MAC: 88:57:21:79:D5:01)
 */

#include <ArduinoOTA.h>
#include <ESP8266WiFi.h>
#include <espnow.h>

// ================= CONFIGURATION =================
// 🎯 TARGET HUB MAC ADDRESS
uint8_t receiverAddress[] = {0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF};

// WIFI FOR OTA & CHANNEL SYNC
#define ROUTER_SSID "Kerala_Vision"
#define ROUTER_PASS "chandrasekharan0039"
#define OTA_HOSTNAME "Nebula-Satellite-GOLD"

// PIN DEFINITIONS (NodeMCU / D1 Mini)
#define PIR1_PIN 5  // D1
#define PIR2_PIN 4  // D2
#define PIR3_PIN 14 // D5
#define PIR4_PIN 12 // D6
#define PIR5_PIN 13 // D7
#define LDR_PIN A0  // Analog

#define EVENT_LOCKOUT 1000 // 1s Debounce per sensor to avoid mesh flooding
#define HEARTBEAT_MS 10000 // 10s light sync

/* ================= DATA STRUCTURE ================= */
typedef struct struct_message {
  char sensorId[16];
  bool motion;
  int lightLevel;
} struct_message;

struct_message myData;
bool lastPIRState[5] = {false, false, false, false, false};
unsigned long lastTriggerTime[5] = {0, 0, 0, 0, 0};
unsigned long lastSendTime[5] = {0, 0, 0, 0, 0};
unsigned long lastHeartbeat = 0;

/* ================= HELPERS ================= */
void onEventSent(uint8_t *mac, uint8_t status) {
  // Serial.printf("📡 Transmission %s\n", status == 0 ? "SUCCESS" : "FAIL");
}

int32_t getWiFiChannel(const char *ssid) {
  int32_t n = WiFi.scanNetworks();
  for (uint8_t i = 0; i < n; i++) {
    if (!strcmp(ssid, WiFi.SSID(i).c_str()))
      return WiFi.channel(i);
  }
  return 1;
}

/* ================= SETUP ================= */
void setup() {
  Serial.begin(115200);
  delay(500);
  Serial.println("\n🚀 NEBULA SATELLITE GOLD BOOTING...");

  pinMode(PIR1_PIN, INPUT);
  pinMode(PIR2_PIN, INPUT);
  pinMode(PIR3_PIN, INPUT);
  pinMode(PIR4_PIN, INPUT);
  pinMode(PIR5_PIN, INPUT);

  WiFi.mode(WIFI_STA);
  WiFi.begin(ROUTER_SSID, ROUTER_PASS);

  unsigned long startT = millis();
  while (WiFi.status() != WL_CONNECTED && millis() - startT < 8000) {
    delay(200);
    Serial.print(".");
  }

  int32_t channel = (WiFi.status() == WL_CONNECTED)
                        ? WiFi.channel()
                        : getWiFiChannel(ROUTER_SSID);

  // Sync transmission frequency
  wifi_promiscuous_enable(1);
  wifi_set_channel(channel);
  wifi_promiscuous_enable(0);

  if (esp_now_init() != 0) {
    Serial.println("❌ ESP-NOW FAIL");
    return;
  }

  esp_now_set_self_role(ESP_NOW_ROLE_CONTROLLER);
  esp_now_register_send_cb(onEventSent);
  esp_now_add_peer(receiverAddress, ESP_NOW_ROLE_SLAVE, channel, NULL, 0);

  ArduinoOTA.setHostname(OTA_HOSTNAME);
  ArduinoOTA.begin();

  Serial.printf("✅ Ready on Channel %d. Monitoring 5 Zones.\n", channel);
}

/* ================= LOOP ================= */
void loop() {
  ArduinoOTA.handle();
  unsigned long now = millis();

  // 1. Read Light Level (0-100)
  int light = map(analogRead(LDR_PIN), 0, 1024, 0, 100);
  int pins[] = {PIR1_PIN, PIR2_PIN, PIR3_PIN, PIR4_PIN};
  bool anyEvent = false;

  // 2. Scan All PIR Zones (Zones 1-4)
  for (int i = 0; i < 4; i++) {
    bool motion = digitalRead(pins[i]);

    if (motion) {
      // START or RE-PULSE
      if (!lastPIRState[i] || (now - lastSendTime[i] > 300)) {
        snprintf(myData.sensorId, 16, "PIR%d", i + 1);
        myData.motion = true;
        myData.lightLevel = light;
        esp_now_send(receiverAddress, (uint8_t *)&myData, sizeof(myData));
        if (!lastPIRState[i])
          Serial.printf("📡 ZONE %d: MOTION DETECTED\n", i + 1);

        lastSendTime[i] = now;
        lastTriggerTime[i] = now;
        lastPIRState[i] = true;
        anyEvent = true;
      }
    } else {
      // END: Send one final OFF signal
      if (lastPIRState[i]) {
        snprintf(myData.sensorId, 16, "PIR%d", i + 1);
        myData.motion = false;
        myData.lightLevel = light;
        esp_now_send(receiverAddress, (uint8_t *)&myData, sizeof(myData));
        Serial.printf("📡 ZONE %d: MOTION END\n", i + 1);
        lastPIRState[i] = false;
      }
    }
  }

  // 3. Heartbeat / LDR Sync (Every 10s)
  if (!anyEvent && (now - lastHeartbeat > HEARTBEAT_MS)) {
    strcpy(myData.sensorId, "NODE_GOLD");
    myData.motion = false;
    myData.lightLevel = light;
    esp_now_send(receiverAddress, (uint8_t *)&myData, sizeof(myData));
    lastHeartbeat = now;

    // 🔬 HARDWARE DIAGNOSTIC PRINT
    Serial.printf("🔬 PIN STATES: P1:%d P2:%d P3:%d P4:%d P5:%d\n",
                  digitalRead(PIR1_PIN), digitalRead(PIR2_PIN),
                  digitalRead(PIR3_PIN), digitalRead(PIR4_PIN),
                  digitalRead(PIR5_PIN));
  }

  yield();
  delay(10);
}
