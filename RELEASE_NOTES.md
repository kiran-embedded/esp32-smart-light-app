# Nebula Core v1.2.0+26 (INTUITION & FLUIDITY)

**Release Date:** January 20, 2026
**Build ID:** `NC-ANDROID-REL-26`
**Update Size:** MAJOR INTERACTION & OPTIMIZATION
**Priority:** RECOMMENDED

---

## 🚀 WHAT'S NEW: THE INTUITION UPDATE
This release transforms how you interact with your home automation by introducing contextual controls and extreme performance optimizations for high-refresh-rate displays.

### 🧠 Contextual Scheduling (Long-Press)
*   **Intuitive Entry**: Removed the global clock icon from the main screen. Now, simply **long-press** any switch tile to open its specific scheduling hub.
*   **Smart Pre-selection**: When you open the scheduler via long-press, the corresponding switch is automatically pre-selected in the "Add Schedule" flow, saving you time and taps.

### 🕒 12-Hour Clock Support
*   **Format Upgrade**: All time displays in the Automation Hub now follow the standard 12-hour format (AM/PM).
*   **Seamless Selection**: The time picker has been updated to support the 12-hour format for a more natural scheduling experience.

### ⚡ 90FPS Fluidity & Breathing UI
*   **Buttery Smooth Scrolling**: Integrated `RepaintBoundary` and optimized `ListView` caching to ensure zero-lag scrolling at 90fps, even with multiple active schedules.
*   **Breathing Animations**:
    *   **Hub Indicator**: A subtle, pulsing neon glow in the header indicates active automation.
    *   **Breathing Button**: The "Create New Schedule" button now features a continuous LED breathing pulse and moving shimmer effect.
    *   **Glassmorphism Polish**: Enhanced Frosted Glass effects across the entire scheduler interface.

### 🛠️ Core Improvements
*   **Code Optimization**: Removed legacy unused widgets and simplified the interaction logic in the Control View.
*   **Resource Management**: Minimized background repaints to further improve battery efficiency.

---

## 📸 THE NEW STANDARD
The Nebula Core UI now feels more alive than ever, responding to every gesture with fluid transitions and vibrant, theme-aware feedback.

---

## 📋 TECHNICAL CHANGELOG
*   `[UI]` **Interaction**: Implemented long-press trigger on `SwitchTile` for scheduler entry.
*   `[UI]` **Scheduler**: Updated `_buildPremiumScheduleItem` and `_AddScheduleSheet` to 12-hour format.
*   `[UI]` **Performance**: Strategic `RepaintBoundary` placement for high-refresh-rate optimization.
*   `[UI]` **Animation**: Added custom breathing and shimmer loops using `flutter_animate`.
*   `[CORE]` **Versioning**: Bumped version to `v1.2.0+26`.

---

**DEPLOYMENT STATUS: ACTIVE**
*Nebula Core - Precise. Beautiful. Efficient.*
