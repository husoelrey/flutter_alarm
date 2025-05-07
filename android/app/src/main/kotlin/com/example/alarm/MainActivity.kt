package com.example.alarm

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private var flutterEngineRef: FlutterEngine? = null

    private val NATIVE_CHANNEL = "com.example.alarm/native"
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
                        Log.d(TAG, "restartAlarmFromFlutter → ID=$id")

                        // 1) Sesi başlat
                        Intent(applicationContext, RingService::class.java).apply {
                            action = RingService.ACTION_START
                            putExtra(RingService.EXTRA_ALARM_ID, id)
                        }.also { startService(it) }

                        // 2) Alarm ekranını tekrar aç
                        Intent(applicationContext, AlarmRingActivity::class.java).apply {
                            putExtra("id", id)
                            addFlags(
                                Intent.FLAG_ACTIVITY_NEW_TASK or
                                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                                        Intent.FLAG_ACTIVITY_SINGLE_TOP
                            )
                        }.also { startActivity(it) }

                        result.success(null)
                    }

                    "scheduleNativeAlarm" -> {
                        val id = call.argument<Int>("id") ?: -1
                        val timeInMillis = call.argument<Long>("timeInMillis") ?: -1L
                        val isRepeating = call.argument<Boolean>("isRepeating") ?: false
                        if (id == -1 || timeInMillis == -1L) {
                            result.error("INVALID_ARGS", "Bad ID/time", null)
                            return@setMethodCallHandler
                        }
                        scheduleAlarm(id, timeInMillis, isRepeating)
                        result.success(true)
                    }

                    "cancelNativeAlarm" -> {
                        val id = call.argument<Int>("id") ?: -1
                        if (id == -1) {
                            result.error("INVALID_ID", "Bad ID", null)
                            return@setMethodCallHandler
                        }
                        cancelAlarm(id)
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

        if (route == "/typing" && alarmId != -1) {
            Log.d(TAG, "openTypingPage → ID=$alarmId")
            flutterEngineRef?.dartExecutor?.binaryMessenger?.let { messenger ->
                MethodChannel(messenger, NATIVE_CHANNEL)
                    .invokeMethod("openTypingPage", mapOf("alarmId" to alarmId))
            }
        }
    }


    private fun scheduleAlarm(id: Int, timeInMillis: Long, repeating: Boolean) {
        val mgr = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(this, AlarmTriggerReceiver::class.java).apply {
            putExtra("ALARM_ID", id)
            putExtra("IS_REPEATING", repeating)
            action = "com.example.alarm.ALARM_TRIGGER_$id"
        }
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        else PendingIntent.FLAG_UPDATE_CURRENT
        val pI = PendingIntent.getBroadcast(this, id, intent, flags)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !mgr.canScheduleExactAlarms()) {
            startActivity(
                Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            )
            Log.w(TAG, "Exact-alarm izni yok, kullanıcıya soruldu")
            return
        }

        mgr.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, timeInMillis, pI)
        Log.d(TAG, "Alarm scheduled → ID=$id, epoch=$timeInMillis")
    }

    private fun cancelAlarm(id: Int) {
        val mgr = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(this, AlarmTriggerReceiver::class.java).apply {
            action = "com.example.alarm.ALARM_TRIGGER_$id"
        }
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        else PendingIntent.FLAG_UPDATE_CURRENT
        mgr.cancel(PendingIntent.getBroadcast(this, id, intent, flags))
        Log.d(TAG, "Alarm cancelled → ID=$id")
    }
}
