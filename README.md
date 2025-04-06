# EmpowerHer: AI-Powered Maternal Health App

EmpowerHer is a comprehensive mobile application built with Flutter that uses artificial intelligence to monitor the health of pregnant women, detect potential risks early, and provide educational resources to improve maternal and infant health outcomes.

## Key Features

### 1. Health Data Collection
- Regularly collects vital signs, symptoms, and lifestyle data
- Tracks pregnancy progress and important milestones
- Monitors mental health with mood and anxiety assessments

### 2. AI-Powered Risk Analysis
- Analyzes health data using advanced AI algorithms
- Identifies patterns that might indicate high-risk pregnancies
- Alerts users to potential complications such as:
  - Preeclampsia
  - Gestational diabetes
  - Anemia
  - HELLP syndrome
  - Placenta previa
  - Intrauterine growth restriction

### 3. Intelligent Alert System
- Generates personalized alerts based on severity levels
- Provides specific recommendations for each detected risk
- Combines rule-based and AI-generated analysis for comprehensive monitoring

### 4. Educational Content
- AI-generated educational resources about pregnancy conditions
- Information about symptoms, risk factors, and preventative measures
- Content tailored to the user's specific health profile

## Technical Implementation

### AI Features

The app uses a multi-layered approach to health risk detection:

1. **Rule-Based Analysis**:
   - First layer of detection using established medical thresholds
   - Checks vital signs against normal ranges for pregnancy
   - Analyzes symptom combinations that indicate specific conditions

2. **Advanced AI Analysis** (using Google's Gemini API):
   - Natural language processing to interpret symptom descriptions
   - Pattern recognition across historical health data
   - Trend analysis to detect gradual changes that might indicate developing conditions

3. **Educational Content Generation**:
   - Dynamic generation of educational content about specific conditions
   - Personalized recommendations based on the user's health profile
   - Regular updates based on the latest medical research

### Data Management

- Secure local SQLite database for health data storage
- Comprehensive data structures to track multiple health parameters
- Data aggregation for trend analysis and visualization

## Getting Started

### Prerequisites
- Flutter SDK (version 3.0 or higher)
- Dart (version 2.17 or higher)
- Android Studio or VS Code with Flutter extensions

### API Key Setup
To use the AI features, you'll need to:
1. Obtain a Google Gemini API key from [Google AI Studio](https://ai.google.dev/)
2. Replace the placeholder in `lib/services/ai_service.dart` with your actual API key

### Running the App
```bash
flutter pub get
flutter run
```

## Future Enhancements

- Cloud synchronization for backup and multi-device support
- Integration with wearable devices for continuous monitoring
- AI-powered chatbot for answering pregnancy-related questions
- Multilingual support for wider accessibility

## Contributing

Contributions to improve the AI algorithms, add new health parameters, or enhance the user interface are welcome. Please feel free to submit pull requests or open issues for discussion.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
