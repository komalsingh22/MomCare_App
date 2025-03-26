import 'package:flutter/material.dart';
import 'package:health_app/screens/health_dashboard_screen.dart';
import 'package:health_app/theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EmpowerHer Maternal Wellness',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const HealthDashboardScreen(),
    );
  }
}
