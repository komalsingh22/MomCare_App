import 'package:flutter/material.dart';
import 'dart:math';
import 'package:health_app/models/health_data.dart';
import 'package:health_app/theme/app_theme.dart';
import 'package:fl_chart/fl_chart.dart';

class MoodWidget extends StatelessWidget {
  final MoodData moodData;
  final VoidCallback onTap;

  const MoodWidget({
    super.key,
    required this.moodData,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Debug the mood data
    print('MOOD WIDGET: Original mood rating = ${moodData.rating}');
    
    // Convert the rating to an index between 0-4 (ensure it's within bounds)
    final int ratingIndex = max(0, min(4, moodData.rating - 1));
    print('MOOD WIDGET: Adjusted mood index = $ratingIndex (0-4 scale)');
    
    List<String> moodLabels = ['Very Low', 'Low', 'Neutral', 'Good', 'Excellent'];
    List<IconData> moodIcons = [
      Icons.sentiment_very_dissatisfied,
      Icons.sentiment_dissatisfied,
      Icons.sentiment_neutral,
      Icons.sentiment_satisfied,
      Icons.sentiment_very_satisfied,
    ];
    List<Color> moodColors = [
      Colors.red.shade300,
      Colors.orange.shade300,
      Colors.yellow.shade300,
      Colors.lightGreen.shade300,
      Colors.green.shade300,
    ];

    // Get mood data
    final currentMoodLabel = moodLabels[ratingIndex];
    final currentMoodIcon = moodIcons[ratingIndex];
    final currentMoodColor = moodColors[ratingIndex];

    // Process history data for the chart
    List<int> moodHistory = [];
    List<String> dateLabels = [];
    
    if (moodData.history != null && moodData.history!.isNotEmpty) {
      // Sort by date, most recent last
      final sortedHistory = List.from(moodData.history!)
        ..sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
      
      // Take last 7 days or all if less
      final displayHistory = sortedHistory.length > 7 
          ? sortedHistory.sublist(sortedHistory.length - 7) 
          : sortedHistory;
      
      for (var entry in displayHistory) {
        final rating = entry['rating'] as int;
        // Convert the 1-5 rating to 0-4 index
        moodHistory.add((rating - 1).clamp(0, 4));
        dateLabels.add(_formatDate(entry['date'] as DateTime));
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFF8F2FF),
              Color(0xFFFFFAFF),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.secondaryColor.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with current mood
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: currentMoodColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    currentMoodIcon,
                    color: currentMoodColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Mood',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currentMoodLabel,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: currentMoodColor,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.update,
                        size: 12,
                        color: AppTheme.secondaryColor,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Updated',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.secondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Mood selector visualization
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(5, (index) {
                final isSelected = index == ratingIndex;
                return Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? moodColors[index] 
                            : moodColors[index].withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: moodColors[index], width: 2)
                            : null,
                        boxShadow: isSelected ? [
                          BoxShadow(
                            color: moodColors[index].withOpacity(0.5),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ] : null,
                      ),
                      child: Icon(
                        moodIcons[index],
                        color: isSelected 
                            ? Colors.white 
                            : moodColors[index],
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      moodLabels[index],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected 
                            ? AppTheme.primaryTextColor 
                            : AppTheme.secondaryTextColor,
                      ),
                    ),
                  ],
                );
              }),
            ),
            
            if (moodHistory.isNotEmpty) ...[
              const SizedBox(height: 24),
              
              // Mood history chart
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Mood History',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryTextColor,
                        ),
                      ),
                      Text(
                        '${moodHistory.length} day trend',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 120,
                    child: _buildMoodChart(
                      context,
                      moodHistory, 
                      dateLabels, 
                      moodColors,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMoodChart(
    BuildContext context, 
    List<int> moodHistory, 
    List<String> dateLabels,
    List<Color> moodColors,
  ) {
    // Define mood labels for the tooltips
    final List<String> moodLabels = ['Very Low', 'Low', 'Neutral', 'Good', 'Excellent'];
    
    if (moodHistory.isEmpty) {
      return const Center(
        child: Text(
          'No mood history available',
          style: TextStyle(
            color: AppTheme.secondaryTextColor,
            fontSize: 12,
          ),
        ),
      );
    }

    // Create spots for line chart
    final spots = List<FlSpot>.generate(
      moodHistory.length,
      (i) => FlSpot(i.toDouble(), moodHistory[i].toDouble()),
    );

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.1),
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          },
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 20,
              getTitlesWidget: (value, meta) {
                final int index = value.toInt();
                if (index < 0 || index >= dateLabels.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(
                    dateLabels[index],
                    style: const TextStyle(
                      color: AppTheme.secondaryTextColor,
                      fontSize: 8,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(
              showTitles: false,
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(
              showTitles: false,
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(
              showTitles: false,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minY: 0,
        maxY: 4,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            barWidth: 3,
            color: AppTheme.secondaryColor,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 5,
                  color: moodColors[spot.y.toInt()],
                  strokeWidth: 1,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppTheme.secondaryColor.withOpacity(0.3),
                  AppTheme.secondaryColor.withOpacity(0.0),
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
            tooltipBgColor: Colors.white,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final moodIndex = spot.y.toInt();
                return LineTooltipItem(
                  moodLabels[moodIndex],
                  TextStyle(
                    color: moodColors[moodIndex],
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    final day = date.day;
    final month = date.month;
    
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    return '$day ${months[month - 1]}';
  }
} 