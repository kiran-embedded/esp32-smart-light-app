package com.iot.nebulacontroller

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.database.DataSnapshot
import com.google.firebase.database.DatabaseError
import com.google.firebase.database.FirebaseDatabase
import com.google.firebase.database.ValueEventListener
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.net.Uri
import android.os.Vibrator
import android.os.VibrationEffect
import org.json.JSONObject

class SecurityForegroundService : Service() {

    private var databaseListener: ValueEventListener? = null
    private var isArmedListener: ValueEventListener? = null
    private var isArmed: Boolean = false
    private var schedulesListener: ValueEventListener? = null
    private var deviceId: String = ""
    private var databaseUrl: String = ""
    private var mediaPlayer: MediaPlayer? = null
    
    private var activePeriods: Map<String, Boolean> = mapOf(
        "morning" to true,
        "afternoon" to true,
        "evening" to true,
        "night" to true,
        "midnight" to true
    )
    private var activePeriodsListener: ValueEventListener? = null

    // Guard: prevent re-triggering alarm on every Firebase snapshot
    private var alarmAlreadyTriggered = false

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            "STOP_ALARM" -> {
                stopAlarmSound()
                disableHardwareBuzzer()
                alarmAlreadyTriggered = false // Reset so next real breach triggers again
            }
            "com.iot.nebulacontroller.ALARM_TRIGGER" -> {
                handleAlarmTrigger(intent)
            }
        }
        return START_STICKY
    }

    private fun handleAlarmTrigger(intent: Intent) {
        val node = intent.getStringExtra("targetNode")
        val state = intent.getBooleanExtra("targetState", false)
        val deviceId = intent.getStringExtra("deviceId") ?: "79215788"
        
        Log.d("SecurityService", "Unified Scheduler Trigger: $node -> $state")
        
        if (node != null) {
            performUpdate(deviceId, node, state)
        }
    }

    private fun performUpdate(deviceId: String, node: String, state: Boolean) {
        val auth = FirebaseAuth.getInstance()
        if (auth.currentUser == null) {
            auth.signInAnonymously().addOnCompleteListener { task ->
                if (task.isSuccessful) {
                    writeToFirebase(deviceId, node, state)
                }
            }
        } else {
            writeToFirebase(deviceId, node, state)
        }
    }

    private fun writeToFirebase(deviceId: String, node: String, state: Boolean) {
        val targetVal = if (state) 1 else 0
        
        // Resolve dynamic Database URL
        val db = if (databaseUrl.isNotEmpty()) FirebaseDatabase.getInstance(databaseUrl) else FirebaseDatabase.getInstance()
        
        // Use EXACT deviceId passed from the Flutter Native Intent to ensure correct Firebase node targeting.
        // Prevent fallbacks to stale SharedPreferences keys.
        val actualDeviceId = deviceId.replace("\"", "")
        
        val ref = db.getReference("devices/$actualDeviceId/commands")
        
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

        // Resolve Nickname from SharedPreferences
        val nicknamesJson = prefs.getString("flutter.switch_nicknames", null)
        var relayName = node
        try {
            if (nicknamesJson != null) {
                val cleanJson = if (nicknamesJson.startsWith("\"")) nicknamesJson.substring(1, nicknamesJson.length - 1).replace("\\\"", "\"") else nicknamesJson
                val json = org.json.JSONObject(cleanJson)
                if (json.has(node)) {
                    relayName = json.getString(node)
                }
            }
        } catch (e: Exception) {}

        val updates = mapOf(node to targetVal)
        ref.updateChildren(updates).addOnCompleteListener { task ->
            if (task.isSuccessful) {
                Log.d("SecurityService", "Success: $node ($relayName) to $targetVal")
                logHistory(db, actualDeviceId, node, relayName, state)
                showCompletionNotification(relayName, state)
            }
        }
    }

    private fun logHistory(db: FirebaseDatabase, deviceId: String, node: String, relayName: String, state: Boolean) {
        try {
            val logRef = db.getReference("devices/$deviceId/logs").push()
            val timestamp = java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSZ", java.util.Locale.US).format(java.util.Date())
            val logData = mapOf(
                "id" to (logRef.key ?: "unknown"),
                "relayId" to node,
                "relayName" to relayName,
                "state" to state,
                "timestamp" to timestamp,
                "triggeredBy" to "scheduler"
            )
            logRef.setValue(logData)
        } catch (e: Exception) {}
    }

    private fun showCompletionNotification(relayName: String, state: Boolean) {
        val channelId = "nebula_automation_notifications"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(channelId, "Automation Results", NotificationManager.IMPORTANCE_DEFAULT)
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }

        val stateText = if (state) "ON" else "OFF"
        val notification = NotificationCompat.Builder(this, channelId)
            .setContentTitle("Schedule Executed")
            .setContentText("Successfully turned $stateText $relayName")
            .setSmallIcon(R.mipmap.launcher_icon)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setAutoCancel(true)
            .build()
            
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(relayName.hashCode(), notification)
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        try {
            val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            deviceId = prefs.getString("flutter.esp32_device_id", "79215788")?.replace("\"", "") ?: "79215788"
            databaseUrl = prefs.getString("flutter.firebase_database_url", "")?.replace("\"", "") ?: ""
            
            Log.d("SecurityService", "Init with DeviceId: $deviceId, URL: $databaseUrl")

            if (com.google.firebase.FirebaseApp.getApps(this).isEmpty()) {
                com.google.firebase.FirebaseApp.initializeApp(this)
            }
            startForegroundNotification()
            startFirebaseListener()
        } catch (e: Exception) {
            Log.e("SecurityService", "CRITICAL ONCREATE ERROR: ${e.message}", e)
        }
    }

    private fun startForegroundNotification() {
        val channelId = "nebula_security_channel"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "Nebula Security Engine",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }

        val notification = NotificationCompat.Builder(this, channelId)
            .setContentTitle("NEBULA SECURITY ACTIVE")
            .setContentText("24/7 Deep-Space Monitoring...")
            .setSmallIcon(R.mipmap.launcher_icon)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .build()

        startForeground(888, notification)
    }

    private fun startFirebaseListener() {
        try {
            val auth = FirebaseAuth.getInstance()
            if (auth.currentUser == null) {
                auth.signInAnonymously().addOnCompleteListener { task ->
                    if (task.isSuccessful) {
                        setupListeners()
                    } else {
                        Log.e("SecurityService", "Native Auth Failed", task.exception)
                    }
                }
            } else {
                setupListeners()
            }
        } catch (e: Exception) {
            Log.e("SecurityService", "Firebase Init Error: ${e.message}")
        }
    }

    private fun setupListeners() {
        val fb = if (databaseUrl.isNotEmpty()) FirebaseDatabase.getInstance(databaseUrl) else FirebaseDatabase.getInstance()
        val dbSecurity = fb.getReference("devices/$deviceId/security")
        val dbCommands = fb.getReference("devices/$deviceId/commands")

        // 1. Listen for Armed state (Correctly pointed to commands/isArmed)
        isArmedListener = dbCommands.child("isArmed").addValueEventListener(object : ValueEventListener {
            override fun onDataChange(snapshot: DataSnapshot) {
                isArmed = snapshot.getValue(Boolean::class.java) ?: false
                if (!isArmed) {
                    // If disarmed, reset the trigger guard so it can fire again when re-armed
                    alarmAlreadyTriggered = false
                    stopAlarmSound()
                }
            }
            override fun onCancelled(error: DatabaseError) {}
        })

        // 2. Listen for Sensor Breaches
        databaseListener = dbSecurity.child("sensors").addValueEventListener(object : ValueEventListener {
            override fun onDataChange(snapshot: DataSnapshot) {
                if (!isArmed) return

                val sensors = snapshot.value as? Map<String, Any> ?: return
                var anyTriggered = false
                var sensorName = "Unknown Sensor"

                for ((name, data) in sensors) {
                    val status = (data as? Map<String, Any>)?.get("status") as? Boolean ?: false
                    if (status) {
                        anyTriggered = true
                        sensorName = name
                        break
                    }
                }

                if (anyTriggered && !alarmAlreadyTriggered) {
                    // Time-based check
                    val calendar = java.util.Calendar.getInstance()
                    val hour = calendar.get(java.util.Calendar.HOUR_OF_DAY)
                    
                    val period = when (hour) {
                        in 6..11 -> "morning"
                        in 12..16 -> "afternoon"
                        in 17..19 -> "evening"
                        in 20..23 -> "night"
                        else -> "midnight" // 0..5
                    }
                    
                    val isPeriodEnabled = activePeriods[period] ?: true
                    
                    if (isPeriodEnabled) {
                        alarmAlreadyTriggered = true
                        
                        // Check if Android Native Alarms are enabled in settings
                        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                        val isNativeEnabled = prefs.getBoolean("flutter.native_alarm_enabled", true)
                        
                        if (isNativeEnabled) {
                            triggerNativeAlarm(sensorName)
                        } else {
                            Log.d("SecurityService", "Sensor triggered, but Native Alarm Overlay is Disabled in User Settings.")
                        }
                    } else {
                        Log.d("SecurityService", "Sensor triggered, but alarm skipped. Period ($period) is disabled.")
                    }
                } else if (!anyTriggered) {
                    // All sensors cleared — reset trigger guard
                    alarmAlreadyTriggered = false
                }
            }
            override fun onCancelled(error: DatabaseError) {
                Log.e("SecurityService", "DB Error: ${error.message}")
            }
        })
        
        // 3. Listen for Schedules to build background triggers
        val schedulesRef = fb.getReference("devices/$deviceId/schedules")
        schedulesListener = schedulesRef.addValueEventListener(object : ValueEventListener {
            override fun onDataChange(snapshot: DataSnapshot) {
                Log.d("SecurityService", "Schedules Updated: Syncing AlarmManager...")
                syncSchedulesWithAlarmManager(snapshot)
            }
            override fun onCancelled(error: DatabaseError) {}
        })

        // 4. Listen for Active Periods (Time-Based Alarm Control)
        val activePeriodsRef = fb.getReference("devices/$deviceId/security/activePeriods")
        activePeriodsListener = activePeriodsRef.addValueEventListener(object : ValueEventListener {
            @Suppress("UNCHECKED_CAST")
            override fun onDataChange(snapshot: DataSnapshot) {
                val data = snapshot.value as? Map<String, Boolean>
                if (data != null) {
                    activePeriods = data
                }
            }
            override fun onCancelled(error: DatabaseError) {}
        })
    }

    private fun syncSchedulesWithAlarmManager(snapshot: DataSnapshot) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as android.app.AlarmManager
        val calendar = java.util.Calendar.getInstance()
        val currentDay = calendar.get(java.util.Calendar.DAY_OF_WEEK) // 1=Sun, 2=Mon...
        // Map Java Calendar day to our 1=Mon...7=Sun
        val ourDay = if (currentDay == 1) 7 else currentDay - 1
        
        val nowHour = calendar.get(java.util.Calendar.HOUR_OF_DAY)
        val nowMin = calendar.get(java.util.Calendar.MINUTE)
        
        for (scheduleSnap in snapshot.children) {
            try {
                val hour = scheduleSnap.child("hour").getValue(Int::class.java) ?: continue
                val minute = scheduleSnap.child("minute").getValue(Int::class.java) ?: continue
                val isEnabled = scheduleSnap.child("isEnabled").getValue(Boolean::class.java) ?: true
                val days = scheduleSnap.child("days").value as? List<Int> ?: emptyList()
                
                if (!isEnabled || !days.contains(ourDay)) continue
                
                // If schedule for today is still ahead
                if (hour > nowHour || (hour == nowHour && minute > nowMin)) {
                    scheduleNativeAlarm(scheduleSnap)
                }
            } catch (e: Exception) {
                Log.e("SecurityService", "Schedule sync error: ${e.message}")
            }
        }
    }

    private fun scheduleNativeAlarm(snap: DataSnapshot) {
        val hour = snap.child("hour").getValue(Int::class.java)!!
        val minute = snap.child("minute").getValue(Int::class.java)!!
        val relayId = snap.child("relayId").getValue(String::class.java)!!
        val state = snap.child("targetState").getValue(Boolean::class.java) ?: true
        
        val calendar = java.util.Calendar.getInstance().apply {
            set(java.util.Calendar.HOUR_OF_DAY, hour)
            set(java.util.Calendar.MINUTE, minute)
            set(java.util.Calendar.SECOND, 0)
        }
        
        val intent = Intent(this, SecurityForegroundService::class.java).apply {
            action = "com.iot.nebulacontroller.ALARM_TRIGGER"
            putExtra("targetNode", relayId)
            putExtra("targetState", state)
            putExtra("deviceId", deviceId)
        }
        
        val pendingIntent = android.app.PendingIntent.getService(
            this, relayId.hashCode() + hour * 60 + minute,
            intent, android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
        )
        
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as android.app.AlarmManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            alarmManager.setExactAndAllowWhileIdle(
                android.app.AlarmManager.RTC_WAKEUP,
                calendar.timeInMillis,
                pendingIntent
            )
        } else {
            alarmManager.setExact(
                android.app.AlarmManager.RTC_WAKEUP,
                calendar.timeInMillis,
                pendingIntent
            )
        }
        Log.d("SecurityService", "Scheduled Alarm for $relayId at $hour:$minute")
    }

    private fun triggerNativeAlarm(sensorName: String) {
        // 1. Play Loud Alarm Sound
        playAlarmSound()

        // 2. Build notification channel
        val channelId = "nebula_alarm_channel_v2"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "CRITICAL ALARM",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                setSound(null, null)
                enableVibration(false) // We handle vibration ourselves
            }
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }

        // 3. PendingIntent to open AlarmActivity on notification tap
        val alarmIntent = Intent(this, AlarmActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("sensorName", sensorName)
        }
        val fullScreenIntent = android.app.PendingIntent.getActivity(
            this, 0, alarmIntent,
            android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
        )

        // 4. DISMISS action — stops siren directly from notification
        val stopIntent = Intent(this, SecurityForegroundService::class.java).apply {
            action = "STOP_ALARM"
        }
        val stopPendingIntent = android.app.PendingIntent.getService(
            this, 1, stopIntent,
            android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
        )

        // 5. Show high-priority full-screen notification
        // NOTE: We do NOT call startActivity() here — that caused the "auto-touch" bug.
        // Android's FullScreenIntent handles lock-screen display natively.
        val notification = NotificationCompat.Builder(this, channelId)
            .setContentTitle("🚨 SECURITY BREACH!")
            .setContentText("$sensorName triggered at your home.")
            .setSmallIcon(R.mipmap.launcher_icon)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setFullScreenIntent(fullScreenIntent, true)
            .addAction(0, "STOP BUZZER", stopPendingIntent)
            .setOngoing(true) // Keep it in notification bar until dismissed
            .setAutoCancel(false)
            .build()

        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(999, notification)

        Log.d("SecurityService", "Native alarm triggered for: $sensorName")
        // DO NOT call startActivity() here - it caused the app auto-open bug
    }

    private fun playAlarmSound() {
        try {
            if (mediaPlayer?.isPlaying == true) return

            val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val customPath = prefs.getString("flutter.custom_alarm_path", null)
            
            val alarmUri: Uri = if (customPath != null && java.io.File(customPath).exists()) {
                Uri.fromFile(java.io.File(customPath))
            } else {
                // Try res/raw/siren
                val resId = resources.getIdentifier("siren", "raw", packageName)
                if (resId != 0) {
                    Uri.parse("android.resource://$packageName/$resId")
                } else {
                    RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                        ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
                }
            }

            Log.d("SecurityService", "Playing Alarm Sound from: $alarmUri")

            mediaPlayer = MediaPlayer().apply {
                setDataSource(applicationContext, alarmUri)
                setAudioStreamType(android.media.AudioManager.STREAM_ALARM)
                isLooping = true
                prepare()
                start()
            }

            // High-power vibration pattern
            val vibrator = getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                vibrator.vibrate(VibrationEffect.createWaveform(longArrayOf(0, 800, 300, 800), 0))
            } else {
                @Suppress("DEPRECATION")
                vibrator.vibrate(longArrayOf(0, 800, 300, 800), 0)
            }
        } catch (e: Exception) {
            Log.e("SecurityService", "Error playing alarm sound", e)
        }
    }

    private fun disableHardwareBuzzer() {
        try {
            val fb = if (databaseUrl.isNotEmpty()) FirebaseDatabase.getInstance(databaseUrl) else FirebaseDatabase.getInstance()
            val commandRef = fb.getReference("devices/$deviceId/commands")
            val securityRef = fb.getReference("devices/$deviceId/security")
            
            // 1. Send silent command to ESP32
            commandRef.child("alarm_disable").setValue(true)
            
            // 2. Clear visual alarm state in Firebase
            securityRef.child("alarmActive").setValue(false)
            
            Log.d("SecurityService", "Hardware buzzer disabled from notification")
        } catch (e: Exception) {
            Log.e("SecurityService", "Error disabling hardware buzzer", e)
        }
    }

    private fun stopAlarmSound() {
        try {
            mediaPlayer?.stop()
            mediaPlayer?.release()
            mediaPlayer = null

            val vibrator = getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
            vibrator.cancel()

            // Cancel the alarm notification
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.cancel(999)
        } catch (e: Exception) {
            Log.e("SecurityService", "Error stopping alarm sound", e)
        }
    }

    override fun onDestroy() {
        val db = FirebaseDatabase.getInstance().getReference("devices/$deviceId/security")
        databaseListener?.let { db.child("sensors").removeEventListener(it) }
        isArmedListener?.let { db.child("isArmed").removeEventListener(it) }
        schedulesListener?.let { 
            FirebaseDatabase.getInstance().getReference("devices/$deviceId/schedules").removeEventListener(it)
        }
        activePeriodsListener?.let {
            FirebaseDatabase.getInstance().getReference("devices/$deviceId/security/activePeriods").removeEventListener(it)
        }
        stopAlarmSound()
        super.onDestroy()
    }
}
