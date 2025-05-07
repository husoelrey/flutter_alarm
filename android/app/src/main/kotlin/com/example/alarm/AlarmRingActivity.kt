package com.example.alarm

import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.icu.text.SimpleDateFormat
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.util.Log
import android.view.WindowManager
import android.widget.Button
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import org.json.JSONObject
import java.util.Date
import java.util.Locale

class AlarmRingActivity : AppCompatActivity() {

    private var wakeLock: PowerManager.WakeLock? = null
    private val TAG = "AlarmRingActivity"

    private val PREFS_NAME = "FlutterSharedPreferences"
    private val ALARMS_KEY = "flutter.alarms_list"
    private val ID_KEY = "id"
    private val LABEL_KEY = "label"
    private val IS_ACTIVE_KEY = "isActive"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d(TAG, "onCreate started")

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
                setShowWhenLocked(true)
                setTurnScreenOn(true)
            } else {
                window.addFlags(
                    WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                            WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
                            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
                )
            }
            Log.d(TAG, "Show/Turn flags set")
        } catch (e: Exception) {
            Log.e(TAG, "Error setting window flags", e)
        }

        try {
            val powerManager = getSystemService(POWER_SERVICE) as PowerManager
            wakeLock = powerManager.newWakeLock(
                PowerManager.FULL_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP,
                "$packageName::AlarmWakeLock"
            )
            wakeLock?.acquire(2 * 60 * 1000L)
            Log.d(TAG, "Wakelock acquired")
        } catch (e: Exception) {
            Log.e(TAG, "Error acquiring wakelock", e)
        }

        try {
            setContentView(R.layout.activity_alarm_ring)
            Log.d(TAG, "Layout activity_alarm_ring set")
        } catch (e: Exception) {
            Log.e(TAG, "Error setting content view", e)
            finish()
            return
        }

        val textViewTime: TextView? = findViewById(R.id.textViewTime)
        val textViewDate: TextView? = findViewById(R.id.textViewDate)
        val textViewLabel: TextView? = findViewById(R.id.textViewLabel)
        val buttonDismiss: Button? = findViewById(R.id.buttonDismiss)

        if (textViewTime == null || textViewDate == null || textViewLabel == null || buttonDismiss == null) {
            Log.e(TAG, "One or more views not found in layout!")
            finish()
            return
        }

        val alarmId = intent.getIntExtra("id", -1)
        Log.d(TAG, "Received alarm ID: $alarmId")

        if (alarmId == -1) {
            Log.e(TAG, "Geçersiz alarmId: $alarmId")
            finish()
            return
        }

        // 🔹 ADIM: Tek seferlik alarmı pasifleştir (SharedPreferences içinde)
        deactivateOneShotAlarmInPrefs(alarmId)

        val currentTime = Date()
        val timeFormatter = SimpleDateFormat("HH:mm", Locale("tr", "TR"))
        val dateFormatter = SimpleDateFormat("d MMMM EEEE", Locale("tr", "TR"))

        textViewTime.text = timeFormatter.format(currentTime)
        textViewDate.text = dateFormatter.format(currentTime)

        val alarmLabel = getAlarmLabelFromPrefs(alarmId)
        if (!alarmLabel.isNullOrEmpty()) {
            textViewLabel.text = alarmLabel
            Log.d(TAG, "Displaying fetched label: $alarmLabel")
        } else {
            textViewLabel.text = "Alarm (ID: $alarmId)"
            Log.d(TAG, "Label is null or empty, displaying ID.")
        }

        buttonDismiss.setOnClickListener {
            Log.d(TAG, "Dismiss button clicked for ID: $alarmId")
            stopRingService(alarmId)

            val flutterIntent = Intent(this, MainActivity::class.java).apply {
                putExtra("route", "/typing")
                putExtra("alarmId", alarmId)
            }
            startActivity(flutterIntent)
            finish()
        }

        Log.d(TAG, "onCreate finished successfully")
    }

    private fun getAlarmLabelFromPrefs(alarmId: Int): String? {
        if (alarmId == -1) return null
        return try {
            val prefs: SharedPreferences = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val alarmsJsonSet: Set<String>? = prefs.getStringSet(ALARMS_KEY, null)

            alarmsJsonSet?.forEach { alarmJsonString ->
                val jsonObject = JSONObject(alarmJsonString)
                val currentId = jsonObject.optInt(ID_KEY, -1)
                if (currentId == alarmId) {
                    val label = jsonObject.optString(LABEL_KEY, null)
                    return if (label.isNullOrEmpty()) null else label
                }
            }
            null
        } catch (e: Exception) {
            Log.e(TAG, "Error reading SharedPreferences for label", e)
            null
        }
    }

    private fun stopRingService(alarmId: Int) {
        Log.d(TAG, "Sending stop intent to RingService for ID: $alarmId")
        val stopIntent = Intent(applicationContext, RingService::class.java).apply {
            action = RingService.ACTION_STOP
            putExtra(RingService.EXTRA_ALARM_ID, alarmId)
        }
        try {
            applicationContext.startService(stopIntent)
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping RingService", e)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        if (wakeLock?.isHeld == true) {
            try {
                wakeLock?.release()
                Log.d(TAG, "Wakelock released")
            } catch (e: Exception) {
                Log.e(TAG, "Error releasing wakelock", e)
            }
        }
        Log.d(TAG, "onDestroy finished")
    }

    override fun onBackPressed() {
        Log.d(TAG, "Back button pressed, ignoring.")
    }

    // 🔧 Tek seferlik alarmı SharedPreferences içinde pasifleştirme
    private fun deactivateOneShotAlarmInPrefs(alarmId: Int) {
        try {
            val prefs: SharedPreferences = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val alarmsJsonSet = prefs.getStringSet(ALARMS_KEY, null)?.toMutableSet() ?: return
            val updatedAlarms = alarmsJsonSet.map { jsonStr ->
                try {
                    val json = JSONObject(jsonStr)
                    if (json.optInt(ID_KEY, -1) == alarmId) {
                        json.put(IS_ACTIVE_KEY, false)
                        Log.d(TAG, "Deactivated alarm ID $alarmId")
                    }
                    json.toString()
                } catch (e: Exception) {
                    Log.w(TAG, "Error parsing alarm JSON: $jsonStr", e)
                    jsonStr
                }
            }.toSet()
            prefs.edit().putStringSet(ALARMS_KEY, updatedAlarms).apply()
        } catch (e: Exception) {
            Log.e(TAG, "Error deactivating alarm in SharedPreferences", e)
        }
    }
}
