package com.example.alarm

import android.content.Context
import android.content.Intent
import android.content.SharedPreferences // SharedPreferences importu
import android.icu.text.SimpleDateFormat // Tarih formatlama için (ICU)
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.util.Log // Log importu
import android.view.WindowManager
import android.widget.Button
import android.widget.TextView // TextView importu
import androidx.appcompat.app.AppCompatActivity
import org.json.JSONObject // JSON parse için
import java.util.Date // Date importu
import java.util.Locale // Locale importu

class AlarmRingActivity : AppCompatActivity() {

    private var wakeLock: PowerManager.WakeLock? = null
    private val TAG = "AlarmRingActivity" // Loglama için TAG

    // SharedPreferences anahtarları (Flutter tarafıyla TUTARLI OLMALI!)
    // Flutter varsayılan olarak bu dosyayı kullanır
    private val PREFS_NAME = "FlutterSharedPreferences"
    // AlarmStorage.dart içindeki _alarmsKey değişkenine karşılık gelen native anahtar
    private val ALARMS_KEY = "flutter.alarms_list" // 'flutter.' prefix'ini unutma!
    // AlarmInfo.dart içindeki toJson/fromJson'da kullanılan anahtarlar
    private val ID_KEY = "id"
    private val LABEL_KEY = "label"
    private val IS_ACTIVE_KEY = "isActive" // Pasifleştirme için lazım olacak

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d(TAG, "onCreate started")

