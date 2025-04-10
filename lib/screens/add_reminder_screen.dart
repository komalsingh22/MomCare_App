import 'package:flutter/material.dart';
import 'package:health_app/screens/reminders_screen.dart';
import 'package:health_app/theme/app_theme.dart';

class AddReminderScreen extends StatefulWidget {
  final void Function(Reminder) onReminderAdded;

  const AddReminderScreen({super.key, required this.onReminderAdded});

  @override
  _AddReminderScreenState createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends State<AddReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String _description = '';
  DateTime _dateTime = DateTime.now().add(const Duration(hours: 1));
  ReminderType _type = ReminderType.other;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Reminder'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
                onSaved: (value) => _title = value ?? '',
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                onSaved: (value) => _description = value ?? '',
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 2,
                child: ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Date & Time'),
                  subtitle: Text(
                    '${_dateTime.toLocal().toString().split(' ')[0]} at ${_dateTime.hour}:${_dateTime.minute.toString().padLeft(2, '0')}'
                  ),
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _dateTime,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      final TimeOfDay? timePicked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(_dateTime),
                      );
                      if (timePicked != null) {
                        setState(() {
                          _dateTime = DateTime(
                            picked.year,
                            picked.month,
                            picked.day,
                            timePicked.hour,
                            timePicked.minute,
                          );
                        });
                      }
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ReminderType>(
                value: _type,
                onChanged: (value) {
                  setState(() {
                    _type = value ?? ReminderType.other;
                  });
                },
                items: ReminderType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(_getReminderTypeName(type)),
                  );
                }).toList(),
                decoration: const InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveReminder,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  backgroundColor: AppTheme.primaryColor,
                  disabledBackgroundColor: Colors.grey,
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save Reminder', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  String _getReminderTypeName(ReminderType type) {
    switch (type) {
      case ReminderType.appointment:
        return 'Doctor Appointment';
      case ReminderType.medication:
        return 'Take Medication';
      case ReminderType.water:
        return 'Drink Water';
      case ReminderType.exercise:
        return 'Exercise';
      case ReminderType.other:
        return 'Other';
    }
  }
  
  void _saveReminder() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });
      
      _formKey.currentState!.save();
      final newReminder = Reminder(
        title: _title,
        dateTime: _dateTime,
        description: _description,
        type: _type,
        isCompleted: false,
      );
      
      widget.onReminderAdded(newReminder);
      Navigator.pop(context);
    }
  }
} 