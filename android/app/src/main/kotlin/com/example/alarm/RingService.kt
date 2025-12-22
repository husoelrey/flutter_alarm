package com.example.alarm

import android.app.*
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.net.Uri
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat

class RingService : Service() {

    private var mediaPlayer: MediaPlayer? = null
    private var currentAlarmId: Int = -1 // Access from here instead of via intent

    private val NOTIFICATION_ID = 123
    private val CHANNEL_ID = "alarm_ring_service_channel"
    private val TAG = "RingService"

    companion object {
        const val ACTION_START = "com.example.alarm.ACTION_START_RING_SERVICE"
        const val ACTION_STOP  = "com.example.alarm.ACTION_STOP_RING_SERVICE"
        const val EXTRA_ALARM_ID = "ALARM_ID"
    }

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "Service onCreate")
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {

        val action = intent?.action
        currentAlarmId = intent?.getIntExtra(EXTRA_ALARM_ID, -1) ?: -1
        Log.d(TAG, "onStartCommand → action=$action  id=$currentAlarmId")

        if (currentAlarmId == -1 && action == ACTION_START) {
            Log.e(TAG, "Geçersiz ALARM_ID, servis başlatılamıyor")
            stopSelf()
            return START_NOT_STICKY
        }

        val fullScreenIntent = Intent(this, AlarmRingActivity::class.java).apply {
            putExtra("id", currentAlarmId)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }

        val piFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        else PendingIntent.FLAG_UPDATE_CURRENT

        val fullScreenPI = PendingIntent.getActivity(this, currentAlarmId, fullScreenIntent, piFlags)

        val tapPI = PendingIntent.getActivity(this, currentAlarmId + 1000, fullScreenIntent, piFlags)

        val notif = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("Alarm Çalıyor!")
            .setContentText("Alarm ID: $currentAlarmId çalıyor")
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setOngoing(true)
            .setAutoCancel(false)
            .setFullScreenIntent(fullScreenPI, true)
            .setContentIntent(tapPI)
            .build()

        try {
            startForeground(NOTIFICATION_ID, notif)
            Log.d(TAG, "Foreground + bildirim başlatıldı")
        } catch (e: Exception) {
            Log.e(TAG, "startForeground hatası", e)
            stopSelf()
            return START_NOT_STICKY
        }

        when (action) {
            ACTION_START -> {
                startSound()
                try {
                    startActivity(fullScreenIntent)
                    Log.d(TAG, "AlarmRingActivity manuel olarak başlatıldı")
                } catch (e: Exception) {
                    Log.e(TAG, "startActivity hatası", e)
                }
            }
            ACTION_STOP -> {
                stopSoundAndService()
                return START_NOT_STICKY
            }
            else -> {
                Log.w(TAG, "Bilinmeyen aksiyon: $action")
                if (mediaPlayer?.isPlaying != true) stopSelf()
            }
        }

        return START_STICKY
    }

    private fun startSound() {
        Log.d(TAG, "startSound()")
        stopSoundOnly()

        val prefs = getSharedPreferences("alarm_prefs", MODE_PRIVATE)
        val customPath = prefs.getString("soundPath_$currentAlarmId", null)

        Log.d(TAG, "Selected soundPath for ID $currentAlarmId: $customPath")

        try {
            mediaPlayer = MediaPlayer().apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .build()
                )
                setOnErrorListener { _, w, e ->
                    Log.e(TAG, "MediaPlayer error what=$w extra=$e")
                    stopSoundAndService()
                    true
                }

                if (!customPath.isNullOrEmpty()) {
                    setDataSource(customPath)
                    Log.d(TAG, "Custom alarm sound selected.")
                } else {
                    val fallback = Uri.parse("android.resource://$packageName/${R.raw.un}")
                    setDataSource(this@RingService, fallback)
                    Log.d(TAG, "Default alarm sound used (un.mp3).")
                }

                isLooping = true
                prepare()
                start()
                Log.d(TAG, "MediaPlayer started")
            }
        } catch (e: Exception) {
            Log.e(TAG, "MediaPlayer hata", e)
            stopSelf()
        }
    }

    private fun stopSoundOnly() {
        try {
            mediaPlayer?.takeIf { it.isPlaying }?.stop()
            mediaPlayer?.release()
        } catch (e: Exception) {
            Log.e(TAG, "MediaPlayer stop/release hata", e)
        } finally {
            mediaPlayer = null
        }
    }

    private fun stopSoundAndService() {
        stopSoundOnly()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N)
            stopForeground(STOP_FOREGROUND_REMOVE)
        else @Suppress("DEPRECATION") stopForeground(true)
        stopSelf()
    }

    override fun onDestroy() {
        stopSoundOnly()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID, "Alarm Servisi",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Alarm çalarken kullanılan kanal"
                setSound(null, null)
                enableVibration(false)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                setBypassDnd(true)
            }
            (getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager)
                .createNotificationChannel(channel)
        }
    }
}
