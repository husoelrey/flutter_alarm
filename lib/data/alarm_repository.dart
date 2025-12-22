import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/alarm_model.dart';
import '../data/alarm_storage.dart';

/// Repository class to handle all alarm-related data and native communication.
/// This separates the business logic from the UI.
class AlarmRepository {
  static const MethodChannel _nativeChannel =
      MethodChannel('com.example.alarm/native');

  /// Loads alarms from storage, sanitizes them (checks for past one-shots),
  /// and ensures the native system is in sync.
  Future<List<AlarmInfo>> loadAndSanitizeAlarms() async {
    List<AlarmInfo> alarms = await AlarmStorage.loadAlarms();
    final now = DateTime.now();
    bool requiresSave = false;

    for (var alarm in alarms) {
      // Logic: Deactivate past, non-repeating alarms
      if (alarm.isActive &&
          alarm.repeatDays.isEmpty &&
          alarm.dateTime.isBefore(now)) {
        debugPrint("Repo: Deactivating past one-shot alarm ID: ${alarm.id}");
        alarm.isActive = false;
        requiresSave = true;
        // Also ensure native side cancels it (just to be safe)
        await cancelNativeAlarm(alarm.id);
      } else {
        if (alarm.isActive) {
          // Recalculate next time just in case
          DateTime nextAlarmTime = alarm.calculateNextAlarmTime(now);
          if (alarm.dateTime != nextAlarmTime) {
            alarm.dateTime = nextAlarmTime;
            requiresSave = true;
          }
          // Ensure it's scheduled natively
          await scheduleNativeAlarm(alarm);
        }
      }
    }

    if (requiresSave) {
      await saveAlarmsToStorage(alarms);
    }
    
    // Sort by time
    alarms.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return alarms;
  }

  /// Saves the list of alarms to local storage.
  Future<void> saveAlarmsToStorage(List<AlarmInfo> alarms) async {
    await AlarmStorage.saveAlarms(alarms);
  }

  /// Adds or updates an alarm in the list, saves it, and schedules it natively.
  Future<List<AlarmInfo>> saveAlarm(AlarmInfo newAlarm, List<AlarmInfo> currentAlarms) async {
    // 1. Calculate correct next time
    newAlarm.dateTime = newAlarm.calculateNextAlarmTime(DateTime.now());
    newAlarm.isActive = true;

    // 2. Schedule Native
    bool scheduled = await scheduleNativeAlarm(newAlarm);
    if (!scheduled) {
      throw Exception("Failed to schedule native alarm");
    }

    // 3. Update List
    int index = currentAlarms.indexWhere((a) => a.id == newAlarm.id);
    if (index != -1) {
      currentAlarms[index] = newAlarm;
    } else {
      currentAlarms.add(newAlarm);
    }
    
    // 4. Sort and Save
    currentAlarms.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    await saveAlarmsToStorage(currentAlarms);
    
    return currentAlarms;
  }

  /// Deletes an alarm, cancels it natively, and saves the list.
  Future<List<AlarmInfo>> deleteAlarm(AlarmInfo alarm, List<AlarmInfo> currentAlarms) async {
    await cancelNativeAlarm(alarm.id);
    currentAlarms.removeWhere((a) => a.id == alarm.id);
    await saveAlarmsToStorage(currentAlarms);
    return currentAlarms;
  }

  /// Toggles an alarm's active state.
  Future<List<AlarmInfo>> toggleAlarm(AlarmInfo alarm, bool isActive, List<AlarmInfo> currentAlarms) async {
    alarm.isActive = isActive;
    if (isActive) {
      alarm.dateTime = alarm.calculateNextAlarmTime(DateTime.now());
      await scheduleNativeAlarm(alarm);
    } else {
      await cancelNativeAlarm(alarm.id);
    }
    
    // Update in list
    int index = currentAlarms.indexWhere((a) => a.id == alarm.id);
    if (index != -1) {
      currentAlarms[index] = alarm;
    }
    
    await saveAlarmsToStorage(currentAlarms);
    return currentAlarms;
  }

  // --- Native Calls ---

  Future<bool> scheduleNativeAlarm(AlarmInfo alarm) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final soundPath = prefs.getString('selected_alarm_sound') ?? "";

      await _nativeChannel.invokeMethod('scheduleNativeAlarm', {
        'id': alarm.id,
        'timeInMillis': alarm.dateTime.millisecondsSinceEpoch,
        'isRepeating': alarm.repeatDays.isNotEmpty,
        'soundPath': soundPath,
      });
      debugPrint("Repo: Native schedule successful for ID: ${alarm.id}");
      return true;
    } catch (e) {
      debugPrint("Repo: Error scheduling native alarm: $e");
      return false;
    }
  }

  Future<bool> cancelNativeAlarm(int alarmId) async {
    try {
      await _nativeChannel.invokeMethod('cancelNativeAlarm', {'id': alarmId});
      debugPrint("Repo: Native cancel successful for ID: $alarmId");
      return true;
    } catch (e) {
      debugPrint("Repo: Error cancelling native alarm: $e");
      return false;
    }
  }
}
