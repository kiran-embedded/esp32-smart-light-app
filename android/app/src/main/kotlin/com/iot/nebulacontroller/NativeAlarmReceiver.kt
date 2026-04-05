package com.iot.nebulacontroller

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.database.FirebaseDatabase

class NativeAlarmReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val pendingResult = goAsync()
        
        try {
            val serviceIntent = Intent(context, SecurityForegroundService::class.java).apply {
                action = "com.iot.nebulacontroller.ALARM_TRIGGER"
                putExtras(intent)
            }
            
            Log.d("NativeReceiver", "Forwarding intent to Unified Security Service")
            
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                context.startForegroundService(serviceIntent)
            } else {
                context.startService(serviceIntent)
            }
        } finally {
            pendingResult.finish()
        }
    }
}
