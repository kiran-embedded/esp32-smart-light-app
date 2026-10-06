package com.aurexa.app

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
    private val CHANNEL = "com.aurexa.app/native_scheduler"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        FirebaseApp.initializeApp(this)
        // startSecurityService() - Disabled per user request
    }

    private fun startSecurityService() {
        // Disabled per user request
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "schedule" -> {
                    // Deprecated: Handled natively by ESP32 NTP Hardware Scheduler
                    result.success(true);
                }
                "cancel" -> {
                    // Deprecated: Handled natively by ESP32 NTP Hardware Scheduler
                    result.success(null)
                }
                "executeAction" -> {
                    // Native execution removed; use direct Firebase SDK
                    result.success(null)
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



}
