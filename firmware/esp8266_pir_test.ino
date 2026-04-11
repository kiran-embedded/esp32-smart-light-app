/*
 * NEBULA MESH – PIR TEST TOOL (ESP8266)
 * -----------------------------------
 * STANDALONE TEST FOR A SINGLE PIR SENSOR.
 */

#define PIR_PIN 5 // (NodeMCU D1) -> Change to 4 for D2

void setup() {
  Serial.begin(115200);
  delay(1000);
  Serial.println("\n\n--- SINGLE PIR TEST BOOTED ---");
  Serial.printf("Monitoring Pin: %d\n", PIR_PIN);

  pinMode(PIR_PIN, INPUT);
}

void loop() {
  bool motion = digitalRead(PIR_PIN);

  if (motion) {
    Serial.println("🚨 MOTION DETECTED!");
  } else {
    Serial.println("SAFE");
  }

  delay(200); // Fast response for testing
}
