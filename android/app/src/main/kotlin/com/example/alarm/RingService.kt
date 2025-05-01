package com.example.alarm

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.net.Uri
import android.os.Build
import android.os.IBinder
import android.util.Log // Log importu
import androidx.core.app.NotificationCompat

class RingService : Service() {

    private var mediaPlayer: MediaPlayer? = null
    // Sabit değerler ama 'var' istendiği için değiştirildi (önerilmez)
    private var NOTIFICATION_ID = 123
    private var CHANNEL_ID = "alarm_ring_service_channel"
    private var TAG = "RingService"

    companion object {
        // Bunlar 'const val' kalmalı, değiştirilemezler.
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
        var action = intent?.action
        var alarmId = intent?.getIntExtra(EXTRA_ALARM_ID, -1) ?: -1

        Log.d(TAG, "onStartCommand received action: $action for ID: $alarmId")

        if (alarmId == -1 && action == ACTION_START) {
            Log.e(TAG, "Cannot start service without a valid ALARM_ID.")
            stopSelf()
            return START_NOT_STICKY
        }

        // --- Tam Ekran Intent'i Hazırlama ---
        var fullScreenIntent = Intent(this, AlarmRingActivity::class.java).apply {
            putExtra("id", alarmId)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
        }
        var pendingIntentFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        var fullScreenPendingIntent = PendingIntent.getActivity(
            this,
            alarmId,
            fullScreenIntent,
            pendingIntentFlags
        )
        // --- Tam Ekran Intent Hazır ---

        // --- Bildirime Tıklanınca Çalışacak Intent'i Hazırlama ---
        var notificationTapIntent = Intent(this, AlarmRingActivity::class.java).apply {
            putExtra("id", alarmId)
            addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }
        var notificationTapPendingIntent = PendingIntent.getActivity(
            this,
            alarmId + 1000,
            notificationTapIntent,
            pendingIntentFlags
        )
        // --- Bildirim Tıklama Intent'i Hazır ---

        // --- Bildirimi Oluşturma ---
        var notificationBuilder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("Alarm Çalıyor!")
            .setContentText(getAlarmLabelFromId(alarmId))
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setOngoing(true)
            .setAutoCancel(false)
            .setFullScreenIntent(fullScreenPendingIntent, true)
            .setContentIntent(notificationTapPendingIntent)

        // --- "KAPAT" Butonu GEÇİCİ OLARAK YORUM SATIRI YAPILDI ---
        /*
        var stopSelfIntent = Intent(this, RingService::class.java).apply {
            action = ACTION_STOP
            putExtra(EXTRA_ALARM_ID, alarmId)
        }
        var stopPendingIntent = PendingIntent.getService(
            this,
            alarmId + 2000,
            stopSelfIntent,
            pendingIntentFlags // Daha önce tanımlanan 'var' kullanılıyor
        )
        notificationBuilder.addAction(R.drawable.ic_alarm_white, "KAPAT", stopPendingIntent)
        */
        // --- Yorum Satırı Bitti ---

        // --- Servisi Foreground'a Al ---
        try {
            // addAction yorumlandığı için build() çağrısı değişmedi
            startForeground(NOTIFICATION_ID, notificationBuilder.build())
            Log.d(TAG, "Service started in foreground with FullScreen Intent for ID: $alarmId.")
        } catch (e: Exception) {
            Log.e(TAG, "Error starting foreground service", e)
            stopSelf()
            return START_NOT_STICKY
        }
        // --- Foreground Başlatıldı ---

        // --- Gelen Eyleme Göre İşlem Yap ---
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
        // --- İşlem Yapıldı ---

        return START_STICKY
    }

    private fun getAlarmLabelFromId(alarmId: Int): String {
        return "Alarm ID: $alarmId çalıyor"
    }

    private fun startSound() {
        Log.d(TAG, "startSound() called.")
        stopSoundOnly()

        var soundUri: Uri? = null
        try {
            var resourceId = R.raw.un // val -> var
            Log.d(TAG, "Attempting to parse URI for resource ID: $resourceId (R.raw.un)")
            soundUri = Uri.parse("android.resource://$packageName/$resourceId")
            Log.d(TAG, "Parsed sound URI: $soundUri")
        } catch (e: Exception) {
            Log.e(TAG, "Error parsing sound URI for resource 'un'", e)
            stopSelf()
            return
        }

        if (soundUri == null) {
            Log.e(TAG, "Sound URI is null after parsing, cannot play sound.")
            stopSelf()
            return
        }

        Log.d(TAG, "Creating MediaPlayer instance.")
        mediaPlayer = MediaPlayer().apply {
            Log.d(TAG, "Setting AudioAttributes.")
            setAudioAttributes(
                AudioAttributes.Builder()
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .build()
            )
            Log.d(TAG, "Setting OnErrorListener.")
            setOnErrorListener { mp, what, extra ->
                Log.e(TAG, "MediaPlayer OnErrorListener triggered - what: $what, extra: $extra")
                stopSoundAndService()
                true
            }
            try {
                Log.d(TAG, "Setting data source: $soundUri")
                setDataSource(applicationContext, soundUri)
                Log.d(TAG, "Setting looping to true.")
                isLooping = true
                Log.d(TAG, "Calling prepareAsync().")
                prepareAsync()
                Log.d(TAG, "Setting OnPreparedListener.")
                setOnPreparedListener { mp ->
                    Log.d(TAG, "MediaPlayer OnPreparedListener triggered.")
                    try {
                        Log.d(TAG, "Calling mp.start()")
                        mp.start()
                        Log.d(TAG, "MediaPlayer started successfully.")
                    } catch (e: IllegalStateException) {
                        Log.e(TAG, "MediaPlayer could not start playback (IllegalStateException)", e)
                        stopSoundAndService()
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Exception during MediaPlayer setup (setDataSource etc.)", e)
                stopSelf()
            }
        }
        Log.d(TAG, "MediaPlayer instance configuration finished.")
    }

    private fun stopSoundOnly() {
        Log.d(TAG, "stopSoundOnly() called.")
        try {
            if (mediaPlayer?.isPlaying == true) {
                Log.d(TAG, "MediaPlayer is playing, stopping.")
                mediaPlayer?.stop()
            } else {
                Log.d(TAG, "MediaPlayer is not playing or null.")
            }
            mediaPlayer?.release()
            Log.d(TAG, "MediaPlayer released.")
        } catch (e: IllegalStateException) {
            Log.e(TAG, "Error stopping/releasing MediaPlayer", e)
        } finally {
            mediaPlayer = null
            Log.d(TAG, "MediaPlayer reference set to null.")
        }
    }

    private fun stopSoundAndService() {
        Log.d(TAG, "Stopping sound and service...")
        stopSoundOnly()

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                stopForeground(STOP_FOREGROUND_REMOVE)
            } else {
                @Suppress("DEPRECATION")
                stopForeground(true)
            }
            Log.d(TAG, "Service stopped foreground.")
        } catch (e: Exception){
            Log.e(TAG, "Error stopping foreground", e)
        }

        stopSelf()
        Log.d(TAG, "Service stopSelf() called.")
    }

    override fun onDestroy() {
        Log.d(TAG, "Service onDestroy")
        stopSoundOnly()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            var channel = NotificationChannel( // val -> var
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
            var manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager // val -> var
            try {
                manager.createNotificationChannel(channel)
                Log.d(TAG, "Notification channel created or updated.")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to create notification channel", e)
            }
        }
    }
}