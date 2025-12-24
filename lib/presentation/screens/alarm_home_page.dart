import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/alarm_model.dart';
import '../../data/alarm_repository.dart';
import '../../theme/app_colors.dart';
import '../widgets/alarm_edit_dialog.dart';

class AlarmHomePage extends StatefulWidget {
  const AlarmHomePage({super.key});

  @override
  State<AlarmHomePage> createState() => _AlarmHomePageState();
}

class _AlarmHomePageState extends State<AlarmHomePage> {
  final AlarmRepository _repository = AlarmRepository();

  List<AlarmInfo> _alarms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlarms();
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
          const SnackBar(content: Text('Alarm sesi kaydedildi')),
        );
      }
    }
  }

  Future<void> _loadAlarms() async {
    setState(() => _isLoading = true);
    try {
      final alarms = await _repository.loadAndSanitizeAlarms();
      if (mounted) {
        setState(() {
          _alarms = alarms;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading alarms: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showAddEditAlarmDialog({AlarmInfo? existingAlarm}) async {
    final newAlarmInfo = await showDialog<AlarmInfo>(
      context: context,
      builder: (context) => AlarmEditDialog(initialAlarm: existingAlarm),
    );

    if (newAlarmInfo != null) {
      await _saveOrUpdateAlarm(newAlarmInfo);
    }
  }

  Future<void> _saveOrUpdateAlarm(AlarmInfo alarm) async {
    try {
      final updatedAlarms = await _repository.saveAlarm(alarm, _alarms);
      setState(() => _alarms = updatedAlarms);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Alarm ${DateFormat('dd MMM HH:mm', 'tr_TR').format(alarm.dateTime)} için ${existingAlarmIndex(alarm.id) != -1 ? 'güncellendi' : 'kuruldu'}'),
          ),
        );
      }
    } catch (e) {
      debugPrint("Failed to save alarm: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alarm kurulamadı. Lütfen tekrar dene.')),
        );
      }
    }
  }
  
  int existingAlarmIndex(int id) => _alarms.indexWhere((a) => a.id == id);

  Future<void> _toggleAlarm(AlarmInfo alarm, bool isActive) async {
    try {
      final updatedAlarms = await _repository.toggleAlarm(alarm, isActive, _alarms);
      setState(() => _alarms = updatedAlarms);
    } catch (e) {
      debugPrint("Failed to toggle alarm: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alarm durumu güncellenemedi.')),
        );
      }
    }
  }

  Future<void> _deleteAlarm(AlarmInfo alarm, int index) async {
    try {
      final updatedAlarms = await _repository.deleteAlarm(alarm, _alarms);
      setState(() => _alarms = updatedAlarms);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alarm silindi')),
        );
      }
    } catch (e) {
       debugPrint("Failed to delete alarm: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Alarmlarım'),
        // AppColors.surface is already set in main.dart theme, but explicit here for clarity if needed
        backgroundColor: AppColors.surface, 
        actions: [
          IconButton(
            icon: const Icon(Icons.add_alarm, color: AppColors.primary),
            tooltip: 'Yeni Alarm Ekle',
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
            label: const Text("Alarm Sesi Seç"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
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
                          'Henüz alarm yok.\nEklemek için + ikonuna dokun.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _alarms.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1, indent: 16, endIndent: 16, color: Colors.white10),
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
      nextTimeString = "Kapalı";
    } else {
      final isToday = now.year == nextOccurrence.year &&
          now.month == nextOccurrence.month &&
          now.day == nextOccurrence.day;
      final isTomorrow = now.add(const Duration(days: 1)).day == nextOccurrence.day;

      if (isToday) {
        nextTimeString = 'Bugün, ${DateFormat('HH:mm').format(nextOccurrence)}';
      } else if (isTomorrow) {
        nextTimeString = 'Yarın, ${DateFormat('HH:mm').format(nextOccurrence)}';
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
        color: alarm.isActive ? AppColors.primary : AppColors.textDisabled,
        size: 30,
      ),
      title: Text(
        DateFormat('HH:mm').format(alarm.dateTime),
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: alarm.isActive
              ? AppColors.textPrimary
              : AppColors.textDisabled,
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
                    ? AppColors.textSecondary
                    : AppColors.textDisabled,
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
        activeColor: AppColors.primary,
        inactiveThumbColor: Colors.grey,
        inactiveTrackColor: Colors.grey.withOpacity(0.3),
      ),
      onTap: onTap,
      onLongPress: () async {
        bool? confirmDelete = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              title: const Text('Alarmı Sil?', style: TextStyle(color: AppColors.textPrimary)),
              content: Text(
                  '${DateFormat('HH:mm').format(alarm.dateTime)} için olan bu alarmı kalıcı olarak silmek istediğine emin misin?',
                  style: const TextStyle(color: AppColors.textSecondary)),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('İPTAL', style: TextStyle(color: AppColors.textSecondary)),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('SİL', style: TextStyle(color: AppColors.error)),
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