import 'package:flutter/material.dart';
import 'package:health_app/models/health_data.dart';
import 'package:health_app/services/ai_service.dart';
import 'package:health_app/theme/app_theme.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class HealthEducationScreen extends StatefulWidget {
  final String condition;
  
  const HealthEducationScreen({
    super.key, 
    required this.condition,
  });

  @override
  State<HealthEducationScreen> createState() => _HealthEducationScreenState();
}

class _HealthEducationScreenState extends State<HealthEducationScreen> {
  final AIService _aiService = AIService();
  String _educationalContent = '';
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadEducationalContent();
  }
  
  Future<void> _loadEducationalContent() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final content = await _aiService.getEducationalContent(widget.condition);
      setState(() {
        _educationalContent = content;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading educational content: $e');
      setState(() {
        _educationalContent = 'Error loading content: $e';
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.condition,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEducationalContent,
            tooltip: 'Refresh content',
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading educational content...'),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      elevation: 2,
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.condition,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Divider(),
                            const SizedBox(height: 8),
                            MarkdownBody(
                              data: _educationalContent,
                              styleSheet: MarkdownStyleSheet(
                                h1: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                h2: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                h3: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                p: const TextStyle(fontSize: 14, height: 1.5),
                                listBullet: const TextStyle(color: AppTheme.accentColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Disclaimer: This information is for educational purposes only and does not replace professional medical advice. Always consult with your healthcare provider.',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Back to Dashboard'),
          ),
        ),
      ),
    );
  }
} 