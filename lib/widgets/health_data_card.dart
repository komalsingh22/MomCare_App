import 'package:flutter/material.dart';
import 'package:health_app/models/health_data.dart';

class HealthDataCard extends StatelessWidget {
  final HealthData healthData;

  const HealthDataCard({
    super.key,
    required this.healthData,
  });

  @override
  Widget build(BuildContext context) {
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
            Text(
              'Health Data - ${healthData.lastUpdated.toString()}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (healthData is PregnancyData) ...[
              _buildPregnancyData(healthData as PregnancyData),
            ] else if (healthData is VitalSign) ...[
              _buildVitalSignData(healthData as VitalSign),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPregnancyData(PregnancyData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDataRow('Current Month', '${data.currentMonth}'),
        _buildDataRow('Due Date', data.dueDate.toString()),
        const SizedBox(height: 8),
        const Text(
          'Milestones:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        ...data.milestones.map((milestone) => Padding(
          padding: const EdgeInsets.only(left: 8, top: 4),
          child: Row(
            children: [
              Icon(
                milestone.isCompleted ? Icons.check_circle : Icons.circle_outlined,
                color: milestone.isCompleted ? Colors.green : Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(milestone.title),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildVitalSignData(VitalSign data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDataRow(data.name, '${data.value} ${data.unit}'),
        if (data is BloodPressure) ...[
          _buildDataRow('Systolic', data.systolic),
          _buildDataRow('Diastolic', data.diastolic),
        ],
        if (data.history != null && data.history!.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text(
            'History:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          ...data.history!.map((item) => Padding(
            padding: const EdgeInsets.only(left: 8, top: 4),
            child: Text(item.toString()),
          )),
        ],
      ],
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
} 