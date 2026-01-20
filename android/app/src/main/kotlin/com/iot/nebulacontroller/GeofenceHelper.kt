package com.iot.nebulacontroller

import android.annotation.SuppressLint
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import com.google.android.gms.location.Geofence
import com.google.android.gms.location.GeofencingRequest
import com.google.android.gms.location.LocationServices

object GeofenceHelper {

    private const val PREFS_NAME = "GeofencePrefs"

    @SuppressLint("MissingPermission")
    fun addGeofence(
        context: Context,
        id: String,
        lat: Double,
        lng: Double,
        radius: Float,
        targetNode: String,
        targetState: Boolean,
        triggerOnEnter: Boolean,
        triggerOnExit: Boolean,
        deviceId: String
    ) {
        // 1. Save Full Data to SharedPrefs for Boot Persistence + Receiver Logic
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        // Format: "lat|lng|radius|targetNode|targetState|triggerOnEnter|triggerOnExit|deviceId"
        val data = "$lat|$lng|$radius|$targetNode|$targetState|$triggerOnEnter|$triggerOnExit|$deviceId"
        prefs.edit().putString(id, data).apply()

        // 2. Register with GeofencingClient
        registerWithClient(context, id, lat, lng, radius)
    }

    fun removeGeofence(context: Context, id: String) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().remove(id).apply()

        val client = LocationServices.getGeofencingClient(context)
        client.removeGeofences(listOf(id))
    }

    @SuppressLint("MissingPermission")
    fun reRegisterAll(context: Context) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val allRules = prefs.all

        for ((id, value) in allRules) {
            if (value is String) {
                // "lat|lng|radius|targetNode|targetState|triggerOnEnter|triggerOnExit|deviceId"
                val parts = value.split("|")
                if (parts.size >= 8) {
                    val lat = parts[0].toDoubleOrNull()
                    val lng = parts[1].toDoubleOrNull()
                    val radius = parts[2].toFloatOrNull()

                    if (lat != null && lng != null && radius != null) {
                        registerWithClient(context, id, lat, lng, radius)
                    }
                }
            }
        }
    }
    
    @SuppressLint("MissingPermission")
    private fun registerWithClient(context: Context, id: String, lat: Double, lng: Double, radius: Float) {
        val client = LocationServices.getGeofencingClient(context)

        val geofence = Geofence.Builder()
            .setRequestId(id)
            .setCircularRegion(lat, lng, radius)
            .setExpirationDuration(Geofence.NEVER_EXPIRE)
            .setTransitionTypes(Geofence.GEOFENCE_TRANSITION_ENTER or Geofence.GEOFENCE_TRANSITION_EXIT)
            .build()

        val request = GeofencingRequest.Builder()
            .setInitialTrigger(GeofencingRequest.INITIAL_TRIGGER_ENTER)
            .addGeofence(geofence)
            .build()
        
        val intent = Intent(context, GeofenceReceiver::class.java)
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
        )

        client.addGeofences(request, pendingIntent)
            .addOnFailureListener { e ->
                // Log failure? (This runs in background on boot, no UI)
            }
    }
}
