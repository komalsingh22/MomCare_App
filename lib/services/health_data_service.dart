import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:health_app/models/health_data.dart';
import 'package:health_app/services/database_service.dart';

class HealthDataService {
  static final HealthDataService _instance = HealthDataService._internal();
  final DatabaseService _databaseService = DatabaseService.instance;
  final String _baseUrl = 'http://localhost:8080';

  factory HealthDataService() {
    return _instance;
  }

  HealthDataService._internal();

  Future<String> getHealthInsights(HealthData healthData) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/analyze'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(healthData.toJson()),
      );

      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception('Failed to get health insights: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting health insights: $e');
      rethrow;
    }
  }
} 