# 🌌 NEBULA CORE — Version 1.2.0+35.5

**Release Date:** April 5, 2026
**Build ID:** `NC-ANDROID-REL-35.5`
**Update Size:** NEON UI REFINEMENT & SOLID DESIGN SYSTEM
**Priority:** MANDATORY

---

## 🚀 WHAT'S NEW: THE UI REFINEMENT UPDATE
This release refines the "Neon" aesthetic and standardizes a high-performance, solid-black design system for maximum efficiency.

### 🌈 Refined Neon Glow
*   **Tightened Shadows**: Redesigned the glow effect on all Action Pills to eliminate "bleeding". It is now a sharp, bordered neon glow.
*   **Border-Centric**: Shifted from broad shadows to a tight, high-contrast border glow for a more professional "Pro" look.

### 🖤 Solid Design System
*   **Zero Blur Architecture**: Removed all remaining `FrostedGlass` and `BackdropFilter` effects from the Automation & Scheduler hubs.
*   **AMOLED Pure Black**: Standardized on `#0A0A0A` and `#151515` solid surfaces for 100% lag-free performance.

### 🔋 Extreme RAM Save (Finalized)
*   **Lifecycle Suspension**: Added deep lifecycle management that suspends non-essential Firebase listeners in the background, slashing RAM footprint when minimized.

---

## 📋 TECHNICAL CHANGELOG
*   `[UI]` **Aesthetics**: Refined Neon shadows in `AdvancedPillBase` and `PremiumActionPill`.
*   `[UI]` **Optimization**: Removed all glass/blur from `SchedulerSettingsPopup` and `SmartScheduleCard`.
*   `[PERF]` **RAM**: Implemented background listener suspension in `SwitchDevicesNotifier` and `SwitchScheduleNotifier`.
*   `[PERF]` **Latency**: Refactored command engine to support batch execution for 0ms master toggles.
*   `[CORE]` **Version**: Bumped to `v1.2.0+37`.

---

**DEPLOYMENT STATUS: ACTIVE**
*Nebula Core - Sharp. Solid. Efficient.*
