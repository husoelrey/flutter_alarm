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

    private val NOTIFICATION_ID = 123
    private val CHANNEL_ID = "alarm_ring_service_channel"
    private val TAG = "RingService"

    companion object {
        const val ACTION_START = "com.example.alarm.ACTION_START_RING_SERVICE"
        const val ACTION_STOP = "com.example.alarm.ACTION_STOP_RING_SERVICE"
        const val EXTRA_ALARM_ID = "ALARM_ID"
    }

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "Service onCreate")
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action
        val alarmId = intent?.getIntExtra(EXTRA_ALARM_ID, -1) ?: -1

        Log.d(TAG, "onStartCommand received action: $action for ID: $alarmId")

        if (alarmId == -1 && action == ACTION_START) {
            Log.e(TAG, "Cannot start service without a valid ALARM_ID.")
            stopSelf()
            return START_NOT_STICKY
        }

        // Tam ekran açılacak sayfa
        val fullScreenIntent = Intent(this, AlarmRingActivity::class.java).apply {
            putExtra("id", alarmId)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
        }
        val pendingIntentFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        else PendingIntent.FLAG_UPDATE_CURRENT

        val fullScreenPendingIntent = PendingIntent.getActivity(this, alarmId, fullScreenIntent, pendingIntentFlags)

        val notificationTapIntent = Intent(this, AlarmRingActivity::class.java).apply {
            putExtra("id", alarmId)
            addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }
        val notificationTapPendingIntent = PendingIntent.getActivity(this, alarmId + 1000, notificationTapIntent, pendingIntentFlags)

        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("Alarm Çalıyor!")
            .setContentText(getAlarmLabelFromId(alarmId))
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setOngoing(true)
            .setAutoCancel(false)
            .setFullScreenIntent(fullScreenPendingIntent, true)
            .setContentIntent(notificationTapPendingIntent)
            .build()

        try {
            startForeground(NOTIFICATION_ID, notification)
            Log.d(TAG, "Service started in foreground with FullScreen Intent for ID: $alarmId.")
        } catch (e: Exception) {
            Log.e(TAG, "Error starting foreground service", e)
            stopSelf()
            return START_NOT_STICKY
        }

        when (action) {
            ACTION_START -> {
                Log.d(TAG, "ACTION_START received. Calling startSound() for ID: $alarmId.")
                startSound()
            }
            ACTION_STOP -> {
                Log.d(TAG, "ACTION_STOP received for ID: $alarmId.")
                stopSoundAndService()
                return START_NOT_STICKY
            }
            else -> {
                Log.w(TAG, "Received unknown or null action ($action). Service might be restarting.")
                if (mediaPlayer == null || mediaPlayer?.isPlaying == false) {
                    Log.w(TAG, "Stopping service due to null/unknown intent and no active playback.")
                    stopSelf()
                    return START_NOT_STICKY
                }
                Log.d(TAG,"Service restarted (?), MediaPlayer seems to be playing. Taking no action.")
            }
        }

        return START_STICKY
    }

    private fun getAlarmLabelFromId(alarmId: Int): String {
        return "Alarm ID: $alarmId çalıyor"
    }

    private fun startSound() {
        Log.d(TAG, "startSound() called.")
        stopSoundOnly()

        val soundUri = Uri.parse("android.resource://$packageName/${R.raw.un}")
        Log.d(TAG, "Parsed sound URI: $soundUri")

        mediaPlayer = MediaPlayer().apply {
            setAudioAttributes(
                AudioAttributes.Builder()
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .build()
            )
            setOnErrorListener { _, what, extra ->
                Log.e(TAG, "MediaPlayer OnErrorListener triggered - what: $what, extra: $extra")
                stopSoundAndService()
                true
            }
            try {
                setDataSource(applicationContext, soundUri)
                isLooping = true
                prepareAsync()
                setOnPreparedListener { mp ->
                    try {
                        mp.start()
                        Log.d(TAG, "MediaPlayer started successfully.")
                    } catch (e: IllegalStateException) {
                        Log.e(TAG, "Failed to start MediaPlayer", e)
                        stopSoundAndService()
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Exception during MediaPlayer setup", e)
                stopSelf()
            }
        }
    }

    private fun stopSoundOnly() {
        Log.d(TAG, "stopSoundOnly() called.")
        try {
            if (mediaPlayer?.isPlaying == true) {
                mediaPlayer?.stop()
            }
            mediaPlayer?.release()
        } catch (e: IllegalStateException) {
            Log.e(TAG, "Error stopping/releasing MediaPlayer", e)
        } finally {
            mediaPlayer = null
        }
    }

    private fun stopSoundAndService() {
        stopSoundOnly()
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                stopForeground(STOP_FOREGROUND_REMOVE)
            } else {
                @Suppress("DEPRECATION")
                stopForeground(true)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping foreground", e)
        }
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
                CHANNEL_ID,
                "Alarm Sesi Servisi",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Alarm çalarken çalışan servis için bildirim kanalı"
                setSound(null, null)
                enableVibration(false)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                setBypassDnd(true)
            }
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            try {
                manager.createNotificationChannel(channel)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to create notification channel", e)
            }
        }
    }
}
