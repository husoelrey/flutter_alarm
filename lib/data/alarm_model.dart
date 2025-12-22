import 'package:flutter/material.dart';

/// Represents the data for a single alarm.
class AlarmInfo {
  /// A unique identifier for the alarm.
  final int id;

  /// The date and time for the alarm.
  /// Note: The date part is used to calculate the next occurrence.
  DateTime dateTime;

  /// An optional descriptive label for the alarm.
  String? label;

  /// A list of weekdays (1=Monday, 7=Sunday) on which the alarm should repeat.
  /// An empty list signifies a one-shot alarm.
  List<int> repeatDays;

  /// Whether the alarm is currently active.
  bool isActive;

  AlarmInfo({
    required this.id,
    required this.dateTime,
    this.label,
    required this.repeatDays,
    this.isActive = true,
  });

  /// Gets the time part of the [dateTime] as a [TimeOfDay] object.
  TimeOfDay get timeOfDay => TimeOfDay.fromDateTime(dateTime);

  /// Returns a display string for the repeat days (e.g., "Mon, Wed, Fri").
  String get repeatDaysText {
    if (repeatDays.isEmpty) return 'One-shot';
    if (repeatDays.length == 7) return 'Every day';

    // Sort days to ensure consistent output, e.g., Mon, Tue, not Tue, Mon
    final sortedDays = List<int>.from(repeatDays)..sort();
    const dayAbbreviations = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return sortedDays.map((d) => dayAbbreviations[d]).join(', ');
  }

  /// Converts this [AlarmInfo] object into a JSON map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'dateTime': dateTime.toIso8601String(),
        'label': label,
        'repeatDays': repeatDays,
        'isActive': isActive,
      };

  /// Creates an [AlarmInfo] instance from a JSON map.
  factory AlarmInfo.fromJson(Map<String, dynamic> json) => AlarmInfo(
        id: json['id'] as int,
        dateTime: DateTime.parse(json['dateTime'] as String),
        label: json['label'] as String?,
        repeatDays: List<int>.from(json['repeatDays'] as List),
        isActive: json['isActive'] as bool,
      );

  /// Calculates the next trigger time for this alarm based on the current time.
  DateTime calculateNextAlarmTime(DateTime now) {
    final alarmTime = TimeOfDay.fromDateTime(dateTime);
    DateTime nextTriggerDate = DateTime(now.year, now.month, now.day, alarmTime.hour, alarmTime.minute);

    // If it's a one-shot alarm
    if (repeatDays.isEmpty) {
      // If the time is in the future for today, schedule it for today
      if (nextTriggerDate.isAfter(now)) {
        return nextTriggerDate;
      }
      // Otherwise, schedule it for tomorrow
      return nextTriggerDate.add(const Duration(days: 1));
    }
    // If it's a repeating alarm
    else {
      // Find the next valid weekday
      for (int i = 0; i < 7; i++) {
        final weekday = nextTriggerDate.weekday;
        if (repeatDays.contains(weekday) && nextTriggerDate.isAfter(now)) {
          return nextTriggerDate;
        }
        nextTriggerDate = nextTriggerDate.add(const Duration(days: 1));
      }
    }
    // Should not be reached in normal circumstances
    return nextTriggerDate;
  }
}
