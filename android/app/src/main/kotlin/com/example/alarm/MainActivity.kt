package com.example.alarm

import android.content.Intent
import android.os.Bundle
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val NATIVE_CHANNEL = "com.example.alarm/native"
    private val ALARM_ACTION   = "com.example.alarm.ACTION_FIRE_ALARM"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NATIVE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "fireNativeReceiver" -> {
                        val id = (call.argument<Int>("id") ?: -1).toString()
                        sendBroadcast(Intent(ALARM_ACTION).apply {
                            putExtra("id", id)
                        })
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
