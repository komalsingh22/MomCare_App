import 'package:flutter/material.dart';
import 'package:health_app/theme/app_theme.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({Key? key}) : super(key: key);

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final List<Reminder> _reminders = [
    Reminder(
      title: 'Prenatal Checkup',
      dateTime: DateTime.now().add(const Duration(days: 3)),
      description: 'Regular monthly checkup at City Hospital with Dr. Smith',
      type: ReminderType.appointment,
      isCompleted: false,
    ),
    Reminder(
      title: 'Take Prenatal Vitamins',
      dateTime: DateTime.now().add(const Duration(hours: 2)),
      description: 'Take your daily prenatal vitamins with food',
      type: ReminderType.medication,
      isCompleted: false,
      isRecurring: true,
    ),
    Reminder(
      title: 'Ultrasound Appointment',
      dateTime: DateTime.now().add(const Duration(days: 14)),
      description: 'Growth scan ultrasound at Women\'s Care Center',
      type: ReminderType.appointment,
      isCompleted: false,
    ),
    Reminder(
      title: 'Drink Water',
      dateTime: DateTime.now(),
      description: 'Remember to stay hydrated - at least 8 glasses today',
      type: ReminderType.water,
      isCompleted: true,
      isRecurring: true,
    ),
  ];

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
              // Show calendar view
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
          // Date picker strip
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
          // Reminders list
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
          // Add new reminder
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Add reminder will be implemented soon'),
              duration: Duration(seconds: 2),
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
                    decoration: BoxDecoration(
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
            decoration: BoxDecoration(
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
        color = const Color(0xFFFF8FAB); // Soft pink
        break;
      case ReminderType.water:
        icon = Icons.water_drop_outlined;
        color = const Color(0xFF7AC9E8); // Soft blue
        break;
      case ReminderType.exercise:
        icon = Icons.directions_walk_rounded;
        color = const Color(0xFF8CD3A9); // Soft green
        break;
      default:
        icon = Icons.notifications_active_rounded;
        color = AppTheme.primaryColor;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          // View reminder details
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Checkbox for completion
              Container(
                decoration: BoxDecoration(
                  color: reminder.isCompleted 
                      ? color 
                      : color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(8),
                child: Icon(
                  reminder.isCompleted 
                      ? Icons.check_rounded 
                      : icon,
                  color: reminder.isCompleted 
                      ? Colors.white 
                      : color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              // Reminder details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: reminder.isCompleted 
                            ? AppTheme.secondaryTextColor 
                            : AppTheme.primaryTextColor,
                        decoration: reminder.isCompleted 
                            ? TextDecoration.lineThrough 
                            : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      reminder.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.secondaryTextColor,
                        decoration: reminder.isCompleted 
                            ? TextDecoration.lineThrough 
                            : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: color.withOpacity(0.8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTime(reminder.dateTime),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: color.withOpacity(0.8),
                          ),
                        ),
                        if (reminder.isRecurring) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.repeat,
                            size: 14,
                            color: color.withOpacity(0.8),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Daily',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: color.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Actions
              IconButton(
                icon: const Icon(
                  Icons.more_vert,
                  color: AppTheme.secondaryTextColor,
                ),
                onPressed: () {
                  // Show more options
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class Reminder {
  final String title;
  final String description;
  final DateTime dateTime;
  final ReminderType type;
  bool isCompleted;
  final bool isRecurring;

  Reminder({
    required this.title,
    required this.dateTime,
    required this.description,
    required this.type,
    required this.isCompleted,
    this.isRecurring = false,
  });
}

enum ReminderType {
  appointment,
  medication,
  water,
  exercise,
  other,
} 