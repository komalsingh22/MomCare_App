import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:health_app/models/health_data.dart';
import 'package:health_app/services/database_service.dart';

class HealthDataService {
  static final HealthDataService _instance = HealthDataService._internal();
  final DatabaseService _databaseService = DatabaseService.instance;
  
  // Base URL for the API - to match ApiService
  late final String _baseUrl;

  factory HealthDataService() {
    return _instance;
  }

  HealthDataService._internal() {
    // Determine the appropriate base URL based on platform
    if (kIsWeb) {
      // For web, always use the actual localhost without port remapping
      _baseUrl = 'http://localhost:8080/api'; // Web development
    } else if (Platform.isAndroid) {
      _baseUrl = 'http://10.0.2.2:8080/api'; // Android emulator needs special IP
    } else if (Platform.isIOS) {
      _baseUrl = 'http://localhost:8080/api'; // iOS simulator
    } else {
      _baseUrl = 'http://localhost:8080/api'; // Default fallback
    }
    print('Initialized Health Data Service with baseUrl: $_baseUrl');
  }
  
  // Common headers for API requests
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    // Add any other headers needed
  };

  Future<String> getHealthInsights(HealthData healthData) async {
    try {
      final url = Uri.parse('$_baseUrl/analyze');
      print('Requesting health insights from: ${url.toString()}');
      
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode(healthData.toJson()),
      );

      print('Health insights response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        return response.body;
      } else {
        print('Error response body: ${response.body}');
        throw Exception('Failed to get health insights: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting health insights: $e');
      rethrow;
    }
  }
} 