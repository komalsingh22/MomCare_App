import 'package:flutter/material.dart';
import 'package:health_app/services/ai_service.dart';
import 'package:health_app/theme/app_theme.dart';

class ApiKeySetupScreen extends StatefulWidget {
  const ApiKeySetupScreen({super.key});

  @override
  State<ApiKeySetupScreen> createState() => _ApiKeySetupScreenState();
}

class _ApiKeySetupScreenState extends State<ApiKeySetupScreen> {
  final TextEditingController _apiKeyController = TextEditingController();
  final AIService _aiService = AIService();
  bool _isLoading = false;
  bool _hasApiKey = false;
  
  @override
  void initState() {
    super.initState();
    _checkApiKey();
  }
  
  Future<void> _checkApiKey() async {
    final hasKey = await _aiService.isApiKeySet();
    setState(() {
      _hasApiKey = hasKey;
    });
  }
  
  Future<void> _saveApiKey() async {
    if (_apiKeyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid API key')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final success = await _aiService.setApiKey(_apiKeyController.text);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('API key saved successfully')),
        );
        _checkApiKey();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to initialize AI with provided key')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Features Setup'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.smart_toy_outlined,
                          color: AppTheme.primaryColor,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'AI Features',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _hasApiKey
                          ? 'AI features are active! The app can now provide advanced health analysis and personalized recommendations.'
                          : 'To enable AI features, you need to provide a Google Gemini API key.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (_hasApiKey)
                      Container(
                        margin: const EdgeInsets.only(top: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green.shade700),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text('API key is set and AI features are available'),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            Text(
              'Enter Gemini API Key',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _apiKeyController,
              decoration: InputDecoration(
                hintText: 'Enter your API key here',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.key),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveApiKey,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save API Key'),
            ),
            
            const SizedBox(height: 24),
            
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How to get a Gemini API Key:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const _StepWidget(
                      number: 1,
                      text: 'Visit Google AI Studio (ai.google.dev)',
                    ),
                    const _StepWidget(
                      number: 2,
                      text: 'Sign in with your Google account',
                    ),
                    const _StepWidget(
                      number: 3,
                      text: 'Go to API Keys in the left menu',
                    ),
                    const _StepWidget(
                      number: 4,
                      text: 'Create a new API key',
                    ),
                    const _StepWidget(
                      number: 5,
                      text: 'Copy and paste the key here',
                    ),
                    
                    const SizedBox(height: 16),
                    const Text(
                      'Note: The app stores your API key securely on your device and uses it only for health analysis features.',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepWidget extends StatelessWidget {
  final int number;
  final String text;

  const _StepWidget({
    required this.number,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: AppTheme.secondaryColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text),
          ),
        ],
      ),
    );
  }
} 