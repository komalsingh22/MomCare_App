import 'package:flutter/material.dart';
import 'package:health_app/models/health_data.dart';
import 'package:health_app/screens/update_health_data_screen.dart';
import 'package:health_app/theme/app_theme.dart';
import 'package:health_app/utils/connectivity_helper.dart';
import 'package:health_app/widgets/health_alert_widget.dart';
import 'package:health_app/widgets/health_report_widget.dart';
import 'package:health_app/widgets/mood_widget.dart';
import 'package:health_app/widgets/offline_indicator.dart';
import 'package:health_app/widgets/pregnancy_progress_widget.dart';
import 'package:health_app/utils/date_utils.dart' as app_date_utils;

class HealthDashboardScreen extends StatefulWidget {
  const HealthDashboardScreen({super.key});

  @override
  State<HealthDashboardScreen> createState() => _HealthDashboardScreenState();
}

class _HealthDashboardScreenState extends State<HealthDashboardScreen> {
  late ConnectivityHelper _connectivityHelper;
  bool _isOffline = false;
  
  // Mock data
  late PregnancyData _pregnancyData;
  late List<VitalSign> _vitalSigns;
  late MoodData _moodData;
  late List<HealthReport> _healthReports;
  late List<HealthAlert> _healthAlerts;

  @override
  void initState() {
    super.initState();
    _connectivityHelper = ConnectivityHelper();
    _connectivityHelper.connectionStatus.listen((isConnected) {
      setState(() {
        _isOffline = !isConnected;
      });
    });
    
    // Load mock data
    _loadMockData();
  }

  void _loadMockData() {
    _pregnancyData = MockHealthDataProvider.getPregnancyData();
    _vitalSigns = MockHealthDataProvider.getVitalSigns();
    _moodData = MockHealthDataProvider.getMoodData();
    _healthReports = MockHealthDataProvider.getHealthReports();
    _healthAlerts = MockHealthDataProvider.getHealthAlerts();
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
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await Future.delayed(const Duration(milliseconds: 1500));
                  _loadMockData();
                  setState(() {});
                },
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
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
                      
                      HealthAlertWidget(
                        alerts: _healthAlerts,
                        onTap: () {},
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
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 16, right: 16),
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          borderRadius: BorderRadius.circular(16),
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const UpdateHealthDataScreen(),
              ),
            );
          },
          backgroundColor: AppTheme.primaryColor,
          icon: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add, size: 22),
          ),
          label: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 12),
            child: Text(
              'Update Data',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor,
            offset: const Offset(0, 2),
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
          
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.secondaryColor,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  backgroundColor: AppTheme.secondaryColor,
                  radius: 20,
                  child: const Icon(
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
        gradient: gradient ?? LinearGradient(
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
    
    if (vitalSign is BloodPressure) {
      for (final entry in vitalSign.history!) {
        final systolic = double.tryParse(entry['systolic'] ?? '0') ?? 0;
        dataPoints.add(systolic);
      }
    } else {
      for (final entry in vitalSign.history!) {
        final value = double.tryParse(entry['value'] ?? '0') ?? 0;
        dataPoints.add(value);
      }
    }
    
    double minValue = dataPoints.reduce((a, b) => a < b ? a : b);
    double maxValue = dataPoints.reduce((a, b) => a > b ? a : b);
    double range = maxValue - minValue;
    
    List<double> normalizedData = dataPoints.map((value) {
      if (range == 0) return 0.5;
      return 0.2 + ((value - minValue) / range) * 0.6;
    }).toList();
    
    return CustomPaint(
      size: const Size(double.infinity, 40),
      painter: _ChartPainter(
        dataPoints: normalizedData,
        color: color,
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<double> dataPoints;
  final Color color;
  
  _ChartPainter({required this.dataPoints, required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;
    
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [color, color],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    
    final path = Path();
    final fillPath = Path();
    
    double stepX = size.width / (dataPoints.length - 1);
    
    path.moveTo(0, size.height * (1 - dataPoints.first));
    fillPath.moveTo(0, size.height);
    fillPath.lineTo(0, size.height * (1 - dataPoints.first));
    
    for (int i = 1; i < dataPoints.length; i++) {
      final x = stepX * i;
      final y = size.height * (1 - dataPoints[i]);
      path.lineTo(x, y);
      fillPath.lineTo(x, y);
    }
    
    fillPath.lineTo(size.width, size.height);
    fillPath.close();
    
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}