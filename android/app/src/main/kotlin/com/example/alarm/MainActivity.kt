package com.example.alarm

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private var flutterEngineRef: FlutterEngine? = null

    // Use constants from our new Constants object
    private val NATIVE_CHANNEL = Constants.CHANNEL_ID
    private val TAG = "MainActivity"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngineRef = flutterEngine

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NATIVE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {

                    "restartAlarmFromFlutter" -> {
                        val id = call.argument<Int>("alarmId") ?: -1
                        if (id == -1) {
                            result.error("INVALID_ID", "Alarm ID is missing", null)
                            return@setMethodCallHandler
                        }
                        Log.d(TAG, "restartAlarmFromFlutter -> ID=$id")

                        // 1. Start the audio service
                        val serviceIntent = Intent(applicationContext, RingService::class.java).apply {
                            action = Constants.ACTION_START_RING
                            putExtra(Constants.EXTRA_ALARM_ID, id)
                        }
                        startService(serviceIntent)

                        // 2. Re-open the alarm screen
                        val activityIntent = Intent(applicationContext, AlarmRingActivity::class.java).apply {
                            putExtra("id", id)
                            addFlags(
                                Intent.FLAG_ACTIVITY_NEW_TASK or
                                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                                        Intent.FLAG_ACTIVITY_SINGLE_TOP
                            )
                        }
                        startActivity(activityIntent)

                        result.success(null)
                    }

                    "scheduleNativeAlarm" -> {
                        val id = call.argument<Int>("id") ?: -1
                        val timeInMillis = call.argument<Long>("timeInMillis") ?: -1L
                        val isRepeating = call.argument<Boolean>("isRepeating") ?: false
                        val soundPath = call.argument<String>("soundPath") ?: ""

                        if (id == -1 || timeInMillis == -1L) {
                            result.error("INVALID_ARGS", "Bad ID/time", null)
                            return@setMethodCallHandler
                        }

                        // Save sound path (helper function at bottom)
                        saveSoundPathForAlarm(id, soundPath)

                        // DELEGATE TO ALARM SCHEDULER
                        AlarmScheduler.scheduleAlarm(this, id, timeInMillis, isRepeating)
                        
                        result.success(true)
                    }

                    "cancelNativeAlarm" -> {
                        val id = call.argument<Int>("id") ?: -1
                        if (id == -1) {
                            result.error("INVALID_ID", "Bad ID", null)
                            return@setMethodCallHandler
                        }
                        
                        // DELEGATE TO ALARM SCHEDULER
                        AlarmScheduler.cancelAlarm(this, id)
                        
                        result.success(true)
                    }

                    else -> result.notImplemented()
                }
            }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val route = intent?.getStringExtra("route")
        val alarmId = intent?.getIntExtra("alarmId", -1) ?: -1

        // Handle navigation requests from native notification actions
        if (alarmId != -1) {
            when (route) {
                "/typing" -> {
                    Log.d(TAG, "openTypingPage -> ID=$alarmId")
                    invokeFlutterMethod("openTypingPage", alarmId)
                }
                "/memory" -> {
                    Log.d(TAG, "openMemoryPage -> ID=$alarmId")
                    invokeFlutterMethod("openMemoryPage", alarmId)
                }
            }
        }
    }

    // Helper to send method calls to Flutter
    private fun invokeFlutterMethod(method: String, alarmId: Int) {
        flutterEngineRef?.dartExecutor?.binaryMessenger?.let { messenger ->
            MethodChannel(messenger, NATIVE_CHANNEL)
                .invokeMethod(method, mapOf("alarmId" to alarmId))
        }
    }

    private fun saveSoundPathForAlarm(alarmId: Int, path: String) {
        val prefs = getSharedPreferences(Constants.ALARM_PREFS, MODE_PRIVATE)
        prefs.edit().putString("soundPath_$alarmId", path).apply()
        Log.d(TAG, "Sound path saved -> ID=$alarmId, path=$path")
    }
}