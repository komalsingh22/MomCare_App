import 'package:flutter/material.dart';
import 'package:health_app/models/health_data.dart';
import 'package:health_app/services/database_service.dart';
import 'package:health_app/widgets/health_alert_widget.dart';

class AllHealthAlertsScreen extends StatefulWidget {
  const AllHealthAlertsScreen({super.key});

  @override
  State<AllHealthAlertsScreen> createState() => _AllHealthAlertsScreenState();
}

class _AllHealthAlertsScreenState extends State<AllHealthAlertsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<HealthAlert> _alerts = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }
  
  Future<void> _loadAlerts() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final alerts = await _databaseService.getAllHealthAlerts();
      setState(() {
        _alerts = alerts;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading health alerts: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _dismissAlert(HealthAlert alert) async {
    try {
      await _databaseService.markHealthAlertAsRead(alert.id);
      setState(() {
        _alerts.removeWhere((a) => a.id == alert.id);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Alert dismissed'),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () {
              _loadAlerts();
            },
          ),
        ),
      );
    } catch (e) {
      print('Error dismissing health alert: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Alerts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAlerts,
            tooltip: 'Refresh alerts',
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _alerts.isEmpty
                ? _buildEmptyState()
                : _buildAlertsList(),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: Colors.green,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'No Health Alerts',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'You have no active health alerts at this time.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadAlerts,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAlertsList() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'You have ${_alerts.length} health ${_alerts.length == 1 ? 'alert' : 'alerts'}',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 8),
        const Divider(),
        const SizedBox(height: 8),
        ..._alerts.map((alert) => HealthAlertWidget(
          alert: alert,
          onDismiss: () => _dismissAlert(alert),
        )),
      ],
    );
  }
} 