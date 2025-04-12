// This file is automatically imported when running on web platforms
// File: lib/services/api_service_web.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:health_app/models/health_data.dart';
import 'package:http/http.dart' as http;
import 'package:health_app/constants/constants.dart';

// Web-specific implementation
class ApiServiceWeb {
  // Return true if this implementation should be used (web platform)
  static bool get shouldUse => kIsWeb;
  
  // Base API URL for web - ensure this matches the backend URL
  final String baseUrl = '$backendUrl/api';
  
  // Get headers with proper content types but NO CORS headers
  // (CORS headers must only be set by the server)
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  // Helper method to create a properly formatted URI
  Uri getUri(String endpoint) {
    final path = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    final url = '$baseUrl/$path'.replaceAll('//', '/').replaceAll('://', '://');
    print('Web API URL: $url');
    return Uri.parse(url);
  }
  
  // Save health data
  Future<int> saveHealthData(Map<String, dynamic> data) async {
    try {
      print('Web API: Saving health data');
      final url = getUri('health-data');
      print('POST request to: $url');
      
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode(data),
      );
      
      print('Web API response: ${response.statusCode}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body)['id'];
      } else {
        throw Exception('Failed to save health data: ${response.statusCode}');
      }
    } catch (e) {
      print('Web API error: $e');
      rethrow;
    }
  }
  
  // Get latest health data
  Future<Map<String, dynamic>?> getLatestHealthData() async {
    try {
      print('Web API: Getting latest health data');
      
      final response = await http.get(
        getUri('health-data/latest'),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to get latest health data: ${response.statusCode}');
      }
    } catch (e) {
      print('Web API error: $e');
      return null;
    }
  }
  
  // Get vital signs
  Future<List<VitalSign>> getVitalSigns() async {
    try {
      print('Web API: Getting vital signs');
      
      final response = await http.get(
        getUri('health-data'),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isEmpty) {
          return [
            Weight(id: '1', lastUpdated: DateTime.now(), value: '65', history: []),
            BloodPressure(id: '2', lastUpdated: DateTime.now(), systolic: '120', diastolic: '80', history: []),
            Temperature(id: '3', lastUpdated: DateTime.now(), value: '36.7', history: []),
          ];
        }
        
        // Process data...
        // Implementation would be similar to regular ApiService
        return [
          Weight(id: '1', lastUpdated: DateTime.now(), value: '65', history: []),
          BloodPressure(id: '2', lastUpdated: DateTime.now(), systolic: '120', diastolic: '80', history: []),
          Temperature(id: '3', lastUpdated: DateTime.now(), value: '36.7', history: []),
        ];
      } else {
        throw Exception('Failed to get vital signs: ${response.statusCode}');
      }
    } catch (e) {
      print('Web API error: $e');
      return [
        Weight(id: '1', lastUpdated: DateTime.now(), value: '65', history: []),
        BloodPressure(id: '2', lastUpdated: DateTime.now(), systolic: '120', diastolic: '80', history: []),
        Temperature(id: '3', lastUpdated: DateTime.now(), value: '36.7', history: []),
      ];
    }
  }
} 