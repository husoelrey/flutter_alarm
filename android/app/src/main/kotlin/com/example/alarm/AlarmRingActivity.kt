package com.example.alarm

import android.content.Intent
import android.os.Bundle
import android.os.PowerManager
import android.view.WindowManager
import androidx.appcompat.app.AppCompatActivity
import io.flutter.embedding.android.FlutterActivity

class AlarmRingActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        println("AlarmRingActivity created")

        // Ekranı aç ve kilidi kaldır
        window.addFlags(
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                    WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
                    WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
        )

        // Ekranı uyandırmak için wake lock kullan (maks. 60 saniye)
        val powerManager = getSystemService(POWER_SERVICE) as PowerManager
        val wakeLock = powerManager.newWakeLock(
            PowerManager.FULL_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP,
            "alarm:wakelock"
        )
        wakeLock.acquire(60 * 1000L) // 1 dakika

        // Alarm ID'yi al
        val alarmId = intent.getStringExtra("id") ?: "-1"
        println("Received alarm ID: $alarmId")

        // FlutterActivity'yi başlat
        val flutterIntent = FlutterActivity
            .withNewEngine()
            .initialRoute("/ring?id=$alarmId")
            .build(this)

        startActivity(flutterIntent)

        // Bu Activity'yi bitir (arka planda kalmasın)
        finish()
    }
}
