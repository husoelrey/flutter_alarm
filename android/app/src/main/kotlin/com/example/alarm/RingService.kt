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
        const val ACTION_STOP  = "com.example.alarm.ACTION_STOP_RING_SERVICE"
        const val EXTRA_ALARM_ID = "ALARM_ID"
    }

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "Service onCreate")
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {

        val action  = intent?.action
        val alarmId = intent?.getIntExtra(EXTRA_ALARM_ID, -1) ?: -1
        Log.d(TAG, "onStartCommand → action=$action  id=$alarmId")

        if (alarmId == -1 && action == ACTION_START) {
            Log.e(TAG, "Geçersiz ALARM_ID, servis başlatılamıyor")
            stopSelf()
            return START_NOT_STICKY
        }

        /* ───── FULL‑SCREEN INTENT •––––––––––––––––––––– */
        val fullScreenIntent = Intent(this, AlarmRingActivity::class.java).apply {
            putExtra("id", alarmId)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }

        val piFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        else PendingIntent.FLAG_UPDATE_CURRENT

        val fullScreenPI = PendingIntent.getActivity(
            this, alarmId, fullScreenIntent, piFlags
        )

        /* Bildirime tıklandığında da aynı sayfa açılsın */
        val tapPI = PendingIntent.getActivity(
            this, alarmId + 1000, fullScreenIntent, piFlags
        )

        /* ───── Bildirim •––––––––––––––––––––────────── */
        val notif = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)          // isteğe göre değiştir
            .setContentTitle("Alarm Çalıyor!")
            .setContentText("Alarm ID: $alarmId çalıyor")
            .setPriority(NotificationCompat.PRIORITY_MAX) // heads‑up
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setOngoing(true)
            .setAutoCancel(false)
            .setFullScreenIntent(fullScreenPI, true)      // 💥 kritik
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

        /* ───── Aksiyonlar •––––––––––––––––––––──────── */
        when (action) {

            ACTION_START -> {
                startSound()
                /* Bazı cihazlarda sistem tam‑ekranı otomatik açmıyor →
                   emin olmak için kendimiz de başlatıyoruz.              */
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
                /* Player zaten çalıyorsa servis yaşamaya devam etsin */
                if (mediaPlayer?.isPlaying != true) stopSelf()
            }
        }

        return START_STICKY
    }

    /* ───── Yardımcı fonksiyonlar (SES) •––––––––––––––––––––──────── */

    private fun startSound() {
        Log.d(TAG, "startSound()")
        stopSoundOnly()  // varsa eskiyi kapat

        val soundUri = Uri.parse("android.resource://$packageName/${R.raw.un}")
        Log.d(TAG, "soundUri = $soundUri")

        mediaPlayer = MediaPlayer().apply {
            setAudioAttributes(
                AudioAttributes.Builder()
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .build()
            )
            setOnErrorListener { _, w, e ->
                Log.e(TAG, "MediaPlayer error what=$w extra=$e"); stopSoundAndService(); true
            }
            try {
                setDataSource(this@RingService, soundUri)
                isLooping = true
                prepare()
                start()
                Log.d(TAG, "MediaPlayer started")
            } catch (e: Exception) {
                Log.e(TAG, "MediaPlayer hata", e)
                stopSelf()
            }
        }
    }

    private fun stopSoundOnly() {
        try {
            mediaPlayer?.takeIf { it.isPlaying }?.stop()
            mediaPlayer?.release()
        } catch (e: Exception) {
            Log.e(TAG, "MediaPlayer stop/release hata", e)
        } finally { mediaPlayer = null }
    }

    private fun stopSoundAndService() {
        stopSoundOnly()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N)
            stopForeground(STOP_FOREGROUND_REMOVE)
        else @Suppress("DEPRECATION") stopForeground(true)
        stopSelf()
    }

    /* ───── Service & kanal boilerplate •––––––––––––––––––––──────── */

    override fun onDestroy() { stopSoundOnly(); super.onDestroy() }
    override fun onBind(intent: Intent?): IBinder? = null

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID, "Alarm Servisi",
                NotificationManager.IMPORTANCE_HIGH    // heads‑up & full‑screen
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
