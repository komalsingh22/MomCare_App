import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:health_app/models/health_data.dart';

class AIService {
  static final AIService _instance = AIService._internal();
  late final GenerativeModel? _model;
  bool _isModelInitialized = false;

  factory AIService() {
    return _instance;
  }

  AIService._internal() {
    try {
      _model = GenerativeModel(
        model: 'gemini-pro',
        apiKey: 'PLACEHOLDER_API_KEY', // Replace with actual key in production
      );
      _isModelInitialized = true;
    } catch (e) {
      print('Error initializing Gemini model: $e');
      _model = null;
      _isModelInitialized = false;
    }
  }

  Future<HealthAlert?> analyzeHealthData(List<VitalSign> vitalSigns) async {
    try {
      // If model isn't initialized, fall back to rule-based analysis
      if (!_isModelInitialized || _model == null) {
        return _fallbackAnalysis(vitalSigns);
      }

      // Prepare health data for analysis
      final healthData = vitalSigns.map((vitalSign) {
        return '${vitalSign.name}: ${vitalSign.value} ${vitalSign.unit}';
      }).join('\n');

      // Create prompt for analysis
      final prompt = '''
        Analyze the following maternal health data and identify any potential risks or concerns:
        $healthData
        
        Consider normal ranges for pregnant women:
        - Blood Pressure: 90-140 mmHg systolic, 60-90 mmHg diastolic
        - Temperature: 36.1-37.2°C
        - Weight: Should increase gradually based on pre-pregnancy BMI
        - Heart Rate: 60-100 bpm
        
        If any values are concerning, provide a detailed analysis with severity level (high/medium/low).
      ''';

      // Get AI response
      final generatedContent = await _model.generateContent([Content.text(prompt)]);
      final analysis = generatedContent.text;

      // Parse AI response to determine if there's a health alert
      if (analysis != null && (
          analysis.toLowerCase().contains('high risk') ||
          analysis.toLowerCase().contains('concerning') ||
          analysis.toLowerCase().contains('warning'))) {
        
        // Determine severity based on analysis
        AlertSeverity severity = AlertSeverity.low;
        if (analysis.toLowerCase().contains('high risk')) {
          severity = AlertSeverity.high;
        } else if (analysis.toLowerCase().contains('moderate risk')) {
          severity = AlertSeverity.medium;
        }

        return HealthAlert(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: 'Health Analysis Alert',
          message: analysis,
          severity: severity,
          lastUpdated: DateTime.now(),
        );
      }

      return null;
    } catch (e) {
      print('Error in AI analysis: $e');
      return _fallbackAnalysis(vitalSigns);
    }
  }
  
  // Fallback method for when AI is not available
  HealthAlert? _fallbackAnalysis(List<VitalSign> vitalSigns) {
    // Check for concerning vital signs using simple rules
    for (final vitalSign in vitalSigns) {
      if (vitalSign is BloodPressure) {
        final systolic = double.tryParse(vitalSign.systolic) ?? 0;
        final diastolic = double.tryParse(vitalSign.diastolic) ?? 0;
        
        if (systolic > 140 || diastolic > 90) {
          return HealthAlert(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: 'Elevated Blood Pressure',
            message: 'Your blood pressure reading of ${vitalSign.value} is above the normal range for pregnant women. Please consult with your healthcare provider.',
            severity: systolic > 160 || diastolic > 100 ? AlertSeverity.high : AlertSeverity.medium,
            lastUpdated: DateTime.now(),
          );
        }
      } else if (vitalSign is Temperature) {
        final temp = double.tryParse(vitalSign.value) ?? 0;
        if (temp > 37.5) {
          return HealthAlert(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: 'Elevated Temperature',
            message: 'Your temperature of ${vitalSign.value}°C is above the normal range. Monitor for other symptoms and consult your healthcare provider if it persists.',
            severity: temp > 38.0 ? AlertSeverity.high : AlertSeverity.medium,
            lastUpdated: DateTime.now(),
          );
        }
      }
    }
    return null;
  }
} 