import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:health_app/constants/constants.dart';
import 'package:health_app/models/health_data.dart';
import 'package:health_app/services/database_service.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AIService {
  static final AIService _instance = AIService._internal();
  late final GenerativeModel? _model;
  bool _isModelInitialized = false;
  final DatabaseService _databaseService = DatabaseService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const String _apiKeyKey = 'gemini_api_key';
  static const String _requestCountKey = 'gemini_request_count';
  static const String _lastRequestDateKey = 'gemini_last_request_date';
  
  // Free tier limits
  static const int _dailyRequestLimit = 60;

  // Define risk conditions and their symptoms
  final Map<String, Map<String, dynamic>> _pregnancyRiskConditions = {
    'Preeclampsia': {
      'symptoms': ['High blood pressure', 'Protein in urine', 'Swelling', 'Severe headache', 'Vision changes'],
      'vitalSigns': {'systolicBP': '>140', 'diastolicBP': '>90'},
      'severity': 'high',
      'description': 'A pregnancy complication characterized by high blood pressure and signs of damage to other organ systems',
      'recommendations': [
        'Immediate medical attention',
        'Blood pressure monitoring',
        'Possible bed rest',
        'Medication may be prescribed'
      ]
    },
    'Gestational Diabetes': {
      'symptoms': ['Increased thirst', 'Frequent urination', 'Fatigue', 'Sugar in urine'],
      'vitalSigns': {'glucose': '>140'},
      'severity': 'medium',
      'description': 'High blood sugar that develops during pregnancy',
      'recommendations': [
        'Blood sugar monitoring',
        'Dietary changes',
        'Regular exercise',
        'Possible insulin therapy'
      ]
    },
    'Anemia': {
      'symptoms': ['Fatigue', 'Weakness', 'Dizziness', 'Shortness of breath'],
      'vitalSigns': {'hemoglobin': '<11'},
      'severity': 'medium',
      'description': 'A condition marked by a deficiency of red blood cells or hemoglobin in the blood',
      'recommendations': [
        'Iron supplements',
        'Iron-rich diet',
        'Regular blood tests'
      ]
    },
    'HELLP Syndrome': {
      'symptoms': ['Headache', 'Nausea', 'Upper abdominal pain', 'Blurred vision'],
      'vitalSigns': {'systolicBP': '>160', 'diastolicBP': '>110', 'platelets': '<100', 'liver enzymes': 'elevated'},
      'severity': 'high',
      'description': 'A life-threatening pregnancy complication usually considered to be a variant of preeclampsia',
      'recommendations': [
        'Immediate hospitalization',
        'Delivery of the baby if near term',
        'Medication to control blood pressure',
        'Corticosteroids to help the baby\'s lungs mature if premature delivery is needed'
      ]
    },
    'Placenta Previa': {
      'symptoms': ['Painless vaginal bleeding', 'Bleeding after intercourse'],
      'vitalSigns': {},
      'severity': 'high',
      'description': 'A condition where the placenta covers the cervix',
      'recommendations': [
        'Pelvic rest',
        'Avoid strenuous activities',
        'Immediate medical attention if bleeding occurs',
        'Possible hospitalization',
        'Cesarean delivery may be required'
      ]
    },
    'Intrauterine Growth Restriction': {
      'symptoms': ['Small fundal height for gestational age'],
      'vitalSigns': {'fetal weight': '<10th percentile'},
      'severity': 'medium',
      'description': 'A condition where the fetus is smaller than expected for gestational age',
      'recommendations': [
        'Regular ultrasounds',
        'Fetal monitoring',
        'Nutritional counseling',
        'Possible early delivery if severe'
      ]
    },
    'Gestational Hypertension': {
      'symptoms': ['High blood pressure after 20 weeks'],
      'vitalSigns': {'systolicBP': '>140', 'diastolicBP': '>90'},
      'severity': 'medium',
      'description': 'High blood pressure that develops after 20 weeks of pregnancy',
      'recommendations': [
        'Regular blood pressure monitoring',
        'Low-sodium diet',
        'Regular prenatal visits',
        'Possible medication'
      ]
    }
  };

  factory AIService() {
    return _instance;
  }

  AIService._internal() {
    _initializeModel();
  }
  
  Future<void> _initializeModel() async {
    try {
      String? storedApiKey = await _secureStorage.read(key: _apiKeyKey);
      
      if (storedApiKey == null || storedApiKey.isEmpty || storedApiKey == 'PLACEHOLDER_API_KEY') {
        print('Using API key from constants file');
        storedApiKey = aimodelapiKey;
        await _secureStorage.write(key: _apiKeyKey, value: aimodelapiKey);
      }
      
      _model = GenerativeModel(
        model: 'gemini-1.5-flash-latest',
        apiKey: storedApiKey,
        generationConfig: GenerationConfig(
          temperature: 0.4,
          maxOutputTokens: 1024,
          topK: 20,
          topP: 0.95,
        ),
        safetySettings: [
          SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
          SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
          SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.high),
          SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.high),
        ],
      );
      _isModelInitialized = true;
      print('Gemini model initialized successfully');
    } catch (e) {
      print('Error initializing Gemini model: $e');
      _model = null;
      _isModelInitialized = false;
    }
  }

  Future<bool> setApiKey(String apiKey) async {
    try {
      await _secureStorage.write(key: _apiKeyKey, value: apiKey);
      await _initializeModel();
      return _isModelInitialized;
    } catch (e) {
      print('Error setting API key: $e');
      return false;
    }
  }

  Future<bool> isApiKeySet() async {
    try {
      final apiKey = await _secureStorage.read(key: _apiKeyKey);
      return apiKey != null && apiKey.isNotEmpty && apiKey != 'PLACEHOLDER_API_KEY';
    } catch (e) {
      return false;
    }
  }
  
  Future<bool> _canMakeRequest() async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final lastRequestDate = await _secureStorage.read(key: _lastRequestDateKey) ?? '';
      
      if (lastRequestDate != today) {
        await _secureStorage.write(key: _requestCountKey, value: '0');
        await _secureStorage.write(key: _lastRequestDateKey, value: today);
        return true;
      }
      
      final requestCount = int.tryParse(await _secureStorage.read(key: _requestCountKey) ?? '0') ?? 0;
      return requestCount < _dailyRequestLimit;
    } catch (e) {
      print('Error checking request limit: $e');
      return true;
    }
  }
  
  Future<void> _incrementRequestCount() async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      await _secureStorage.write(key: _lastRequestDateKey, value: today);
      
      final requestCount = int.tryParse(await _secureStorage.read(key: _requestCountKey) ?? '0') ?? 0;
      await _secureStorage.write(key: _requestCountKey, value: (requestCount + 1).toString());
    } catch (e) {
      print('Error updating request count: $e');
    }
  }
  
  Future<int> getRemainingRequests() async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final lastRequestDate = await _secureStorage.read(key: _lastRequestDateKey) ?? '';
      
      if (lastRequestDate != today) {
        return _dailyRequestLimit;
      }
      
      final requestCount = int.tryParse(await _secureStorage.read(key: _requestCountKey) ?? '0') ?? 0;
      return _dailyRequestLimit - requestCount;
    } catch (e) {
      print('Error getting remaining requests: $e');
      return 0;
    }
  }

  Future<List<HealthAlert>> analyzeHealthData(Map<String, dynamic> latestData) async {
    try {
      final allHealthData = await _databaseService.getAllHealthData();
      final vitalSigns = await _databaseService.getVitalSigns();
      
      List<HealthAlert> alerts = [];
      
      if (_isModelInitialized && _model != null) {
        if (await _canMakeRequest()) {
          final aiAlerts = await _aiAnalysis(vitalSigns, allHealthData, latestData);
          if (aiAlerts.isNotEmpty) {
            alerts.addAll(aiAlerts);
          }
        } else {
          print('Daily AI request limit exceeded. Using rule-based analysis only.');
          alerts.add(HealthAlert(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: 'AI Analysis Unavailable',
            message: 'Daily AI analysis quota exceeded. Only basic analysis is available. Try again tomorrow.',
            severity: AlertSeverity.low,
            lastUpdated: DateTime.now(),
          ));
        }
      }
      
      if (alerts.isEmpty) {
        final ruleBasedAlerts = _ruleBasedAnalysis(vitalSigns, latestData);
        if (ruleBasedAlerts.isNotEmpty) {
          alerts.addAll(ruleBasedAlerts);
        }
      }
      
      return alerts;
    } catch (e) {
      print('Error in health data analysis: $e');
      return [];
    }
  }
  
  List<HealthAlert> _ruleBasedAnalysis(List<VitalSign> vitalSigns, Map<String, dynamic> latestData) {
    List<HealthAlert> alerts = [];
    
    BloodPressure? bp;
    for (var vital in vitalSigns) {
      if (vital is BloodPressure) {
        bp = vital;
        break;
      }
    }
    
    if (bp != null) {
      final systolic = double.tryParse(bp.systolic) ?? 0;
      final diastolic = double.tryParse(bp.diastolic) ?? 0;
      
      if (systolic >= 160 || diastolic >= 110) {
        alerts.add(HealthAlert(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: 'Severe Hypertension',
          message: 'Your blood pressure reading of ${bp.value} is severely elevated. This could indicate preeclampsia, especially if accompanied by protein in urine or swelling. Please seek immediate medical attention.',
          severity: AlertSeverity.high,
          lastUpdated: DateTime.now(),
        ));
      } else if (systolic >= 140 || diastolic >= 90) {
        alerts.add(HealthAlert(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: 'Elevated Blood Pressure',
          message: 'Your blood pressure reading of ${bp.value} is above the normal range for pregnant women. This could indicate gestational hypertension. Please consult with your healthcare provider.',
          severity: AlertSeverity.medium,
          lastUpdated: DateTime.now(),
        ));
      }
    }
    
    for (var vital in vitalSigns) {
      if (vital.name == 'Glucose') {
        final glucose = double.tryParse(vital.value) ?? 0;
        if (glucose > 140) {
          alerts.add(HealthAlert(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: 'Elevated Blood Glucose',
            message: 'Your blood glucose level of ${vital.value} ${vital.unit} is above the normal range. This could indicate gestational diabetes. Please consult with your healthcare provider.',
            severity: AlertSeverity.medium,
            lastUpdated: DateTime.now(),
          ));
        }
      }
    }
    
    for (var vital in vitalSigns) {
      if (vital.name == 'Hemoglobin') {
        final hemoglobin = double.tryParse(vital.value) ?? 0;
        if (hemoglobin < 11) {
          alerts.add(HealthAlert(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: 'Low Hemoglobin',
            message: 'Your hemoglobin level of ${vital.value} ${vital.unit} is below the normal range. This could indicate anemia, which is common during pregnancy but should be monitored. Consider increasing iron-rich foods and consult with your healthcare provider.',
            severity: hemoglobin < 9 ? AlertSeverity.high : AlertSeverity.medium,
            lastUpdated: DateTime.now(),
          ));
        }
      }
    }
    
    for (var vital in vitalSigns) {
      if (vital is Temperature) {
        final temp = double.tryParse(vital.value) ?? 0;
        if (temp > 38.0) {
          alerts.add(HealthAlert(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: 'Fever',
            message: 'Your temperature of ${vital.value}°C indicates a fever. This could be concerning during pregnancy and should be evaluated. Please contact your healthcare provider, especially if accompanied by other symptoms.',
            severity: AlertSeverity.high,
            lastUpdated: DateTime.now(),
          ));
        } else if (temp > 37.5) {
          alerts.add(HealthAlert(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: 'Elevated Temperature',
            message: 'Your temperature of ${vital.value}°C is slightly elevated. Monitor for other symptoms and contact your healthcare provider if it increases or persists.',
            severity: AlertSeverity.medium,
            lastUpdated: DateTime.now(),
          ));
        }
      }
    }
    
    if (latestData.containsKey('weight') && latestData.containsKey('pregnancy_month')) {
      final weight = double.tryParse(latestData['weight'].toString()) ?? 0;
      final month = int.tryParse(latestData['pregnancy_month'].toString()) ?? 0;
      
      if (month > 0 && month > 3) {
        _databaseService.getWeightHistory().then((weightHistory) {
          if (weightHistory.isNotEmpty && weightHistory.length > 1) {
            final latestEntry = weightHistory.first;
            final previousEntry = weightHistory[1];
            
            final latestWeight = double.tryParse(latestEntry['value'].toString()) ?? 0;
            final previousWeight = double.tryParse(previousEntry['value'].toString()) ?? 0;
            final daysBetween = latestEntry['date'].difference(previousEntry['date']).inDays;
            
            if (daysBetween > 0) {
              final weightGainPerMonth = (latestWeight - previousWeight) / daysBetween * 30;
              
              if (weightGainPerMonth < 0.5 && month > 3) {
                alerts.add(HealthAlert(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  title: 'Insufficient Weight Gain',
                  message: 'Your current weight gain of approximately ${weightGainPerMonth.toStringAsFixed(1)} kg per month is below the recommended range for your stage of pregnancy. This could potentially affect fetal growth. Please discuss your nutrition with your healthcare provider.',
                  severity: AlertSeverity.medium,
                  lastUpdated: DateTime.now(),
                ));
              } else if (weightGainPerMonth > 3) {
                alerts.add(HealthAlert(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  title: 'Excessive Weight Gain',
                  message: 'Your current weight gain of approximately ${weightGainPerMonth.toStringAsFixed(1)} kg per month is above the recommended range for your stage of pregnancy. While weight gain is normal and necessary during pregnancy, excessive gain may increase risks. Please discuss with your healthcare provider.',
                  severity: AlertSeverity.medium,
                  lastUpdated: DateTime.now(),
                ));
              }
            }
          }
        });
      }
    }
    
    if (latestData.containsKey('symptoms')) {
      final symptoms = latestData['symptoms'].toString().toLowerCase();
      
      if (symptoms.contains('vaginal bleeding') || symptoms.contains('bleeding after')) {
        alerts.add(HealthAlert(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: 'Possible Placenta Previa',
          message: 'You reported vaginal bleeding, which can be a sign of placenta previa or other serious conditions. Please seek immediate medical attention.',
          severity: AlertSeverity.high,
          lastUpdated: DateTime.now(),
        ));
      }
      
      if ((symptoms.contains('headache') || symptoms.contains('nausea')) && 
          (symptoms.contains('abdominal pain') || symptoms.contains('vision'))) {
        if (bp != null) {
          final systolic = double.tryParse(bp.systolic) ?? 0;
          final diastolic = double.tryParse(bp.diastolic) ?? 0;
          
          if (systolic > 140 || diastolic > 90) {
            alerts.add(HealthAlert(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              title: 'Possible HELLP Syndrome',
              message: 'Your combination of symptoms (headache, abdominal pain) and elevated blood pressure could indicate HELLP syndrome, a serious complication. Please seek immediate medical evaluation.',
              severity: AlertSeverity.high,
              lastUpdated: DateTime.now(),
            ));
          }
        }
      }
    }
    
    return alerts;
  }
  
  Future<List<HealthAlert>> _aiAnalysis(List<VitalSign> vitalSigns, List<Map<String, dynamic>> allHealthData, Map<String, dynamic> latestData) async {
    try {
      if (!_isModelInitialized || _model == null) {
        return [];
      }
      
      final vitalSignsText = vitalSigns.map((vitalSign) {
        return '${vitalSign.name}: ${vitalSign.value} ${vitalSign.unit}';
      }).join('\n');
      
      final prompt = '''
        As a medical AI specializing in maternal health, analyze these health data points and identify potential risks or complications. Pay special attention to extreme values and combinations of symptoms.

        Current Vital Signs:
        $vitalSignsText

        Additional Information:
        ${latestData.containsKey('symptoms') ? 'Symptoms: ${latestData['symptoms']}' : 'No symptoms reported'}
        ${latestData.containsKey('mood_rating') ? 'Mood: ${latestData['mood_rating']}/5' : 'Mood not reported'}
        ${latestData.containsKey('anxiety_level') ? 'Anxiety: ${latestData['anxiety_level']}/5' : 'Anxiety not reported'}
        ${latestData.containsKey('pregnancy_month') ? 'Pregnancy Month: ${latestData['pregnancy_month']}' : 'Pregnancy month not reported'}
        ${latestData.containsKey('dietary_log') ? 'Dietary Information: ${latestData['dietary_log']}' : 'No dietary information'}
        ${latestData.containsKey('physical_activity') ? 'Physical Activity: ${latestData['physical_activity']}' : 'No physical activity reported'}

        Please analyze this data considering:
        1. Any values that are significantly outside normal ranges for pregnancy
        2. Combinations of symptoms that might indicate serious conditions
        3. Potential risks for both mother and baby
        4. Urgency of medical attention needed
        5. Specific recommendations for immediate action

        Format your response as JSON:
        {
          "risks": [
            {
              "condition": "Name of condition",
              "risk_level": "high/medium/low",
              "evidence": "Detailed explanation of why this is concerning, including specific values and their implications",
              "recommendations": ["Specific action items, including when to seek medical attention"],
              "urgency": "immediate/soon/routine"
            }
          ],
          "urgent": true/false,
          "summary": "Overall assessment of the situation",
          "next_steps": ["Immediate actions to take"]
        }
      ''';

      await _incrementRequestCount();

      final generatedContent = await _model.generateContent([Content.text(prompt)]);
      final analysisText = generatedContent.text;
      
      if (analysisText == null || analysisText.isEmpty) {
        print('Empty response from AI model');
        return [];
      }
      
      print('AI Response: $analysisText');
      
      String jsonStr = analysisText;
      
      if (jsonStr.contains('```json')) {
        final startIndex = jsonStr.indexOf('```json') + 7;
        final endIndex = jsonStr.lastIndexOf('```');
        if (endIndex > startIndex) {
          jsonStr = jsonStr.substring(startIndex, endIndex).trim();
        }
      }
      
      final jsonStartIndex = jsonStr.indexOf('{');
      final jsonEndIndex = jsonStr.lastIndexOf('}') + 1;
      if (jsonStartIndex >= 0 && jsonEndIndex > jsonStartIndex) {
        jsonStr = jsonStr.substring(jsonStartIndex, jsonEndIndex);
      }
      
      final Map<String, dynamic> analysis = json.decode(jsonStr);
      
      List<HealthAlert> alerts = [];
      
      if (analysis.containsKey('risks')) {
        for (var risk in analysis['risks']) {
          final condition = risk['condition'];
          final riskLevel = risk['risk_level']?.toLowerCase() ?? 'medium';
          final evidence = risk['evidence'];
          final recommendations = risk['recommendations'] is List 
              ? (risk['recommendations'] as List).cast<String>() 
              : ['Consult your healthcare provider'];
          final urgency = risk['urgency']?.toLowerCase() ?? 'routine';
              
          AlertSeverity severity;
          if (urgency == 'immediate' || riskLevel == 'high') {
            severity = AlertSeverity.high;
          } else if (urgency == 'soon' || riskLevel == 'medium') {
            severity = AlertSeverity.medium;
          } else {
            severity = AlertSeverity.low;
          }
          
          final message = '''
            $evidence
            
            Recommendations:
            - ${recommendations.join('\n- ')}
            
            ${urgency == 'immediate' ? '⚠️ URGENT: Please seek immediate medical attention!' : ''}
            ${urgency == 'soon' ? '⚠️ Please consult your healthcare provider soon.' : ''}
          ''';
          
          alerts.add(HealthAlert(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: condition,
            message: message,
            severity: severity,
            lastUpdated: DateTime.now(),
          ));
        }
      }
      
      if (analysis.containsKey('summary') && analysis['summary'] != null) {
        alerts.add(HealthAlert(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: 'Overall Assessment',
          message: analysis['summary'],
          severity: analysis['urgent'] == true ? AlertSeverity.high : AlertSeverity.low,
          lastUpdated: DateTime.now(),
        ));
      }
      
      if (analysis.containsKey('next_steps') && analysis['next_steps'] is List) {
        final nextSteps = (analysis['next_steps'] as List).cast<String>();
        if (nextSteps.isNotEmpty) {
          alerts.add(HealthAlert(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: 'Next Steps',
            message: nextSteps.join('\n'),
            severity: AlertSeverity.medium,
            lastUpdated: DateTime.now(),
          ));
        }
      }
      
      return alerts;
    } catch (e) {
      print('Error in AI analysis: $e');
      return [];
    }
  }
  
  Future<String> getEducationalContent(String condition) async {
    try {
      if (!_isModelInitialized || _model == null) {
        return _getDefaultEducationalContent(condition);
      }
      
      if (!(await _canMakeRequest())) {
        print('Daily AI request limit exceeded. Using default educational content.');
        return _getDefaultEducationalContent(condition);
      }
      
      final prompt = '''
        Provide brief, practical information about $condition during pregnancy:
        1. What it is
        2. Key symptoms
        3. Treatment options
        4. When to seek medical help
        Max 300 words, simple language.
      ''';
      
      await _incrementRequestCount();
      final generatedContent = await _model.generateContent([Content.text(prompt)]);
      final content = generatedContent.text;
      
      return content ?? _getDefaultEducationalContent(condition);
    } catch (e) {
      print('Error getting educational content: $e');
      return _getDefaultEducationalContent(condition);
    }
  }
  
  String _getDefaultEducationalContent(String condition) {
    if (_pregnancyRiskConditions.containsKey(condition)) {
      final data = _pregnancyRiskConditions[condition]!;
      
      return '''
        **$condition**
        
        ${data['description']}
        
        **Common symptoms:**
        - ${(data['symptoms'] as List).join('\n- ')}
        
        **Recommendations:**
        - ${(data['recommendations'] as List).join('\n- ')}
        
        Always consult with your healthcare provider for personalized advice about your pregnancy.
      ''';
    }
    
    return '''
      Information about $condition

      Please consult with your healthcare provider to learn more about this condition and how it might affect your pregnancy. Regular prenatal care is essential for monitoring your health and addressing any concerns promptly.
      
      If you experience concerning symptoms, don't hesitate to contact your healthcare provider immediately.
    ''';
  }
  
  Future<List<Map<String, dynamic>>> getWeightHistory() async {
    return await _databaseService.getHistoryForField('weight');
  }

  // Method to handle chat interactions
  Future<String> chat(String userInput, {List<String>? context}) async {
    try {
      if (!_isModelInitialized || _model == null) {
        return 'Error: AI model not initialized.';
      }

      // Prepare the prompt for the model
      final contextText = context != null ? context.join('\n') : '';
      final prompt = '''
        Context:
        $contextText

        User: $userInput
        Assistant: Let me help you with that.
      ''';

      // Generate a response using the model
      final generatedContent = await _model!.generateContent([Content.text(prompt)]);
      final response = generatedContent.text;

      return response ?? 'Sorry, I could not generate a response.';
    } catch (e) {
      print('Error in chat: $e');
      return 'An error occurred while processing your request.';
    }
  }
}