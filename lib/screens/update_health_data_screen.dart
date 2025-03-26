import 'package:flutter/material.dart';
import 'package:health_app/theme/app_theme.dart';
import 'package:health_app/utils/connectivity_helper.dart';
import 'package:health_app/widgets/offline_indicator.dart';
import 'package:health_app/services/database_service.dart';

class UpdateHealthDataScreen extends StatefulWidget {
  const UpdateHealthDataScreen({super.key});

  @override
  State<UpdateHealthDataScreen> createState() => _UpdateHealthDataScreenState();
}

class _UpdateHealthDataScreenState extends State<UpdateHealthDataScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ConnectivityHelper _connectivityHelper;
  bool _isOffline = false;
  
  // Form key for validation
  final _formKey = GlobalKey<FormState>();
  
  // Pregnancy information
  bool _isPregnant = false;
  DateTime? _selectedDueDate;

  // Form controllers for Manual Entry
  final TextEditingController _pregnancyMonthController = TextEditingController();
  final TextEditingController _dueDateController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _systolicController = TextEditingController();
  final TextEditingController _diastolicController = TextEditingController();
  final TextEditingController _temperatureController = TextEditingController();
  final TextEditingController _hemoglobinController = TextEditingController();
  final TextEditingController _glucoseController = TextEditingController();
  final TextEditingController _symptomsController = TextEditingController();
  final TextEditingController _dietaryLogController = TextEditingController();
  final TextEditingController _physicalActivityController = TextEditingController();
  final TextEditingController _supplementsController = TextEditingController();

  // Mood rating
  double _moodRating = 3.0;
  bool _hasAnxiety = false;
  double _anxietyLevel = 0.0;

  // Uploaded reports
  final List<String> _uploadedReports = [];

  final DatabaseService _dbService = DatabaseService();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _connectivityHelper = ConnectivityHelper();
    _connectivityHelper.connectionStatus.listen((isConnected) {
      setState(() {
        _isOffline = !isConnected;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _connectivityHelper.dispose();
    
    // Dispose all controllers
    _pregnancyMonthController.dispose();
    _dueDateController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _systolicController.dispose();
    _diastolicController.dispose();
    _temperatureController.dispose();
    _hemoglobinController.dispose();
    _glucoseController.dispose();
    _symptomsController.dispose();
    _dietaryLogController.dispose();
    _physicalActivityController.dispose();
    _supplementsController.dispose();
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text('Update Health Data'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () {
              // Show info modal
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('How It Works'),
                  content: const Text(
                    'You can update your health data manually or by uploading medical reports. '
                    'Our AI will automatically extract key information from uploaded reports.'
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Got it'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.borderColor,
                  width: 1,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              tabs: [
                Tab(
                  icon: const Icon(Icons.edit_note_rounded),
                  child: const Text('Manual Entry'),
                ),
                Tab(
                  icon: const Icon(Icons.upload_file_rounded),
                  child: const Text('Upload Report'),
                ),
              ],
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: AppTheme.secondaryTextColor,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorColor: AppTheme.primaryColor,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Offline indicator
          OfflineIndicator(
            isOffline: _isOffline,
            onTap: () {
              // Show connectivity options or refresh
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Checking network connection...'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Manual Entry Tab
                _buildManualEntryTab(),
                
                // Upload Report Tab
                _buildUploadReportTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildManualEntryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pregnancy Information Section
            _buildSectionTitle('Pregnancy Information'),
            const SizedBox(height: 8),
            
            // Pregnancy checkbox
            Row(
              children: [
                Checkbox(
                  value: _isPregnant,
                  onChanged: (value) {
                    setState(() {
                      _isPregnant = value ?? false;
                    });
                  },
                ),
                const Text('Currently pregnant'),
              ],
            ),
            
            if (_isPregnant) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _pregnancyMonthController,
                      decoration: const InputDecoration(
                        labelText: 'Current Month of Pregnancy',
                        hintText: 'e.g., 5',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _dueDateController,
                      decoration: const InputDecoration(
                        labelText: 'Expected Due Date',
                        hintText: 'MM/DD/YYYY',
                        prefixIcon: Icon(Icons.event),
                      ),
                      onTap: () async {
                        // Show date picker
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 90)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 300)),
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedDueDate = picked;
                          });
                          _dueDateController.text = '${picked.month}/${picked.day}/${picked.year}';
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Vital Signs Section
            _buildSectionTitle('Vital Signs & Clinical Data'),
            const SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _weightController,
                    decoration: const InputDecoration(
                      labelText: 'Weight (kg)',
                      hintText: 'e.g., 65',
                      prefixIcon: Icon(Icons.monitor_weight_outlined),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _heightController,
                    decoration: const InputDecoration(
                      labelText: 'Height (cm)',
                      hintText: 'e.g., 165',
                      prefixIcon: Icon(Icons.height),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _systolicController,
                    decoration: const InputDecoration(
                      labelText: 'Blood Pressure (Systolic)',
                      hintText: 'e.g., 120',
                      prefixIcon: Icon(Icons.favorite_outline),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _diastolicController,
                    decoration: const InputDecoration(
                      labelText: 'Blood Pressure (Diastolic)',
                      hintText: 'e.g., 80',
                      prefixIcon: Icon(Icons.favorite_outline),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _temperatureController,
              decoration: const InputDecoration(
                labelText: 'Temperature (°C)',
                hintText: 'e.g., 36.7',
                prefixIcon: Icon(Icons.thermostat_outlined),
              ),
              keyboardType: TextInputType.number,
            ),
            
            const SizedBox(height: 24),
            
            // Optional Lab Values
            _buildSectionTitle('Optional Lab Values'),
            const SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _hemoglobinController,
                    decoration: const InputDecoration(
                      labelText: 'Hemoglobin (g/dL)',
                      hintText: 'e.g., 12.5',
                      prefixIcon: Icon(Icons.science_outlined),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _glucoseController,
                    decoration: const InputDecoration(
                      labelText: 'Blood Glucose (mg/dL)',
                      hintText: 'e.g., 95',
                      prefixIcon: Icon(Icons.science_outlined),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Symptom & Lifestyle Data
            _buildSectionTitle('Symptom & Lifestyle Data'),
            const SizedBox(height: 8),
            
            TextFormField(
              controller: _symptomsController,
              decoration: const InputDecoration(
                labelText: 'Symptoms',
                hintText: 'e.g., mild headache, slight swelling in feet',
                prefixIcon: Icon(Icons.sick_outlined),
              ),
              maxLines: 2,
            ),
            
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _dietaryLogController,
              decoration: const InputDecoration(
                labelText: 'Dietary Log',
                hintText: 'e.g., breakfast: oatmeal with fruit; lunch: chicken salad...',
                prefixIcon: Icon(Icons.restaurant_outlined),
              ),
              maxLines: 3,
            ),
            
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _physicalActivityController,
              decoration: const InputDecoration(
                labelText: 'Physical Activity',
                hintText: 'e.g., 30 min walking, light stretching...',
                prefixIcon: Icon(Icons.directions_walk_outlined),
              ),
              maxLines: 2,
            ),
            
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _supplementsController,
              decoration: const InputDecoration(
                labelText: 'Supplements',
                hintText: 'e.g., prenatal vitamin, iron, folic acid...',
                prefixIcon: Icon(Icons.medication_outlined),
              ),
              maxLines: 2,
            ),
            
            const SizedBox(height: 24),
            
            // Mental Health Assessment
            _buildSectionTitle('Mental Health Assessment'),
            const SizedBox(height: 8),
            
            Text(
              'How are you feeling today?',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.sentiment_very_dissatisfied, color: Colors.red),
                const Icon(Icons.sentiment_dissatisfied, color: Colors.orange),
                const Icon(Icons.sentiment_neutral, color: Colors.amber),
                const Icon(Icons.sentiment_satisfied, color: Colors.lightGreen),
                const Icon(Icons.sentiment_very_satisfied, color: Colors.green),
              ],
            ),
            
            Slider(
              value: _moodRating,
              min: 1,
              max: 5,
              divisions: 4,
              label: _getMoodLabel(),
              onChanged: (value) {
                setState(() {
                  _moodRating = value;
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Checkbox(
                  value: _hasAnxiety,
                  onChanged: (value) {
                    setState(() {
                      _hasAnxiety = value ?? false;
                    });
                  },
                ),
                const Text('Are you experiencing stress or anxiety?'),
              ],
            ),
            
            if (_hasAnxiety) ...[
              const SizedBox(height: 8),
              Text(
                'Intensity level: ${_anxietyLevel.toInt()}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              Slider(
                value: _anxietyLevel,
                min: 0,
                max: 10,
                divisions: 10,
                label: _anxietyLevel.toInt().toString(),
                onChanged: (value) {
                  setState(() {
                    _anxietyLevel = value;
                  });
                },
              ),
            ],
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadReportTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upload Health Report',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upload medical reports, lab results, or other health documents. The AI will automatically extract key parameters.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Simulate file selection
                        setState(() {
                          _uploadedReports.add('Medical_Report_${DateTime.now().millisecondsSinceEpoch}.pdf');
                        });
                      },
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Select File'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Supported formats: PDF, JPG, PNG',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          if (_uploadedReports.isNotEmpty) ...[
            Text(
              'Uploaded Reports',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _uploadedReports.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: Text(_uploadedReports[index]),
                    subtitle: Text('Uploaded at ${DateTime.now().hour}:${DateTime.now().minute}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () {
                        setState(() {
                          _uploadedReports.removeAt(index);
                        });
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.cancel_outlined, size: 20),
              label: const Text('Cancel'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 8,
            child: ElevatedButton.icon(
              onPressed: _saveHealthData,
              icon: const Icon(Icons.save_outlined, size: 20),
              label: const Text('Save Data'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: AppTheme.accentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Container(
          height: 2,
          width: 60,
          color: AppTheme.primaryColor,
        ),
      ],
    );
  }

  String _getMoodLabel() {
    switch (_moodRating.toInt()) {
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
        return 'Neutral';
    }
  }

  Future<void> _saveHealthData() async {
    // First validate the form
    if (_formKey.currentState!.validate()) {
      try {
        // Even if validation fails, we still want to save the data
        // to avoid overwriting existing values with null
        
        // Show loading indicator
        setState(() => _isSaving = true);
        
        // Collect form data - only include non-empty values
        Map<String, dynamic> dataToSave = {};
        
        // Pregnancy information
        if (_pregnancyMonthController.text.isNotEmpty) {
          dataToSave['pregnancyMonth'] = int.parse(_pregnancyMonthController.text);
        }
        if (_dueDateController.text.isNotEmpty) {
          dataToSave['dueDate'] = _dueDateController.text;
        }
        
        // Vital signs
        if (_weightController.text.isNotEmpty) {
          dataToSave['weight'] = _weightController.text;
        }
        if (_heightController.text.isNotEmpty) {
          dataToSave['height'] = _heightController.text;
        }
        if (_systolicController.text.isNotEmpty) {
          dataToSave['systolicBP'] = _systolicController.text;
        }
        if (_diastolicController.text.isNotEmpty) {
          dataToSave['diastolicBP'] = _diastolicController.text;
        }
        if (_temperatureController.text.isNotEmpty) {
          dataToSave['temperature'] = _temperatureController.text;
        }
        
        // Lab values
        if (_hemoglobinController.text.isNotEmpty) {
          dataToSave['hemoglobin'] = _hemoglobinController.text;
        }
        if (_glucoseController.text.isNotEmpty) {
          dataToSave['glucose'] = _glucoseController.text;
        }
        
        // Symptoms and lifestyle
        if (_symptomsController.text.isNotEmpty) {
          dataToSave['symptoms'] = _symptomsController.text;
        }
        if (_dietaryLogController.text.isNotEmpty) {
          dataToSave['dietaryLog'] = _dietaryLogController.text;
        }
        if (_physicalActivityController.text.isNotEmpty) {
          dataToSave['physicalActivity'] = _physicalActivityController.text;
        }
        if (_supplementsController.text.isNotEmpty) {
          dataToSave['supplements'] = _supplementsController.text;
        }
        
        // Mental health
        if (_moodRating != null) {
          dataToSave['moodRating'] = _moodRating!.toDouble();
          print('Saving mood rating: ${_moodRating!}');
        }
        
        if (_hasAnxiety != null) {
          dataToSave['hasAnxiety'] = _hasAnxiety!;
        }
        if (_anxietyLevel != null) {
          dataToSave['anxietyLevel'] = _anxietyLevel!.toDouble();
        }
        
        print('Saving data with fields: ${dataToSave.keys.join(', ')}');
        
        // Save to database
        final result = await _dbService.saveHealthData(
          pregnancyMonth: dataToSave['pregnancyMonth'],
          dueDate: dataToSave['dueDate'],
          weight: dataToSave['weight'],
          height: dataToSave['height'],
          systolicBP: dataToSave['systolicBP'],
          diastolicBP: dataToSave['diastolicBP'],
          temperature: dataToSave['temperature'],
          hemoglobin: dataToSave['hemoglobin'],
          glucose: dataToSave['glucose'],
          symptoms: dataToSave['symptoms'],
          dietaryLog: dataToSave['dietaryLog'],
          physicalActivity: dataToSave['physicalActivity'],
          supplements: dataToSave['supplements'],
          moodRating: dataToSave['moodRating'],
          hasAnxiety: dataToSave['hasAnxiety'],
          anxietyLevel: dataToSave['anxietyLevel'],
        );
        
        // Hide loading indicator
        setState(() => _isSaving = false);
        
        print('Data saved successfully with ID: $result');
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Health data saved successfully'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
        
        // Return true to indicate successful save
        Navigator.pop(context, true);
      } catch (e) {
        // Hide loading indicator
        setState(() => _isSaving = false);
        
        print('Error saving health data: $e');
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving data: $e'),
            duration: const Duration(seconds: 4),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 