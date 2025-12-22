package com.example.alarm

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

class AlarmFireReceiver : BroadcastReceiver() {

    companion object {
        const val ACTION_START = "com.example.alarm.ACTION_START"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val alarmIdStr = intent.getStringExtra("id") ?: "-1"
        Log.d("AlarmFireReceiver", "Broadcast received for alarm ID: $alarmIdStr")

        // 1. Start RingService to play the alarm sound
        val serviceIntent = Intent(context, RingService::class.java).apply {
            // Use the action defined in RingService itself for consistency
            action = RingService.ACTION_START
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(serviceIntent)
        } else {
            context.startService(serviceIntent)
        }

        // 2. Start the full-screen UI (AlarmRingActivity which hosts Flutter)
        val ringUiIntent = Intent(context, AlarmRingActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            putExtra("id", alarmIdStr) // Pass the alarm ID to the UI
        }
        context.startActivity(ringUiIntent)
    }
}
