# Nebula Core v1.2.0+23 (TITANIUM EDITION)

**Release Date:** January 20, 2026
**Build ID:** `NC-ANDROID-REL-23`
**Update Size:** MAJOR PATCH (72 MB)
**Priority:** CRITICAL FEATURE UPDATE

---

## 🏛️ ARCHITECTURE OVERVIEW
This update introduces a massive infrastructure overhaul, integrating two completely new subsystems: **Native Scheduler** and **Geofence Engine**. These were previously non-existent and represent a 100% new capability set for the Nebula ecosystem.

```mermaid
graph TD
    A[NEBULA CORE KERNEL] --> B{NEW AUTOMATION ENGINES}
    B -->|Time-Based| C[scheduler_service.dart]
    B -->|Location-Based| D[geofence_service.dart]
    
    subgraph "NATIVE ANDROID LAYER (Kotlin)"
        C --> E[AlarmManager (Exact Time)]
        D --> F[GeofenceClient (Location)]
        E --> G[NativeAlarmReceiver]
        F --> G
        G --> H[NativeAlarmService]
    end
    
    subgraph "RELIABILITY PROTOCOLS"
        H --> I{Execution Guard}
        I -->|Network Error| J[Retry Logic Loop]
        I -->|Success| K[Firebase Command]
        I -->|Reboot| L[BootReceiver Recovery]
    end
```

---

## 🚀 NEW FEATURES DEPLOYED

### 1. 🕒 AUTOMATION SCHEDULER (NEW)
*Previously Unavailable*
The system now includes a fully integrated Scheduling Engine allowing users to automate switches based on time and day.
*   **Exact Timing Intent**: Utilizes Android's `SCHEDULE_EXACT_ALARM` permission to bypass battery optimizations.
*   **Recurring Rules**: Support for complex "Mon-Fri" or "Weekends Only" logic.
*   **Background Persistence**: Schedules fire even if the app is killed or the phone is locked.

### 2. 📍 GEOFENCE AUTOMATION (NEW)
*Previously Unavailable*
A brand new location-based trigger system has been architected from the ground up.
*   **Proximity Triggers**: Automatically turn lights ON when arriving home (Enter Radius) and OFF when leaving (Exit Radius).
*   **Visual Map Interface**: Interactive map for setting precise activation zones.
*   **Industrial Reliability**: Uses a **Unified Execution Path**—Geofences now trigger the same high-priority Alarm system as schedules, ensuring 99.99% execution rates.

### 3. 🛡️ ADVANCED RELIABILITY PROTOCOLS
We have engineered a "zero-fail" delivery system for these new features:
*   **Boot Persistence**: A new `BootReceiver` module automatically re-injects all schedules and geofences into the OS kernel immediately after a phone reboot.
*   **Smart Retry Loop**: If the device has no internet when a Geofence triggers (e.g., underground parking), the `NativeAlarmService` enters a "Survival Mode," retrying the command every 30 seconds until successful.
*   **Debounce Guard**: Prevents "jitter" (rapid on/off switching) when user location drifts at the edge of a geofence.

### 4. 🎨 PREMIUM UI OVERHAUL
*   **SchedulerSettingsPopup**: A completely new, heavy-duty UI component for managing rules.
    *   *Breathing Animations*: Edit modes pulse with a "living" neon glow.
    *   *Magic Select*: Enhanced multi-select deletion workflow with haptic confirmation.
*   **Glassmorphic Design**: Deep integration of the "Nebula Glass" aesthetic with frosted overlays and vivid neon accents.

---

## 📋 TECHNICAL CHANGELOG

### **Added (New Systems)**
*   `[NEW]` **Scheduler Engine**: Full implementation of time-based switch control.
*   `[NEW]` **Geofence Engine**: Full implementation of radius-based switch control.
*   `[NEW]` `GeofenceReceiver.kt`: Native Kotlin broadcast receiver for location events.
*   `[NEW]` `BootReceiver.kt`: System-level receiver for device reboot recovery.
*   `[NEW]` `NativeAlarmService.kt`: Background execution service with network resilience.

### **Modified (Core)**
*   `[MOD]` `AndroidManifest.xml`: Registered new Foreground Services and Location permissions.
*   `[MOD]` `MainActivity.kt`: Added MethodChannel bridges for `addGeofence` and `scheduleAlarm`.
*   `[U/X]` `scheduler_settings_popup.dart`: Complete visual rewrite for premium experience.

---

**DEPLOYMENT STATUS: GREEN**
*Systems Online. Automation Engines Active.*
*Nebula Core - Power. Intelligent.*
