package com.iot.nebulacontroller

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.pm.PackageManager
import android.os.Build
import java.security.MessageDigest
import java.io.ByteArrayInputStream
import java.security.cert.CertificateFactory
import java.security.cert.X509Certificate

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.nebula.core/fingerprints"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getFingerprints" -> {
                    val fingerprints = mutableMapOf<String, String>()
                    fingerprints["sha1"] = getFingerprint("SHA-1")
                    fingerprints["sha256"] = getFingerprint("SHA-256")
                    result.success(fingerprints)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun getFingerprint(type: String): String {
        try {
            val packageInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                packageManager.getPackageInfo(packageName, PackageManager.GET_SIGNING_CERTIFICATES)
            } else {
                packageManager.getPackageInfo(packageName, PackageManager.GET_SIGNATURES)
            }

            val signatures = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                packageInfo?.signingInfo?.signingCertificateHistory
            } else {
                packageInfo?.signatures
            }

            if (signatures != null) {
                for (signature in signatures) {
                    val md = MessageDigest.getInstance(type)
                    val digest = md.digest(signature.toByteArray())
                    val hexString = StringBuilder()
                    for (b in digest) {
                        val hex = Integer.toHexString(0xFF and b.toInt())
                        if (hex.length == 1) hexString.append('0')
                        hexString.append(hex.uppercase())
                        hexString.append(':')
                    }
                    return hexString.toString().removeSuffix(":")
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return "Not Available"
    }
}

