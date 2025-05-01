package com.example.alarm

import android.app.AlarmManager // AlarmManager import
import android.app.PendingIntent // PendingIntent import
import android.content.Context // Context import
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.provider.Settings // Settings import (opsiyonel, izin kontrolü için)
import android.util.Log // Log import
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Calendar // Zaman hesaplama için

class MainActivity : FlutterActivity() {

    private val NATIVE_CHANNEL = "com.example.alarm/native"
    private val TAG = "MainActivity" // Loglama için TAG

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NATIVE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "scheduleNativeAlarm" -> {
                        val id = call.argument<Int>("id") ?: -1
                        val timeInMillis = call.argument<Long>("timeInMillis") ?: -1L
                        val isRepeating = call.argument<Boolean>("isRepeating") ?: false
                        // val label = call.argument<String>("label") // Etiket de alınabilir

                        if (id != -1 && timeInMillis != -1L) {
                            Log.d(TAG,"Scheduling native alarm: ID=$id, Time=$timeInMillis, Repeating=$isRepeating")
                            scheduleAlarm(id, timeInMillis, isRepeating)
                            result.success(true)
                        } else {
                            Log.e(TAG,"Invalid arguments for scheduleNativeAlarm: ID=$id, Time=$timeInMillis")
                            result.error("INVALID_ARGS", "Invalid ID or timeInMillis for scheduling.", null)
                        }
                    }
                    "cancelNativeAlarm" -> {
                        val id = call.argument<Int>("id") ?: -1
                        if (id != -1) {
                            Log.d(TAG,"Cancelling native alarm: ID=$id")
                            cancelAlarm(id)
                            result.success(true)
                        } else {
                            Log.e(TAG,"Invalid arguments for cancelNativeAlarm: ID=$id")
                            result.error("INVALID_ARGS", "Invalid ID for cancelling.", null)
                        }
                    }
                    // startAlarmExperience metodu artık yok
                    else -> result.notImplemented()
                }
            }
    }

    // Belirli bir alarmı kuran yardımcı fonksiyon
    private fun scheduleAlarm(id: Int, timeInMillis: Long, isRepeating: Boolean) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

        // Alarm tetiklendiğinde çalışacak olan AlarmTriggerReceiver için Intent
        val intent = Intent(context, AlarmTriggerReceiver::class.java).apply {
            putExtra("ALARM_ID", id)
            putExtra("IS_REPEATING", isRepeating) // Tekrarlama bilgisini receiver'a gönder
            // putExtra("ALARM_LABEL", label) // Etiket de gönderilebilir
            // Farklı ID'ler için PendingIntent'lerin benzersiz olmasını sağla
            action = "com.example.alarm.ALARM_TRIGGER_$id" // Benzersiz action ata
        }


        // PendingIntent oluşturma (FLAG_UPDATE_CURRENT ve FLAG_IMMUTABLE önemli)
        val pendingIntentFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            id, // Request code olarak alarm ID'yi kullanmak iptal etmeyi kolaylaştırır
            intent,
            pendingIntentFlags
        )

        // Tam zamanlı alarm iznini kontrol et (Android 12+)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (!alarmManager.canScheduleExactAlarms()) {
                Log.e(TAG, "Cannot schedule exact alarms. Asking user to grant permission.")
                // Kullanıcıyı ayarlara yönlendirmek gerekebilir
                Intent().apply {
                    action = Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM
                }.also {
                    try {
                        startActivity(it)
                        // Kullanıcı izni verdikten sonra tekrar denemeli
                    } catch (e: Exception) {
                        Log.e(TAG, "Could not open ACTION_REQUEST_SCHEDULE_EXACT_ALARM settings", e)
                    }
                }
                // İzin alınamadığı için şimdilik işlemi durdurabiliriz
                // Veya inexact alarm kurmayı deneyebiliriz (alarm uygulaması için pek uygun değil)
                return
            }
        }

        // Alarmı kur (setExactAndAllowWhileIdle en uygunu)
        try {
            alarmManager.setExactAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP, // Cihaz uykudayken uyandır ve UTC zamanını kullan
                timeInMillis,
                pendingIntent
            )
            Log.d(TAG,"Exact alarm scheduled successfully for ID: $id at $timeInMillis")
        } catch (se: SecurityException) {
            Log.e(TAG, "SecurityException scheduling alarm for ID: $id. Check permissions.", se)
            // İzin hatası varsa kullanıcıya bilgi ver
        } catch (e: Exception) {
            Log.e(TAG, "Exception scheduling alarm for ID: $id", e)
        }
    }

    // Belirli bir alarmı iptal eden yardımcı fonksiyon
    private fun cancelAlarm(id: Int) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, AlarmTriggerReceiver::class.java).apply{
            // Kurarken kullanılan action'ı tekrar ata
            action = "com.example.alarm.ALARM_TRIGGER_$id"
        }

        // Kurarken kullandığımız PendingIntent'i aynı şekilde oluşturuyoruz
        val pendingIntentFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE // veya FLAG_NO_CREATE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            id,
            intent,
            pendingIntentFlags // FLAG_NO_CREATE kullanmak, sadece varsa iptal etmeyi sağlar
        )

        // Alarmı iptal et
        try {
            alarmManager.cancel(pendingIntent)
            Log.d(TAG,"Alarm cancelled successfully for ID: $id")
        } catch (e: Exception) {
            Log.e(TAG,"Exception cancelling alarm for ID: $id", e)
        }

    }
}