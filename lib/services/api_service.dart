import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:health_app/models/health_data.dart';

class ApiService {
  static final ApiService instance = ApiService._internal();

  // Base URL for the API - update to match your running backend
  late final String baseUrl;
  
  ApiService._internal() {
    // Determine the appropriate base URL based on platform
    if (kIsWeb) {
      // For web, use localhost:8080 directly without any remapping
      baseUrl = 'http://localhost:8080/api';
      print('Web platform detected. Using direct backend URL: $baseUrl');
    } else if (Platform.isAndroid) {
      baseUrl = 'http://10.0.2.2:8080/api'; // Android emulator needs special IP
    } else if (Platform.isIOS) {
      baseUrl = 'http://localhost:8080/api'; // iOS simulator
    } else {
      baseUrl = 'http://localhost:8080/api'; // Default fallback
    }
    print('Initialized API Service with baseUrl: $baseUrl');
  }
  
  // Common headers for API requests
  Map<String, String> get _headers {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    // Don't add CORS headers in the client - they should only be set by the server
    
    return headers;
  }
  
  // Helper method to create properly formatted URIs
  Uri getUri(String path) {
    final fullUrl = '$baseUrl/$path'.replaceAll('//', '/').replaceAll('://', '://');
    print('Creating URI: $fullUrl');
    return Uri.parse(fullUrl);
  }
  
  // Health Data Methods
  
