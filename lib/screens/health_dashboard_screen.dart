import 'package:flutter/material.dart';
import 'package:health_app/models/health_data.dart';
import 'package:health_app/screens/update_health_data_screen.dart';
import 'package:health_app/theme/app_theme.dart';
import 'package:health_app/utils/connectivity_helper.dart';
import 'package:health_app/widgets/health_alerts_list.dart';
import 'package:health_app/widgets/offline_indicator.dart';
import 'package:health_app/widgets/health_report_widget.dart';
import 'package:health_app/widgets/mood_widget.dart';
import 'package:health_app/widgets/pregnancy_progress_widget.dart';
import 'package:health_app/utils/date_utils.dart' as app_date_utils;
import 'package:health_app/services/database_service.dart';
import 'package:health_app/services/ai_service.dart';
import 'package:health_app/screens/all_health_alerts_screen.dart';
import 'package:fl_chart/fl_chart.dart';


class HealthDashboardScreen extends StatefulWidget {
  const HealthDashboardScreen({super.key});

  @override
  State<HealthDashboardScreen> createState() => _HealthDashboardScreenState();
}

class _HealthDashboardScreenState extends State<HealthDashboardScreen> {
  late ConnectivityHelper _connectivityHelper;
  bool _isOffline = false;
  
  // Data
  late PregnancyData _pregnancyData;
  late List<VitalSign> _vitalSigns = [];
  late MoodData _moodData;
  late List<HealthReport> _healthReports;
  late List<HealthAlert> _healthAlerts = [];
  final DatabaseService _databaseService = DatabaseService();
  final AIService _aiService = AIService();
  bool _isLoading = true;
  
  // Latest health data
  Map<String, dynamic>? _latestHealthData;

  @override
  void initState() {
    super.initState();
    _connectivityHelper = ConnectivityHelper();
    _connectivityHelper.connectionStatus.listen((isConnected) {
      setState(() {
        _isOffline = !isConnected;
      });
    });
    
    // Initialize with mock data as a fallback only
    _loadMockData();
    
    // Load real data from database (which will override mock data)
    _loadData();
  }

