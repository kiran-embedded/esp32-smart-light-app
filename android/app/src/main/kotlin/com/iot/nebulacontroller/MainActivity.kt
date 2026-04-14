package com.iot.nebulacontroller

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.pm.PackageManager
import android.os.Build

import com.google.android.gms.location.LocationServices
import com.google.firebase.FirebaseApp
import android.content.Context
import android.content.Intent
import android.os.Bundle

import java.security.MessageDigest
import java.util.Locale

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.iot.nebulacontroller/native_scheduler"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        FirebaseApp.initializeApp(this)
        startSecurityService()
    }

    private fun startSecurityService() {
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val isEnabled = prefs.getBoolean("flutter.backgroundRunningEnabled", true)
        if (!isEnabled) return

        val intent = Intent(this, SecurityForegroundService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "schedule" -> {
                    val id = call.argument<Int>("id") ?: 0
                    val time = call.argument<Long>("time") ?: 0L
                    val node = call.argument<String>("targetNode")
                    val state = call.argument<Boolean>("targetState")
                    val deviceId = call.argument<String>("deviceId")

                    if(node != null && deviceId != null && state != null){
                        scheduleAlarm(id, time, node, state, deviceId)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGS", "Missing args", null)
                    }
                }
                "cancel" -> {
                   val id = call.argument<Int>("id") ?: 0
                   cancelAlarm(id)
                   result.success(null)
                }
                "executeAction" -> {
                    val node = call.argument<String>("targetNode")
                    val state = call.argument<Boolean>("targetState")
                    val deviceId = call.argument<String>("deviceId")
                    
                    if (node != null && state != null && deviceId != null) {
                        val intent = Intent(this@MainActivity, SecurityForegroundService::class.java).apply {
                            action = "com.iot.nebulacontroller.ALARM_TRIGGER"
                            putExtra("targetNode", node)
                            putExtra("targetState", state)
                            putExtra("deviceId", deviceId)
                        }
                        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }
                        result.success(null)
                    } else {
                        result.error("INVALID_ARGS", "Missing arguments", null)
                    }
                }
                "openBatterySettings" -> {
                    val intent = Intent()
                    intent.action = android.provider.Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS
                    intent.data = android.net.Uri.parse("package:$packageName")
                    try {
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERR", e.message, null)
                    }
                }
                "startNativeSecurity" -> {
                    val intent = Intent(this@MainActivity, SecurityForegroundService::class.java)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(intent)
                    } else {
                        startService(intent)
                    }
                    result.success(null)
                }
                "stopNativeSecurity" -> {
                    val intent = Intent(this@MainActivity, SecurityForegroundService::class.java)
                    stopService(intent)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        // Fingerprint Retrieval Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.nebula.core/fingerprints").setMethodCallHandler { call, result ->
            if (call.method == "getFingerprints") {
                val fingerprints = getFingerprints()
                if (fingerprints.isNotEmpty()) {
                    result.success(fingerprints)
                } else {
                    result.error("UNAVAILABLE", "Could not fetch fingerprints", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun getFingerprints(): Map<String, String> {
        val fingerprints = mutableMapOf<String, String>()
        try {
            val packageInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                packageManager.getPackageInfo(packageName, PackageManager.GET_SIGNING_CERTIFICATES)
            } else {
                @Suppress("DEPRECATION")
                packageManager.getPackageInfo(packageName, PackageManager.GET_SIGNATURES)
            }

            val signatures = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                packageInfo.signingInfo?.signingCertificateHistory
            } else {
                @Suppress("DEPRECATION")
                packageInfo.signatures
            }

            if (signatures != null) {
                for (signature in signatures) {
                    val mdSha1 = MessageDigest.getInstance("SHA1")
                    val sha1 = hexString(mdSha1.digest(signature.toByteArray()))
                    fingerprints["sha1"] = sha1

                    val mdSha256 = MessageDigest.getInstance("SHA256")
                    val sha256 = hexString(mdSha256.digest(signature.toByteArray()))
                    fingerprints["sha256"] = sha256
                    break 
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return fingerprints
    }

    private fun hexString(buffer: ByteArray): String {
        val hexArray = "0123456789ABCDEF".toCharArray()
        val hexChars = CharArray(buffer.size * 2)
        for (i in buffer.indices) {
            val v = buffer[i].toInt() and 0xFF
            hexChars[i * 2] = hexArray[v ushr 4]
            hexChars[i * 2 + 1] = hexArray[v and 0x0F]
        }
        return String(hexChars).chunked(2).joinToString(":").uppercase(Locale.ROOT)
    }


    private fun scheduleAlarm(id: Int, time: Long, node: String, state: Boolean, deviceId: String) {
        val alarmManager = getSystemService(android.content.Context.ALARM_SERVICE) as android.app.AlarmManager
        val intent = android.content.Intent(this, NativeAlarmReceiver::class.java).apply {
            putExtra("targetNode", node)
            putExtra("targetState", state)
            putExtra("deviceId", deviceId)
            action = "com.iot.nebulacontroller.ALARM_TRIGGER" 
        }

        val pendingIntent = android.app.PendingIntent.getBroadcast(
            this, 
            id, 
            intent, 
            android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
        )

        val showIntent = android.content.Intent(this, MainActivity::class.java)
        val showPendingIntent = android.app.PendingIntent.getActivity(
            this,
            id,
            showIntent,
            android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
        )

        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.LOLLIPOP) {
            val alarmClockInfo = android.app.AlarmManager.AlarmClockInfo(time, showPendingIntent)
            alarmManager.setAlarmClock(alarmClockInfo, pendingIntent)
        } else if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
            alarmManager.setExactAndAllowWhileIdle(
                android.app.AlarmManager.RTC_WAKEUP,
                time,
                pendingIntent
            )
        } else {
            alarmManager.setExact(
                android.app.AlarmManager.RTC_WAKEUP,
                time,
                pendingIntent
            )
        }
    }

    private fun cancelAlarm(id: Int) {
         val alarmManager = getSystemService(android.content.Context.ALARM_SERVICE) as android.app.AlarmManager
         val intent = android.content.Intent(this, NativeAlarmReceiver::class.java)
         intent.action = "com.iot.nebulacontroller.ALARM_TRIGGER"
         
         val pendingIntent = android.app.PendingIntent.getBroadcast(
            this,
            id,
            intent,
            android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
         )
         
         alarmManager.cancel(pendingIntent)
    }
}