  // Save health data to backend
  Future<int> saveHealthData({
    int? pregnancyMonth,
    String? dueDate,
    String? weight,
    String? height,
    String? systolicBP,
    String? diastolicBP,
    String? temperature,
    String? hemoglobin,
    String? glucose,
    String? symptoms,
    String? dietaryLog,
    String? physicalActivity,
    String? supplements,
    double? moodRating,
    bool? hasAnxiety,
    double? anxietyLevel,
  }) async {
    try {
      print('Saving health data via API');
      print('Using baseUrl: $baseUrl');
      
      // Create request body
      final Map<String, dynamic> data = {
        'pregnancyMonth': pregnancyMonth,
        'dueDate': dueDate,
        'weight': weight,
        'height': height,
        'systolicBP': systolicBP,
        'diastolicBP': diastolicBP,
        'temperature': temperature,
        'hemoglobin': hemoglobin,
        'glucose': glucose,
        'symptoms': symptoms,
        'dietaryLog': dietaryLog,
        'physicalActivity': physicalActivity,
        'supplements': supplements,
        'moodRating': moodRating,
        'hasAnxiety': hasAnxiety ?? false,
        'anxietyLevel': anxietyLevel,
      };
      
      // Remove null values
      data.removeWhere((key, value) => value == null);
      
      final url = Uri.parse('$baseUrl/health-data');
      print('Making request to: ${url.toString()}');
      
      // Send request to backend
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode(data),
      );
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('Health data saved successfully with ID: ${responseData['id']}');
        return responseData['id'];
      } else {
        throw Exception('Failed to save health data: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error saving health data via API: $e');
      rethrow;
    }
  }
  
  // Get latest health data
  Future<Map<String, dynamic>?> getLatestHealthData() async {
    try {
      final url = Uri.parse('$baseUrl/health-data/latest');
      print('Getting latest health data from: ${url.toString()}');
      
      final response = await http.get(
        url,
        headers: _headers,
      );
      
      print('Response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else if (response.statusCode == 404) {
        print('No health data found');
        return null; // No data found
      } else {
        print('Error response body: ${response.body}');
        throw Exception('Failed to fetch latest health data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching latest health data: $e');
      if (kIsWeb) {
        print('Web platform detected, CORS issue may have occurred. Try using a CORS proxy or check server headers.');
      }
      return null;
    }
  }
  
  // Get all health data entries
  Future<List<Map<String, dynamic>>> getAllHealthData() async {
    try {
      final url = Uri.parse('$baseUrl/health-data');
      print('Getting all health data from: ${url.toString()}');
      
      final response = await http.get(
        url,
        headers: _headers,
      );
      
      print('Response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Map<String, dynamic>.from(item)).toList();
      } else {
        print('Error response body: ${response.body}');
        throw Exception('Failed to fetch health data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching all health data: $e');
      return [];
    }
  }
  
  // Get vital signs
  Future<List<VitalSign>> getVitalSigns() async {
    try {
      final url = Uri.parse('$baseUrl/health-data');
      print('Getting vital signs from: ${url.toString()}');
      
      final response = await http.get(
        url,
        headers: _headers,
      );
      
      print('Response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isEmpty) {
          return [
            Weight(id: '1', lastUpdated: DateTime.now(), value: '65', history: []),
            BloodPressure(id: '2', lastUpdated: DateTime.now(), systolic: '120', diastolic: '80', history: []),
            Temperature(id: '3', lastUpdated: DateTime.now(), value: '36.7', history: []),
          ];
        }

        // Get the latest entry
        final latestData = data.first;
        final List<VitalSign> vitalSigns = [];

        // Process weight
        if (latestData['weight'] != null) {
          vitalSigns.add(Weight(
            id: latestData['id'].toString(),
            lastUpdated: DateTime.parse(latestData['timestamp']),
            value: latestData['weight'],
            history: _createHistoryFromData(data, 'weight'),
          ));
        }

        // Process blood pressure
        if (latestData['systolicBP'] != null && latestData['diastolicBP'] != null) {
          vitalSigns.add(BloodPressure(
            id: latestData['id'].toString(),
            lastUpdated: DateTime.parse(latestData['timestamp']),
            systolic: latestData['systolicBP'],
            diastolic: latestData['diastolicBP'],
            history: _createBPHistoryFromData(data),
          ));
        }

        // Process temperature
        if (latestData['temperature'] != null) {
          vitalSigns.add(Temperature(
            id: latestData['id'].toString(),
            lastUpdated: DateTime.parse(latestData['timestamp']),
            value: latestData['temperature'],
            history: _createHistoryFromData(data, 'temperature'),
          ));
        }

        return vitalSigns;
      } else {
        print('Error response body: ${response.body}');
        throw Exception('Failed to fetch vital signs: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching vital signs: $e');
      return [
        Weight(id: '1', lastUpdated: DateTime.now(), value: '65', history: []),
        BloodPressure(id: '2', lastUpdated: DateTime.now(), systolic: '120', diastolic: '80', history: []),
        Temperature(id: '3', lastUpdated: DateTime.now(), value: '36.7', history: []),
      ];
    }
  }
  
  // Helper method to create history from data
  List<Map<String, dynamic>> _createHistoryFromData(List<dynamic> data, String field) {
    return data.take(10).map((item) => {
      'date': DateTime.parse(item['timestamp']),
      'value': item[field],
    }).toList();
  }
  
  // Helper method to create blood pressure history from data
  List<Map<String, dynamic>> _createBPHistoryFromData(List<dynamic> data) {
    return data.take(10).map((item) => {
      'date': DateTime.parse(item['timestamp']),
      'systolic': item['systolicBP'],
      'diastolic': item['diastolicBP'],
    }).toList();
  }
  
  // Health Alerts
  
  // Get health alerts
  Future<List<HealthAlert>> getHealthAlerts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health-alerts?limit=10'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => HealthAlert(
          id: item['id'].toString(),
          title: item['title'],
          message: item['message'],
          severity: _parseSeverity(item['severity']),
          lastUpdated: DateTime.parse(item['timestamp']),
        )).toList();
      } else {
        throw Exception('Failed to fetch health alerts: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching health alerts: $e');
      return [];
    }
  }
  
  // Get all health alerts
  Future<List<HealthAlert>> getAllHealthAlerts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health-alerts'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => HealthAlert(
          id: item['id'].toString(),
          title: item['title'],
          message: item['message'],
          severity: _parseSeverity(item['severity']),
          lastUpdated: DateTime.parse(item['timestamp']),
        )).toList();
      } else {
        throw Exception('Failed to fetch all health alerts: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching all health alerts: $e');
      return [];
    }
  }
  
  // Save health alert
  Future<int> saveHealthAlert(HealthAlert alert) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/health-alerts'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': alert.title,
          'message': alert.message,
          'severity': alert.severity.index,
          'timestamp': alert.lastUpdated.toIso8601String(),
        }),
      );
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['id'];
      } else {
        throw Exception('Failed to save health alert: ${response.statusCode}');
      }
    } catch (e) {
      print('Error saving health alert: $e');
      return -1;
    }
  }
  
  // Mark health alert as read
  Future<void> markHealthAlertAsRead(String alertId) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/health-alerts/$alertId/read'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to mark health alert as read: ${response.statusCode}');
      }
    } catch (e) {
      print('Error marking health alert as read: $e');
      rethrow;
    }
  }
  
  // Mood Data
  
  // Get mood data
  Future<Map<String, dynamic>> getMoodData() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health-data'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isEmpty) {
          return {
            'currentMoodRating': null,
            'moodHistory': [],
          };
        }

        // Get current mood rating from latest entry
        final currentMoodRating = data.first['moodRating'];

        // Process history
        final moodHistory = data.take(7).map((item) => {
          'date': DateTime.parse(item['timestamp']),
          'rating': item['moodRating']?.round() ?? 0,
        }).toList();

        return {
          'currentMoodRating': currentMoodRating,
          'moodHistory': moodHistory,
        };
      } else {
        throw Exception('Failed to fetch mood data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching mood data: $e');
      return {
        'currentMoodRating': null,
        'moodHistory': [],
      };
    }
  }
  
  // Pregnancy Data
  
  // Get pregnancy data
  Future<Map<String, dynamic>?> getPregnancyData() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health-data/latest'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['pregnancyMonth'] == null && data['dueDate'] == null) {
          return null;
        }
        return {
          'pregnancyMonth': data['pregnancyMonth'],
          'dueDate': data['dueDate'],
        };
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to fetch pregnancy data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching pregnancy data: $e');
      return null;
    }
  }
  
  // Reminders
  
  // Get reminders
  Future<List<Map<String, dynamic>>> getReminders() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reminders'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Map<String, dynamic>.from(item)).toList();
      } else {
        throw Exception('Failed to fetch reminders: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching reminders: $e');
      return [];
    }
  }
  
  // Save reminder
  Future<int> saveReminder({
    required String title,
    String? description,
    required int reminderType,
    required DateTime date,
    required DateTime time,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reminders'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': title,
          'description': description,
          'reminderType': reminderType,
          'date': date.toIso8601String().split('T')[0],
          'time': '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
          'isCompleted': false,
        }),
      );
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['id'];
      } else {
        throw Exception('Failed to save reminder: ${response.statusCode}');
      }
    } catch (e) {
      print('Error saving reminder: $e');
      rethrow;
    }
  }
  
  // Update reminder
  Future<bool> updateReminder({
    required int id,
    String? title,
    String? description,
    int? reminderType,
    DateTime? date,
    DateTime? time,
    bool? isCompleted,
  }) async {
    try {
      // Build update payload
      Map<String, dynamic> updates = {};
      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (reminderType != null) updates['reminderType'] = reminderType;
      if (date != null) updates['date'] = date.toIso8601String().split('T')[0];
      if (time != null) updates['time'] = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      if (isCompleted != null) updates['isCompleted'] = isCompleted;
      
      final response = await http.patch(
        Uri.parse('$baseUrl/reminders/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updates),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error updating reminder: $e');
      return false;
    }
  }
  
  // Delete reminder
  Future<bool> deleteReminder(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/reminders/$id'),
        headers: {'Content-Type': 'application/json'},
      );
      
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Error deleting reminder: $e');
      return false;
    }
  }
  
  // Toggle reminder completion
  Future<bool> toggleReminderCompletion(int id) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/reminders/$id/toggle'),
        headers: {'Content-Type': 'application/json'},
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error toggling reminder completion: $e');
      return false;
    }
  }
  
  // Helper methods
  
  // Parse severity from string or int
  AlertSeverity _parseSeverity(dynamic severity) {
    if (severity is int) {
      return AlertSeverity.values[severity];
    } else if (severity is String) {
      switch (severity.toLowerCase()) {
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
    return AlertSeverity.medium;
  }
} 