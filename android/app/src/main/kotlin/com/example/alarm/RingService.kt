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

    companion object {
        const val ACTION_START = "com.example.alarm.ACTION_START_RING"
        const val ACTION_STOP = "com.example.alarm.ACTION_STOP_RING"
        const val EXTRA_ALARM_ID = "ALARM_ID"
        private const val NOTIFICATION_ID = 123
        private const val CHANNEL_ID = "alarm_ring_channel"
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action
        val alarmId = intent?.getIntExtra(EXTRA_ALARM_ID, -1) ?: -1

        Log.d("RingService", "onStartCommand -> action=$action, id=$alarmId")

        if (alarmId == -1 && action == ACTION_START) {
            Log.e("RingService", "Invalid alarm ID, service cannot start.")
            stopSelf()
            return START_NOT_STICKY
        }

        val notification = createNotification(alarmId)
        startForeground(NOTIFICATION_ID, notification)

        when (action) {
            ACTION_START -> startSound(alarmId)
            ACTION_STOP -> stopSoundAndService()
            else -> {
                Log.w("RingService", "Unknown action: $action")
                if (mediaPlayer?.isPlaying != true) stopSelf()
            }
        }

        return START_STICKY
    }

    private fun startSound(alarmId: Int) {
        stopSoundOnly() // Stop any previous sound

        try {
            mediaPlayer = MediaPlayer().apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .build()
                )

                // For now, using a fallback sound. Custom sound path can be added here.
                val fallbackUri = Uri.parse("android.resource://$packageName/${R.raw.un}")
                setDataSource(this@RingService, fallbackUri)
                isLooping = true
                prepare()
                start()
                Log.d("RingService", "MediaPlayer started for alarm ID: $alarmId")
            }
        } catch (e: Exception) {
            Log.e("RingService", "MediaPlayer setup failed", e)
            stopSelf() // Stop service if sound cannot be played
        }
    }

    private fun stopSoundOnly() {
        mediaPlayer?.apply {
            if (isPlaying) stop()
            release()
        }
        mediaPlayer = null
    }

    private fun stopSoundAndService() {
        stopSoundOnly()
        stopForeground(true)
        stopSelf()
        Log.d("RingService", "Service and sound stopped.")
    }

    private fun createNotification(alarmId: Int): Notification {
        val fullScreenIntent = Intent(this, AlarmRingActivity::class.java).apply {
            putExtra("id", alarmId.toString())
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }

        val pendingIntentFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }

        val fullScreenPendingIntent = PendingIntent.getActivity(this, alarmId, fullScreenIntent, pendingIntentFlags)

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("Alarm is ringing!")
            .setContentText("Alarm ID: $alarmId")
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setOngoing(true)
            .setAutoCancel(false)
            .setFullScreenIntent(fullScreenPendingIntent, true)
            .build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID, "Alarm Ringing",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Channel used when an alarm is actively ringing."
                setSound(null, null) // Sound is handled by MediaPlayer
                enableVibration(false)
            }
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }

    override fun onDestroy() {
        stopSoundOnly()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
