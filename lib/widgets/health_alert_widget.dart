import 'package:flutter/material.dart';
import 'package:health_app/models/health_data.dart';
import 'package:health_app/screens/health_education_screen.dart';
import 'package:health_app/theme/app_theme.dart';

class HealthAlertWidget extends StatelessWidget {
  final HealthAlert alert;
  final Function? onDismiss;

  const HealthAlertWidget({
    super.key,
    required this.alert,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    // Determine color based on severity
    Color severityColor;
    IconData severityIcon;
    
    switch (alert.severity) {
      case AlertSeverity.high:
        severityColor = Colors.red;
        severityIcon = Icons.warning_rounded;
        break;
      case AlertSeverity.medium:
        severityColor = Colors.orange;
        severityIcon = Icons.warning_amber_rounded;
        break;
      default:
        severityColor = Colors.blue;
        severityIcon = Icons.info_outline;
        break;
    }
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: severityColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          _showAlertDialog(context);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    severityIcon,
                    color: severityColor,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      alert.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (onDismiss != null)
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () {
                        if (onDismiss != null) {
                          onDismiss!();
                        }
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _getShortMessage(alert.message),
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDate(alert.lastUpdated),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    'Tap for details',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.accentColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showAlertDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              _getSeverityIcon(),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  alert.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alert.message),
                const SizedBox(height: 16),
                Text(
                  'Detected on: ${_formatDate(alert.lastUpdated)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('CLOSE'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Navigate to the educational screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HealthEducationScreen(
                      condition: alert.title,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('LEARN MORE'),
            ),
          ],
        );
      },
    );
  }
  
  Widget _getSeverityIcon() {
    IconData iconData;
    Color iconColor;
    
    switch (alert.severity) {
      case AlertSeverity.high:
        iconData = Icons.warning_rounded;
        iconColor = Colors.red;
        break;
      case AlertSeverity.medium:
        iconData = Icons.warning_amber_rounded;
        iconColor = Colors.orange;
        break;
      default:
        iconData = Icons.info_outline;
        iconColor = Colors.blue;
        break;
    }
    
    return Icon(
      iconData,
      color: iconColor,
    );
  }
  
  String _getShortMessage(String message) {
    // Remove markdown formatting for cleaner preview
    String cleanMessage = message.replaceAll(RegExp(r'\*\*|\*|`|#'), '');
    
    // If the message contains recommendations, only show the first part
    if (cleanMessage.contains('Recommendations:')) {
      return cleanMessage.split('Recommendations:')[0].trim();
    }
    
    return cleanMessage;
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
} 