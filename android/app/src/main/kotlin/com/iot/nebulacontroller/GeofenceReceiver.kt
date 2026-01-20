package com.iot.nebulacontroller

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import com.google.android.gms.location.Geofence
import com.google.android.gms.location.GeofencingEvent

class GeofenceReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val geofencingEvent = GeofencingEvent.fromIntent(intent)
        
        if (geofencingEvent == null) {
             Log.e("GeofenceReceiver", "GeofencingEvent is null")
             return
        }

        if (geofencingEvent.hasError()) {
            Log.e("GeofenceReceiver", "Geofencing Error: ${geofencingEvent.errorCode}")
            return
        }

        val geofenceTransition = geofencingEvent.geofenceTransition

        // Helper to trigger execution via ALARM PATH (Unified Reliability)
        fun scheduleExecution(ruleId: String, transitionType: Int) {
            val prefs = context.getSharedPreferences("GeofencePrefs", Context.MODE_PRIVATE)
            val storedRule = prefs.getString(ruleId, null) ?: return 
            
            // Format: "lat|lng|radius|targetNode|targetState|triggerOnEnter|triggerOnExit|deviceId"
            val parts = storedRule.split("|")
            if (parts.size < 8) return

            val targetNode = parts[3]
            val targetState = parts[4].toBoolean()
            val triggerOnEnter = parts[5].toBoolean()
            val triggerOnExit = parts[6].toBoolean()
            val deviceId = parts[7]

            // 1. Determine if we should trigger
            var shouldTrigger = false
            if (transitionType == Geofence.GEOFENCE_TRANSITION_ENTER && triggerOnEnter) {
                shouldTrigger = true
            } else if (transitionType == Geofence.GEOFENCE_TRANSITION_EXIT && triggerOnExit) {
                shouldTrigger = true
            }

            if (!shouldTrigger) return

            // 2. Execution Guard (Debounce - 5 minutes)
            val lastRunKey = "last_run_$ruleId"
            val lastRunTime = prefs.getLong(lastRunKey, 0)
            val now = System.currentTimeMillis()
            if (now - lastRunTime < 5 * 60 * 1000) {
                Log.d("GeofenceReceiver", "Skipping double-fire for $ruleId (Debounced)")
                return
            }
            prefs.edit().putLong(lastRunKey, now).apply()

            // 3. Schedule Exact Alarm (The "Scheduler Path")
            Log.d("GeofenceReceiver", "Scheduling Exact Alarm for Rule: $ruleId")
            
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val alarmIntent = Intent(context, NativeAlarmReceiver::class.java).apply {
                action = "com.iot.nebulacontroller.ALARM_TRIGGER"
                putExtra("targetNode", targetNode)
                putExtra("targetState", targetState)
                putExtra("deviceId", deviceId)
                putExtra("isGeofence", true) // Tag for logging/retry logic
            }
            
            // Generate a unique ID for this execution (Current Time based)
            val pendingIntent = PendingIntent.getBroadcast(
                context, 
                System.currentTimeMillis().toInt(), 
                alarmIntent, 
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val triggerAt = System.currentTimeMillis() + 3000 // 3s delay for stability
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    triggerAt,
                    pendingIntent
                )
            } else {
                alarmManager.setExact(
                    AlarmManager.RTC_WAKEUP,
                    triggerAt,
                    pendingIntent
                )
            }
        }

        if (geofenceTransition == Geofence.GEOFENCE_TRANSITION_ENTER ||
            geofenceTransition == Geofence.GEOFENCE_TRANSITION_EXIT) {
            
            val triggeringGeofences = geofencingEvent.triggeringGeofences
            triggeringGeofences?.forEach { geofence ->
                scheduleExecution(geofence.requestId, geofenceTransition)
            }
        }
    }
}
