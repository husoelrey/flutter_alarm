package com.example.alarm

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

class AlarmTriggerReceiver : BroadcastReceiver() {

    private val TAG = "AlarmTriggerReceiver"

    override fun onReceive(context: Context, intent: Intent) {
        val alarmId = intent.getIntExtra("ALARM_ID", -1)
        Log.d(TAG, "Alarm triggered for ID: $alarmId")

        if (alarmId == -1) {
            Log.e(TAG, "Invalid alarm ID received.")
            return
        }

        // --- SADECE RingService'i Başlat ---
        // Servis artık FullScreen Intent ile UI'ı tetikleyecek.
        Log.d(TAG, "Starting RingService for ID: $alarmId")
        val serviceIntent = Intent(context, RingService::class.java).apply {
            action = RingService.ACTION_START
            putExtra(RingService.EXTRA_ALARM_ID, alarmId) // Alarm ID'yi servise gönder
        }
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(serviceIntent)
            } else {
                context.startService(serviceIntent)
            }
            Log.d(TAG, "RingService start requested.")
        } catch (e: Exception) {
            Log.e(TAG, "Error starting RingService", e)
        }

        // --- AlarmRingActivity'yi başlatma kodunu KALDIRDIK ---
        /*
        Log.d(TAG, "Starting AlarmRingActivity for ID: $alarmId")
        val ringUiIntent = Intent(context, AlarmRingActivity::class.java).apply {
            // ... flags and extras ...
        }
        context.startActivity(ringUiIntent)
        */

        // --- Tekrarlayan Alarmı Yeniden Kurma Mantığı (Hala geliştirilmeli) ---
        val isRepeating = intent.getBooleanExtra("IS_REPEATING", false)
        if (isRepeating) {
            Log.d(TAG, "Alarm ID $alarmId is repeating. Needs rescheduling (Not implemented here).")
            // NativeAlarmScheduler.rescheduleRepeatingAlarm(context, alarmId)
        } else {
            Log.d(TAG, "Alarm ID $alarmId is one-shot.")
        }

        Log.d(TAG, "onReceive finished for ID: $alarmId") // Receiver bitti logu
    }

}
