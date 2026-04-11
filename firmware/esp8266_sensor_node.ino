/*
 * NEBULA CORE – ULTRA SATELLITE NODE (ESP8266)
 * VERSION: v1.6.5-PRO
 * --------------------------------------------
 * SENSORS: 4x PIR Sensors, 1x LDR Sensor
 * PROTOCOL: ESP-NOW (High-Speed Wireless)
 * FEATURES: Auto-Channel Sync, OTA Support, Pro Debounce
 */

#include <ArduinoOTA.h>
#include <ESP8266WiFi.h>
#include <espnow.h>

// ================= CONFIGURATION =================
// 1. MAIN ESP32 MAC ADDRESS (Recovered from Project records)
uint8_t receiverAddress[] = {0x88, 0x57, 0x21, 0x79, 0xD5, 0x01};

// 2. WIFI FOR OTA & CHANNEL SYNC
#define ROUTER_SSID "Kerala_Vision"
#define ROUTER_PASS "chandrasekharan0039"
#define OTA_HOSTNAME "Nebula-Satellite-Node"

// 3. PIN DEFINITIONS (NodeMCU/D1 Mini Layout)
#define PIR1_PIN 5  // D1
#define PIR2_PIN 4  // D2
#define PIR3_PIN 14 // D5 (Living/Hallway)
#define PIR4_PIN 12 // D6 (Security Entry)
#define LDR_PIN A0  // Analog

// 4. TIMING & PERFORMANCE
#define HEARTBEAT_INTERVAL 10000 // 10s light sync
#define EVENT_LOCKOUT 800        // 800ms debounce

// ================= DATA STRUCTURE =================
typedef struct struct_message {
  char sensorId[16];
  bool motion;
  int lightLevel;
} struct_message;

struct_message myData;
struct_message lastSent[4]; // Cache states for 4 PIRs

// ================= GLOBALS =================
unsigned long lastHeartbeatTime = 0;
unsigned long lastTriggerTime[4] = {0, 0, 0, 0};
int failedSendsArr = 0;

/* ================= AUTO-CHANNEL SYNC ================= */
int32_t getWiFiChannel(const char *ssid) {
  int32_t n = WiFi.scanNetworks();
  for (uint8_t i = 0; i < n; i++) {
    if (!strcmp(ssid, WiFi.SSID(i).c_str())) {
      return WiFi.channel(i);
    }
  }
  return 1; // Default
}

void onEventSent(uint8_t *mac, uint8_t status) {
  if (status != 0)
    failedSendsArr++;
  else
    failedSendsArr = 0;
}

/* ================= SETUP ================= */
void setup() {
  Serial.begin(115200);
  delay(500);
  Serial.println("\n🚀 NEBULA PRO SATELLITE (ESP8266) BOOTING...");

  pinMode(PIR1_PIN, INPUT);
  pinMode(PIR2_PIN, INPUT);
  pinMode(PIR3_PIN, INPUT);
  pinMode(PIR4_PIN, INPUT);

  WiFi.mode(WIFI_STA);
  WiFi.begin(ROUTER_SSID, ROUTER_PASS);

  unsigned long startT = millis();
  while (WiFi.status() != WL_CONNECTED && millis() - startT < 8000) {
    delay(500);
    Serial.print(".");
  }

  int32_t channel = (WiFi.status() == WL_CONNECTED)
                        ? WiFi.channel()
                        : getWiFiChannel(ROUTER_SSID);

  // Align transmission frequency with router channel
  wifi_promiscuous_enable(1);
  wifi_set_channel(channel);
  wifi_promiscuous_enable(0);

  if (esp_now_init() != 0) {
    Serial.println("❌ ESP-NOW Init Failed");
    return;
  }

  esp_now_set_self_role(ESP_NOW_ROLE_CONTROLLER);
  esp_now_register_send_cb(onEventSent);
  esp_now_add_peer(receiverAddress, ESP_NOW_ROLE_SLAVE, channel, NULL, 0);

  ArduinoOTA.setHostname(OTA_HOSTNAME);
  ArduinoOTA.begin();

  Serial.printf("✅ Ready on Channel %d. Monitoring 4 Zones...\n", channel);
}

/* ================= LOOP ================= */
void loop() {
  ArduinoOTA.handle();
  unsigned long now = millis();

  int currentLDR = map(analogRead(LDR_PIN), 0, 1024, 0, 100);
  int pins[] = {PIR1_PIN, PIR2_PIN, PIR3_PIN, PIR4_PIN};
  bool anyPIRChanged = false;

  for (int i = 0; i < 4; i++) {
    bool motion = digitalRead(pins[i]);

    if (motion && !lastSent[i].motion) {
      if (now - lastTriggerTime[i] > EVENT_LOCKOUT) {
        snprintf(myData.sensorId, 16, "PIR%d", i + 1);
        myData.motion = true;
        myData.lightLevel = currentLDR;

        esp_now_send(receiverAddress, (uint8_t *)&myData, sizeof(myData));
        Serial.printf("📡 ALERT: %s Triggered!\n", myData.sensorId);

        lastSent[i].motion = true;
        lastTriggerTime[i] = now;
        anyPIRChanged = true;
      }
    } else if (!motion && lastSent[i].motion) {
      // Send "OFF" to clear status in App immediately
      snprintf(myData.sensorId, 16, "PIR%d", i + 1);
      myData.motion = false;
      myData.lightLevel = currentLDR;
      esp_now_send(receiverAddress, (uint8_t *)&myData, sizeof(myData));

      lastSent[i].motion = false;
    }
  }

  // Periodic Heartbeat (Keep LDR Synced)
  if (!anyPIRChanged && (now - lastHeartbeatTime > HEARTBEAT_INTERVAL)) {
    strcpy(myData.sensorId, "NODE_SAT1");
    myData.motion = false;
    myData.lightLevel = currentLDR;
    esp_now_send(receiverAddress, (uint8_t *)&myData, sizeof(myData));
    lastHeartbeatTime = now;
  }

  if (failedSendsArr > 10) {
    Serial.println("⚠️ Comm error. Rebooting...");
    ESP.restart();
  }

  yield();
}
