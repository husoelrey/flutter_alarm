// lib/alarm_storage.dart
import 'dart:convert';
import 'package:flutter/foundation.dart'; // debugPrint için
import 'package:shared_preferences/shared_preferences.dart';
import 'alarm_model.dart';

/// Native tarafla uyumlu olması için bu key değiştirildi! ÇOK ÖNEMLİ BURASI
const String _alarmsKey = 'flutter.alarms_list';

class AlarmStorage {
  // Alarmları Kaydet
  static Future<void> saveAlarms(List<AlarmInfo> alarms) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> alarmsJsonList = alarms.map((alarm) => jsonEncode(alarm.toJson())).toList();
    await prefs.setStringList(_alarmsKey, alarmsJsonList);
    debugPrint("Alarmlar kaydedildi: ${alarmsJsonList.length} adet");
  }

  // Alarmları Yükle
  static Future<List<AlarmInfo>> loadAlarms() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String>? alarmsJsonList = prefs.getStringList(_alarmsKey);

    if (alarmsJsonList == null || alarmsJsonList.isEmpty) {
      debugPrint("Kaydedilmiş alarm bulunamadı.");
      return [];
    }

    try {
      List<AlarmInfo> alarms = alarmsJsonList
          .map((alarmJson) => AlarmInfo.fromJson(jsonDecode(alarmJson)))
          .toList();
      debugPrint("Alarmlar yüklendi: ${alarms.length} adet");
      return alarms;
    } catch (e) {
      debugPrint("Alarmları yüklerken hata oluştu: $e");
      return [];
    }
  }

  // Benzersiz ID üret
  static Future<int> getNextAlarmId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    int lastId = prefs.getInt('last_alarm_id') ?? -1;
    int nextId = lastId + 1;
    await prefs.setInt('last_alarm_id', nextId);
    return nextId;
  }

  // Belirli alarmı güncelle
  static Future<void> updateAlarm(AlarmInfo alarmToUpdate) async {
    List<AlarmInfo> currentAlarms = await loadAlarms();
    int index = currentAlarms.indexWhere((alarm) => alarm.id == alarmToUpdate.id);
    if (index != -1) {
      currentAlarms[index] = alarmToUpdate;
      await saveAlarms(currentAlarms);
    }
  }
}
