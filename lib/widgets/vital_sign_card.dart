import 'package:flutter/material.dart';
import 'package:health_app/models/health_data.dart';

class VitalSignCard extends StatelessWidget {
  final HealthData healthData;

  const VitalSignCard({
    super.key,
    required this.healthData,
  });

  @override
  Widget build(BuildContext context) {
    if (healthData is! VitalSign) {
      return const SizedBox.shrink();
    }

    final vitalSign = healthData as VitalSign;

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
              vitalSign.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildVitalSignValue(vitalSign),
            if (vitalSign.history != null && vitalSign.history!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'History',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...vitalSign.history!.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item['date'] ?? '',
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      '${item['value']} ${vitalSign.unit}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVitalSignValue(VitalSign vitalSign) {
    if (vitalSign is BloodPressure) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildValueCard('Systolic', vitalSign.systolic, 'mmHg'),
          _buildValueCard('Diastolic', vitalSign.diastolic, 'mmHg'),
        ],
      );
    }

    return _buildValueCard(vitalSign.name, vitalSign.value, vitalSign.unit);
  }

  Widget _buildValueCard(String label, String value, String unit) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$value $unit',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
} 