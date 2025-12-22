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

        // --- Start ONLY RingService ---
        // The service will now trigger the UI via FullScreen Intent.
        Log.d(TAG, "Starting RingService for ID: $alarmId")
        val serviceIntent = Intent(context, RingService::class.java).apply {
            action = Constants.ACTION_START_RING
            putExtra(Constants.EXTRA_ALARM_ID, alarmId) // Send Alarm ID to the service
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

        // --- Logic to reschedule repeating alarm (Still under development) ---
        val isRepeating = intent.getBooleanExtra(Constants.EXTRA_IS_REPEATING, false)
        if (isRepeating) {
            Log.d(TAG, "Alarm ID $alarmId is repeating. Needs rescheduling (Not implemented here).")
            // NativeAlarmScheduler.rescheduleRepeatingAlarm(context, alarmId)
        } else {
            Log.d(TAG, "Alarm ID $alarmId is one-shot.")
        }

        Log.d(TAG, "onReceive finished for ID: $alarmId") // Receiver finished log
    }

}
