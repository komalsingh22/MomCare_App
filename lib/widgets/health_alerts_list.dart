import 'package:flutter/material.dart';
import 'package:health_app/models/health_data.dart';
import 'package:health_app/widgets/health_alert_widget.dart';

class HealthAlertsList extends StatelessWidget {
  final List<HealthAlert> alerts;
  final Function(HealthAlert)? onDismiss;
  final VoidCallback? onSeeAll;

  const HealthAlertsList({
    super.key,
    required this.alerts,
    this.onDismiss,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) {
      return Card(
        elevation: 1,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, color: Colors.green, size: 48),
                SizedBox(height: 16),
                Text(
                  'No health alerts',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Your health data is looking good!',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Health Alerts',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (onSeeAll != null && alerts.length > 3)
              TextButton(
                onPressed: onSeeAll,
                child: const Text('See All'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        ...alerts.take(3).map((alert) => HealthAlertWidget(
          alert: alert,
          onDismiss: onDismiss != null ? () => onDismiss!(alert) : null,
        )),
        if (alerts.length > 3)
          Center(
            child: TextButton.icon(
              onPressed: onSeeAll,
              icon: const Icon(Icons.arrow_downward),
              label: Text('${alerts.length - 3} more alerts'),
            ),
          ),
      ],
    );
  }
} 