import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/alarm_model.dart';
import '../../data/alarm_storage.dart';
import '../widgets/alarm_edit_dialog.dart';

class AlarmHomePage extends StatefulWidget {
  const AlarmHomePage({super.key});

  @override
  State<AlarmHomePage> createState() => _AlarmHomePageState();
}

class _AlarmHomePageState extends State<AlarmHomePage> {
  static const MethodChannel _nativeChannel =
      MethodChannel('com.example.alarm/native');

  List<AlarmInfo> _alarms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAndRescheduleAlarms();
  }

  Future<void> _pickAndSaveSound() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );

    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      debugPrint("Audio file selected and saved: $path");

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_alarm_sound', path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alarm sound saved')),
        );
      }
    }
  }

  /// Loads all alarms from storage, deactivates past one-shot alarms,
  /// and reschedules active alarms with the native system.
  Future<void> _loadAndRescheduleAlarms() async {
    setState(() => _isLoading = true);

    List<AlarmInfo> alarmsFromStorage = await AlarmStorage.loadAlarms();
    final now = DateTime.now();
    bool requiresSave = false;
    List<Future<void>> schedulingTasks = [];

    for (var alarm in alarmsFromStorage) {
      // Deactivate past, non-repeating alarms
      if (alarm.isActive &&
          alarm.repeatDays.isEmpty &&
          alarm.dateTime.isBefore(now)) {
        debugPrint("Deactivating past one-shot alarm ID: ${alarm.id}");
        alarm.isActive = false;
        requiresSave = true;
        schedulingTasks.add(_cancelSystemAlarm(alarm));
      } else {
        if (alarm.isActive) {
          // Ensure next alarm time is correctly calculated and update if needed
          DateTime nextAlarmTime = alarm.calculateNextAlarmTime(now);
          if (alarm.dateTime != nextAlarmTime) {
            alarm.dateTime = nextAlarmTime;
            requiresSave = true;
          }
        }
        // Schedule or cancel the alarm based on its current state
        schedulingTasks.add(_scheduleOrCancelSystemAlarm(alarm));
      }
    }

    await Future.wait(schedulingTasks);

    if (requiresSave) {
      await AlarmStorage.saveAlarms(alarmsFromStorage);
    }

    // Sort alarms by time and update the UI
    alarmsFromStorage.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    if (mounted) {
      setState(() {
        _alarms = alarmsFromStorage;
        _isLoading = false;
      });
    }
    debugPrint("Alarms loaded and system schedules updated.");
  }

  /// Opens the dialog to add a new alarm or edit an existing one.
  Future<void> _showAddEditAlarmDialog({AlarmInfo? existingAlarm}) async {
    final newAlarmInfo = await showDialog<AlarmInfo>(
      context: context,
      builder: (context) => AlarmEditDialog(initialAlarm: existingAlarm),
    );

    if (newAlarmInfo != null) {
      await _saveOrUpdateAlarm(newAlarmInfo);
    }
  }

  /// Saves a new alarm or updates an existing one.
  Future<void> _saveOrUpdateAlarm(AlarmInfo alarm) async {
    alarm.dateTime = alarm.calculateNextAlarmTime(DateTime.now());
    alarm.isActive = true;

    bool scheduled = await _scheduleOrCancelSystemAlarm(alarm);

    if (scheduled) {
      int existingIndex = _alarms.indexWhere((a) => a.id == alarm.id);
      setState(() {
        if (existingIndex != -1) {
          _alarms[existingIndex] = alarm;
        } else {
          _alarms.add(alarm);
        }
        _alarms.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      });
      await AlarmStorage.saveAlarms(_alarms);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Alarm ${existingIndex != -1 ? 'updated' : 'set'} for: ${DateFormat('dd MMM HH:mm', 'tr_TR').format(alarm.dateTime)}'),
          ),
        );
      }
    } else {
      debugPrint("Failed to request native schedule for ID: ${alarm.id}");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to set alarm. Please try again.')),
        );
      }
    }
  }

  /// Toggles the active state of an alarm.
  Future<void> _toggleAlarm(AlarmInfo alarm, bool isActive) async {
    final originalState = alarm.isActive;
    setState(() {
      alarm.isActive = isActive;
      if (isActive) {
        alarm.dateTime = alarm.calculateNextAlarmTime(DateTime.now());
      }
    });

    bool success = await _scheduleOrCancelSystemAlarm(alarm);

    if (success) {
      await AlarmStorage.updateAlarm(alarm);
    } else {
      // Revert state if the system call fails
      setState(() => alarm.isActive = originalState);
      debugPrint("Failed to update alarm status for ID: ${alarm.id}");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update alarm status.')),
        );
      }
    }
  }

  /// Deletes an alarm after confirming with the user.
  Future<void> _deleteAlarm(AlarmInfo alarm, int index) async {
    await _cancelSystemAlarm(alarm);

    setState(() {
      _alarms.removeAt(index);
    });
    await AlarmStorage.saveAlarms(_alarms);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alarm deleted')),
      );
    }
  }

  // --- Native Method Calls ---

  /// Schedules or cancels a system alarm based on the alarm's active state.
  Future<bool> _scheduleOrCancelSystemAlarm(AlarmInfo alarm) {
    if (alarm.isActive) {
      return _scheduleSystemAlarm(alarm);
    } else {
      return _cancelSystemAlarm(alarm);
    }
  }

  /// Invokes the native method to schedule an alarm.
  Future<bool> _scheduleSystemAlarm(AlarmInfo alarm) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final soundPath = prefs.getString('selected_alarm_sound') ?? "";

      await _nativeChannel.invokeMethod('scheduleNativeAlarm', {
        'id': alarm.id,
        'timeInMillis': alarm.dateTime.millisecondsSinceEpoch,
        'isRepeating': alarm.repeatDays.isNotEmpty,
        'soundPath': soundPath,
      });
      debugPrint("Native schedule request successful for ID: ${alarm.id}");
      return true;
    } catch (e, s) {
      debugPrint("Error invoking native schedule for ID ${alarm.id}: $e\n$s");
      return false;
    }
  }

  /// Invokes the native method to cancel an alarm.
  Future<bool> _cancelSystemAlarm(AlarmInfo alarm) async {
    try {
      await _nativeChannel.invokeMethod('cancelNativeAlarm', {'id': alarm.id});
      debugPrint("Native cancel request successful for ID: ${alarm.id}");
      return true;
    } catch (e, s) {
      debugPrint("Error invoking native cancel for ID ${alarm.id}: $e\n$s");
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Alarms'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_alarm),
            tooltip: 'Add New Alarm',
            onPressed: () => _showAddEditAlarmDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _pickAndSaveSound,
            icon: const Icon(Icons.music_note),
            label: const Text("Select Alarm Sound"),
            style: ElevatedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
              textStyle: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _alarms.isEmpty
                    ? const Center(
                        child: Text(
                          'No alarms yet.\nTap the + icon to add one.',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.separated(
                        itemCount: _alarms.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1, indent: 16, endIndent: 16),
                        itemBuilder: (context, index) {
                          final alarm = _alarms[index];
                          return AlarmListItem(
                            alarm: alarm,
                            onToggle: (bool value) => _toggleAlarm(alarm, value),
                            onTap: () =>
                                _showAddEditAlarmDialog(existingAlarm: alarm),
                            onDelete: () => _deleteAlarm(alarm, index),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

/// A widget to display a single alarm in the list.
class AlarmListItem extends StatelessWidget {
  const AlarmListItem({
    super.key,
    required this.alarm,
    required this.onToggle,
    required this.onTap,
    required this.onDelete,
  });

  final AlarmInfo alarm;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final nextOccurrence = alarm.dateTime;
    String nextTimeString;

    if (!alarm.isActive) {
      nextTimeString = "Inactive";
    } else {
      final isToday = now.year == nextOccurrence.year &&
          now.month == nextOccurrence.month &&
          now.day == nextOccurrence.day;
      final isTomorrow = now.add(const Duration(days: 1)).day == nextOccurrence.day;

      if (isToday) {
        nextTimeString = 'Today, ${DateFormat('HH:mm').format(nextOccurrence)}';
      } else if (isTomorrow) {
        nextTimeString = 'Tomorrow, ${DateFormat('HH:mm').format(nextOccurrence)}';
      } else {
        nextTimeString =
            DateFormat('dd MMM E, HH:mm', 'tr_TR').format(nextOccurrence);
      }
    }

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      leading: Icon(
        alarm.isActive ? Icons.alarm_on : Icons.alarm_off,
        color: alarm.isActive ? Theme.of(context).colorScheme.primary : Colors.grey,
        size: 30,
      ),
      title: Text(
        DateFormat('HH:mm').format(alarm.dateTime),
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: alarm.isActive
              ? Theme.of(context).textTheme.bodyLarge?.color
              : Colors.grey[500],
          decoration: !alarm.isActive ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (alarm.label != null && alarm.label!.isNotEmpty)
            Text(
              alarm.label!,
              style: TextStyle(
                fontSize: 16,
                color: alarm.isActive
                    ? Theme.of(context).textTheme.bodyMedium?.color
                    : Colors.grey,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              '${alarm.repeatDaysText} | $nextTimeString',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ],
      ),
      trailing: Switch(
        value: alarm.isActive,
        onChanged: onToggle,
        activeColor: Theme.of(context).colorScheme.primary,
      ),
      onTap: onTap,
      onLongPress: () async {
        bool? confirmDelete = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Delete Alarm?'),
              content: Text(
                  'Are you sure you want to permanently delete this alarm for ${DateFormat('HH:mm').format(alarm.dateTime)}?'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('CANCEL'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('DELETE', style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        );
        if (confirmDelete == true) {
          onDelete();
        }
      },
    );
  }
}
