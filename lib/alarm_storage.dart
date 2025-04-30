// lib/alarm_storage.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'alarm_model.dart';

const String _alarmsKey = 'alarms_list';

class AlarmStorage {
  // Alarmları Kaydetme
  static Future<void> saveAlarms(List<AlarmInfo> alarms) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    // Alarm listesini JSON listesine çevir
    List<String> alarmsJsonList = alarms
        .map((alarm) => jsonEncode(alarm.toJson())) // Her alarmı JSON string'e çevir
        .toList();
    await prefs.setStringList(_alarmsKey, alarmsJsonList); // String listesini kaydet
    print("Alarmlar kaydedildi: ${alarmsJsonList.length} adet");
  }

  // Alarmları Yükleme
  static Future<List<AlarmInfo>> loadAlarms() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String>? alarmsJsonList = prefs.getStringList(_alarmsKey);

    if (alarmsJsonList == null || alarmsJsonList.isEmpty) {
      print("Kaydedilmiş alarm bulunamadı.");
      return []; // Kayıtlı alarm yoksa boş liste döndür
    }

    try {
      List<AlarmInfo> alarms = alarmsJsonList
          .map((alarmJson) => AlarmInfo.fromJson(jsonDecode(alarmJson))) // Her JSON string'i AlarmInfo'ya çevir
          .toList();
      print("Alarmlar yüklendi: ${alarms.length} adet");
      return alarms;
    } catch (e) {
      print("Alarmları yüklerken hata oluştu: $e");
      // Hata durumunda eski bozuk veriyi temizleyebiliriz
      // await prefs.remove(_alarmsKey);
      return []; // Hata durumunda boş liste döndür
    }
  }

  // Benzersiz ID üretmek için son ID'yi saklama ve alma
  static Future<int> getNextAlarmId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    int lastId = prefs.getInt('last_alarm_id') ?? -1; // Başlangıçta -1 olsun
    int nextId = lastId + 1;
    await prefs.setInt('last_alarm_id', nextId);
    return nextId;
  }

  // (Opsiyonel) Sadece tek bir alarmı güncellemek için
  static Future<void> updateAlarm(AlarmInfo alarmToUpdate) async {
    List<AlarmInfo> currentAlarms = await loadAlarms();
    int index = currentAlarms.indexWhere((alarm) => alarm.id == alarmToUpdate.id);
    if (index != -1) {
      currentAlarms[index] = alarmToUpdate;
      await saveAlarms(currentAlarms);
    }
  }
}