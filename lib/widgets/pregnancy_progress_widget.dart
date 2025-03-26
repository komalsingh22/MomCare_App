import 'package:flutter/material.dart';
import 'package:health_app/models/health_data.dart';
import 'package:health_app/theme/app_theme.dart';


class PregnancyProgressWidget extends StatelessWidget {
  final PregnancyData pregnancyData;
  final VoidCallback onTap;

  const PregnancyProgressWidget({
    super.key,
    required this.pregnancyData,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate remaining days
    final currentDate = DateTime.now();
    final remainingDays = pregnancyData.dueDate.difference(currentDate).inDays;
    
    // Calculate progress percentage (assuming 40 weeks = 280 days total pregnancy)
    const totalDays = 280;
    final daysPassed = totalDays - remainingDays;
    final progressPercentage = (daysPassed / totalDays).clamp(0.0, 1.0);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFFE0F0),
              Color(0xFFFFF5F9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pregnancy Progress',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        style: Theme.of(context).textTheme.bodyMedium,
                        children: [
                          TextSpan(
                            text: 'Month ${pregnancyData.currentMonth} ',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryTextColor,
                            ),
                          ),
                          TextSpan(
                            text: '• Due in $remainingDays days',
                            style: TextStyle(
                              color: AppTheme.secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.child_friendly_outlined,
                    color: AppTheme.primaryColor,
                    size: 28,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Progress bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${(progressPercentage * 100).toInt()}%',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Stack(
                  children: [
                    // Background
                    Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    // Progress fill
                    FractionallySizedBox(
                      widthFactor: progressPercentage,
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                    // Month markers
                    SizedBox(
                      height: 10,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(9, (index) {
                          // Show markers for months 1, 3, 5, 7, 9
                          if (index % 2 == 0) {
                            return Container(
                              width: 2,
                              color: Colors.white.withOpacity(0.7),
                            );
                          }
                          return const SizedBox(width: 2);
                        }),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '1st Trimester',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.secondaryTextColor,
                      ),
                    ),
                    Text(
                      '2nd Trimester',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.secondaryTextColor,
                      ),
                    ),
                    Text(
                      '3rd Trimester',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Milestones
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent Milestones',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ...pregnancyData.milestones.map((milestone) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: milestone.isCompleted
                              ? AppTheme.primaryColor
                              : Colors.white,
                          shape: BoxShape.circle,
                          border: milestone.isCompleted
                              ? null
                              : Border.all(color: AppTheme.borderColor),
                        ),
                        child: milestone.isCompleted
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 14,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          milestone.title,
                          style: TextStyle(
                            color: milestone.isCompleted
                                ? AppTheme.primaryTextColor
                                : AppTheme.secondaryTextColor,
                            fontWeight: milestone.isCompleted
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (milestone.completedDate != null)
                        Text(
                          _formatDate(milestone.completedDate!),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.secondaryTextColor,
                          ),
                        ),
                    ],
                  ),
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]}';
  }
} 