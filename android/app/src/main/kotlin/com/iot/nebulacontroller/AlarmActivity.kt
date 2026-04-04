package com.iot.nebulacontroller

import android.app.Activity
import android.app.KeyguardManager
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.Typeface
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.view.Gravity
import android.view.WindowManager
import android.widget.Button
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.TextView

/**
 * Pure native alarm screen — extends Activity (not FlutterActivity).
 * Boots instantly (<100ms). No Flutter engine needed for alarm UI.
 */
class AlarmActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d("AlarmActivity", "Native Alarm Activity Created")

        // Show over lock screen and turn on screen
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
            val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
            keyguardManager.requestDismissKeyguard(this, null)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            )
        }
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

        val sensorName = intent.getStringExtra("sensorName") ?: "Unknown Sensor"

        // Build native UI programmatically
        val root = FrameLayout(this)
        root.setBackgroundColor(Color.parseColor("#0A0A0A"))

        val column = LinearLayout(this)
        column.orientation = LinearLayout.VERTICAL
        column.gravity = Gravity.CENTER
        column.setPadding(64, 0, 64, 0)

        val warningIcon = TextView(this)
        warningIcon.text = "🚨"
        warningIcon.textSize = 72f
        warningIcon.gravity = Gravity.CENTER

        val titleText = TextView(this)
        titleText.text = "SECURITY BREACH"
        titleText.textSize = 28f
        titleText.setTextColor(Color.parseColor("#FF4D4D"))
        titleText.gravity = Gravity.CENTER
        titleText.setPadding(0, 32, 0, 0)
        titleText.setTypeface(null, Typeface.BOLD)

        val sensorText = TextView(this)
        sensorText.text = sensorName.uppercase()
        sensorText.textSize = 18f
        sensorText.setTextColor(Color.parseColor("#AAAAAA"))
        sensorText.gravity = Gravity.CENTER
        sensorText.setPadding(0, 16, 0, 64)

        val dismissBtn = Button(this)
        dismissBtn.text = "DISMISS ALARM"
        dismissBtn.textSize = 16f
        dismissBtn.setTextColor(Color.WHITE)
        dismissBtn.setBackgroundColor(Color.parseColor("#FF4D4D"))
        val btnParams = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        )
        btnParams.setMargins(0, 0, 0, 24)
        dismissBtn.layoutParams = btnParams
        dismissBtn.setPadding(0, 32, 0, 32)
        dismissBtn.setOnClickListener { dismissAlarm() }

        column.addView(warningIcon)
        column.addView(titleText)
        column.addView(sensorText)
        column.addView(dismissBtn)

        val colParams = FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.MATCH_PARENT
        )
        colParams.gravity = Gravity.CENTER
        root.addView(column, colParams)
        setContentView(root)
    }

    private fun dismissAlarm() {
        val stopIntent = Intent(this, SecurityForegroundService::class.java).apply {
            action = "STOP_ALARM"
        }
        startService(stopIntent)
        finish()
    }
}
