import 'package:flutter/material.dart';
import 'package:health_app/models/health_data.dart';
import 'package:health_app/theme/app_theme.dart';

class HealthReportWidget extends StatelessWidget {
  final HealthReport report;
  final VoidCallback onTap;

  const HealthReportWidget({
    Key? key,
    required this.report,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Report icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getReportColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getReportIcon(),
                    color: _getReportColor(),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Report details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(report.lastUpdated),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.secondaryTextColor,
                        ),
                      ),
                      
                      if (report.extractedData.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        // Data preview
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: _buildDataPreview(context),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Arrow icon
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppTheme.secondaryTextColor,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDataPreview(BuildContext context) {
    // Show only first 2 items with key-value pairs
    final previewData = report.extractedData.entries.take(2).toList();
    
    return previewData.map((entry) => Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            entry.key,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.secondaryTextColor,
            ),
          ),
          Text(
            entry.value.toString(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    )).toList();
  }

  IconData _getReportIcon() {
    switch (report.type) {
      case 'ultrasound':
        return Icons.pregnant_woman_rounded;
      case 'lab_report':
        return Icons.biotech_outlined;
      case 'prescription':
        return Icons.receipt_long_outlined;
      case 'vaccination':
        return Icons.vaccines_outlined;
      default:
        return Icons.description_outlined;
    }
  }

  Color _getReportColor() {
    switch (report.type) {
      case 'ultrasound':
        return const Color(0xFF8C9EFF);
      case 'lab_report':
        return const Color(0xFF4FC3F7);
      case 'prescription':
        return const Color(0xFFFFD54F);
      case 'vaccination':
        return const Color(0xFF81C784);
      default:
        return AppTheme.primaryColor;
    }
  }
  
  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
} 