  void _loadMockData() {
    _pregnancyData = MockHealthDataProvider.getPregnancyData();
    _moodData = MockHealthDataProvider.getMoodData();
    _healthReports = MockHealthDataProvider.getHealthReports();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('Loading dashboard data...');
      
      // Get vital signs (weight, BP, etc.)
      final vitalSigns = await _databaseService.getVitalSigns();
      print('Loaded ${vitalSigns.length} vital signs');
      
      // Get latest health data for AI analysis
      final latestHealthData = await _databaseService.getLatestHealthData();
      
      // Run AI analysis on the data
      final aiAlerts = await _aiService.analyzeHealthData(latestHealthData ?? {});
      print('AI analysis generated ${aiAlerts.length} health alerts');
      
      // Get health alerts (combining existing alerts with AI-generated ones)
      final dbAlerts = await _databaseService.getHealthAlerts();
      final allAlerts = [...dbAlerts, ...aiAlerts];
      
      // Save AI-generated alerts to database
      for (var alert in aiAlerts) {
        await _databaseService.saveHealthAlert(alert);
      }
      
      // Load mood data using the new method
      final moodData = await _databaseService.getMoodData();
      print('MOOD DATA from DB: Current rating = ${moodData['currentMoodRating']}, History entries = ${moodData['moodHistory'].length}');

      // Get pregnancy data if available
      final pregnancyData = await _databaseService.getPregnancyData();
      
      setState(() {
        _vitalSigns = vitalSigns;
        _healthAlerts = allAlerts;
        _latestHealthData = latestHealthData;
        
        // Update pregnancy data if available
        if (pregnancyData != null && 
            pregnancyData['due_date'] != null && 
            pregnancyData['due_date'].isNotEmpty) {
          _pregnancyData = PregnancyData(
            id: _pregnancyData.id,
            lastUpdated: DateTime.now(),
            currentMonth: pregnancyData['current_month'] ?? 1,
            dueDate: DateTime.parse(pregnancyData['due_date']),
            milestones: _pregnancyData.milestones,
          );
          print('Updated pregnancy data: Due date: ${pregnancyData['due_date']}, Month: ${pregnancyData['current_month']}');
        } else {
          _pregnancyData = PregnancyData(
            id: _pregnancyData.id,
            lastUpdated: DateTime.now(),
            currentMonth: 1,
            dueDate: DateTime.now(),
            milestones: _pregnancyData.milestones,
          );
        }
        
        // Update mood data - IMPORTANT part
        if (moodData['currentMoodRating'] != null) {
          // Log previous mood data
          print('DASHBOARD: Updating mood from ${_moodData.rating} to ${moodData['currentMoodRating']}');
          
          List<dynamic> historyEntries = [];
          
          for (var entry in moodData['moodHistory']) {
            historyEntries.add({
              'date': entry['date'],
              'rating': entry['rating'],
            });
          }
          
          _moodData = MoodData(
            id: _moodData.id,
            lastUpdated: DateTime.now(),
            rating: moodData['currentMoodRating'],
            history: historyEntries,
          );
          
          // Log updated mood data for verification
          print('DASHBOARD: Updated mood to rating = ${_moodData.rating}, History size = ${_moodData.history?.length ?? 0}');
        } else {
          print('DASHBOARD: No mood data found, keeping current value of ${_moodData.rating}');
        }
        
        _isLoading = false;
      });
      
      print('Dashboard data load complete');
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _connectivityHelper.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  child: Column(
                    children: [
                      // Offline indicator
                      OfflineIndicator(
                        isOffline: _isOffline,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Checking network connection...'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                      
                      // Header
                      _buildHeader(),
                      
                      // Main content (scrollable)
                      Column(
                        children: [
                          // Pregnancy Progress Widget
                          PregnancyProgressWidget(
                            pregnancyData: _pregnancyData,
                            onTap: () {},
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Section title
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
                            child: Row(
                              children: [
                                Container(
                                  height: 18,
                                  width: 3,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Vital Signs',
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Vital Signs Grid
                          GridView.count(
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            shrinkWrap: true,
                            childAspectRatio: 0.85,
                            children: _vitalSigns.map((vitalSign) {
                              IconData icon;
                              Color iconColor;
                              LinearGradient? gradient;
                              
                              if (vitalSign is Weight) {
                                icon = Icons.monitor_weight_outlined;
                                iconColor = const Color(0xFFE667A0);
                                gradient = const LinearGradient(
                                  colors: [Color(0xFFFFE0EB), Color(0xFFFFF5F8)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                );
                              } else if (vitalSign is BloodPressure) {
                                icon = Icons.favorite_outline;
                                iconColor = const Color(0xFFFF5C8A);
                                gradient = const LinearGradient(
                                  colors: [Color(0xFFFFE4EA), Color(0xFFFFF6F8)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                );
                              } else if (vitalSign is Temperature) {
                                icon = Icons.thermostat_outlined;
                                iconColor = const Color(0xFFFF8E7F);
                                gradient = const LinearGradient(
                                  colors: [Color(0xFFFFECE8), Color(0xFFFFF9F8)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                );
                              } else {
                                icon = Icons.medical_services_outlined;
                                iconColor = AppTheme.primaryColor;
                                gradient = null;
                              }
                              
                              return _buildVitalSignCard(
                                context,
                                vitalSign: vitalSign,
                                icon: icon,
                                iconColor: iconColor.withOpacity(0.5),
                                gradient: gradient,
                              );
                            }).toList(),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Mental Health Widget
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
                            child: Row(
                              children: [
                                Container(
                                  height: 18,
                                  width: 3,
                                  decoration: BoxDecoration(
                                    color: AppTheme.secondaryColor,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Mental Health',
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          MoodWidget(
                            moodData: _moodData,
                            onTap: () {},
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Health Alerts
                          if (_healthAlerts.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
                              child: Row(
                                children: [
                                  Container(
                                    height: 18,
                                    width: 3,
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade300,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Alerts',
                                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            HealthAlertsList(
                              alerts: _healthAlerts,
                              onDismiss: _dismissAlert,
                              onSeeAll: () => Navigator.push(
                                context, 
                                MaterialPageRoute(
                                  builder: (context) => const AllHealthAlertsScreen(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                          
                          // Section title
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
                            child: Row(
                              children: [
                                Container(
                                  height: 18,
                                  width: 3,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Health Reports',
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Health Reports
                          ..._healthReports.map((report) => Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: HealthReportWidget(
                              report: report,
                              onTap: () {},
                            ),
                          )),
                          
                          const SizedBox(height: 80),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
      ),
      floatingActionButton: _buildUpdateDataButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor,
            offset: Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.5),
                      offset: const Offset(0, 3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.pregnant_woman_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EmpowerHer',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Maternal Wellness',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.secondaryTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          // Profile icon with popup menu
          PopupMenuButton(
            offset: const Offset(0, 40),
            icon: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.secondaryColor,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const CircleAvatar(
                    backgroundColor: AppTheme.secondaryColor,
                    radius: 20,
                    child: Icon(
                      Icons.person_outline,
                      color: Colors.white,
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppTheme.accentColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Text(
                      '1',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline),
                    SizedBox(width: 8),
                    Text('Profile'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'api_key',
                child: Row(
                  children: [
                    Icon(Icons.smart_toy_outlined),
                    SizedBox(width: 8),
                    Text('AI Features Setup'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined),
                    SizedBox(width: 8),
                    Text('Settings'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'api_key') {
                Navigator.pushNamed(context, '/api_key_setup');
              } else if (value == 'profile') {
                // TODO: Navigate to profile
              } else if (value == 'settings') {
                // TODO: Navigate to settings
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVitalSignCard(BuildContext context, {
    required VitalSign vitalSign,
    required IconData icon,
    required Color iconColor,
    LinearGradient? gradient,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient ?? const LinearGradient(
          colors: [Colors.white, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: iconColor,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {},
          splashColor: iconColor,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: iconColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: iconColor,
                        size: 24,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        app_date_utils.DateUtils.formatLastUpdated(vitalSign.lastUpdated),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.secondaryTextColor,
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                
                const Spacer(),
                
                Text(
                  vitalSign.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
                
                const SizedBox(height: 6),
                
                // Fixed overflow issue here
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        vitalSign.value,
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: iconColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        vitalSign.unit,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                
                if (vitalSign.history != null && vitalSign.history!.length > 1) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 40,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: _buildMiniChart(vitalSign, iconColor),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildMiniChart(VitalSign vitalSign, Color color) {
    final List<double> dataPoints = [];
    final List<DateTime> dates = [];
    
    if (vitalSign is BloodPressure) {
      for (final entry in vitalSign.history!) {
        final systolic = double.tryParse(entry['systolic'] ?? '0') ?? 0;
        dataPoints.add(systolic);
        if (entry['date'] is DateTime) {
          dates.add(entry['date'] as DateTime);
        }
      }
    } else {
      for (final entry in vitalSign.history!) {
        final value = double.tryParse(entry['value'] ?? '0') ?? 0;
        dataPoints.add(value);
        if (entry['date'] is DateTime) {
          dates.add(entry['date'] as DateTime);
        }
      }
    }
    
    if (dataPoints.isEmpty) {
      return Container(height: 40);
    }

    // Create spots for LineChart
    final spots = List<FlSpot>.generate(
      dataPoints.length,
      (i) => FlSpot(i.toDouble(), dataPoints[i]),
    );

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: color.withOpacity(0.2),
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.6),
                  color.withOpacity(0.01),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            shadow: Shadow(
              color: color.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 3),
            ),
          ),
        ],
        lineTouchData: const LineTouchData(enabled: false),
        backgroundColor: Colors.transparent,
      ),
    );
  }

  Widget _buildUpdateDataButton() {
    return FloatingActionButton.extended(
      onPressed: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const UpdateHealthDataScreen(),
          ),
        );
        
        if (result == true) {
          // Refresh data if returned with true (data was saved)
          _loadData();
        }
      },
      label: const Text('Update Data'),
      icon: const Icon(Icons.edit_outlined),
      backgroundColor: AppTheme.accentColor,
    );
  }

  Future<void> _dismissAlert(HealthAlert alert) async {
    try {
      await _databaseService.markHealthAlertAsRead(alert.id);
      setState(() {
        _healthAlerts.removeWhere((a) => a.id == alert.id);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Alert dismissed'),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: _loadData,
          ),
        ),
      );
    } catch (e) {
      print('Error dismissing health alert: $e');
    }
  }
}