// lib/alarm_model.dart
import 'dart:convert'; // JSON dönüşümü için
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
// Haftanın günleri için sabitler (DateTime.monday = 1, ..., DateTime.sunday = 7)
const List<int> allWeekdays = [
  DateTime.monday, DateTime.tuesday, DateTime.wednesday, DateTime.thursday,
  DateTime.friday, DateTime.saturday, DateTime.sunday
];

class AlarmInfo {
  final int id;
  DateTime dateTime; // Artık final değil, sonraki çalıştırmayı güncellemek için
  String? label; // Alarm etiketi (opsiyonel)
  List<int> repeatDays; // Tekrarlama günleri (1-7), boş ise tek seferlik
  bool isActive; // Alarm aktif mi?

  AlarmInfo({
    required this.id,
    required this.dateTime,
    this.label,
    required this.repeatDays,
    this.isActive = true,
  });

  TimeOfDay get timeOfDay => TimeOfDay.fromDateTime(dateTime);

  // Tekrarlama durumunu metin olarak döndüren yardımcı fonksiyon
  /// Seçilen günlerin kısaltılmış metni
  String get repeatDaysText {
    if (repeatDays.isEmpty) return 'Tek seferlik';

    // ❌ repeatDays.sort();  // orijinal sorunlu satır
    // ✅ önce modifiye edilebilir bir kopya al
    final List<int> days = List<int>.from(repeatDays)..sort();

    const dayShort = ['', 'Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    return days.map((d) => dayShort[d]).join(', ');
  }


  // JSON'a dönüştürme (shared_preferences için)
  Map<String, dynamic> toJson() => {
    'id': id,
    'dateTime': dateTime.toIso8601String(), // Tarihi string olarak kaydet
    'label': label,
    'repeatDays': repeatDays, // Liste doğrudan kaydedilebilir
    'isActive': isActive,
  };

  // JSON'dan oluşturma (shared_preferences için)
  factory AlarmInfo.fromJson(Map<String, dynamic> json) => AlarmInfo(
    id: json['id'] as int,
    // Kaydedilen string'den DateTime'a geri dönüştür
    dateTime: DateTime.parse(json['dateTime'] as String),
    label: json['label'] as String?,
    // JSON listesini List<int> olarak al
    repeatDays: List<int>.from(json['repeatDays'] as List),
    isActive: json['isActive'] as bool,
  );

  // Sonraki alarm zamanını hesaplama
  DateTime calculateNextAlarmTime(DateTime now) {
    // Eğer tekrar etmiyorsa veya zaten gelecek bir zamandaysa, mevcut zamanı kullan
    if (repeatDays.isEmpty || dateTime.isAfter(now)) {
      // Ancak tek seferlik ve geçmişteyse, sonraki güne atla (ilk kurulum için)
      if (repeatDays.isEmpty && dateTime.isBefore(now)) {
        return dateTime.add(Duration(days: 1));
      }
      return dateTime;
    }

    // Tekrarlıyorsa ve zamanı geçmişse, sonraki uygun günü bul
    DateTime nextAlarm = dateTime;
    while (nextAlarm.isBefore(now) || !repeatDays.contains(nextAlarm.weekday)) {
      nextAlarm = nextAlarm.add(Duration(days: 1));
    }
    return DateTime(nextAlarm.year, nextAlarm.month, nextAlarm.day, timeOfDay.hour, timeOfDay.minute);
  }
}

// Listeleri karşılaştırmak için (pubspec'e collection eklenmeli)
// ignore: depend_on_referenced_packages
