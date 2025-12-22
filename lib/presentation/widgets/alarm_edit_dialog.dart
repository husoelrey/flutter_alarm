import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/alarm_model.dart';
import '../../data/alarm_storage.dart';

/// A dialog for adding a new alarm or editing an existing one.
class AlarmEditDialog extends StatefulWidget {
  final AlarmInfo? initialAlarm;

  const AlarmEditDialog({super.key, this.initialAlarm});

  @override
  _AlarmEditDialogState createState() => _AlarmEditDialogState();
}

class _AlarmEditDialogState extends State<AlarmEditDialog> {
  late TimeOfDay _selectedTime;
  late TextEditingController _labelController;
  late Set<int> _selectedDays;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedTime = widget.initialAlarm?.timeOfDay ??
        TimeOfDay.fromDateTime(now.add(const Duration(minutes: 5)));
    _labelController = TextEditingController(text: widget.initialAlarm?.label ?? '');
    _selectedDays = widget.initialAlarm?.repeatDays.toSet() ?? {};
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  /// Creates an [AlarmInfo] object from the dialog's state and pops the navigator.
  void _save() async {
    final now = DateTime.now();
    DateTime dateTimeWithSelectedTime = DateTime(
        now.year, now.month, now.day, _selectedTime.hour, _selectedTime.minute);

    final alarmInfo = AlarmInfo(
      id: widget.initialAlarm?.id ?? await AlarmStorage.getNextAlarmId(),
      dateTime: dateTimeWithSelectedTime, // This is temporary; final calculation happens in `saveOrUpdateAlarm`
      label: _labelController.text.trim(),
      repeatDays: _selectedDays.toList()..sort(),
      isActive: widget.initialAlarm?.isActive ?? true,
    );
    Navigator.of(context).pop(alarmInfo);
  }

  @override
  Widget build(BuildContext context) {
    final List<String> dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return AlertDialog(
      title: Center(
        child: Text(widget.initialAlarm == null ? 'Set New Alarm' : 'Edit Alarm'),
      ),
      contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 0),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(
              child: InkWell(
                onTap: _pickTime,
                child: Text(
                  _selectedTime.format(context),
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ),
            ),
            const Divider(height: 24),
            TextField(
              controller: _labelController,
              decoration: const InputDecoration(
                labelText: 'Label (Optional)',
                prefixIcon: Icon(Icons.label_outline),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12))),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            Text('Repeat Days:', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              alignment: WrapAlignment.center,
              children: List<Widget>.generate(7, (int index) {
                final dayValue = index + 1; // Monday is 1, Sunday is 7
                final isSelected = _selectedDays.contains(dayValue);
                return ChoiceChip(
                  label: Text(dayNames[index]),
                  selected: isSelected,
                  onSelected: (bool selected) {
                    setState(() {
                      if (selected) {
                        _selectedDays.add(dayValue);
                      } else {
                        _selectedDays.remove(dayValue);
                      }
                    });
                  },
                );
              }),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('CANCEL'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        ElevatedButton(
          child: const Text('SAVE'),
          onPressed: _save,
        ),
      ],
    );
  }
}
