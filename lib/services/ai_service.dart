import 'package:http/http.dart' as http;
import 'package:health_app/constants/constants.dart';
import 'package:health_app/models/health_data.dart';
import 'package:health_app/services/database_service.dart';
import 'dart:convert';

class AIService {
  static final AIService _instance = AIService._internal();
  final DatabaseService _databaseService = DatabaseService.instance;
  
  factory AIService() {
    return _instance;
  }

  AIService._internal();

  Future<List<HealthAlert>> analyzeHealthData(Map<String, dynamic> latestData) async {
    try {
      final allHealthData = await _databaseService.getAllHealthData();
      final vitalSigns = await _databaseService.getVitalSigns();
      
      List<HealthAlert> alerts = [];
      
      // Send data to backend for analysis
      final response = await http.post(
        Uri.parse('$backendUrl/analyze'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'vitalSigns': vitalSigns,
          'healthData': allHealthData,
          'latestData': latestData
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['alerts'] != null) {
          alerts.addAll((data['alerts'] as List)
              .map((alert) => HealthAlert(
                id: alert['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
                title: alert['title'] ?? 'Alert',
                message: alert['message'] ?? '',
                severity: _parseSeverity(alert['severity']),
                lastUpdated: DateTime.parse(alert['lastUpdated'] ?? DateTime.now().toIso8601String()),
              ))
              .toList());
        }
      }

      return alerts;
    } catch (e) {
      print('Error analyzing health data: $e');
      return [];
    }
  }

  AlertSeverity _parseSeverity(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'high':
        return AlertSeverity.high;
      case 'medium':
        return AlertSeverity.medium;
      case 'low':
        return AlertSeverity.low;
      default:
        return AlertSeverity.medium;
    }
  }

  Future<String> chat(String message, {List<String>? context}) async {
    try {
      final response = await http.post(
        Uri.parse('$backendUrl/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'prompt': message}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response'] ?? 'Sorry, I could not process your request.';
      } else {
        throw Exception('Failed to get response from server: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in chat: $e');
      throw Exception('Failed to communicate with the server');
    }
  }

  Future<String> getEducationalContent(String condition) async {
    try {
      final response = await http.post(
        Uri.parse('$backendUrl/educational'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'condition': condition}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['content'] ?? _getDefaultEducationalContent(condition);
      } else {
        return _getDefaultEducationalContent(condition);
      }
    } catch (e) {
      print('Error getting educational content: $e');
      return _getDefaultEducationalContent(condition);
    }
  }

  String _getDefaultEducationalContent(String condition) {
    return '''
      Information about $condition

      Please consult with your healthcare provider to learn more about this condition and how it might affect your pregnancy. Regular prenatal care is essential for monitoring your health and addressing any concerns promptly.
      
      If you experience concerning symptoms, don't hesitate to contact your healthcare provider immediately.
    ''';
  }
}