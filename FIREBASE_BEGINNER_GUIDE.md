# 🌟 Firebase Visual Guide for Beginners

Welcome to the **Nebula Core** data guide! This document is designed to help you easily understand what goes on behind the scenes when your app talks to your ESP32 / ESP8266 hardware through the Firebase Realtime Database. 

Think of Firebase as a live spreadsheet. Whenever an ESP pushes data, or your Phone pushes a button, the cells in this spreadsheet change instantly. Below is exactly what your database looks like!

---

## 📂 The Top Level Directory
Everything belongs to a single core folder called `devices/`, followed by your unique secret ID.

```json
devices/
  └── 79215788/          <-- Your Unique Device ID
```

Inside this device folder, the data splits into **Four Main Areas**:

---

## 1. 🕹️ Commands (The App telling Hardware what to do)
*When you press a switch or move a slider in the App, the data flashes into this folder. The ESP32 and ESP8266 are constantly watching this folder and react instantly when these numbers change.*

```json
    commands/
      ├── relay1: 1                <-- 1 (ON) or 0 (OFF). Smart Switch #1.
      ├── relay2: 0                
      ├── panic: false             <-- Triggers the physical alarm buzzer
      ├── isArmed: true            <-- Is the security system armed?
      │
      └── satellite/config/        <-- ESP8266 Motion Sensor Settings
           ├── pulses: 2           <-- Slider: Pulses required
           ├── gap: 2000           <-- Slider: Minimum gap
           └── window: 15000       <-- Slider: Verification window
```

---

## 2. 📡 Telemetry (The Hardware telling the App what's happening)
*This is the live confirmation. After the ESP32 physically clicks the relay, it pushes the physical truth back up to this folder. Your App watches this to color your switches on the screen.*

```json
    telemetry/
      ├── relay1: true             <-- Switch #1 is successfully clicked ON!
      ├── relay2: false            
      ├── voltage: 234.5           <-- The current AC mains voltage
      ├── rssi: -45                <-- WiFi Strength of the ESP32 Hub
      └── uptime: 3600             <-- How long the ESP32 has been running
```

---

## 3. 🚨 Security (Motion Detectors & Logs)
*When the ESP8266 detects someone walking by, it blasts the `status: true` signal into this folder. The ESP32 watches this folder, and if the system is `isArmed: true`, it instantly triggers the alarms!*

```json
    security/
      ├── sensors/
      │     └── PIR1/
      │            ├── status: true        <-- MOTION DETECTED! (true/false)
      │            ├── lightLevel: 55      <-- Is it dark? (LDR Value 0-100)
      │            └── lastTriggered: 1713089400  <-- When it happened
      │
      └── logs/
            └── -Nxy1...          <-- Saved Breach Log
                   ├── sensor: "PIR1"
                   └── timestamp: 1713089400
```

---

## 4. 🌩️ Status (Heartbeats / Are they alive?)
*Every 10 to 30 seconds, both devices send a "heartbeat" here so the App knows they didn't lose power or WiFi.*

```json
    status/
      ├── online: true             <-- The ESP32 Hub is alive
      └── lastSeen: 1713089400

    security/nodeActive/
      ├── online: true             <-- The ESP8266 Motion Satellite is alive
      ├── signal: -50              <-- Hardware WiFi strength
      └── version: "v2.5.0-NEURAL" <-- Satellite Firmware Version
```

---

### 💡 Pro-Tip for Beginners:
If you want to watch the Matrix happen in real-time:
1. Open up your Firebase Web Console.
2. Expand the `devices/{DEVICE_ID}/commands` folder.
3. Open your mobile app.
4. Press `Switch 1` on your phone, and watch `relay1` magically change from `0` to `1` on your computer screen!
5. Expand the `security/sensors` folder, wave your hand in front of the physical ESP8266 PIR sensor, and watch `status` jump to `true` instantly!
