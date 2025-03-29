import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:health_app/models/health_data.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  static Database? _database;
  static DatabaseFactory databaseFactory = databaseFactoryFfi;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'health_data.db');
      print('Initializing database at: $path');
      
      // Use appropriate database implementation based on platform
      if (Platform.isAndroid || Platform.isIOS) {
        // Use regular sqflite for mobile platforms
        return await openDatabase(
          path,
          version: 3,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        );
      } else {
        // Use sqflite_ffi for desktop platforms
        sqfliteFfiInit();
        return await databaseFactoryFfi.openDatabase(
          path,
          options: OpenDatabaseOptions(
            version: 3,
            onCreate: _onCreate,
            onUpgrade: _onUpgrade,
          ),
        );
      }
    } catch (e) {
      print('Error initializing database: $e');
      rethrow;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    print('Creating database tables...');
    await db.execute('''
      CREATE TABLE health_data (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        weight REAL,
        blood_pressure TEXT,
        blood_sugar TEXT,
        mood TEXT,
        symptoms TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE reminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        reminder_type INTEGER NOT NULL,
        date TEXT NOT NULL,
        time TEXT NOT NULL,
        is_completed INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    print('Database tables created successfully');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Drop old tables and create new ones
      await db.execute('DROP TABLE IF EXISTS vital_signs');
      await db.execute('DROP TABLE IF EXISTS health_alerts');
      await _createTables(db, newVersion);
    }
    
    if (oldVersion < 3) {
      // Create reminders table for version 3
      await db.execute('''
        CREATE TABLE IF NOT EXISTS reminders (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          description TEXT,
          reminder_type INTEGER NOT NULL,
          date TEXT NOT NULL,
          time TEXT NOT NULL,
          is_completed INTEGER DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');
      print('Created reminders table for version 3');
    }
  }

  Future<void> _createTables(Database db, int version) async {
    // Health data table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS health_data (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp TEXT NOT NULL,
        pregnancy_month INTEGER,
        due_date TEXT,
        weight TEXT,
        height TEXT,
        systolic_bp TEXT,
        diastolic_bp TEXT,
        temperature TEXT,
        hemoglobin TEXT,
        glucose TEXT,
        symptoms TEXT,
        dietary_log TEXT,
        physical_activity TEXT,
        supplements TEXT,
        mood_rating INTEGER,
        has_anxiety INTEGER,
        anxiety_level REAL
      )
    ''');
    
    // Health alerts table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS health_alerts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        severity INTEGER NOT NULL,
        timestamp TEXT NOT NULL,
        is_read INTEGER DEFAULT 0
      )
    ''');

    // Reminders table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS reminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        reminder_type INTEGER NOT NULL,
        date TEXT NOT NULL,
        time TEXT NOT NULL,
        is_completed INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    
    print('Database tables created successfully');
  }

  // Save health data from form
  Future<int> saveHealthData({
    int? pregnancyMonth,
    String? dueDate,
    String? weight,
    String? height,
    String? systolicBP,
    String? diastolicBP,
    String? temperature,
    String? hemoglobin,
    String? glucose,
    String? symptoms,
    String? dietaryLog,
    String? physicalActivity,
    String? supplements,
    double? moodRating,
    bool? hasAnxiety,
    double? anxietyLevel,
  }) async {
    try {
      final db = await database;
      final timestamp = DateTime.now().toIso8601String();
      
      // Print all parameters to debug
      print('Saving health data:');
      print('- pregnancyMonth: $pregnancyMonth');
      print('- dueDate: $dueDate');
      print('- weight: $weight');
      print('- moodRating: $moodRating');
      
      // Convert doubles to int for mood rating
      int? moodRatingInt;
      if (moodRating != null) {
        moodRatingInt = moodRating.round();
        print('- moodRatingInt: $moodRatingInt (converted from $moodRating)');
      }
      
      final id = await db.insert(
        'health_data',
        {
          'timestamp': timestamp,
          'pregnancy_month': pregnancyMonth,
          'due_date': dueDate,
          'weight': weight,
          'height': height,
          'systolic_bp': systolicBP,
          'diastolic_bp': diastolicBP,
          'temperature': temperature,
          'hemoglobin': hemoglobin,
          'glucose': glucose,
          'symptoms': symptoms,
          'dietary_log': dietaryLog,
          'physical_activity': physicalActivity,
          'supplements': supplements,
          'mood_rating': moodRatingInt, // Save as integer
          'has_anxiety': hasAnxiety == true ? 1 : 0,
          'anxiety_level': anxietyLevel,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      print('Saved health data with ID: $id');
      return id;
    } catch (e) {
      print('Error saving health data: $e');
      rethrow;
    }
  }

  // Get the latest health data entry
  Future<Map<String, dynamic>?> getLatestHealthData() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> results = await db.query(
        'health_data',
        orderBy: 'timestamp DESC',
        limit: 1,
      );
      
      if (results.isEmpty) {
        return null;
      }
      
      return results.first;
    } catch (e) {
      print('Error getting latest health data: $e');
      return null;
    }
  }

  // Get latest value for a specific health parameter
  Future<dynamic> getLatestValueFor(String columnName) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      'health_data',
      columns: [columnName],
      where: '$columnName IS NOT NULL',
      orderBy: 'timestamp DESC',
      limit: 1,
    );
    
    if (results.isNotEmpty && results.first[columnName] != null) {
      return results.first[columnName];
    }
    
    return null;
  }

  // Get all health data entries
  Future<List<Map<String, dynamic>>> getAllHealthData() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> results = await db.query(
        'health_data',
        orderBy: 'timestamp DESC',
      );
      
      print('Found ${results.length} health data entries');
      return results;
    } catch (e) {
      print('Error getting all health data: $e');
      return [];
    }
  }

  // Save a health alert to the database
  Future<int> saveHealthAlert(HealthAlert alert) async {
    try {
      final db = await database;
      
      // First check if this alert already exists (to avoid duplicates)
      final List<Map<String, dynamic>> existingAlerts = await db.query(
        'health_alerts',
        where: 'title = ?',
        whereArgs: [alert.title],
        orderBy: 'timestamp DESC',
        limit: 1,
      );
      
      // If a similar alert exists and is less than 24 hours old, don't create a new one
      if (existingAlerts.isNotEmpty) {
        final existingAlert = existingAlerts.first;
        final existingTimestamp = DateTime.parse(existingAlert['timestamp']);
        final timeDifference = DateTime.now().difference(existingTimestamp).inHours;
        
        if (timeDifference < 24) {
          print('Similar alert already exists and is less than 24 hours old. Skipping.');
          return existingAlert['id'];
        }
      }
      
      // Insert the new alert
      return await db.insert(
        'health_alerts',
        {
          'title': alert.title,
          'message': alert.message,
          'severity': alert.severity.index,
          'timestamp': DateTime.now().toIso8601String(),
          'is_read': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print('Error saving health alert: $e');
      return -1;
    }
  }

  // Get all health alerts
  Future<List<HealthAlert>> getHealthAlerts() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> results = await db.query(
        'health_alerts',
        orderBy: 'timestamp DESC',
        limit: 10, // Limit to most recent alerts
      );
      
      print('Found ${results.length} health alerts');
      
      List<HealthAlert> alerts = [];
      for (var alertData in results) {
        alerts.add(HealthAlert(
          id: alertData['id'].toString(),
          title: alertData['title'],
          message: alertData['message'],
          severity: AlertSeverity.values[alertData['severity']],
          lastUpdated: DateTime.parse(alertData['timestamp']),
        ));
      }
      
      return alerts;
    } catch (e) {
      print('Error getting health alerts: $e');
      return [];
    }
  }

  // Convert database entries to VitalSign objects for the dashboard
  Future<List<VitalSign>> getVitalSigns() async {
    final List<VitalSign> vitalSigns = [];
    
    try {
      print("Getting vital signs from database...");
      
      // Get all health data entries sorted by timestamp (newest first)
      final allEntries = await getAllHealthData();
      print("Found ${allEntries.length} health data entries");
      
      // If no data exists, return mock data
      if (allEntries.isEmpty) {
        print("No data found, returning mock data");
        return [
          Weight(
            id: '1',
            lastUpdated: DateTime.now(),
            value: '65',
            history: [],
          ),
          BloodPressure(
            id: '2',
            lastUpdated: DateTime.now(),
            systolic: '120',
            diastolic: '80',
            history: [],
          ),
          Temperature(
            id: '3',
            lastUpdated: DateTime.now(),
            value: '36.7',
            history: [],
          ),
        ];
      }
      
      // Create a map to store the latest non-null value for each vital sign type
      Map<String, dynamic> latestValues = {};
      
      // Scan through all entries to find the most recent non-null value for each field
      for (var entry in allEntries) {
        // Process weight
        if (entry['weight'] != null && !latestValues.containsKey('weight')) {
          latestValues['weight'] = {
            'value': entry['weight'],
            'timestamp': entry['timestamp'],
            'id': entry['id'].toString(),
          };
          print("Found weight: ${entry['weight']}");
        }
        
        // Process blood pressure - both systolic and diastolic needed
        if (entry['systolic_bp'] != null && entry['diastolic_bp'] != null && !latestValues.containsKey('blood_pressure')) {
          latestValues['blood_pressure'] = {
            'systolic': entry['systolic_bp'],
            'diastolic': entry['diastolic_bp'],
            'timestamp': entry['timestamp'],
            'id': entry['id'].toString(),
          };
          print("Found blood pressure: ${entry['systolic_bp']}/${entry['diastolic_bp']}");
        }
        
        // Process temperature
        if (entry['temperature'] != null && !latestValues.containsKey('temperature')) {
          latestValues['temperature'] = {
            'value': entry['temperature'],
            'timestamp': entry['timestamp'],
            'id': entry['id'].toString(),
          };
          print("Found temperature: ${entry['temperature']}");
        }
        
        // Process hemoglobin
        if (entry['hemoglobin'] != null && !latestValues.containsKey('hemoglobin')) {
          latestValues['hemoglobin'] = {
            'value': entry['hemoglobin'],
            'timestamp': entry['timestamp'],
            'id': entry['id'].toString(),
          };
          print("Found hemoglobin: ${entry['hemoglobin']}");
        }
        
        // Process glucose
        if (entry['glucose'] != null && !latestValues.containsKey('glucose')) {
          latestValues['glucose'] = {
            'value': entry['glucose'],
            'timestamp': entry['timestamp'],
            'id': entry['id'].toString(),
          };
          print("Found glucose: ${entry['glucose']}");
        }
        
        // Add more vital signs as needed
        if (entry['height'] != null && !latestValues.containsKey('height')) {
          latestValues['height'] = {
            'value': entry['height'],
            'timestamp': entry['timestamp'],
            'id': entry['id'].toString(),
          };
          print("Found height: ${entry['height']}");
        }
      }
      
      print("Found ${latestValues.length} types of vital signs with values");
      
      // Create vital sign objects from the latest values
      if (latestValues.containsKey('weight')) {
        final data = latestValues['weight'];
        vitalSigns.add(Weight(
          id: data['id'],
          lastUpdated: DateTime.parse(data['timestamp']),
          value: data['value'],
          history: await _getHistoryForField('weight'),
        ));
      }
      
      if (latestValues.containsKey('blood_pressure')) {
        final data = latestValues['blood_pressure'];
        vitalSigns.add(BloodPressure(
          id: data['id'],
          lastUpdated: DateTime.parse(data['timestamp']),
          systolic: data['systolic'],
          diastolic: data['diastolic'],
          history: await _getHistoryForField('systolic_bp', 'diastolic_bp'),
        ));
      }
      
      if (latestValues.containsKey('temperature')) {
        final data = latestValues['temperature'];
        vitalSigns.add(Temperature(
          id: data['id'],
          lastUpdated: DateTime.parse(data['timestamp']),
          value: data['value'],
          history: await _getHistoryForField('temperature'),
        ));
      }
      
      // Add more vital signs as needed
      if (latestValues.containsKey('hemoglobin')) {
        final data = latestValues['hemoglobin'];
        vitalSigns.add(VitalSign(
          id: data['id'],
          lastUpdated: DateTime.parse(data['timestamp']),
          name: 'Hemoglobin',
          value: data['value'],
          unit: 'g/dL',
          history: await _getHistoryForField('hemoglobin'),
        ));
      }
      
      if (latestValues.containsKey('glucose')) {
        final data = latestValues['glucose'];
        vitalSigns.add(VitalSign(
          id: data['id'],
          lastUpdated: DateTime.parse(data['timestamp']),
          name: 'Blood Glucose',
          value: data['value'],
          unit: 'mg/dL',
          history: await _getHistoryForField('glucose'),
        ));
      }
      
      if (latestValues.containsKey('height')) {
        final data = latestValues['height'];
        vitalSigns.add(VitalSign(
          id: data['id'],
          lastUpdated: DateTime.parse(data['timestamp']),
          name: 'Height',
          value: data['value'],
          unit: 'cm',
          history: await _getHistoryForField('height'),
        ));
      }
      
      print("Returning ${vitalSigns.length} vital signs");
      return vitalSigns;
    } catch (e) {
      print('Error getting vital signs: $e');
      // Return empty list on error
      return [];
    }
  }
  
  // Helper method to get history data for a field
  Future<List<Map<String, dynamic>>> _getHistoryForField(String fieldName, [String? secondFieldName]) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> results = await db.query(
        'health_data',
        columns: secondFieldName != null 
            ? ['id', 'timestamp', fieldName, secondFieldName] 
            : ['id', 'timestamp', fieldName],
        where: '$fieldName IS NOT NULL',
        orderBy: 'timestamp ASC',
      );
      
      print('Found ${results.length} history entries for $fieldName');
      
      List<Map<String, dynamic>> history = [];
      
      // Only keep entries where the field has a valid value (not null or empty)
      for (var entry in results) {
        if (entry[fieldName] != null && entry[fieldName].toString().isNotEmpty) {
          if (secondFieldName != null) {
            // For blood pressure with systolic and diastolic
            if (entry[secondFieldName] != null && entry[secondFieldName].toString().isNotEmpty) {
              history.add({
                'date': DateTime.parse(entry['timestamp']),
                'systolic': entry[fieldName],
                'diastolic': entry[secondFieldName],
              });
            }
          } else {
            // For other vital signs with single value
            history.add({
              'date': DateTime.parse(entry['timestamp']),
              'value': entry[fieldName],
            });
          }
        }
      }
      
      // If we have too many history entries, keep only the most recent ones
      if (history.length > 10) {
        history = history.sublist(history.length - 10);
      }
      
      // If no history, create a default history with the current value to avoid chart errors
      if (history.isEmpty && results.isNotEmpty) {
        final latestEntry = results.last;
        if (secondFieldName != null) {
          history.add({
            'date': DateTime.parse(latestEntry['timestamp']),
            'systolic': latestEntry[fieldName],
            'diastolic': latestEntry[secondFieldName],
          });
        } else {
          history.add({
            'date': DateTime.parse(latestEntry['timestamp']),
            'value': latestEntry[fieldName],
          });
        }
      }
      
      return history;
    } catch (e) {
      print('Error getting history for $fieldName: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getMoodData() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> results = await db.query(
        'health_data',
        columns: ['id', 'timestamp', 'mood_rating'],
        where: 'mood_rating IS NOT NULL',
        orderBy: 'timestamp DESC',
      );

      print('Found ${results.length} mood entries');
      
      if (results.isEmpty) {
        // Return default structure with null ratings
        return {
          'currentMoodRating': null,
          'moodHistory': [],
        };
      }

      // Get most recent mood rating - handle both int and double types
      var rawMoodRating = results.first['mood_rating'];
      int? currentMoodRating;
      
      if (rawMoodRating is int) {
        currentMoodRating = rawMoodRating;
      } else if (rawMoodRating is double) {
        currentMoodRating = rawMoodRating.round();
      }
      
      print('Latest mood rating (processed): $currentMoodRating');

      // Process history - get the last 7 days of mood ratings
      List<Map<String, dynamic>> moodHistory = [];
      
      // Map to track dates we've already processed (to avoid duplicates)
      Map<String, bool> processedDates = {};
      
      for (var entry in results) {
        if (entry['mood_rating'] != null) {
          final DateTime date = DateTime.parse(entry['timestamp']);
          final String dateKey = '${date.year}-${date.month}-${date.day}';
          
          // Only add if we haven't processed this date yet
          if (!processedDates.containsKey(dateKey)) {
            // Handle both int and double rating types
            var rawRating = entry['mood_rating'];
            int rating;
            
            if (rawRating is int) {
              rating = rawRating;
            } else if (rawRating is double) {
              rating = rawRating.round();
            } else {
              // Skip this entry if we can't process the rating
              continue;
            }
            
            moodHistory.add({
              'date': date,
              'rating': rating,
            });
            processedDates[dateKey] = true;
          }
        }
      }
      
      // Sort by date (oldest to newest)
      moodHistory.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
      
      // Limit to last 7 days
      if (moodHistory.length > 7) {
        moodHistory = moodHistory.sublist(moodHistory.length - 7);
      }

      return {
        'currentMoodRating': currentMoodRating,
        'moodHistory': moodHistory,
      };
    } catch (e) {
      print('Error getting mood data: $e');
      return {
        'currentMoodRating': null,
        'moodHistory': [],
      };
    }
  }

  Future<Map<String, dynamic>?> getPregnancyData() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> results = await db.query(
        'health_data',
        columns: ['id', 'timestamp', 'due_date', 'current_month'],
        where: 'due_date IS NOT NULL OR current_month IS NOT NULL',
        orderBy: 'timestamp DESC',
        limit: 1,
      );

      if (results.isEmpty) {
        return null;
      }

      return {
        'due_date': results.first['due_date'],
        'current_month': results.first['current_month'],
      };
    } catch (e) {
      print('Error getting pregnancy data: $e');
      return null;
    }
  }

  // Method to get history data for weight measurements
  Future<List<Map<String, dynamic>>> getWeightHistory() async {
    return await _getHistoryForField('weight');
  }
  
  // Generic method to get history data for any field
  Future<List<Map<String, dynamic>>> getHistoryForField(String fieldName) async {
    return await _getHistoryForField(fieldName);
  }

  // Get all health alerts (without limit)
  Future<List<HealthAlert>> getAllHealthAlerts() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> results = await db.query(
        'health_alerts',
        orderBy: 'timestamp DESC',
      );
      
      print('Found ${results.length} total health alerts');
      
      List<HealthAlert> alerts = [];
      for (var alertData in results) {
        alerts.add(HealthAlert(
          id: alertData['id'].toString(),
          title: alertData['title'],
          message: alertData['message'],
          severity: AlertSeverity.values[alertData['severity']],
          lastUpdated: DateTime.parse(alertData['timestamp']),
        ));
      }
      
      return alerts;
    } catch (e) {
      print('Error getting all health alerts: $e');
      return [];
    }
  }
  
  // Mark a health alert as read
  Future<void> markHealthAlertAsRead(String alertId) async {
    try {
      final db = await database;
      await db.update(
        'health_alerts',
        {'is_read': 1},
        where: 'id = ?',
        whereArgs: [alertId],
      );
      print('Marked health alert $alertId as read');
    } catch (e) {
      print('Error marking health alert as read: $e');
      rethrow;
    }
  }

  // Reminder CRUD operations
  Future<int> saveReminder({
    required String title,
    String? description,
    required int reminderType,
    required DateTime date,
    required DateTime time,
  }) async {
    try {
      final db = await database;
      final now = DateTime.now().toIso8601String();
      
      // Format date and time separately
      final dateStr = date.toIso8601String().split('T')[0];
      final timeStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      
      print('Saving reminder:');
      print('- Title: $title');
      print('- Date: $dateStr');
      print('- Time: $timeStr');
      print('- Type: $reminderType');
      
      return await db.insert(
        'reminders',
        {
          'title': title,
          'description': description,
          'reminder_type': reminderType,
          'date': dateStr,
          'time': timeStr,
          'is_completed': 0,
          'created_at': now,
          'updated_at': now,
        },
      );
    } catch (e) {
      print('Error saving reminder: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getReminders() async {
    try {
      final db = await database;
      return await db.query(
        'reminders',
        orderBy: 'date ASC, time ASC',
      );
    } catch (e) {
      print('Error getting reminders: $e');
      return [];
    }
  }

  Future<bool> updateReminder({
    required int id,
    String? title,
    String? description,
    int? reminderType,
    DateTime? date,
    DateTime? time,
    bool? isCompleted,
  }) async {
    try {
      final db = await database;
      final Map<String, dynamic> updates = {
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (reminderType != null) updates['reminder_type'] = reminderType;
      if (date != null) updates['date'] = date.toIso8601String();
      if (time != null) updates['time'] = time.toIso8601String();
      if (isCompleted != null) updates['is_completed'] = isCompleted ? 1 : 0;

      await db.update(
        'reminders',
        updates,
        where: 'id = ?',
        whereArgs: [id],
      );
      return true;
    } catch (e) {
      print('Error updating reminder: $e');
      return false;
    }
  }

  Future<bool> deleteReminder(int id) async {
    try {
      final db = await database;
      await db.delete(
        'reminders',
        where: 'id = ?',
        whereArgs: [id],
      );
      return true;
    } catch (e) {
      print('Error deleting reminder: $e');
      return false;
    }
  }

  Future<bool> toggleReminderCompletion(int id) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> results = await db.query(
        'reminders',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (results.isEmpty) return false;

      final currentStatus = results.first['is_completed'] == 1;
      return await updateReminder(id: id, isCompleted: !currentStatus);
    } catch (e) {
      print('Error toggling reminder completion: $e');
      return false;
    }
  }

  Future<void> deleteDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'health_data.db');
      
      if (Platform.isAndroid || Platform.isIOS) {
        // Use regular sqflite for mobile platforms
        await databaseFactory.deleteDatabase(path);
      } else {
        // Use sqflite_ffi for desktop platforms
        await databaseFactoryFfi.deleteDatabase(path);
      }
      
      _database = null;
      print('Database deleted successfully');
    } catch (e) {
      print('Error deleting database: $e');
      rethrow;
    }
  }
} 