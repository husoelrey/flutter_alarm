package com.example.alarm

/**
 * Holds constant values used across the Android app.
 */
object Constants {
    const val CHANNEL_ID = "com.example.alarm/native"
    const val ALARM_PREFS = "alarm_prefs"
    
    // Intent Actions
    const val ACTION_START_RING = "com.example.alarm.ACTION_START_RING"
    const val ACTION_STOP_RING = "com.example.alarm.ACTION_STOP_RING"
    
    // Extras Keys
    const val EXTRA_ALARM_ID = "ALARM_ID"
    const val EXTRA_IS_REPEATING = "IS_REPEATING"
    const val EXTRA_SOUND_PATH = "soundPath"
}
