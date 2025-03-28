import 'package:flutter/material.dart';
import 'package:health_app/screens/reminders_screen.dart';

class AddReminderScreen extends StatefulWidget {
  final void Function(Reminder) onReminderAdded;

  const AddReminderScreen({Key? key, required this.onReminderAdded}) : super(key: key);

  @override
  _AddReminderScreenState createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends State<AddReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String _description = '';
  DateTime _dateTime = DateTime.now();
  ReminderType _type = ReminderType.other;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Reminder'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
                onSaved: (value) => _title = value ?? '',
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Description'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
                onSaved: (value) => _description = value ?? '',
              ),
              ListTile(
                title: Text('Date & Time'),
                subtitle: Text(_dateTime.toString()),
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _dateTime,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(Duration(days: 365)),
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
                    child: Text(type.toString().split('.').last),
                  );
                }).toList(),
                decoration: InputDecoration(labelText: 'Type'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
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
                },
                child: Text('Save Reminder'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 