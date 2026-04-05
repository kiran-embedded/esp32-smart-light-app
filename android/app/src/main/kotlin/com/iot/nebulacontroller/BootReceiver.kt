package com.iot.nebulacontroller

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED || intent.action == "android.intent.action.QUICKBOOT_POWERON") {
            Log.d("BootReceiver", "Device Rebooted. Rescheduling Alarms...")
            rescheduleAllAlarms(context)
        }
    }

    private fun rescheduleAllAlarms(context: Context) {
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val schedulesJson = prefs.getString("flutter.switch_schedules", null)
        val deviceId = prefs.getString("flutter.esp32_device_id", "esp32_001") ?: "esp32_001"

        if (schedulesJson == null) {
            Log.d("BootReceiver", "No schedules found to reschedule.")
            return
        }

        try {
            val schedules = JSONArray(schedulesJson)
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as android.app.AlarmManager
            val now = System.currentTimeMillis()

            for (i in 0 until schedules.length()) {
                val s = schedules.getJSONObject(i)
                if (!s.optBoolean("isEnabled", true)) continue

                val id = s.getString("id").hashCode()
                val hour = s.getInt("hour")
                val minute = s.getInt("minute")
                val node = s.getString("targetNode")
                val state = s.getBoolean("targetState")
                val days = s.getJSONArray("days")

                // Calculate next occurrence
                val calendar = Calendar.getInstance()
                calendar.set(Calendar.HOUR_OF_DAY, hour)
                calendar.set(Calendar.MINUTE, minute)
                calendar.set(Calendar.SECOND, 0)
                calendar.set(Calendar.MILLISECOND, 0)

                if (calendar.timeInMillis <= now) {
                    calendar.add(Calendar.DAY_OF_YEAR, 1)
                }

                // If specific days are selected, find the next matching day
                if (days.length() > 0) {
                    val daysList = mutableListOf<Int>()
                    for (j in 0 until days.length()) {
                        // Flutter 1(Mon)-7(Sun) -> Calendar 2(Mon)-1(Sun)
                        val flutterDay = days.getInt(j)
                        val androidDay = if (flutterDay == 7) Calendar.SUNDAY else flutterDay + 1
                        daysList.add(androidDay)
                    }

                    var count = 0
                    while (!daysList.contains(calendar.get(Calendar.DAY_OF_WEEK)) && count < 7) {
                        calendar.add(Calendar.DAY_OF_YEAR, 1)
                        count++
                    }
                }

                val triggerTime = calendar.timeInMillis
                Log.d("BootReceiver", "Rescheduling #$id for $node at ${calendar.time}")

                val alarmIntent = Intent(context, NativeAlarmReceiver::class.java).apply {
                    action = "com.iot.nebulacontroller.ALARM_TRIGGER"
                    putExtra("targetNode", node)
                    putExtra("targetState", state)
                    putExtra("deviceId", deviceId)
                }

                val pendingIntent = android.app.PendingIntent.getBroadcast(
                    context,
                    id,
                    alarmIntent,
                    android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
                )

                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.LOLLIPOP) {
                    val showIntent = Intent(context, MainActivity::class.java)
                    val showPendingIntent = android.app.PendingIntent.getActivity(
                        context,
                        id,
                        showIntent,
                        android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
                    )
                    val alarmClockInfo = android.app.AlarmManager.AlarmClockInfo(triggerTime, showPendingIntent)
                    alarmManager.setAlarmClock(alarmClockInfo, pendingIntent)
                } else {
                    alarmManager.setExact(android.app.AlarmManager.RTC_WAKEUP, triggerTime, pendingIntent)
                }
            }
        } catch (e: Exception) {
            Log.e("BootReceiver", "Error rescheduling: ${e.message}")
        }
    }
}
