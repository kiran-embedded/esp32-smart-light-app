package com.iot.nebulacontroller

import android.app.Application
import android.app.ActivityManager
import android.content.Context
import android.util.Log
import com.google.firebase.FirebaseApp

class NebulaApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        
        val processName = getProcessName(this)
        Log.d("NebulaApplication", "App started in process: $processName")

        if (processName != null && processName.endsWith(":security")) {
            // JVM Bootloader for the isolated process
            Log.d("NebulaApplication", "Initializing isolated Firebase Bootloader for :security process")
            
            // Explicitly initialize Firebase for Realtime Database connectivity in this isolated bubble
            if (FirebaseApp.getApps(this).isEmpty()) {
                FirebaseApp.initializeApp(this)
            }
            // By NOT invoking any Flutter mechanisms here, we keep the memory usage ~25MB
            // instead of mapping the 400MB Flutter UI engine into RAM.
        } else {
            // Main Flutter process
            Log.d("NebulaApplication", "Starting Main Flutter Process")
            // Flutter UI engine will natively be spun up by MainActivity (FlutterActivity)
        }
    }

    private fun getProcessName(context: Context): String? {
        val pid = android.os.Process.myPid()
        val manager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        for (processInfo in manager.runningAppProcesses ?: emptyList()) {
            if (processInfo.pid == pid) {
                return processInfo.processName
            }
        }
        return null
    }
}
