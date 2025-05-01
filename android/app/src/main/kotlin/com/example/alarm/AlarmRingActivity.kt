package com.example.alarm

import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.view.WindowManager
import android.widget.Button // Button importu
import android.widget.TextView // TextView importu (opsiyonel)
import androidx.appcompat.app.AppCompatActivity // AppCompatActivity kullan

class AlarmRingActivity : AppCompatActivity() { // AppCompatActivity'den türet

    private var wakeLock: PowerManager.WakeLock? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        println("Native AlarmRingActivity created")

        // Ekranı aç ve kilidi kaldır (API seviyesine göre ayarla)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
            // KeyguardManager ile dismiss denenebilir ama genellikle showWhenLocked yeterli
        } else {
            window.addFlags(
                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                        WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
                        WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                        WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            )
        }
        // Ekranı uyanık tutmak için
        try {
            val powerManager = getSystemService(POWER_SERVICE) as PowerManager
            wakeLock = powerManager.newWakeLock(
                PowerManager.FULL_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP,
                "alarm::wakelock" // İsimlendirme kuralına dikkat
            )
            wakeLock?.acquire(1 * 60 * 1000L /*1 minute*/) // 1 dakika sonra otomatik bırak
        } catch (e: Exception) {
            println("Wakelock acquire error: $e")
        }


        // Layout'u set et
        setContentView(R.layout.activity_alarm_ring)

        // Alarm ID'yi al (opsiyonel, UI'da göstermek için)
        val alarmId = intent.getIntExtra("id", -1) // ID'yi Int olarak al
        println("Native AlarmRingActivity received ID: $alarmId")
        // val alarmLabel = intent.getStringExtra("label") ?: ""
        // val titleTextView = findViewById<TextView>(R.id.textViewAlarmTitle)
        // titleTextView.text = alarmLabel.ifEmpty { "UYANMA ZAMANI!" }

        // Kapat butonuna listener ekle
        val dismissButton = findViewById<Button>(R.id.buttonDismiss)
        dismissButton.setOnClickListener {
            stopRingService()
            finishAndRemoveTask() // Activity'yi tamamen kapat
        }
    }

    private fun stopRingService() {
        println("Native AlarmRingActivity: Sending stop intent to RingService")
        val stopIntent = Intent(applicationContext, RingService::class.java).apply {
            action = RingService.ACTION_STOP
        }
        // Servisi durdurmak için startService kullanılır
        try {
            applicationContext.startService(stopIntent)
        } catch (e: Exception) {
            println("Error stopping RingService: $e")
            // Android 12+'da foreground service durdururken crash olabiliyor
            // stopForeground(true) ve stopSelf() RingService içinde çağrılıyor olmalı
        }

    }

    override fun onDestroy() {
        super.onDestroy()
        // WakeLock'ı serbest bırak
        if (wakeLock?.isHeld == true) {
            wakeLock?.release()
            println("Native AlarmRingActivity: Wakelock released")
        }
    }

    // Geri tuşunu engellemek isteyebilirsin (opsiyonel)
    override fun onBackPressed() {
        // super.onBackPressed() // Geri tuşunu devre dışı bırakmak için bu satırı yorumla
        println("Native AlarmRingActivity: Back press ignored")
    }
}