import 'package:flutter/material.dart';
import 'package:health_app/models/health_data.dart';
import 'package:health_app/theme/app_theme.dart';
// import 'package:health_app/utils/date_utils.dart' as app_date_utils;
// import 'package:fl_chart/fl_chart.dart';

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

    // Ensure rating is within bounds
    int rating = moodData.rating.clamp(0, 4);

    // Get mood data
    final currentMoodLabel = moodLabels[rating];
    final currentMoodIcon = moodIcons[rating];
    final currentMoodColor = moodColors[rating];

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
        moodHistory.add((entry['rating'] as int).clamp(0, 4));
        dateLabels.add(_formatDate(entry['date'] as DateTime));
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFF8F2FF),
              const Color(0xFFFFFAFF),
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
                  child: Text(
                    'Log Mood',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.secondaryColor,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Mood selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(5, (index) {
                final isSelected = index == rating;
                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? moodColors[index] 
                            : moodColors[index].withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: moodColors[index], width: 2)
                            : null,
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
                  const Text(
                    'Mood History',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryTextColor,
                    ),
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
    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(moodHistory.length, (index) {
              final mood = moodHistory[index];
              final barHeight = (mood + 1) / 5 * 70; // Scale to max height
              
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        height: barHeight,
                        decoration: BoxDecoration(
                          color: moodColors[mood],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 8),
        // Date labels
        Row(
          children: dateLabels.map((date) => 
            Expanded(
              child: Text(
                date,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.secondaryTextColor,
                ),
              ),
            )
          ).toList(),
        ),
      ],
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