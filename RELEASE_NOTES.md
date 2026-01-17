# 🌌 NEBULA CORE — Version 1.2.0+20
### *The "Industrial Power" Stability Update*

This release represents a significant shift towards industrial-grade stability. We have refined the "Server Rack Edition" firmware as the primary stable branch and introduced mission-critical safety features.

---

## ⚡ Technical Manifest (V1.2.0+20)

### 🧠 Industrial Stability Update
- **Local Mode Suspension**: Local hotspot/direct mode has been temporarily disabled to ensure 100% stable execution via the **Server Rack Edition** Cloud architecture.
- **Deadman Safety Engine**: High-end firmware safety that automatically trips relays to OFF if total network isolation is detected for more than 60 seconds.

### 🎨 Visual & UI Overhaul
- **7-Mode Neon Engine**: Action pills now feature 7 selectable animation modes (Sweep, Dot Runner, Comet, Pulse, Strobe, Rainbow, Auto-Change).
- **Hyper-Premium Settings**: Redesigned Appearance and Help screens with dynamic glow intensity and refined typography.

### 🔋 "Server Rack Edition" Firmware
- Optimized FreeRTOS tasking for connectivity and telemetry.
- Reduced CPU footprint by removing legacy web server logic.
- Hardened AC Voltage sampling with smooth RMS filtering.

---

# 🌌 NEBULA CORE — Version 1.2.0+19
### *The "Hybrid Synergy" Architecture Update*

We are proud to introduce a revolutionary update to the Nebula Core ecosystem. This release marks the transition from cloud-dependent control to a sophisticated **Hybrid Connection Engine**, giving you absolute sovereignty over your smart environment.

---

## 💎 The Golden Principle: User-Centric Sovereignty
In this update, we have completely decoupled Local and Cloud operations. The app no longer "guesses" your intent; it respects your manual selection, ensuring zero ghost-commands and 100% predictable relay behavior.

### � Hybrid Engine Architecture
| Feature | **Local Mode** 🏠 | **Cloud Mode** ☁️ |
| :--- | :--- | :--- |
| **Connectivity** | Direct WiFi (HTTP/MQTT) | Firebase Realtime DB |
| **Internet Req.** | **None (0% WAN)** | Required |
| **Response Time** | Instant (<10ms) | Low Latency (Region Dep.) |
| **Privacy** | 100% On-Premise | Secure Cloud Sync |
| **Best For** | Power users & Privacy | Remote Access |

---

## �️ Technical Manifest (V1.2.0+17)

### 🧠 App Logic Flow
The Nebula Core app now operates on a strict single-channel validation loop:
- **WAN Detection**: Real-time monitoring of global internet availability.
- **Firebase Guard**: Cloud commands are strictly blocked if a secure handshake isn't established.
- **Listener Isolation**: When in **Local Mode**, all Firebase background listeners are terminated to prevent battery drain and state conflicts.

### 🔋 ESP32 Firmware Logic
The firmware has been hardened for cross-network stability:
- **Persistent WiFi Recovery**: Reconnects to your router in <2s upon signal loss.
- **Mode Decoupling**: In **Local Mode**, the ESP32 completely ignores external cloud pulses, responding only to direct-IP commands.

---

## 📜 The Golden Rules of Nebula
To maintain the "Ultra-Premium" stability of this system, the following rules are non-negotiable:
1. **Manual Selection Only**: No auto-switching. You control the bridge.
2. **Absolute States**: ON/OFF commands are explicit; no toggle ambiguity.
3. **No BLE**: Bluetooth has been retired to eliminate discovery lag and interference.
4. **App Sovereignty**: The Mobile App manages the mode; the ESP32 follows.

---

## 🚀 Performance & Stability
- **Radial Depth Engine**: Refined background vignette for a more immersive UI.
- **Analog Texture**: Integrated high-end noise layer to eliminate OLED banding.
- **120FPS Optimization**: Micro-animations now dynamically scale based on device thermal and performance profiles.

---
*Built for the future of smart living. Built by **Kiran Embedded**.*
