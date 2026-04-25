# 🌐 NEBULA CORE – Firebase Data Map & Address Guide

> **Complete reference for all Firebase Realtime Database paths used by the Nebula Core ecosystem.**
> This guide helps you understand what data flows between your **App**, **ESP32 Hub**, and **ESP8266 Satellite**.

---

## 📦 Database Structure

All device data lives under: `devices/{DEVICE_ID}/...`

> Replace `{DEVICE_ID}` with your unique device ID (e.g., `79215788`).

---

## 🎮 COMMANDS (App → ESP32)

Path: `devices/{DEVICE_ID}/commands/`

| Key | Type | Example | Description |
|-----|------|---------|-------------|
| `relay1` – `relay7` | `int` (0/1) | `1` | Switch relay ON(1) / OFF(0) |
| `invert1` – `invert7` | `bool` | `true` | Inverted relay logic (Active LOW) |
| `isArmed` | `bool` | `true` | Security system armed/disarmed |
| `panic` | `bool` | `true` | Trigger panic alarm (siren) |
| `buzzerMute` | `bool` | `false` | Mute the physical buzzer |
| `ldrThreshold` | `int` | `50` | Light level threshold (0-100) |
| `pirTimer` | `int` | `60` | Auto-OFF timer in seconds after motion |
| `ecoMode` | `bool` | `false` | Eco mode (slower telemetry) |
| `mapPIR1` – `mapPIR5` | `int` | `3` | Bitmask: which relays PIR triggers |
| `globalMotionMode` | `int` | `0` | 0=Always, 4=Night-Only |
| `ldrSecurity` | `bool` | `false` | LDR-gated security |

### Nested under `commands/security/`

| Key | Type | Example | Description |
|-----|------|---------|-------------|
| `securityMode` | `int` | `2` | 0=LDR, 1=Schedule, 2=Hybrid, 3=Always |
| `activePeriods/morning` | `bool` | `true` | Enable morning period (6AM-12PM) |
| `activePeriods/afternoon` | `bool` | `true` | Enable afternoon period (12PM-5PM) |
| `activePeriods/evening` | `bool` | `true` | Enable evening period (5PM-8PM) |
| `activePeriods/night` | `bool` | `true` | Enable night period (8PM-12AM) |
| `activePeriods/midnight` | `bool` | `true` | Enable midnight period (12AM-6AM) |
| `calibration/PIR1/sensitivity` | `int` | `80` | PIR sensitivity (0-100) |
| `calibration/PIR1/debounce` | `int` | `200` | PIR debounce in ms |

---

## 📊 TELEMETRY (ESP32 → App)

Path: `devices/{DEVICE_ID}/telemetry/`

| Key | Type | Example | Description |
|-----|------|---------|-------------|
| `relay1` – `relay7` | `bool` | `true` | Actual relay hardware state |
| `voltage` | `float` | `232.5` | Measured AC voltage |
| `heap` | `int` | `48000` | Free heap memory (bytes) |
| `rssi` | `int` | `-45` | WiFi signal strength (dBm) |
| `uptime` | `int` | `3600` | System uptime in seconds |

---

## 💓 STATUS / HEARTBEAT

### ESP32 Hub: `devices/{DEVICE_ID}/status/`

| Key | Type | Example | Description |
|-----|------|---------|-------------|
| `online` | `bool` | `true` | Hub is alive |
| `lastSeen` | `int` | `1713089400` | Unix epoch seconds |
| `heap` | `int` | `48000` | Free heap memory |
| `rssi` | `int` | `-45` | WiFi signal |
| `version` | `string` | `v2.0.0` | Firmware version |

### ESP8266 Satellite: `devices/{DEVICE_ID}/security/nodeActive/`

| Key | Type | Example | Description |
|-----|------|---------|-------------|
| `online` | `bool` | `true` | Satellite is alive |
| `lastSeen` | `int` | `1713089400` | Unix epoch seconds |
| `signal` | `int` | `-55` | WiFi signal (dBm) |
| `version` | `string` | `v2.1.0` | Firmware version |

---

## 🔐 SECURITY (ESP8266 → Firebase → ESP32)

### Sensor Data: `devices/{DEVICE_ID}/security/sensors/PIR1/`

| Key | Type | Example | Description |
|-----|------|---------|-------------|
| `status` | `bool` | `true` | Motion detected |
| `lightLevel` | `int` | `35` | LDR value (0-100) |
| `lastTriggered` | `int` | `1713089400` | Unix epoch seconds |
| `nickname` | `string` | `"Front Door"` | User-given name |
| `isAlarmEnabled` | `bool` | `true` | Per-sensor alarm toggle |

### Breach Logs: `devices/{DEVICE_ID}/security/logs/{pushId}/`

| Key | Type | Example | Description |
|-----|------|---------|-------------|
| `sensor` | `string` | `"PIR1"` | Which sensor triggered |
| `timestamp` | `int` | `1713089400` | When it happened |

---

## 🛰️ SATELLITE CONFIG (App → ESP8266)

Path: `devices/{DEVICE_ID}/commands/satellite/config/`

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `pulses` | `int` | `2` | Required pulses for detection |
| `window` | `int` | `15000` | Detection window (ms) |
| `hold` | `int` | `3000` | Hold time after detection (ms) |
| `gap` | `int` | `2000` | Minimum gap between pulses (ms) |
| `valid` | `int` | `150` | Minimum HIGH duration to be valid (ms) |

---

## 🔄 PIR → RELAY BITMASK EXPLAINED

The `mapPIR` value is a **bitmask** where each bit represents a relay:

```
Bit 0 = Relay 1    (value: 1)
Bit 1 = Relay 2    (value: 2)
Bit 2 = Relay 3    (value: 4)
Bit 3 = Relay 4    (value: 8)
Bit 4 = Relay 5    (value: 16)
Bit 5 = Relay 6    (value: 32)
Bit 6 = Relay 7    (value: 64)
```

**Examples:**
- `mapPIR1 = 1` → PIR1 triggers Relay 1 only
- `mapPIR1 = 3` → PIR1 triggers Relay 1 + Relay 2
- `mapPIR1 = 7` → PIR1 triggers Relay 1 + 2 + 3
- `mapPIR1 = 127` → PIR1 triggers ALL 7 relays

---

## 🔌 ESP32 PIN MAP

| Pin | Function |
|-----|----------|
| GPIO 26 | Relay 1 |
| GPIO 27 | Relay 2 |
| GPIO 25 | Relay 3 |
| GPIO 33 | Relay 4 |
| GPIO 32 | Relay 5 |
| GPIO 14 | Relay 6 |
| GPIO 23 | Relay 7 |
| GPIO 34 | Voltage Sensor (ADC) |
| GPIO 13 | Buzzer |
| GPIO 19 | LED Red |
| GPIO 16 | LED Green |
| GPIO 17 | LED Blue |

## 🔌 ESP8266 PIN MAP

| Pin | Function |
|-----|----------|
| GPIO 5 (D1) | PIR Zone 1 |
| GPIO 4 (D2) | PIR Zone 2 |
| GPIO 14 (D5) | PIR Zone 3 |
| GPIO 12 (D6) | PIR Zone 4 |
| A0 | LDR (Light Sensor) |
| LED_BUILTIN | Status LED |
