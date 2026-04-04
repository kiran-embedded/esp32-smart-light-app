package com.iot.nebulacontroller

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

class FCMService : FirebaseMessagingService() {

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)
        Log.d("FCMService", "Message Received from: ${remoteMessage.from}")

        // Handle Data Messages
        if (remoteMessage.data.isNotEmpty()) {
            val type = remoteMessage.data["type"]
            val zone = remoteMessage.data["zone"] ?: "Unknown"
            
            if (type == "motion") {
                triggerNativeAlarm(zone)
            }
        }
    }

    private fun triggerNativeAlarm(zone: String) {
        Log.d("FCMService", "Triggering Native Alarm for zone: $zone")
        
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(this, AlarmReceiver::class.java).apply {
            action = "com.iot.nebulacontroller.TRIGGER_SECURITY_ALARM"
            putExtra("zone", zone)
        }

        val pendingIntent = PendingIntent.getBroadcast(
            this,
            System.currentTimeMillis().toInt(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Use RTC_WAKEUP to ensure it fires even when device is asleep
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            alarmManager.setExactAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                System.currentTimeMillis(),
                pendingIntent
            )
        } else {
            alarmManager.setExact(
                AlarmManager.RTC_WAKEUP,
                System.currentTimeMillis(),
                pendingIntent
            )
        }
    }

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        Log.d("FCMService", "New Token: $token")
        // Note: The Flutter side also handles token registration, but we log here for native debugging
    }
}
