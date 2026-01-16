# Release Notes - Nebula Core v1.2.0+17

## 🚀 Hybrid Connection Architecture

This release implements a robust, manual-mode switching architecture that ensures 100% control reliability whether internet is available or not.

### � CORE IDEA
• Same Wi-Fi router always  
• WAN (internet) may be ON or OFF  
• **LOCAL mode** → direct ESP32 IP (HTTP/MQTT)  
• **CLOUD mode** → Firebase only  
• **ONLY ONE MODE ACTIVE** (manual selection)  
• No auto switching between modes  

---

### 📱 START APP Logic
**MODE** = CLOUD (User selectable)  
**INTERNET** = FALSE  
**FIREBASE** = FALSE  

**LOOP FOREVER:**
1. **CHECK INTERNET (WAN):** Detects if global internet is reachable.
2. **CHECK FIREBASE:** Detects if cloud database is connected.
3. **MODE VALIDATION:**
   - IF **MODE == CLOUD**: If Firebase is unavailable, block commands and notify user.
   - IF **MODE == LOCAL**: Disable all Firebase listeners to save battery and data.
4. **USER COMMAND:**
   - IF **MODE == CLOUD**: Send relay state → **Firebase**
   - IF **MODE == LOCAL**: Send relay state → **ESP32 LOCAL IP**

---

### 🔹 MODE SELECTION (MANUAL ONLY)
**USER IS BOSS.** Select mode from Settings.

- **IF user selects LOCAL:**
  - `MODE = LOCAL`
  - DISABLE Firebase completely.
- **IF user selects CLOUD:**
  - IF Internet & Firebase are UP:
    - `MODE = CLOUD`
    - ENABLE Firebase & SYNC ESP32 → Firebase.
  - ELSE: Show "No Internet / Firebase".

---

### ⚠️ NO AUTO MODE CHANGE
The app will never switch modes automatically to prevent "ghost control" or unexpected relay flips.

---

### � START ESP32 Logic
**MODE** = LOCAL (Safe default)  
**WIFI** = DISCONNECTED  

**LOOP FOREVER:**
1. **WIFI CHECK:** Ensure persistent router connection.
2. **MODE CHECK:**
   - IF **MODE == LOCAL**: Handle local HTTP commands, **IGNORE** Firebase.
   - IF **MODE == CLOUD**: Reconnect Firebase if needed, read and apply states.

---

### � LOCAL MODE (NO INTERNET NEEDED)
**Phone ──WiFi── Router ──WiFi── ESP32**
- ❌ WAN / ❌ Firebase
- ✅ Works 100%
- *Example:* `http://192.168.1.50/relay?ch=1&state=1`

### 🔹 CLOUD MODE (INTERNET REQUIRED)
**Phone → Firebase → ESP32**
- ✅ WAN REQUIRED

---

### 🔹 RECONNECTION TRUTH (IMPORTANT)
1. **WAN lost:** Firebase stops → CLOUD mode unusable → **USER switches to LOCAL** → Control continues.
2. **WAN returns:** Firebase reconnects → **USER switches back to CLOUD** → App syncs ESP32 state.

---

### � GOLDEN RULES
1. **ONE MODE AT A TIME**
2. **NO BLE** (Fully removed for stability)
3. **SAME WIFI FOR LOCAL**
4. **ABSOLUTE ON / OFF ONLY**
5. **APP DECIDES MODE** (ESP32 never decides)
6. **CLOUD & LOCAL NEVER RUN TOGETHER**

---

### 🔹 ONE-LINE MEMORY
**Manual LOCAL** → No Internet needed | **Manual CLOUD** → Firebase only
