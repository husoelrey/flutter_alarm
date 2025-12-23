package com.example.alarm

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import android.util.Log

/**
 * A helper object to handle alarm scheduling logic.
 * This keeps MainActivity clean and focused on Flutter communication.
 */
object AlarmScheduler {

    private const val TAG = "AlarmScheduler"

    /**
     * Schedules an exact alarm.
     */
    fun scheduleAlarm(context: Context, id: Int, timeInMillis: Long, repeating: Boolean) {
        val mgr = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        
        // Create the intent that will trigger our BroadcastReceiver
        val intent = Intent(context, AlarmTriggerReceiver::class.java).apply {
            putExtra("ALARM_ID", id)
            putExtra("IS_REPEATING", repeating)
            action = "com.example.alarm.ALARM_TRIGGER_$id"
        }

        // PendingIntent flags
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        else PendingIntent.FLAG_UPDATE_CURRENT

        val pI = PendingIntent.getBroadcast(context, id, intent, flags)

        // Check for exact alarm permission on Android 12+ (API 31+)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !mgr.canScheduleExactAlarms()) {
            val intentSettings = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intentSettings)
            Log.w(TAG, "Exact alarm permission is missing; prompted the user.")
            return
        }

        // Schedule the alarm using setAlarmClock for maximum reliability
        // This makes the alarm visible in the status bar and ensures it rings even in Doze mode.
        val alarmClockInfo = AlarmManager.AlarmClockInfo(timeInMillis, pI)
        mgr.setAlarmClock(alarmClockInfo, pI)
        
        Log.d(TAG, "Alarm scheduled using setAlarmClock -> ID=$id, time=$timeInMillis, repeating=$repeating")
    }

    /**
     * Cancels an existing alarm.
     */
    fun cancelAlarm(context: Context, id: Int) {
        val mgr = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        
        val intent = Intent(context, AlarmTriggerReceiver::class.java).apply {
            action = "com.example.alarm.ALARM_TRIGGER_$id"
        }

        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        else PendingIntent.FLAG_UPDATE_CURRENT

        val pI = PendingIntent.getBroadcast(context, id, intent, flags)
        
        mgr.cancel(pI)
        Log.d(TAG, "Alarm cancelled -> ID=$id")
    }
}
