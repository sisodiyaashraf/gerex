import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ActivityLog {
  final String id;
  final String type; // 'water' or 'steps' or 'calories'
  final String description;
  final DateTime timestamp;

  ActivityLog({
    required this.id,
    required this.type,
    required this.description,
    required this.timestamp,
  });

  Map<String, String> toJson() {
    return {
      'id': id,
      'type': type,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ActivityLog.fromJson(Map<String, String> json) {
    return ActivityLog(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      description: json['description'] ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
    );
  }
}

class ActivityProvider extends ChangeNotifier {
  final SharedPreferences _prefs;

  ActivityProvider(this._prefs) {
    _loadState();
  }

  // Current values
  int _waterIntake = 1200; // in ml
  int _waterTarget = 2500;
  int _stepsCount = 4230;
  int _stepsTarget = 8000;
  double _sleepHours = 6.5;
  double _sleepTarget = 8.0;
  int _calories = 1450;
  int _caloriesTarget = 2200;

  double _userHeight = 175.0; // in cm, for BMI calculation

  List<ActivityLog> _logs = [];

  // Getters
  int get waterIntake => _waterIntake;
  int get waterTarget => _waterTarget;
  int get stepsCount => _stepsCount;
  int get stepsTarget => _stepsTarget;
  double get sleepHours => _sleepHours;
  double get sleepTarget => _sleepTarget;
  int get calories => _calories;
  int get caloriesTarget => _caloriesTarget;
  double get userHeight => _userHeight;
  List<ActivityLog> get logs => _logs;

  void _loadState() {
    _waterIntake = _prefs.getInt('act_water_intake') ?? 1200;
    _waterTarget = _prefs.getInt('act_water_target') ?? 2500;
    _stepsCount = _prefs.getInt('act_steps_count') ?? 4230;
    _stepsTarget = _prefs.getInt('act_steps_target') ?? 8000;
    _sleepHours = _prefs.getDouble('act_sleep_hours') ?? 6.5;
    _sleepTarget = _prefs.getDouble('act_sleep_target') ?? 8.0;
    _calories = _prefs.getInt('act_calories') ?? 1450;
    _caloriesTarget = _prefs.getInt('act_calories_target') ?? 2200;
    _userHeight = _prefs.getDouble('act_user_height') ?? 175.0;

    final logList = _prefs.getStringList('act_logs_list') ?? [];
    _logs = logList.map((item) {
      final parts = item.split('::');
      return ActivityLog(
        id: parts[0],
        type: parts[1],
        description: parts[2],
        timestamp: DateTime.tryParse(parts[3]) ?? DateTime.now(),
      );
    }).toList();

    notifyListeners();
  }

  Future<void> _saveState() async {
    await _prefs.setInt('act_water_intake', _waterIntake);
    await _prefs.setInt('act_water_target', _waterTarget);
    await _prefs.setInt('act_steps_count', _stepsCount);
    await _prefs.setInt('act_steps_target', _stepsTarget);
    await _prefs.setDouble('act_sleep_hours', _sleepHours);
    await _prefs.setDouble('act_sleep_target', _sleepTarget);
    await _prefs.setInt('act_calories', _calories);
    await _prefs.setInt('act_calories_target', _caloriesTarget);
    await _prefs.setDouble('act_user_height', _userHeight);

    final logList = _logs.map((l) => '${l.id}::${l.type}::${l.description}::${l.timestamp.toIso8601String()}').toList();
    await _prefs.setStringList('act_logs_list', logList);
  }

  Future<void> addWater(int ml) async {
    _waterIntake += ml;
    _logs.insert(
      0,
      ActivityLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: 'water',
        description: 'Logged $ml ml of Water Intake',
        timestamp: DateTime.now(),
      ),
    );
    if (_logs.length > 50) _logs.removeLast();
    await _saveState();
    notifyListeners();
  }

  Future<void> addSteps(int steps) async {
    _stepsCount += steps;
    // Assume 0.04 kcal per step
    _calories += (steps * 0.04).round();
    _logs.insert(
      0,
      ActivityLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: 'steps',
        description: 'Walked $steps steps (+${(steps * 0.04).round()} kcal)',
        timestamp: DateTime.now(),
      ),
    );
    if (_logs.length > 50) _logs.removeLast();
    await _saveState();
    notifyListeners();
  }

  Future<void> addSleep(double hours) async {
    _sleepHours = (_sleepHours + hours).clamp(0.0, 24.0);
    _logs.insert(
      0,
      ActivityLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: 'sleep',
        description: 'Logged $hours hours of Sleep',
        timestamp: DateTime.now(),
      ),
    );
    if (_logs.length > 50) _logs.removeLast();
    await _saveState();
    notifyListeners();
  }

  Future<void> setUserHeight(double height) async {
    if (height > 50.0 && height < 300.0) {
      _userHeight = height;
      await _saveState();
      notifyListeners();
    }
  }

  Future<void> clearLogs() async {
    _logs.clear();
    await _saveState();
    notifyListeners();
  }
}
