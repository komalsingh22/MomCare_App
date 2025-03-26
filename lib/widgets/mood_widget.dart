import 'package:flutter/material.dart';
import 'package:health_app/models/health_data.dart';
import 'package:health_app/theme/app_theme.dart';
import 'package:health_app/utils/date_utils.dart' as app_date_utils;
import 'package:fl_chart/fl_chart.dart';

class MoodWidget extends StatelessWidget {
  final MoodData moodData;
  final VoidCallback? onTap;

  const MoodWidget({
    super.key,
    required this.moodData,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.sentiment_satisfied_alt,
                        color: AppTheme.accentColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Mental Health',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  Text(
                    'Last Updated: ${app_date_utils.DateUtils.formatLastUpdated(moodData.lastUpdated)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Mood',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _getMoodEmoji(),
                          const SizedBox(width: 8),
                          Text(
                            _getMoodText(),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getMoodColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getMoodColor().withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Rating: ${moodData.rating}/5',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: _getMoodColor(),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (moodData.history != null && moodData.history!.length > 1) ...[
                const SizedBox(height: 20),
                Text(
                  'Mood Trend',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 1,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey.withOpacity(0.2),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              // Only show 1, 3, and 5
                              if (value % 2 == 0 || value == 0) {
                                return const SizedBox.shrink();
                              }
                              return Text(
                                value.toInt().toString(),
                                style: const TextStyle(
                                  color: AppTheme.secondaryTextColor,
                                  fontSize: 10,
                                ),
                              );
                            },
                            reservedSize: 28,
                          ),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
                          left: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
                          right: BorderSide.none,
                          top: BorderSide.none,
                        ),
                      ),
                      minX: 0,
                      maxX: (moodData.history!.length - 1).toDouble(),
                      minY: 0,
                      maxY: 5,
                      lineBarsData: [
                        LineChartBarData(
                          spots: _getChartData(),
                          isCurved: true,
                          color: AppTheme.accentColor,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 4,
                                color: AppTheme.accentColor,
                                strokeWidth: 1,
                                strokeColor: Colors.white,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppTheme.accentColor.withOpacity(0.2),
                          ),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          tooltipBgColor: Colors.white,
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((touchedSpot) {
                              final index = touchedSpot.x.toInt();
                              if (index >= 0 && index < moodData.history!.length) {
                                final date = moodData.history![index]['date'] as DateTime;
                                return LineTooltipItem(
                                  '${app_date_utils.DateUtils.formatDate(date)}\nRating: ${touchedSpot.y.toInt()}',
                                  const TextStyle(color: AppTheme.primaryTextColor),
                                );
                              }
                              return null;
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
    );
  }

  Widget _getMoodEmoji() {
    switch (moodData.rating) {
      case 1:
        return const Icon(Icons.sentiment_very_dissatisfied, color: Colors.red, size: 24);
      case 2:
        return const Icon(Icons.sentiment_dissatisfied, color: Colors.orange, size: 24);
      case 3:
        return const Icon(Icons.sentiment_neutral, color: Colors.amber, size: 24);
      case 4:
        return const Icon(Icons.sentiment_satisfied, color: Colors.lightGreen, size: 24);
      case 5:
        return const Icon(Icons.sentiment_very_satisfied, color: Colors.green, size: 24);
      default:
        return const Icon(Icons.sentiment_neutral, color: Colors.grey, size: 24);
    }
  }

  String _getMoodText() {
    switch (moodData.rating) {
      case 1:
        return 'Very Sad';
      case 2:
        return 'Sad';
      case 3:
        return 'Neutral';
      case 4:
        return 'Happy';
      case 5:
        return 'Very Happy';
      default:
        return 'Unknown';
    }
  }

  Color _getMoodColor() {
    switch (moodData.rating) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.amber;
      case 4:
        return Colors.lightGreen;
      case 5:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  List<FlSpot> _getChartData() {
    if (moodData.history == null || moodData.history!.isEmpty) {
      return [];
    }
    
    // Sort history by date
    final sortedHistory = List<dynamic>.from(moodData.history!)
      ..sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
    
    final List<FlSpot> spots = [];
    for (int i = 0; i < sortedHistory.length; i++) {
      final rating = sortedHistory[i]['rating'] as int;
      spots.add(FlSpot(i.toDouble(), rating.toDouble()));
    }
    
    return spots;
  }
} 