        // --- Ekranı Açma ve Kilidi Kaldırma ---
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
                setShowWhenLocked(true)
                setTurnScreenOn(true)
            } else {
                window.addFlags(
                    WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                            WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
                            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
                )
            }
            Log.d(TAG, "Show/Turn flags set")
        } catch (e: Exception) { Log.e(TAG, "Error setting window flags", e) }

        // --- Ekranı Uyanık Tutma (WakeLock) ---
        try {
            val powerManager = getSystemService(POWER_SERVICE) as PowerManager
            wakeLock = powerManager.newWakeLock(
                PowerManager.FULL_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP,
                "$packageName::AlarmWakeLock"
            )
            wakeLock?.acquire(2 * 60 * 1000L /* 2 dakika */) // Süreyi biraz uzattım
            Log.d(TAG, "Wakelock acquired")
        } catch (e: Exception) { Log.e(TAG, "Error acquiring wakelock", e) }

        // --- Layout'u Yükleme ---
        try {
            setContentView(R.layout.activity_alarm_ring)
            Log.d(TAG, "Layout activity_alarm_ring set")
        } catch (e: Exception) {
            Log.e(TAG, "Error setting content view", e); finish(); return
        }

        // --- View Referanslarını Alma ---
        val textViewTime: TextView? = findViewById(R.id.textViewTime)
        val textViewDate: TextView? = findViewById(R.id.textViewDate)
        val textViewLabel: TextView? = findViewById(R.id.textViewLabel)
        val buttonDismiss: Button? = findViewById(R.id.buttonDismiss)

        if (textViewTime == null || textViewDate == null || textViewLabel == null || buttonDismiss == null) {
            Log.e(TAG, "One or more views not found in layout!"); finish(); return
        }

        // --- Verileri Gösterme ---
        val alarmId = intent.getIntExtra("id", -1)
        Log.d(TAG, "Received alarm ID: $alarmId")

        // Anlık Saat ve Tarihi Formatla
        val currentTime = Date()
        val timeFormatter = SimpleDateFormat("HH:mm", Locale("tr", "TR"))
        val dateFormatter = SimpleDateFormat("d MMMM EEEE", Locale("tr", "TR"))

        textViewTime.text = timeFormatter.format(currentTime)
        textViewDate.text = dateFormatter.format(currentTime)

        // Alarm Etiketini Göster (SharedPreferences'dan okuyarak)
        // ***** YENİ KISIM: Etiket null veya boş ise ID göster *****
        val alarmLabel = getAlarmLabelFromPrefs(alarmId)
        if (!alarmLabel.isNullOrEmpty()) { // Etiket null değilse VE boş değilse
            textViewLabel.text = alarmLabel
            Log.d(TAG, "Displaying fetched label: $alarmLabel")
        } else { // Etiket yoksa veya boşsa ID'yi göster
            textViewLabel.text = "Alarm (ID: $alarmId)"
            Log.d(TAG, "Label is null or empty, displaying ID.")
        }
        // ***** BİTTİ *****

        // --- Kapat Butonu Listener ---
        buttonDismiss.setOnClickListener {
            Log.d(TAG, "Dismiss button clicked for ID: $alarmId")
            // TODO: Tek seferlik alarmı pasifleştirme kodu buraya eklenecek (Adım 3)
            // deactivateOneShotAlarmInPrefs(alarmId)
            stopRingService(alarmId) // ID'yi stop'a da gönderelim
            finishAndRemoveTask()
        }

        Log.d(TAG, "onCreate finished successfully")
    }

    // SharedPreferences'dan ilgili alarmın etiketini okuyan fonksiyon
    private fun getAlarmLabelFromPrefs(alarmId: Int): String? {
        if (alarmId == -1) {
            Log.w(TAG, "getAlarmLabelFromPrefs called with invalid ID (-1)")
            return null
        }
        var label: String? = null
        try {
            Log.d(TAG, "Reading SharedPreferences: $PREFS_NAME")
            val prefs: SharedPreferences = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            Log.d(TAG, "Attempting to get alarm Set with key: $ALARMS_KEY")

            // SADECE getStringSet KULLANILIYOR
            val alarmsJsonSet: Set<String>? = prefs.getStringSet(ALARMS_KEY, null)

            if (alarmsJsonSet == null) {
                Log.w(TAG, "Alarm list key '$ALARMS_KEY' not found or not a Set in SharedPreferences.")
                return null
            }

            Log.d(TAG, "Found ${alarmsJsonSet.size} alarms in SharedPreferences. Searching for ID: $alarmId")

            // Set üzerinde döngü yap
            for (alarmJsonString in alarmsJsonSet) {
                Log.d(TAG, "Processing JSON String: $alarmJsonString") // <-- JSON'ı logla
                try {
                    val jsonObject = JSONObject(alarmJsonString)
                    val currentId = jsonObject.optInt(ID_KEY, -1)
                    if (currentId == alarmId) {
                        label = jsonObject.optString(LABEL_KEY, null) // Etiketi al (null olabilir)
                        // Etiket boş string ise null kabul edelim
                        if (label?.isEmpty() == true) {
                            label = null
                        }
                        Log.d(TAG, "Found matching alarm. Label: $label")
                        break // Alarm bulundu
                    }
                } catch (jsonEx: Exception) {
                    Log.w(TAG, "Error parsing individual alarm JSON: $alarmJsonString", jsonEx)
                }
            }
            if (label == null) {
                Log.w(TAG, "Alarm with ID $alarmId not found or label is null/empty in the list.")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error reading SharedPreferences for label", e)
        }
        return label
    }

    // RingService'i durdurma fonksiyonu (ID parametresi eklendi)
    private fun stopRingService(alarmId: Int) {
        Log.d(TAG, "Sending stop intent to RingService for ID: $alarmId")
        val stopIntent = Intent(applicationContext, RingService::class.java).apply {
            action = RingService.ACTION_STOP
            putExtra(RingService.EXTRA_ALARM_ID, alarmId) // ID'yi servise gönder
        }
        try {
            applicationContext.startService(stopIntent)
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping RingService", e)
        }
    }

    // Activity yok edildiğinde çağrılır
    override fun onDestroy() {
        super.onDestroy()
        if (wakeLock?.isHeld == true) {
            try { wakeLock?.release(); Log.d(TAG, "Wakelock released") }
            catch (e: Exception) { Log.e(TAG, "Error releasing wakelock", e) }
        }
        Log.d(TAG, "onDestroy finished")
    }

    // Geri tuşuna basılmasını engelle
    override fun onBackPressed() {
        Log.d(TAG, "Back button pressed, ignoring.")
        // Geri tuşunu engellemek için super.onBackPressed() çağrılmaz.
    }

    // TODO: Tek seferlik alarmı pasifleştirmek için fonksiyon (Adım 3)
    /*
    private fun deactivateOneShotAlarmInPrefs(alarmId: Int) {
        if (alarmId == -1) return
        Log.d(TAG, "Attempting to deactivate alarm ID $alarmId in SharedPreferences")
        try {
            val prefs: SharedPreferences = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val editor = prefs.edit()
            val alarmsJsonSet = prefs.getStringSet(ALARMS_KEY, null)
            val alarmsJsonList = if (alarmsJsonSet == null) prefs.getStringList(ALARMS_KEY, null) else null
            val alarmsCollection : MutableCollection<String>? = alarmsJsonSet?.toMutableSet() ?: alarmsJsonList?.toMutableList()

            if (alarmsCollection == null) {
                Log.w(TAG, "Cannot deactivate: Alarm list not found or not a Set/List.")
                return
            }

            val iterator = alarmsCollection.iterator()
            var found = false
            val updatedAlarms = mutableListOf<String>() // Güncellenmiş listeyi tutmak için

            while (iterator.hasNext()) {
                val alarmJsonString = iterator.next()
                try {
                    val jsonObject = JSONObject(alarmJsonString)
                    if (jsonObject.optInt(ID_KEY, -1) == alarmId) {
                        Log.d(TAG, "Found alarm to deactivate. Setting isActive=false.")
                        jsonObject.put(IS_ACTIVE_KEY, false) // isActive değerini false yap
                        updatedAlarms.add(jsonObject.toString()) // Güncellenmiş JSON'u ekle
                        found = true
                        // iterator.remove() // Eğer Set ise direkt remove edilebilir ama List ise ConcurrentModificationException verebilir
                    } else {
                         updatedAlarms.add(alarmJsonString) // Değişmeyenleri tekrar ekle
                    }
                } catch (jsonEx: Exception) {
                    Log.w(TAG, "Error processing alarm JSON during deactivation: $alarmJsonString", jsonEx)
                    updatedAlarms.add(alarmJsonString) // Hatalıysa bile orijinali koru
                }
            }

            if (found) {
                // SharedPreferences'a güncellenmiş listeyi kaydet
                if (alarmsJsonSet != null) {
                    editor.putStringSet(ALARMS_KEY, updatedAlarms.toSet())
                } else if (alarmsJsonList != null) {
                     //putStringList Android SDK < 33 için yok, bu yüzden Set kullanmak daha iyi
                     Log.w(TAG, "Saving updated list as Set because putStringList might not be available.")
                     editor.putStringSet(ALARMS_KEY, updatedAlarms.toSet())
                }
                editor.apply() // Değişiklikleri uygula
                Log.d(TAG, "Alarm ID $alarmId deactivated successfully in SharedPreferences.")
            } else {
                 Log.w(TAG, "Alarm ID $alarmId not found during deactivation attempt.")
            }

        } catch (e: Exception) {
            Log.e(TAG, "Error deactivating alarm in SharedPreferences", e)
        }
    }
    */
}