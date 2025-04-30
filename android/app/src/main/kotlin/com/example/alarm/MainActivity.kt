package com.example.alarm

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.os.PowerManager
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.alarm/alarm_channel"
    private val TAG = "MainActivity"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            
            when (call.method) {
                "launchAlarmScreen" -> {
                    val id = call.argument<Int>("id") ?: -1
                    launchAlarmScreen(id)
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    private fun launchAlarmScreen(alarmId: Int) {
        Log.d(TAG, "Launching alarm screen with ID: $alarmId")
        val intent = Intent(this, AlarmRingActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            putExtra("id", alarmId.toString())
        }
        startActivity(intent)
    }
}
