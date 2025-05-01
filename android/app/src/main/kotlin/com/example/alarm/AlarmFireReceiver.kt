package com.example.alarm


import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import android.os.Build
// AlarmFireReceiver.kt



class AlarmFireReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        // Alarm ID'yi al (Flutter UI'a göndermek için)
        val alarmIdStr = intent.getStringExtra("id") ?: "-1"
        Log.d("AlarmFireReceiver", "Broadcast alındı, id = $alarmIdStr")

        // 1. RingService'i başlat (Sesi çalmak için)
        val serviceIntent = Intent(context, RingService::class.java).apply {
            action = RingService.ACTION_START
        }
        // Android O+'da foreground service başlatma yöntemi farklı
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(serviceIntent)
        } else {
            context.startService(serviceIntent)
        }

        // 2. Tam ekran UI Activity'sini başlat (AlarmRingActivity -> Flutter)
        val ringUiIntent = Intent(context, AlarmRingActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            putExtra("id", alarmIdStr) // Alarm ID'yi UI'a ilet
        }
        context.startActivity(ringUiIntent)
    }
}