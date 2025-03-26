import 'package:flutter/material.dart';
import 'package:health_app/theme/app_theme.dart';
import 'package:health_app/utils/date_utils.dart' as app_date_utils;
import 'package:fl_chart/fl_chart.dart';

class HealthParameterCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final DateTime lastUpdated;
  final List<dynamic>? history;
  final IconData icon;
  final Color? iconColor;
  final VoidCallback? onTap;

  const HealthParameterCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.lastUpdated,
    this.history,
    required this.icon,
    this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (iconColor ?? AppTheme.primaryColor).withOpacity(0.1),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: (iconColor ?? AppTheme.primaryColor).withOpacity(0.1),
          highlightColor: (iconColor ?? AppTheme.primaryColor).withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: (iconColor ?? AppTheme.primaryColor).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            icon,
                            color: iconColor ?? AppTheme.primaryColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 12,
                            color: AppTheme.secondaryTextColor.withOpacity(0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            app_date_utils.DateUtils.formatLastUpdated(lastUpdated),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      value,
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: iconColor ?? AppTheme.primaryTextColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        unit,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.secondaryTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                if (history != null && history!.length > 1) ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        height: 8,
                        width: 8,
                        decoration: BoxDecoration(
                          color: iconColor ?? AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Trend',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 70,
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: _getChartData(),
                            isCurved: true,
                            color: iconColor ?? AppTheme.primaryColor,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) {
                                return FlDotCirclePainter(
                                  radius: 3,
                                  color: iconColor ?? AppTheme.primaryColor,
                                  strokeWidth: 1,
                                  strokeColor: Colors.white,
                                );
                              },
                              checkToShowDot: (spot, barData) => 
                                spot.x == 0 || spot.x == barData.spots.length - 1,
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              color: (iconColor ?? AppTheme.primaryColor).withOpacity(0.15),
                              gradient: LinearGradient(
                                colors: [
                                  (iconColor ?? AppTheme.primaryColor).withOpacity(0.2),
                                  (iconColor ?? AppTheme.primaryColor).withOpacity(0.05),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ],
                        lineTouchData: LineTouchData(
                          enabled: true,
                          touchTooltipData: LineTouchTooltipData(
                            tooltipBgColor: AppTheme.primaryTextColor.withOpacity(0.8),
                            tooltipRoundedRadius: 8,
                            getTooltipItems: (touchedSpots) {
                              return touchedSpots.map((touchedSpot) {
                                String value;
                                if (title == 'Blood Pressure') {
                                  final index = touchedSpot.x.toInt();
                                  if (index >= 0 && index < history!.length) {
                                    value = '${history![index]['systolic']}/${history![index]['diastolic']} mmHg';
                                  } else {
                                    value = '';
                                  }
                                } else {
                                  final index = touchedSpot.x.toInt();
                                  if (index >= 0 && index < history!.length) {
                                    value = '${history![index]['value']} $unit';
                                  } else {
                                    value = '';
                                  }
                                }
                                return LineTooltipItem(
                                  value,
                                  const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              }).toList();
                            },
                          ),
                        ),
                      ),
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

  List<FlSpot> _getChartData() {
    if (history == null || history!.isEmpty) {
      return [];
    }
    
    // Sort history by date
    final sortedHistory = List<dynamic>.from(history!)
      ..sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
    
    double maxValue = 0;
    double minValue = double.infinity;
    
    // For blood pressure, use systolic
    if (title == 'Blood Pressure') {
      for (final item in sortedHistory) {
        final value = double.tryParse(item['systolic'] ?? '0') ?? 0;
        if (value > maxValue) maxValue = value;
        if (value < minValue) minValue = value;
      }
    } else {
      for (final item in sortedHistory) {
        final value = double.tryParse(item['value'] ?? '0') ?? 0;
        if (value > maxValue) maxValue = value;
        if (value < minValue) minValue = value;
      }
    }
    
    final List<FlSpot> spots = [];
    for (int i = 0; i < sortedHistory.length; i++) {
      double y;
      if (title == 'Blood Pressure') {
        y = double.tryParse(sortedHistory[i]['systolic'] ?? '0') ?? 0;
      } else {
        y = double.tryParse(sortedHistory[i]['value'] ?? '0') ?? 0;
      }
      
      // Normalize y to fit in chart
      if (maxValue != minValue) {
        y = (y - minValue) / (maxValue - minValue);
      } else {
        y = 0.5;
      }
      
      spots.add(FlSpot(i.toDouble(), y));
    }
    
    return spots;
  }
} 