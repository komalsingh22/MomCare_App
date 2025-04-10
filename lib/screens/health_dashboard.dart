import 'package:flutter/material.dart';
import 'package:health_app/models/health_data.dart';
import 'package:health_app/services/api_service.dart';
import 'package:health_app/widgets/health_data_card.dart';
import 'package:health_app/widgets/vital_sign_card.dart';
import 'package:health_app/widgets/symptom_tracker_card.dart';

class HealthDashboard extends StatefulWidget {
  const HealthDashboard({super.key});

  @override
  State<HealthDashboard> createState() => _HealthDashboardState();
}

class _HealthDashboardState extends State<HealthDashboard> {
  final ApiService _apiService = ApiService.instance;
  bool _isLoading = false;
  bool _isLoadingHistory = false;
  bool _hasData = false;
  String? _error;
  HealthData? _healthData;
  List<HealthData> _allHealthData = [];

  @override
  void initState() {
    super.initState();
    _loadLatestHealthData();
    _fetchAllHealthData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadLatestHealthData();
              _fetchAllHealthData();
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadLatestHealthData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _loadLatestHealthData();
        await _fetchAllHealthData();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_healthData != null) ...[
            HealthDataCard(healthData: _healthData!),
            const SizedBox(height: 16),
            if (_healthData is VitalSign) VitalSignCard(healthData: _healthData!),
            const SizedBox(height: 16),
            if (_healthData is PregnancyData) SymptomTrackerCard(healthData: _healthData!),
          ],
          if (_allHealthData.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Health History',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ..._allHealthData.map((data) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: HealthDataCard(healthData: data),
            )),
          ],
        ],
      ),
    );
  }

  Future<void> _loadLatestHealthData() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final data = await _apiService.getLatestHealthData();
      print('Received health data: $data'); // Debug log
      
      if (data != null) {
        setState(() {
          _healthData = _convertToHealthData(data);
          _hasData = true;
          _error = null;
        });
      } else {
        setState(() {
          _hasData = false;
          _error = "No health data available yet";
        });
      }
    } catch (e) {
      setState(() {
        _error = "Error loading health data: $e";
        _hasData = false;
      });
      print("Error loading health data: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchAllHealthData() async {
    try {
      setState(() {
        _isLoadingHistory = true;
      });
      
      final dataList = await _apiService.getAllHealthData();
      
      setState(() {
        _allHealthData = dataList.map((data) => _convertToHealthData(data)).toList();
        _isLoadingHistory = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingHistory = false;
      });
      print("Error loading health history: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading health history: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  HealthData _convertToHealthData(Map<String, dynamic> data) {
    try {
      print('Converting health data: $data'); // Debug log
      
      // Extract common fields with null safety
      final id = data['id']?.toString() ?? '';
      final lastUpdated = DateTime.tryParse(data['lastUpdated']?.toString() ?? '') ?? DateTime.now();
      
      // Check if it's pregnancy data
      if (data['pregnancyMonth'] != null) {
        return PregnancyData(
          id: id,
          lastUpdated: lastUpdated,
          currentMonth: (data['pregnancyMonth'] as num?)?.toInt() ?? 0,
          dueDate: DateTime.tryParse(data['dueDate']?.toString() ?? '') ?? 
                  DateTime.now().add(const Duration(days: 280)),
          milestones: _parseMilestones(data['milestones']),
        );
      }
      
      // Check for vital signs
      if (data['systolicBP'] != null && data['diastolicBP'] != null) {
        return BloodPressure(
          id: id,
          lastUpdated: lastUpdated,
          systolic: data['systolicBP'].toString(),
          diastolic: data['diastolicBP'].toString(),
          history: _parseHistory(data['history']),
        );
      }
      
      if (data['weight'] != null) {
        return Weight(
          id: id,
          lastUpdated: lastUpdated,
          value: data['weight'].toString(),
          history: _parseHistory(data['history']),
        );
      }
      
      if (data['temperature'] != null) {
        return Temperature(
          id: id,
          lastUpdated: lastUpdated,
          value: data['temperature'].toString(),
          history: _parseHistory(data['history']),
        );
      }
      
      // Default to a basic VitalSign if no specific type is detected
      return VitalSign(
        id: id,
        lastUpdated: lastUpdated,
        name: data['name']?.toString() ?? 'Unknown',
        value: data['value']?.toString() ?? '0',
        unit: data['unit']?.toString() ?? '',
        history: _parseHistory(data['history']),
      );
    } catch (e, stackTrace) {
      print('Error converting health data: $e');
      print('Stack trace: $stackTrace');
      return VitalSign(
        id: '',
        lastUpdated: DateTime.now(),
        name: 'Error',
        value: '0',
        unit: '',
      );
    }
  }

  List<Milestone> _parseMilestones(dynamic milestonesData) {
    if (milestonesData == null) return [];
    try {
      final List<dynamic> milestonesList = milestonesData is List ? milestonesData : [];
      return milestonesList.map((m) => Milestone(
        title: m['title']?.toString() ?? '',
        isCompleted: m['isCompleted'] as bool? ?? false,
        completedDate: m['completedDate'] != null ? 
            DateTime.tryParse(m['completedDate'].toString()) : null,
      )).toList();
    } catch (e) {
      print('Error parsing milestones: $e');
      return [];
    }
  }

  List<dynamic>? _parseHistory(dynamic historyData) {
    if (historyData == null) return null;
    try {
      return historyData is List ? historyData : [];
    } catch (e) {
      print('Error parsing history: $e');
      return null;
    }
  }
} 