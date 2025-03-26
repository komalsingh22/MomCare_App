import 'package:flutter/material.dart';
import 'package:health_app/models/health_data.dart';
import 'package:health_app/theme/app_theme.dart';
import 'package:health_app/utils/date_utils.dart' as app_date_utils;

class HealthReportWidget extends StatelessWidget {
  final HealthReport report;
  final VoidCallback? onTap;

  const HealthReportWidget({
    super.key,
    required this.report,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getReportIcon(),
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        report.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  Text(
                    'Added: ${app_date_utils.DateUtils.formatLastUpdated(report.lastUpdated)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...report.extractedData.entries.map((entry) => _buildDataItem(context, entry)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataItem(BuildContext context, MapEntry<String, dynamic> entry) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${entry.key}: ',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Expanded(
            child: Text(
              entry.value.toString(),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getReportIcon() {
    switch (report.type) {
      case 'ultrasound':
        return Icons.pregnant_woman_rounded;
      case 'lab_report':
        return Icons.science_outlined;
      case 'vaccination':
        return Icons.vaccines_outlined;
      case 'prescription':
        return Icons.medication_outlined;
      default:
        return Icons.description_outlined;
    }
  }
} 