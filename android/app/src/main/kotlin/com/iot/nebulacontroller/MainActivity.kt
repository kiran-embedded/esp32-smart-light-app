package com.iot.nebulacontroller

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.pm.PackageManager
import android.os.Build
import com.google.android.gms.location.GeofencingClient
import com.google.android.gms.location.LocationServices
import android.content.Context
import android.content.Intent

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.iot.nebulacontroller/native_scheduler"

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
                        val intent = android.content.Intent(this, NativeAlarmService::class.java).apply {
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
                "addGeofence" -> {
                    val id = call.argument<String>("id")
                    val lat = call.argument<Double>("latitude")
                    val lng = call.argument<Double>("longitude")
                    val radius = call.argument<Double>("radius")
                    val triggerOnEnter = call.argument<Boolean>("triggerOnEnter") ?: true
                    val triggerOnExit = call.argument<Boolean>("triggerOnExit") ?: false
                    val node = call.argument<String>("targetNode")
                    val state = call.argument<Boolean>("targetState") ?: true
                    val deviceId = call.argument<String>("deviceId")

                    if (id != null && lat != null && lng != null && radius != null && node != null && deviceId != null) {
                        GeofenceHelper.addGeofence(
                            this, id, lat, lng, radius.toFloat(), node, state, triggerOnEnter, triggerOnExit, deviceId
                        )
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGS", "Missing geofence args", null)
                    }
                }
                "removeGeofence" -> {
                     val id = call.argument<String>("id")
                     if (id != null) {
                         GeofenceHelper.removeGeofence(this, id)
                         result.success(true)
                     } else {
                         result.error("INVALID_ARGS", "Missing id", null)
                     }
                }
                else -> result.notImplemented()
            }
        }
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
