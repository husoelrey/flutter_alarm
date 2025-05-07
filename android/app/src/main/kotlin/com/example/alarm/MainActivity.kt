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

/** Ana Flutter activity – native alarm işlemleri + /typing sayfası geçişleri */
class MainActivity : FlutterActivity() {

    private val NATIVE_CHANNEL = "com.example.alarm/native"
    private val TAG            = "MainActivity"

    // ─────────────────────────────────────────────────────────────────────
    //  Flutter <‑> Native kanal köprüsü
    // ─────────────────────────────────────────────────────────────────────
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NATIVE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {

                    /** Flutter tarafı, yazma ekranından çıkıldığında alarmı yeniden
                     *  başlatmak için bu metodu çağırıyor. */
                    "restartAlarmFromFlutter" -> {
                        val id = call.argument<Int>("alarmId") ?: -1
                        if (id == -1) {
                            result.error("INVALID_ID", "Alarm ID is missing or invalid.", null)
                            return@setMethodCallHandler
                        }

                        Log.d(TAG, "restartAlarmFromFlutter for ID=$id")

                        // 1) Sesi yeniden başlat
                        Intent(applicationContext, RingService::class.java).apply {
                            action = RingService.ACTION_START
                            putExtra("alarm_id", id)
                        }.also { startService(it) }

                        // 2) AlarmRingActivity’yi tekrar aç
                        Intent(applicationContext, AlarmRingActivity::class.java).apply {
                            putExtra("id", id)
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK
                                    or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                        }.also { startActivity(it) }

                        result.success(null)
                    }

                    /** Yeni (veya güncellenmiş) bir alarmı programlar */
                    "scheduleNativeAlarm" -> {
                        val id           = call.argument<Int>("id") ?: -1
                        val timeInMillis = call.argument<Long>("timeInMillis") ?: -1L
                        val isRepeating  = call.argument<Boolean>("isRepeating") ?: false

                        if (id == -1 || timeInMillis == -1L) {
                            result.error("INVALID_ARGS",
                                "Invalid ID or timeInMillis for scheduling.", null)
                            return@setMethodCallHandler
                        }

                        scheduleAlarm(id, timeInMillis, isRepeating)
                        result.success(true)
                    }

                    /** Var‑olan bir alarmı iptal eder */
                    "cancelNativeAlarm" -> {
                        val id = call.argument<Int>("id") ?: -1
                        if (id == -1) {
                            result.error("INVALID_ARGS", "Invalid ID for cancelling.", null)
                            return@setMethodCallHandler
                        }
                        cancelAlarm(id)
                        result.success(true)
                    }

                    else -> result.notImplemented()
                }
            }
    }

    // ─────────────────────────────────────────────────────────────────────
    //  Android intent ile gelen /typing talebini Flutter’a ilet
    // ─────────────────────────────────────────────────────────────────────
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val route   = intent?.getStringExtra("route")
        val alarmId = intent?.getIntExtra("alarmId", -1) ?: -1

        if (route == "/typing" && alarmId != -1) {
            // Flutter tarafında openTypingPage metodunu tetikle
            flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                MethodChannel(messenger, NATIVE_CHANNEL)
                    .invokeMethod("openTypingPage", mapOf("alarmId" to alarmId))
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────────
    //  Alarm programlama yardimcilari
    // ─────────────────────────────────────────────────────────────────────
    private fun scheduleAlarm(id: Int, timeInMillis: Long, isRepeating: Boolean) {
        val alarmManager = applicationContext
            .getSystemService(Context.ALARM_SERVICE) as AlarmManager

        val intent = Intent(applicationContext, AlarmTriggerReceiver::class.java).apply {
            putExtra("ALARM_ID", id)
            putExtra("IS_REPEATING", isRepeating)
            action = "com.example.alarm.ALARM_TRIGGER_$id"
        }

        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        else PendingIntent.FLAG_UPDATE_CURRENT

        val pIntent = PendingIntent.getBroadcast(
            applicationContext, id, intent, flags)

        // Android 12+ için kesin alarm izni kontrolü
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
            !alarmManager.canScheduleExactAlarms()) {
            Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).also {
                it.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(it)
            }
            Log.w(TAG, "Exact alarm permission not granted – requesting user action.")
            return
        }

        alarmManager.setExactAndAllowWhileIdle(
            AlarmManager.RTC_WAKEUP, timeInMillis, pIntent)

        Log.d(TAG, "Alarm scheduled: ID=$id at $timeInMillis")
    }

    private fun cancelAlarm(id: Int) {
        val alarmManager = applicationContext
            .getSystemService(Context.ALARM_SERVICE) as AlarmManager

        val intent = Intent(applicationContext, AlarmTriggerReceiver::class.java).apply {
            action = "com.example.alarm.ALARM_TRIGGER_$id"
        }

        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        else PendingIntent.FLAG_UPDATE_CURRENT

        val pIntent = PendingIntent.getBroadcast(
            applicationContext, id, intent, flags)

        alarmManager.cancel(pIntent)
        Log.d(TAG, "Alarm cancelled: ID=$id")
    }
}
