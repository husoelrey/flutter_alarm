import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'alarm_model.dart';

/// Manages the persistence of alarms using [SharedPreferences].
class AlarmStorage {
  /// The key for storing the alarm list in [SharedPreferences].
  /// IMPORTANT: This must match the key used in the native Android code to prevent conflicts.
  static const String _alarmsKey = 'flutter.alarms_list';

  /// The key for storing the last used alarm ID.
  static const String _lastIdKey = 'last_alarm_id';

  /// Saves a list of [AlarmInfo] objects to persistent storage.
  static Future<void> saveAlarms(List<AlarmInfo> alarms) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> alarmsJsonList =
        alarms.map((alarm) => jsonEncode(alarm.toJson())).toList();
    await prefs.setStringList(_alarmsKey, alarmsJsonList);
    debugPrint("Alarms saved: ${alarms.length} items.");
  }

  /// Loads the list of [AlarmInfo] objects from persistent storage.
  static Future<List<AlarmInfo>> loadAlarms() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String>? alarmsJsonList = prefs.getStringList(_alarmsKey);

    if (alarmsJsonList == null || alarmsJsonList.isEmpty) {
      debugPrint("No saved alarms found.");
      return [];
    }

    try {
      List<AlarmInfo> alarms = alarmsJsonList
          .map((alarmJson) => AlarmInfo.fromJson(jsonDecode(alarmJson)))
          .toList();
      debugPrint("Alarms loaded: ${alarms.length} items.");
      return alarms;
    } catch (e, s) {
      debugPrint("Error decoding alarms: $e\n$s");
      // If decoding fails, it's safer to return an empty list
      // to prevent the app from crashing.
      return [];
    }
  }

  /// Generates a new unique ID for an alarm.
  /// This is a simple auto-incrementing ID.
  static Future<int> getNextAlarmId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    int lastId = prefs.getInt(_lastIdKey) ?? -1;
    int nextId = lastId + 1;
    await prefs.setInt(_lastIdKey, nextId);
    return nextId;
  }

  /// Finds an alarm by its ID and updates it in the storage.
  static Future<void> updateAlarm(AlarmInfo alarmToUpdate) async {
    List<AlarmInfo> currentAlarms = await loadAlarms();
    int index = currentAlarms.indexWhere((alarm) => alarm.id == alarmToUpdate.id);

    if (index != -1) {
      currentAlarms[index] = alarmToUpdate;
      await saveAlarms(currentAlarms);
      debugPrint("Alarm with ID ${alarmToUpdate.id} updated.");
    } else {
      debugPrint("Could not update alarm: ID ${alarmToUpdate.id} not found.");
    }
  }
}
