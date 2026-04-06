#include <ESP8266WiFi.h>
#include <espnow.h>

/* ================= CONFIGURATION ================= */
// REPLACE WITH ESP32 MAC ADDRESS
uint8_t broadcastAddress[] = {0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF};

#define PIR1_PIN 14 // D5 (Living)
#define PIR2_PIN 12 // D6 (Kitchen)
#define PIR3_PIN 13 // D7 (Hallway)
#define PIR4_PIN 4  // D2 (Garage)
#define PIR5_PIN 5  // D1 (Front Door)

const char *pirNames[5] = {"living", "kitchen", "hallway", "garage", "door"};
const int pirPins[5] = {PIR1_PIN, PIR2_PIN, PIR3_PIN, PIR4_PIN, PIR5_PIN};

bool lastPirStates[5] = {false, false, false, false, false};
unsigned long lastHeartbeat = 0;
const int HEARTBEAT_INTERVAL = 10000; // 10 seconds

/* ================= MESH STRUCTURE ================= */
typedef struct struct_message {
  char sensorId[16];
  bool motion;
  int lightLevel; // Not used currently, keep for struct alignment with ESP32
} struct_message;

struct_message outgoingData;

/* ================= ESP-NOW CALLBACK ================= */
void OnDataSent(uint8_t *mac_addr, uint8_t sendStatus) {
  Serial.print("Last Packet Send Status: ");
  if (sendStatus == 0) {
    Serial.println("Delivery success");
  } else {
    Serial.println("Delivery fail");
  }
}

void sendState(int index, bool motion) {
  strcpy(outgoingData.sensorId, pirNames[index]);
  outgoingData.motion = motion;
  outgoingData.lightLevel = 0;

  esp_now_send(broadcastAddress, (uint8_t *)&outgoingData,
               sizeof(outgoingData));
  Serial.printf("Sent: %s -> %d\n", pirNames[index], motion);
}

void sendHeartbeat() {
  strcpy(outgoingData.sensorId, "ping");
  outgoingData.motion = true;    // active indicator
  outgoingData.lightLevel = 100; // magic number identifying as ping

  esp_now_send(broadcastAddress, (uint8_t *)&outgoingData,
               sizeof(outgoingData));
  Serial.println("Sent: Heartbeat (PING)");
}

void setup() {
  Serial.begin(115200);
  Serial.println("\nNEBULA SENSOR NODE BOOTING...");

  WiFi.mode(WIFI_STA);
  WiFi.disconnect();

  if (esp_now_init() != 0) {
    Serial.println("Error initializing ESP-NOW");
    return;
  }

  esp_now_set_self_role(ESP_NOW_ROLE_CONTROLLER);
  esp_now_register_send_cb(OnDataSent);

  esp_now_add_peer(broadcastAddress, ESP_NOW_ROLE_SLAVE, 1, NULL, 0);

  for (int i = 0; i < 5; i++) {
    pinMode(pirPins[i], INPUT);
    lastPirStates[i] = digitalRead(pirPins[i]);
  }
}

void loop() {
  unsigned long now = millis();

  // Poll PIR sensors
  for (int i = 0; i < 5; i++) {
    bool currentState = digitalRead(pirPins[i]);
    if (currentState != lastPirStates[i]) {
      // Debounce logic could be added here if needed, but HC-SR501 usually
      // debounces internally
      sendState(i, currentState);
      lastPirStates[i] = currentState;
      delay(50); // slight delay to prevent absolute flooding
    }
  }

  // Heartbeat
  if (now - lastHeartbeat >= HEARTBEAT_INTERVAL) {
    sendHeartbeat();
    lastHeartbeat = now;
  }

  delay(20);
}
