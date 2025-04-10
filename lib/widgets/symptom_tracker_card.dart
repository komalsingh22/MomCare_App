import 'package:flutter/material.dart';
import 'package:health_app/models/health_data.dart';

class SymptomTrackerCard extends StatelessWidget {
  final HealthData healthData;

  const SymptomTrackerCard({
    super.key,
    required this.healthData,
  });

  @override
  Widget build(BuildContext context) {
    if (healthData is! PregnancyData) {
      return const SizedBox.shrink();
    }

    final pregnancyData = healthData as PregnancyData;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pregnancy Progress',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildProgressIndicator(pregnancyData),
            const SizedBox(height: 16),
            const Text(
              'Milestones',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...pregnancyData.milestones.map((milestone) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    milestone.isCompleted ? Icons.check_circle : Icons.circle_outlined,
                    color: milestone.isCompleted ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          milestone.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (milestone.completedDate != null)
                          Text(
                            'Completed on: ${milestone.completedDate!.toString()}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(PregnancyData data) {
    final progress = data.currentMonth / 9.0; // Assuming 9 months pregnancy
    final remainingMonths = 9 - data.currentMonth;

    return Column(
      children: [
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade400),
          minHeight: 8,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Month ${data.currentMonth}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '$remainingMonths months remaining',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ],
    );
  }
} 