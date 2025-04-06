import 'package:flutter/material.dart';
import 'package:health_app/theme/app_theme.dart';
import 'package:health_app/screens/add_reminder_screen.dart';
import 'package:health_app/services/database_service.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final DatabaseService _databaseService = DatabaseService.instance;
  List<Reminder> _reminders = [];
  final DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    try {
      // Initialize database if needed
      await _databaseService.database;
      
      final remindersData = await _databaseService.getReminders();
      if (mounted) {
        setState(() {
          _reminders = remindersData.map((data) => Reminder(
            id: data['id'],
            title: data['title'],
            description: data['description'],
            dateTime: DateTime.parse('${data['date']} ${data['time']}'),
            type: ReminderType.values[data['reminder_type']],
            isCompleted: data['is_completed'] == 1,
          )).toList();
        });
      }
    } catch (e) {
      print('Error loading reminders: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading reminders: $e')),
        );
      }
    }
  }

  Future<void> _addReminder(Reminder reminder) async {
    try {
      final id = await _databaseService.saveReminder(
        title: reminder.title,
        description: reminder.description,
        reminderType: reminder.type.index,
        date: reminder.dateTime,
        time: reminder.dateTime,
      );
      
      if (id != -1) {
        setState(() {
          reminder.id = id;
          _reminders.add(reminder);
          _reminders.sort((a, b) => a.dateTime.compareTo(b.dateTime));
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reminder added successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add reminder')),
        );
      }
    } catch (e) {
      print('Error adding reminder: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding reminder: $e')),
      );
    }
  }

  Future<void> _toggleReminderCompletion(Reminder reminder) async {
    try {
      final success = await _databaseService.toggleReminderCompletion(reminder.id!);
      if (success) {
        setState(() {
          reminder.isCompleted = !reminder.isCompleted;
        });
      }
    } catch (e) {
      print('Error toggling reminder completion: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error updating reminder')),
      );
    }
  }

  Future<void> _deleteReminder(Reminder reminder) async {
    try {
      final success = await _databaseService.deleteReminder(reminder.id!);
      if (success) {
        setState(() {
          _reminders.remove(reminder);
        });
      }
    } catch (e) {
      print('Error deleting reminder: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error deleting reminder')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders & Schedule'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Calendar view will be implemented soon'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, 2),
                  blurRadius: 5,
                ),
              ],
            ),
            child: _buildDateSelector(),
          ),
          Expanded(
            child: _reminders.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _reminders.length,
                    itemBuilder: (context, index) {
                      return _buildReminderItem(_reminders[index]);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddReminderScreen(
                onReminderAdded: _addReminder,
              ),
            ),
          );
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildDateSelector() {
    final now = DateTime.now();
    final dates = List.generate(7, (index) => now.add(Duration(days: index)));

    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: dates.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final date = dates[index];
          final isToday = index == 0;
          
          return Container(
            margin: const EdgeInsets.only(right: 12),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isToday ? AppTheme.primaryColor : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isToday ? AppTheme.primaryColor : AppTheme.borderColor,
                    ),
                    boxShadow: isToday ? [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ] : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _getDayName(date),
                        style: TextStyle(
                          fontSize: 12,
                          color: isToday ? Colors.white : AppTheme.secondaryTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        date.day.toString(),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isToday ? Colors.white : AppTheme.primaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                if (isToday)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getDayName(DateTime date) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppTheme.backgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              size: 60,
              color: AppTheme.primaryColor.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No reminders for today',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Text(
            'Tap the + button to add a new reminder',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildReminderItem(Reminder reminder) {
    IconData icon;
    Color color;

    switch (reminder.type) {
      case ReminderType.appointment:
        icon = Icons.calendar_today_rounded;
        color = AppTheme.primaryColor;
        break;
      case ReminderType.medication:
        icon = Icons.medication_rounded;
        color = const Color(0xFFFF8FAB);
        break;
      case ReminderType.water:
        icon = Icons.water_drop_outlined;
        color = const Color(0xFF7AC9E8);
        break;
      case ReminderType.exercise:
        icon = Icons.directions_walk_rounded;
        color = const Color(0xFF4CAF50);
        break;
      default:
        icon = Icons.notifications_rounded;
        color = AppTheme.primaryColor;
    }

    return Dismissible(
      key: Key(reminder.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) => _deleteReminder(reminder),
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color),
          ),
          title: Text(
            reminder.title,
            style: TextStyle(
              decoration: reminder.isCompleted ? TextDecoration.lineThrough : null,
              color: reminder.isCompleted ? Colors.grey : null,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...[
              Text(reminder.description),
              const SizedBox(height: 4),
            ],
              Text(
                '${reminder.dateTime.hour.toString().padLeft(2, '0')}:${reminder.dateTime.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  color: AppTheme.secondaryTextColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                value: reminder.isCompleted,
                onChanged: (bool? value) {
                  if (value != null) {
                    _toggleReminderCompletion(reminder);
                  }
                },
                activeColor: AppTheme.primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Reminder {
  int? id;
  final String title;
  final String description;
  final DateTime dateTime;
  final ReminderType type;
  bool isCompleted;

  Reminder({
    this.id,
    required this.title,
    required this.description,
    required this.dateTime,
    required this.type,
    required this.isCompleted,
  });
}

enum ReminderType {
  appointment,
  medication,
  water,
  exercise,
  other,
} 