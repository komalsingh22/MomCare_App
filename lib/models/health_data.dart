class HealthData {
  final String id;
  final DateTime lastUpdated;
  
  HealthData({
    required this.id,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}

class PregnancyData extends HealthData {
  final int currentMonth;
  final DateTime dueDate;
  final List<Milestone> milestones;

  PregnancyData({
    required super.id,
    required super.lastUpdated,
    required this.currentMonth,
    required this.dueDate,
    required this.milestones,
  });
}

class Milestone {
  final String title;
  final bool isCompleted;
  final DateTime? completedDate;

  Milestone({
    required this.title,
    required this.isCompleted,
    this.completedDate,
  });
}

class VitalSign extends HealthData {
  final String name;
  final String value;
  final String unit;
  final List<dynamic>? history;

  VitalSign({
    required super.id,
    required super.lastUpdated,
    required this.name,
    required this.value,
    required this.unit,
    this.history,
  });
}

class BloodPressure extends VitalSign {
  final String systolic;
  final String diastolic;

  BloodPressure({
    required super.id,
    required super.lastUpdated,
    required this.systolic,
    required this.diastolic,
    super.history,
  }) : super(
          name: 'Blood Pressure',
          value: '$systolic/$diastolic',
          unit: 'mmHg',
        );
}

class Weight extends VitalSign {
  Weight({
    required super.id,
    required super.lastUpdated,
    required super.value,
    super.history,
  }) : super(
          name: 'Weight',
          unit: 'kg',
        );
}

class Temperature extends VitalSign {
  Temperature({
    required super.id,
    required super.lastUpdated,
    required super.value,
    super.history,
  }) : super(
          name: 'Temperature',
          unit: '°C',
        );
}

class MoodData extends HealthData {
  final int rating;
  final List<dynamic>? history;

  MoodData({
    required super.id,
    required super.lastUpdated,
    required this.rating,
    this.history,
  });
}

class HealthReport extends HealthData {
  final String title;
  final String type;
  final Map<String, dynamic> extractedData;
  final String? fileUrl;

  HealthReport({
    required super.id,
    required super.lastUpdated,
    required this.title,
    required this.type,
    required this.extractedData,
    this.fileUrl,
  });
}

class HealthAlert extends HealthData {
  final String title;
  final String message;
  final AlertSeverity severity;

  HealthAlert({
    required super.id,
    required super.lastUpdated,
    required this.title,
    required this.message,
    required this.severity,
  });
}

enum AlertSeverity {
  low,
  medium,
  high,
}

// Mock data provider for testing
class MockHealthDataProvider {
  static PregnancyData getPregnancyData() {
    return PregnancyData(
      id: '1',
      lastUpdated: DateTime.now().subtract(const Duration(days: 2)),
      currentMonth: 5,
      dueDate: DateTime.now().add(const Duration(days: 120)),
      milestones: [
        Milestone(
          title: 'First Check-up',
          isCompleted: true,
          completedDate: DateTime.now().subtract(const Duration(days: 60)),
        ),
        Milestone(
          title: 'Vaccination Complete',
          isCompleted: false,
          completedDate: null,
        ),
        Milestone(
          title: 'Ultrasound',
          isCompleted: true,
          completedDate: DateTime.now().subtract(const Duration(days: 15)),
        ),
      ],
    );
  }

  static List<VitalSign> getVitalSigns() {
    return [
      Weight(
        id: '2',
        lastUpdated: DateTime.now().subtract(const Duration(days: 3)),
        value: '65',
        history: [
          {'date': DateTime.now().subtract(const Duration(days: 30)), 'value': '63'},
          {'date': DateTime.now().subtract(const Duration(days: 15)), 'value': '64'},
          {'date': DateTime.now().subtract(const Duration(days: 3)), 'value': '65'},
        ],
      ),
      BloodPressure(
        id: '3',
        lastUpdated: DateTime.now().subtract(const Duration(days: 1)),
        systolic: '120',
        diastolic: '80',
        history: [
          {'date': DateTime.now().subtract(const Duration(days: 30)), 'systolic': '118', 'diastolic': '78'},
          {'date': DateTime.now().subtract(const Duration(days: 15)), 'systolic': '122', 'diastolic': '82'},
          {'date': DateTime.now().subtract(const Duration(days: 1)), 'systolic': '120', 'diastolic': '80'},
        ],
      ),
      Temperature(
        id: '4',
        lastUpdated: DateTime.now().subtract(const Duration(days: 1)),
        value: '36.7',
        history: [
          {'date': DateTime.now().subtract(const Duration(days: 30)), 'value': '36.5'},
          {'date': DateTime.now().subtract(const Duration(days: 15)), 'value': '36.8'},
          {'date': DateTime.now().subtract(const Duration(days: 1)), 'value': '36.7'},
        ],
      ),
    ];
  }

  static MoodData getMoodData() {
    return MoodData(
      id: '5',
      lastUpdated: DateTime.now().subtract(const Duration(days: 1)),
      rating: 4,
      history: [
        {'date': DateTime.now().subtract(const Duration(days: 30)), 'rating': 3},
        {'date': DateTime.now().subtract(const Duration(days: 15)), 'rating': 4},
        {'date': DateTime.now().subtract(const Duration(days: 5)), 'rating': 2},
        {'date': DateTime.now().subtract(const Duration(days: 1)), 'rating': 4},
      ],
    );
  }

  static List<HealthReport> getHealthReports() {
    return [
      HealthReport(
        id: '6',
        lastUpdated: DateTime.now().subtract(const Duration(days: 15)),
        title: 'Ultrasound Report',
        type: 'ultrasound',
        extractedData: {
          'Fetal measurements': '23 cm',
          'Heart rate': '145 bpm',
          'Gender': 'Female',
        },
      ),
      HealthReport(
        id: '7',
        lastUpdated: DateTime.now().subtract(const Duration(days: 30)),
        title: 'Blood Test',
        type: 'lab_report',
        extractedData: {
          'Hemoglobin': '12.5 g/dL',
          'RBC Count': '4.5 million/mcL',
          'WBC Count': '8,000/mcL',
        },
      ),
    ];
  }

  static List<HealthAlert> getHealthAlerts() {
    return [
      HealthAlert(
        id: '8',
        lastUpdated: DateTime.now().subtract(const Duration(hours: 12)),
        title: 'Abnormal Blood Pressure',
        message: 'Your blood pressure reading is higher than your average. Consider resting and measuring again.',
        severity: AlertSeverity.medium,
      ),
      HealthAlert(
        id: '9',
        lastUpdated: DateTime.now().subtract(const Duration(days: 2)),
        title: 'Missed Medication',
        message: 'You may have missed your prenatal vitamins yesterday. Try to maintain your regular schedule.',
        severity: AlertSeverity.low,
      ),
    ];
  }
} 