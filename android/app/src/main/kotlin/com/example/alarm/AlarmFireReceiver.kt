package com.example.alarm


import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import android.os.Build
// AlarmFireReceiver.kt



class AlarmFireReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        // Retrieve Alarm ID (to send to Flutter UI)
        val alarmIdStr = intent.getStringExtra("id") ?: "-1"
        Log.d("AlarmFireReceiver", "Broadcast alındı, id = $alarmIdStr")

        // 1. Start RingService (to play sound)
        val serviceIntent = Intent(context, RingService::class.java).apply {
            action = RingService.ACTION_START
        }
        // Use correct method for starting foreground service on Android O+
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(serviceIntent)
        } else {
            context.startService(serviceIntent)
        }

        // 2. Start full-screen UI Activity (AlarmRingActivity -> Flutter)
        val ringUiIntent = Intent(context, AlarmRingActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            putExtra("id", alarmIdStr) // Pass Alarm ID to UI
        }
        context.startActivity(ringUiIntent)
    }
}