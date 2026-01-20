package com.iot.nebulacontroller

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.net.ConnectivityManager
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.database.FirebaseDatabase
import android.app.AlarmManager
import android.app.PendingIntent
import android.os.PowerManager

class NativeAlarmService : Service() {

    private var wakeLock: PowerManager.WakeLock? = null

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        try {
            val node = intent?.getStringExtra("targetNode")
            val state = intent?.getBooleanExtra("targetState", false) ?: false
            val deviceId = intent?.getStringExtra("deviceId") ?: "esp32_001"
            val isGeofence = intent?.getBooleanExtra("isGeofence", false) ?: false
            val retryCount = intent?.getIntExtra("retryCount", 0) ?: 0

            if (node == null) {
                stopSelf()
                return START_NOT_STICKY
            }

            startForegroundServiceNotification()

            // Acquire WakeLock immediately
            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
            wakeLock = powerManager.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "Nebula:NativeServiceWakelock")
            wakeLock?.acquire(10 * 1000L) // 10s strict timeout
            Log.d("NativeService", "WakeLock Acquired (10s limit)")

            // 4. Network Readiness Check
            if (!isNetworkAvailable()) {
                Log.w("NativeService", "No Network! Retry Count: $retryCount")
                if (retryCount < 2) {
                    scheduleRetry(node, state, deviceId, isGeofence, retryCount + 1)
                }
                stopSelf()
                return START_NOT_STICKY
            }

            performUpdate(deviceId, node, state)

        } catch (e: Exception) {
            Log.e("NativeService", "CRITICAL ERROR: ${e.message}", e)
            stopSelf()
        }

        return START_NOT_STICKY
    }

    private fun isNetworkAvailable(): Boolean {
        val cm = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        val activeNetwork = cm.activeNetworkInfo
        return activeNetwork != null && activeNetwork.isConnectedOrConnecting
    }

    private fun scheduleRetry(node: String, state: Boolean, deviceId: String, isGeofence: Boolean, retryCount: Int) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(this, NativeAlarmReceiver::class.java).apply {
            action = "com.iot.nebulacontroller.ALARM_TRIGGER"
            putExtra("targetNode", node)
            putExtra("targetState", state)
            putExtra("deviceId", deviceId)
            putExtra("isGeofence", isGeofence)
            putExtra("retryCount", retryCount)
        }

        val pendingIntent = PendingIntent.getBroadcast(
            this,
            System.currentTimeMillis().toInt(), // Unique ID for retry
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val triggerAt = System.currentTimeMillis() + 30000 // 30s retry delay
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pendingIntent)
        } else {
            alarmManager.setExact(AlarmManager.RTC_WAKEUP, triggerAt, pendingIntent)
        }
    }

    private fun startForegroundServiceNotification() {
        val channelId = "nebula_automation_channel"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "Nebula Automation",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }

        val notification = NotificationCompat.Builder(this, channelId)
            .setContentTitle("Nebula Automation")
            .setContentText("Executing scheduled task...")
            .setSmallIcon(R.mipmap.launcher_icon) 
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()

        startForeground(777, notification)
    }

    private fun performUpdate(deviceId: String, node: String, state: Boolean) {
        val auth = FirebaseAuth.getInstance()
        if (auth.currentUser == null) {
            auth.signInAnonymously().addOnCompleteListener { task ->
                if (task.isSuccessful) {
                    writeToFirebase(deviceId, node, state)
                } else {
                    Log.e("NativeService", "Auth Failed", task.exception)
                    stopSelf()
                }
            }
        } else {
            writeToFirebase(deviceId, node, state)
        }
    }

    private fun writeToFirebase(deviceId: String, node: String, state: Boolean) {
        // Path: devices/esp32_001/commands/{node}
        val targetVal = if (state) 1 else 0
        Log.d("NativeService", "Writing to devices/$deviceId/commands/$node = $targetVal")

        val db = FirebaseDatabase.getInstance()
        val ref = db.getReference("devices/$deviceId/commands")

        ref.child(node).setValue(targetVal).addOnCompleteListener {
            Log.d("NativeService", "Write Complete: ${it.isSuccessful}")
            if (it.isSuccessful) {
                showCompletionNotification(node, state)
            }
            stopSelf()
        }
    }

    private fun showCompletionNotification(node: String, state: Boolean) {
        val channelId = "nebula_automation_notifications"
        val stateText = if (state) "ON" else "OFF"
        val title = "Schedule Executed"
        val content = "Successfully turned $stateText $node"

        val notification = NotificationCompat.Builder(this, channelId)
            .setContentTitle(title)
            .setContentText(content)
            .setSmallIcon(R.mipmap.launcher_icon)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .build()
            
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(System.currentTimeMillis().toInt(), notification)
    }

    override fun onDestroy() {
        super.onDestroy()
        if (wakeLock?.isHeld == true) {
            Log.d("NativeService", "WakeLock Released in onDestroy")
            wakeLock?.release()
        }
    }
}
