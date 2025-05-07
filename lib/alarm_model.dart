// lib/alarm_model.dart
import 'package:flutter/material.dart';

/// Haftanın günleri (DateTime: 1 = Pzt, ..., 7 = Paz)
const List<int> allWeekdays = [
  DateTime.monday,
  DateTime.tuesday,
  DateTime.wednesday,
  DateTime.thursday,
  DateTime.friday,
  DateTime.saturday,
  DateTime.sunday,
];

class AlarmInfo {
  final int id;
  DateTime dateTime; // Alarmın zamanı (güncellenebilir)
  String? label; // Etiket (isteğe bağlı)
  List<int> repeatDays; // Haftanın günleri (1-7 arası)
  bool isActive; // Aktiflik durumu

  AlarmInfo({
    required this.id,
    required this.dateTime,
    this.label,
    required this.repeatDays,
    this.isActive = true,
  });

  TimeOfDay get timeOfDay => TimeOfDay.fromDateTime(dateTime);

  /// Alarm tekrar günlerini metinle gösterir
  String get repeatDaysText {
    if (repeatDays.isEmpty) return 'Tek seferlik';
    final List<int> days = List<int>.from(repeatDays)..sort();
    const dayShort = ['', 'Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    return days.map((d) => dayShort[d]).join(', ');
  }

  /// JSON’a dönüştür
  Map<String, dynamic> toJson() => {
    'id': id,
    'dateTime': dateTime.toIso8601String(),
    'label': label,
    'repeatDays': repeatDays,
    'isActive': isActive,
  };

  /// JSON’dan AlarmInfo oluştur
  factory AlarmInfo.fromJson(Map<String, dynamic> json) => AlarmInfo(
    id: json['id'] as int,
    dateTime: DateTime.parse(json['dateTime'] as String),
    label: json['label'] as String?,
    repeatDays: List<int>.from(json['repeatDays'] as List),
    isActive: json['isActive'] as bool,
  );

  /// Sonraki tetiklenme zamanını hesapla
  DateTime calculateNextAlarmTime(DateTime now) {
    if (repeatDays.isEmpty) {
      if (dateTime.isAfter(now)) return dateTime;
      return dateTime.add(const Duration(days: 1));
    }

    DateTime next = DateTime(now.year, now.month, now.day, timeOfDay.hour, timeOfDay.minute);

    for (int i = 0; i < 7; i++) {
      int weekday = next.weekday;
      if (repeatDays.contains(weekday) && next.isAfter(now)) {
        return next;
      }
      next = next.add(const Duration(days: 1));
    }

    // Hiçbir şey bulunamazsa (güvenlik için, teorik olarak gerekmez)
    return next;
  }
}
