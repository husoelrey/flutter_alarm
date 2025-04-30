package com.example.alarm

import android.content.Intent
import android.os.Bundle
import android.util.Log
import android.view.WindowManager
import androidx.appcompat.app.AppCompatActivity   // ← BU SATIR KRİTİK
import io.flutter.embedding.android.FlutterActivity

class AlarmRingActivity : AppCompatActivity() {
    private val TAG = "AlarmRingActivity"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d(TAG, "AlarmRingActivity created")

        window.addFlags(
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
                    or WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
                    or WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED
                    or WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
        )

        val alarmId = intent.getStringExtra("id") ?: "-1"
        Log.d(TAG, "Received alarm ID: $alarmId")

        val intent = FlutterActivity
            .withNewEngine()
            .initialRoute("/ring?id=$alarmId")
            .build(this)

        startActivity(intent)
        finish()
    }
}
