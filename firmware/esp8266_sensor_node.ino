/*
 * NEBULA MESH – SENSOR NODE (ESP8266)
 * VERSION: v1.0.0
 * -----------------------------------
 */

#include <ESP8266WiFi.h>
#include <espnow.h>

// MAC Address of the Main ESP32 Bridge
uint8_t broadcastAddress[] = {0x00, 0x00, 0x00,
                              0x00, 0x00, 0x00}; // REPLACE WITH YOUR ESP32 MAC

#define PIR_PIN D5
#define LDR_PIN A0

typedef struct struct_message {
  char sensorId[16];
  bool motion;
  int lightLevel;
} struct_message;

struct_message myData;
unsigned long lastSend = 0;
const int sendInterval = 10000; // 10s heartbeat
const int cooldown = 5000;      // 5s PIR cooldown

void OnDataSent(uint8_t *mac_addr, uint8_t sendStatus) {
  Serial.print("Last Packet Send Status: ");
  Serial.println(sendStatus == 0 ? "Delivery Success" : "Delivery Fail");
}

void setup() {
  Serial.begin(115200);
  pinMode(PIR_PIN, INPUT);

  WiFi.mode(WIFI_STA);
  if (esp_now_init() != 0) {
    Serial.println("Error initializing ESP-NOW");
    return;
  }

  esp_now_set_self_role(ESP_NOW_ROLE_CONTROLLER);
  esp_now_register_send_cb(OnDataSent);
  esp_now_add_peer(broadcastAddress, ESP_NOW_ROLE_SLAVE, 1, NULL, 0);

  strcpy(myData.sensorId, "Kitchen_Node");
}

void loop() {
  int motion = digitalRead(PIR_PIN);
  int light = analogRead(LDR_PIN);

  bool triggered = (motion == HIGH && (millis() - lastSend > cooldown));
  bool heartbeat = (millis() - lastSend > sendInterval);

  if (triggered || heartbeat) {
    myData.motion = (motion == HIGH);
    myData.lightLevel = map(light, 0, 1024, 0, 100); // Percentage

    esp_now_send(broadcastAddress, (uint8_t *)&myData, sizeof(myData));
    lastSend = millis();

    if (triggered)
      Serial.println("🚨 Motion Data Sent via MESH");
  }

  delay(100);
}
