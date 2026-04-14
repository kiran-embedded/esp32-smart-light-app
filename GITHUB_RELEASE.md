<h1 align="center">
  <img src="https://readme-typing-svg.demolab.com?font=Orbitron&weight=900&size=36&pause=1000&color=00FFFF&center=true&vCenter=true&width=600&lines=Nebula+Core+v1.2.0%2B42;Industrial+Stabilization;Absolute+Parity" alt="Typing SVG" />
</h1>

<div align="center">
  <h3>⚡ The Core Stabilization Protocol ⚡</h3>
  <p><b>A massive overhaul achieving absolute parity between the Flutter interface and hardware counterparts.</b></p>
</div>

---

### 🛑 The Problem
Previous versions suffered from a volatile RED-GREEN restart loop due to blocking delays, path mismatches blocking the Neural Grid automation, and phantom UI relay glitches ("echoes") where the hardware telemetry overwrote immediate commands. 

### 🚀 The Solutions

#### 🧩 1. Non-Blocking Architecture & Watchdog Safety
* **O-Delay Execution**: Stripped all blocking `delay()` from the `applyRelays()` engine and replaced with non-blocking stagger. Completely eliminates watchdog crashes!
* **Soft Recovery**: Upgraded `softRecoveryEngine` to enforce a 30s cooldown and strictly await WiFi reconnection before aggressively querying Firebase.

#### 🌌 2. Total Path Synchronization 
* **Absolute Parity**: Fully mapped and synced the ESP32 Hub, ESP8266 Satellite, and Flutter app to follow the strict `FIREBASE_DATA_MAP.md` schema. 
* **Neural Paths Restored**: `globalMotionMode` and `securityMode` seamlessly bridge the App to the Hub. PIR arrays now directly trigger mapped Relays instantly.

#### ✨ 3. Complete UI Glitch Eradication
* **The "Echo" Fix**: Rebuilt the stream merging engine. When a UI switch is toggled, it locks into an optimistic state for 5 seconds and strictly debounces incoming firmware telemetry for 2s, completely eliminating visual bounce-back.

#### 📡 4. Developer Console Revolution
* **True Diagnostics**: Corrected critical pathing errors where the Dev Console read incorrect telemetry data. Wait no more—the console now proudly pulls real `signal`, `version`, and `online` heartbeat status directly from the ESP8266!

<br/>

<div align="center">
  <b>Included in this release:</b>
  <p><code>app-release.apk</code> | <code>esp32_firmware_pro.ino</code> | <code>esp8266_satellite_node.ino</code></p>
</div>
