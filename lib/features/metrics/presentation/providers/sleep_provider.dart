import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:health/health.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../domain/entities/sleep_entities.dart';
import 'package:gerex/core/providers/notification_provider.dart';
import 'package:gerex/core/utils/logger.dart';
import 'package:gerex/core/notifications/notification_models.dart';

class SleepScoreBreakdown {
  final double durationScore;
  final double consistencyScore;
  final double qualityScore;
  final double totalScore;

  SleepScoreBreakdown({
    required this.durationScore,
    required this.consistencyScore,
    required this.qualityScore,
    required this.totalScore,
  });
}

class SleepProvider extends ChangeNotifier {
  final SharedPreferences _prefs;
  final NotificationProvider _notifications;
  
  Timer? _alarmTimer;
  String _lastFiredMinute = '';

  // OS Health Sync State
  SleepConnectionState _connectionState = SleepConnectionState.connect;
  SleepSource _activeSource = SleepSource.none;
  bool _hadEmptyHealthResponse = false;
  String? _healthConnectError;
  bool _isHealthConnectInstalled = true;
  bool _isHealthConnectDeniedPermanently = false;
  SyncedSleepData? _syncedSleepData;

  // Smart Alarm Accelerometer State
  StreamSubscription<UserAccelerometerEvent>? _accelerometerSubscription;
  bool _isTrackingSmartAlarm = false;
  final List<double> _accelerometerMagnitudes = [];
  SleepAlarm? _activeFiringAlarm;

  // Sleep Goal & Configuration
  double _sleepGoalHours = 8.0;
  int _windDownLeadMinutes = 30;

  SleepProvider(this._prefs, this._notifications) {
    _loadSleepGoal();
    _loadWindDownConfig();
    _loadSleepLogs();
    _loadAlarms();
    _startAlarmCheckLoop();
    _initHealthSyncOnLaunch();
  }

  // Getters
  List<SleepLog> _sleepLogs = [];
  List<SleepLog> get sleepLogs => _sleepLogs;

  List<SleepAlarm> _alarms = [];
  List<SleepAlarm> get alarms => _alarms;

  double get sleepGoalHours => _sleepGoalHours;
  int get windDownLeadMinutes => _windDownLeadMinutes;

  SleepConnectionState get connectionState => _connectionState;
  SleepSource get activeSource => _activeSource;
  bool get hadEmptyHealthResponse => _hadEmptyHealthResponse;
  String? get healthConnectError => _healthConnectError;
  bool get isHealthConnectInstalled => _isHealthConnectInstalled;
  bool get isHealthConnectDeniedPermanently => _isHealthConnectDeniedPermanently;
  SyncedSleepData? get syncedSleepData => _syncedSleepData;

  bool get isTrackingSmartAlarm => _isTrackingSmartAlarm;
  SleepAlarm? get activeFiringAlarm => _activeFiringAlarm;

  // ----------------------------------------------------
  // Init & Goal Management
  // ----------------------------------------------------
  void _loadSleepGoal() {
    _sleepGoalHours = _prefs.getDouble('sleep_goal_hours') ?? 8.0;
  }

  void _loadWindDownConfig() {
    _windDownLeadMinutes = _prefs.getInt('wind_down_lead_minutes') ?? 30;
  }

  Future<void> updateSleepGoal(double newGoal) async {
    _sleepGoalHours = newGoal;
    await _prefs.setDouble('sleep_goal_hours', newGoal);
    notifyListeners();
  }

  Future<void> updateWindDownLeadMinutes(int minutes) async {
    _windDownLeadMinutes = minutes;
    await _prefs.setInt('wind_down_lead_minutes', minutes);
    for (var alarm in _alarms) {
      if (alarm.isEnabled) {
        await _scheduleAlarm(alarm);
      }
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _alarmTimer?.cancel();
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

  // ----------------------------------------------------
  // Sleep Logs Management
  // ----------------------------------------------------
  void _loadSleepLogs() {
    final list = _prefs.getStringList('cached_sleep_logs') ?? [];
    if (list.isEmpty) {
      final now = DateTime.now();
      _sleepLogs = List.generate(7, (idx) {
        final date = now.subtract(Duration(days: 6 - idx));
        final hrs = 6.0 + (idx % 3) * 1.0 + (idx * 0.15) % 0.8;
        final quality = 60.0 + (hrs * 4.5) + (idx * 2.5) % 15.0;
        return SleepLog(
          id: 'seed_$idx',
          date: date,
          hours: double.parse(hrs.toStringAsFixed(1)),
          quality: double.parse(quality.clamp(0.0, 100.0).toStringAsFixed(1)),
        );
      });
      _saveSleepLogs();
    } else {
      try {
        _sleepLogs = list.map((item) {
          final parts = item.split(':::');
          return SleepLog(
            id: parts[0],
            date: DateTime.parse(parts[1]),
            hours: double.parse(parts[2]),
            quality: double.parse(parts[3]),
            wakeUpMood: parts.length > 4 ? (parts[4].isEmpty ? null : parts[4]) : null,
          );
        }).toList();
        _sleepLogs.sort((a, b) => a.date.compareTo(b.date));
      } catch (e) {
        SecureLogger.logError('Failed to parse sleep logs', e);
      }
    }
    notifyListeners();
  }

  Future<void> _saveSleepLogs() async {
    final list = _sleepLogs.map((log) => '${log.id}:::${log.date.toIso8601String()}:::${log.hours}:::${log.quality}:::${log.wakeUpMood ?? ""}').toList();
    await _prefs.setStringList('cached_sleep_logs', list);
  }

  Future<void> addSleepLog(DateTime date, double hours, double quality, [String? mood]) async {
    final newLog = SleepLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: date,
      hours: hours,
      quality: quality,
      wakeUpMood: mood,
    );
    _sleepLogs.add(newLog);
    if (_sleepLogs.length > 30) {
      _sleepLogs.removeAt(0);
    }
    await _saveSleepLogs();
    notifyListeners();
  }

  // ----------------------------------------------------
  // Alarms Configuration
  // ----------------------------------------------------
  void _loadAlarms() {
    final list = _prefs.getStringList('cached_sleep_alarms') ?? [];
    if (list.isEmpty) {
      _alarms = [
        const SleepAlarm(
          id: 'default_alarm',
          bedtimeHour: '22:30',
          wakeHour: '06:30',
          repeatDays: [1, 2, 3, 4, 5],
          isEnabled: true,
          vibrate: true,
        ),
      ];
      _saveAlarms();
    } else {
      try {
        _alarms = list.map((item) {
          final parts = item.split(':::');
          final days = parts[3].isEmpty ? <int>[] : parts[3].split(',').map(int.parse).toList();
          final isSmart = parts.length > 6 ? parts[6] == '1' : false;
          final smartStart = parts.length > 7 ? (parts[7].isEmpty ? null : parts[7]) : null;
          return SleepAlarm(
            id: parts[0],
            bedtimeHour: parts[1],
            wakeHour: parts[2],
            repeatDays: days,
            isEnabled: parts[4] == '1',
            vibrate: parts[5] == '1',
            isSmartAlarm: isSmart,
            smartAlarmWindowStart: smartStart,
          );
        }).toList();
      } catch (e) {
        SecureLogger.logError('Failed to parse alarms list', e);
      }
    }
    notifyListeners();
  }

  Future<void> _saveAlarms() async {
    final list = _alarms.map((a) => '${a.id}:::${a.bedtimeHour}:::${a.wakeHour}:::${a.repeatDays.join(',')}:::${a.isEnabled ? '1' : '0'}:::${a.vibrate ? '1' : '0'}:::${a.isSmartAlarm ? '1' : '0'}:::${a.smartAlarmWindowStart ?? ""}').toList();
    await _prefs.setStringList('cached_sleep_alarms', list);
  }

  double calculateDuration(String bedtime, String wake) {
    try {
      final bParts = bedtime.split(':').map(int.parse).toList();
      final wParts = wake.split(':').map(int.parse).toList();

      final bMin = bParts[0] * 60 + bParts[1];
      final wMin = wParts[0] * 60 + wParts[1];

      int diff = wMin - bMin;
      if (diff < 0) {
        diff += 24 * 60;
      }
      return double.parse((diff / 60.0).toStringAsFixed(1));
    } catch (_) {
      return 8.0;
    }
  }

  Future<String?> addAlarm({
    required String bedtime,
    required String wake,
    required List<int> repeatDays,
    required bool vibrate,
    bool isSmartAlarm = false,
    String? smartAlarmWindowStart,
  }) async {
    final duration = calculateDuration(bedtime, wake);
    if (duration < 2.0 || duration > 16.0) {
      return 'Projected sleep duration must be between 2 and 16 hours.';
    }

    if (repeatDays.isEmpty) {
      return 'Please select at least one day for the alarm to repeat.';
    }

    final newAlarm = SleepAlarm(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      bedtimeHour: bedtime,
      wakeHour: wake,
      repeatDays: repeatDays,
      isEnabled: true,
      vibrate: vibrate,
      isSmartAlarm: isSmartAlarm,
      smartAlarmWindowStart: smartAlarmWindowStart,
    );

    _alarms.add(newAlarm);
    await _saveAlarms();
    await _scheduleAlarm(newAlarm);
    notifyListeners();
    return null;
  }

  Future<void> toggleAlarm(String id, bool enabled) async {
    final idx = _alarms.indexWhere((a) => a.id == id);
    if (idx != -1) {
      final old = _alarms[idx];
      _alarms[idx] = SleepAlarm(
        id: old.id,
        bedtimeHour: old.bedtimeHour,
        wakeHour: old.wakeHour,
        repeatDays: old.repeatDays,
        isEnabled: enabled,
        vibrate: old.vibrate,
        isSmartAlarm: old.isSmartAlarm,
        smartAlarmWindowStart: old.smartAlarmWindowStart,
      );
      await _saveAlarms();
      if (enabled) {
        await _scheduleAlarm(_alarms[idx]);
      } else {
        for (int w = 1; w <= 7; w++) {
          await _notifications.cancelNotification('sleep-bedtime-$id-$w');
          await _notifications.cancelNotification('sleep-wake-$id-$w');
          await _notifications.cancelNotification('sleep-winddown-$id-$w');
        }
      }
      notifyListeners();
    }
  }

  Future<void> deleteAlarm(String id) async {
    _alarms.removeWhere((a) => a.id == id);
    await _saveAlarms();
    for (int w = 1; w <= 7; w++) {
      await _notifications.cancelNotification('sleep-bedtime-$id-$w');
      await _notifications.cancelNotification('sleep-wake-$id-$w');
      await _notifications.cancelNotification('sleep-winddown-$id-$w');
    }
    notifyListeners();
  }

  Future<void> _scheduleAlarm(SleepAlarm alarm) async {
    final duration = calculateDuration(alarm.bedtimeHour, alarm.wakeHour);
    
    // Cancel old ones
    for (int w = 1; w <= 7; w++) {
      await _notifications.cancelNotification('sleep-bedtime-${alarm.id}-$w');
      await _notifications.cancelNotification('sleep-wake-${alarm.id}-$w');
      await _notifications.cancelNotification('sleep-winddown-${alarm.id}-$w');
    }

    for (final weekday in alarm.repeatDays) {
      // 1. Bedtime Reminder
      {
        final parts = alarm.bedtimeHour.split(':').map(int.parse).toList();
        var date = DateTime.now();
        while (date.weekday != weekday || !DateTime(date.year, date.month, date.day, parts[0], parts[1]).isAfter(DateTime.now())) {
          date = date.add(const Duration(days: 1));
        }
        await _notifications.scheduleNotification(NotificationPayload(
          id: 'sleep-bedtime-${alarm.id}-$weekday',
          title: 'Bedtime reminder (Goal: ${duration.toStringAsFixed(1)} hrs)',
          body: 'Time to wind down for your scheduled sleep session.',
          category: NotificationCategory.sleep,
          deepLink: '/sleep-tracker',
          scheduledTime: DateTime(date.year, date.month, date.day, parts[0], parts[1]),
          repeatRule: NotificationRepeatRule.weekly,
        ));
      }

      // 2. Wind-down reminder (N minutes before bedtime)
      {
        final windDownTime = _subtractMinutes(alarm.bedtimeHour, _windDownLeadMinutes);
        final parts = windDownTime.split(':').map(int.parse).toList();
        var date = DateTime.now();
        while (date.weekday != weekday || !DateTime(date.year, date.month, date.day, parts[0], parts[1]).isAfter(DateTime.now())) {
          date = date.add(const Duration(days: 1));
        }
        await _notifications.scheduleNotification(NotificationPayload(
          id: 'sleep-winddown-${alarm.id}-$weekday',
          title: 'Time to Wind Down 🌙',
          body: 'Your bedtime is in $_windDownLeadMinutes minutes. Start your ambient sounds or breathing exercise.',
          category: NotificationCategory.sleep,
          deepLink: '/wind-down',
          scheduledTime: DateTime(date.year, date.month, date.day, parts[0], parts[1]),
          repeatRule: NotificationRepeatRule.weekly,
        ));
      }

      // 3. Wake Alarm
      {
        final parts = alarm.wakeHour.split(':').map(int.parse).toList();
        var date = DateTime.now();
        while (date.weekday != weekday || !DateTime(date.year, date.month, date.day, parts[0], parts[1]).isAfter(DateTime.now())) {
          date = date.add(const Duration(days: 1));
        }
        await _notifications.scheduleNotification(NotificationPayload(
          id: 'sleep-wake-${alarm.id}-$weekday',
          title: alarm.isSmartAlarm ? 'Smart Alarm ⏰ (Wake Window End)' : 'Wake up alarm (Slept: ${duration.toStringAsFixed(1)} hrs)',
          body: alarm.isSmartAlarm ? 'Time to rise and shine!' : 'Rise and shine — your recovery session is complete!',
          category: NotificationCategory.sleep,
          deepLink: '/sleep-tracker',
          scheduledTime: DateTime(date.year, date.month, date.day, parts[0], parts[1]),
          repeatRule: NotificationRepeatRule.weekly,
        ));
      }
    }
  }

  String _subtractMinutes(String hhmm, int minutes) {
    final parts = hhmm.split(':').map(int.parse).toList();
    int min = parts[0] * 60 + parts[1] - minutes;
    if (min < 0) {
      min += 24 * 60;
    }
    final hr = (min ~/ 60).toString().padLeft(2, '0');
    final m = (min % 60).toString().padLeft(2, '0');
    return '$hr:$m';
  }

  // ----------------------------------------------------
  // Primary Path: Platform Health (Health Connect/Kit)
  // ----------------------------------------------------
  final Health _health = Health();
  bool _isHealthConfigured = false;

  Future<void> _ensureHealthConfigured() async {
    if (!_isHealthConfigured) {
      await _health.configure();
      _isHealthConfigured = true;
    }
  }

  static const MethodChannel _healthConnectChannel = MethodChannel('com.example.gerex/health_connect');

  Future<void> openHealthConnectPermissions() async {
    try {
      await _healthConnectChannel.invokeMethod('openHealthConnectSettings');
    } catch (e) {
      SecureLogger.logError('SleepProvider: Failed to open Health Connect settings', e);
    }
  }

  Future<void> installHealthConnect() async {
    if (Platform.isAndroid) {
      try {
        await _health.installHealthConnect();
      } catch (e) {
        SecureLogger.logError('SleepProvider: Install health connect error', e);
      }
    }
  }

  Future<bool> requestHealthPermissions() async {
    _healthConnectError = null;
    _isHealthConnectInstalled = true;
    _isHealthConnectDeniedPermanently = false;
    notifyListeners();

    try {
      await _ensureHealthConfigured();
      if (Platform.isAndroid) {
        final available = await _health.isHealthConnectAvailable();
        if (!available) {
          _isHealthConnectInstalled = false;
          _healthConnectError = 'Health Connect is not installed or available on this device.';
          notifyListeners();
          return false;
        }
      }

      final types = [
        HealthDataType.SLEEP_ASLEEP,
        HealthDataType.SLEEP_AWAKE,
        HealthDataType.SLEEP_DEEP,
        HealthDataType.SLEEP_REM,
        HealthDataType.SLEEP_LIGHT,
        HealthDataType.SLEEP_SESSION,
      ];
      final bool alreadyHas = await _health.hasPermissions(types) ?? false;
      if (alreadyHas) {
        return true;
      }

      final bool hasPerm = await _health.requestAuthorization(types);
      if (!hasPerm) {
        _isHealthConnectDeniedPermanently = true;
        _healthConnectError = 'Permissions previously denied — manage it in Health Connect settings.';
        notifyListeners();
      }
      return hasPerm;
    } catch (e) {
      _healthConnectError = 'Health Connect Error: ${e.toString()}';
      notifyListeners();
      SecureLogger.logError('SleepProvider: Health Connect/Kit perm check error', e);
      return false;
    }
  }

  Future<void> startHealthConnectPolling() async {
    final allowed = await requestHealthPermissions();
    if (!allowed) {
      SecureLogger.logError('SleepProvider: Health permissions', 'denied');
      return;
    }

    _connectionState = SleepConnectionState.live;
    _activeSource = SleepSource.health;
    await _prefs.setBool('sleep_sync_enabled', true);
    notifyListeners();

    await fetchLatestSleepData();
  }

  Future<void> disconnectHealthSync() async {
    _connectionState = SleepConnectionState.disconnected;
    _activeSource = SleepSource.none;
    _syncedSleepData = null;
    await _prefs.setBool('sleep_sync_enabled', false);
    notifyListeners();
  }

  void _initHealthSyncOnLaunch() {
    final syncEnabled = _prefs.getBool('sleep_sync_enabled') ?? false;
    if (syncEnabled) {
      startHealthConnectPolling();
    }
  }

  Future<void> fetchLatestSleepData() async {
    try {
      await _ensureHealthConfigured();
      final now = DateTime.now();
      final startTime = now.subtract(const Duration(hours: 36));

      final types = [
        HealthDataType.SLEEP_ASLEEP,
        HealthDataType.SLEEP_AWAKE,
        HealthDataType.SLEEP_DEEP,
        HealthDataType.SLEEP_REM,
        HealthDataType.SLEEP_LIGHT,
        HealthDataType.SLEEP_SESSION,
      ];

      final sleepData = await _health.getHealthDataFromTypes(
        types: types,
        startTime: startTime,
        endTime: now,
      );

      if (sleepData.isNotEmpty) {
        _hadEmptyHealthResponse = false;
        
        DateTime latestWake = sleepData.first.dateTo;
        for (var p in sleepData) {
          if (p.dateTo.isAfter(latestWake)) {
            latestWake = p.dateTo;
          }
        }

        final sessionStartLimit = latestWake.subtract(const Duration(hours: 16));
        final latestSessionPoints = sleepData.where((p) => p.dateFrom.isAfter(sessionStartLimit)).toList();

        double deepMin = 0;
        double remMin = 0;
        double lightMin = 0;
        double awakeMin = 0;
        double genericAsleepMin = 0;

        for (var p in latestSessionPoints) {
          final durationMin = p.dateTo.difference(p.dateFrom).inMinutes.toDouble();
          switch (p.type) {
            case HealthDataType.SLEEP_DEEP:
              deepMin += durationMin;
              break;
            case HealthDataType.SLEEP_REM:
              remMin += durationMin;
              break;
            case HealthDataType.SLEEP_LIGHT:
              lightMin += durationMin;
              break;
            case HealthDataType.SLEEP_AWAKE:
              awakeMin += durationMin;
              break;
            case HealthDataType.SLEEP_ASLEEP:
            case HealthDataType.SLEEP_SESSION:
              genericAsleepMin += durationMin;
              break;
            default:
              break;
          }
        }

        final hasStages = (deepMin > 0 || remMin > 0 || lightMin > 0);
        double totalHrs = 0;
        if (hasStages) {
          totalHrs = (deepMin + remMin + lightMin) / 60.0;
        } else {
          totalHrs = genericAsleepMin > 0 ? (genericAsleepMin / 60.0) : 0.0;
        }

        totalHrs = double.parse(totalHrs.toStringAsFixed(1)).clamp(0.0, 24.0);
        final deepHours = double.parse((deepMin / 60.0).toStringAsFixed(1));
        final remHours = double.parse((remMin / 60.0).toStringAsFixed(1));
        final lightHours = double.parse((lightMin / 60.0).toStringAsFixed(1));
        final awakeHours = double.parse((awakeMin / 60.0).toStringAsFixed(1));

        _syncedSleepData = SyncedSleepData(
          totalHours: totalHrs,
          deepHours: deepHours,
          remHours: remHours,
          lightHours: lightHours,
          awakeHours: awakeHours,
          hasStages: hasStages,
          wakeTime: latestWake,
        );

        final calculatedScore = calculateSleepScore(
          totalHours: totalHrs,
          deepHours: deepHours,
          remHours: remHours,
          lightHours: lightHours,
          hasStages: hasStages,
        );

        final dateKey = DateTime(latestWake.year, latestWake.month, latestWake.day);
        final existingIdx = _sleepLogs.indexWhere((l) {
          final lDate = DateTime(l.date.year, l.date.month, l.date.day);
          return lDate == dateKey;
        });

        final logId = 'synced_${dateKey.millisecondsSinceEpoch}';
        final newLog = SleepLog(
          id: logId,
          date: latestWake,
          hours: totalHrs,
          quality: calculatedScore,
          wakeUpMood: hasStages ? (calculatedScore >= 80 ? 'Energized' : 'Rested') : null,
        );

        if (existingIdx != -1) {
          _sleepLogs[existingIdx] = newLog;
        } else {
          _sleepLogs.add(newLog);
          if (_sleepLogs.length > 30) {
            _sleepLogs.removeAt(0);
          }
        }
        _sleepLogs.sort((a, b) => a.date.compareTo(b.date));
        await _saveSleepLogs();
      } else {
        _hadEmptyHealthResponse = true;
      }
      notifyListeners();
    } catch (e) {
      _hadEmptyHealthResponse = true;
      notifyListeners();
      SecureLogger.logError('SleepProvider: Failed fetching sleep data', e);
    }
  }

  // ----------------------------------------------------
  // Sleep Score Calculation logic
  // ----------------------------------------------------
  double calculateSleepScore({
    required double totalHours,
    required double deepHours,
    required double remHours,
    required double lightHours,
    required bool hasStages,
  }) {
    // 1. Duration Score (up to 50 pts)
    double durationScore = (totalHours / _sleepGoalHours) * 50.0;
    if (totalHours > 10.0) {
      durationScore -= (totalHours - 10.0) * 5.0;
    }
    durationScore = durationScore.clamp(0.0, 50.0);

    // 2. Consistency Score (up to 30 pts)
    double consistencyScore = 25.0; 
    if (_sleepLogs.length >= 3) {
      final hoursList = _sleepLogs.map((l) => l.hours).toList();
      final mean = hoursList.reduce((a, b) => a + b) / hoursList.length;
      final variance = hoursList.map((h) => (h - mean) * (h - mean)).reduce((a, b) => a + b) / hoursList.length;
      final stdDev = sqrt(variance);
      consistencyScore = (30.0 - (stdDev * 10.0)).clamp(5.0, 30.0);
    }

    // 3. Stage Quality Score (up to 20 pts)
    double qualityScore = 15.0; 
    if (hasStages && totalHours > 0) {
      final deepRatio = deepHours / totalHours;
      final remRatio = remHours / totalHours;
      
      double deepPts = 10.0;
      if (deepRatio < 0.15) {
        deepPts = 10.0 * (deepRatio / 0.15);
      } else if (deepRatio > 0.25) {
        deepPts = 10.0 - (deepRatio - 0.25) * 10.0;
      }
      deepPts = deepPts.clamp(0.0, 10.0);

      double remPts = 10.0;
      if (remRatio < 0.20) {
        remPts = 10.0 * (remRatio / 0.20);
      } else if (remRatio > 0.25) {
        remPts = 10.0 - (remRatio - 0.25) * 10.0;
      }
      remPts = remPts.clamp(0.0, 10.0);

      qualityScore = deepPts + remPts;
    }

    final finalScore = durationScore + consistencyScore + qualityScore;
    return double.parse(finalScore.clamp(0.0, 100.0).toStringAsFixed(1));
  }

  SleepScoreBreakdown calculateScoreBreakdown(SleepLog log) {
    double durationScore = (log.hours / _sleepGoalHours) * 50.0;
    if (log.hours > 10.0) {
      durationScore -= (log.hours - 10.0) * 5.0;
    }
    durationScore = durationScore.clamp(0.0, 50.0);

    double consistencyScore = 25.0; 
    if (_sleepLogs.length >= 3) {
      final hoursList = _sleepLogs.map((l) => l.hours).toList();
      final mean = hoursList.reduce((a, b) => a + b) / hoursList.length;
      final variance = hoursList.map((h) => (h - mean) * (h - mean)).reduce((a, b) => a + b) / hoursList.length;
      final stdDev = sqrt(variance);
      consistencyScore = (30.0 - (stdDev * 10.0)).clamp(5.0, 30.0);
    }

    double qualityScore = 15.0;
    if (log.id.startsWith('synced_')) {
      if (_syncedSleepData != null && _syncedSleepData!.hasStages) {
        final totalHrs = _syncedSleepData!.totalHours;
        if (totalHrs > 0) {
          final deepRatio = _syncedSleepData!.deepHours / totalHrs;
          final remRatio = _syncedSleepData!.remHours / totalHrs;
          
          double deepPts = 10.0;
          if (deepRatio < 0.15) deepPts = 10.0 * (deepRatio / 0.15);
          else if (deepRatio > 0.25) deepPts = 10.0 - (deepRatio - 0.25) * 10.0;
          deepPts = deepPts.clamp(0.0, 10.0);

          double remPts = 10.0;
          if (remRatio < 0.20) remPts = 10.0 * (remRatio / 0.20);
          else if (remRatio > 0.25) remPts = 10.0 - (remRatio - 0.25) * 10.0;
          remPts = remPts.clamp(0.0, 10.0);

          qualityScore = deepPts + remPts;
        }
      }
    } else {
      qualityScore = (log.quality / 100.0) * 20.0;
    }
    
    qualityScore = double.parse(qualityScore.toStringAsFixed(1));
    durationScore = double.parse(durationScore.toStringAsFixed(1));
    consistencyScore = double.parse(consistencyScore.toStringAsFixed(1));
    
    return SleepScoreBreakdown(
      durationScore: durationScore,
      consistencyScore: consistencyScore,
      qualityScore: qualityScore,
      totalScore: log.quality,
    );
  }

  // ----------------------------------------------------
  // On-Device Smart Alarm (Accelerometer tracking)
  // ----------------------------------------------------
  int _parseTimeToMinutes(String hhmm) {
    final parts = hhmm.split(':').map(int.parse).toList();
    return parts[0] * 60 + parts[1];
  }

  void _startAccelerometerTracking(SleepAlarm alarm) {
    if (_isTrackingSmartAlarm) return;
    _isTrackingSmartAlarm = true;
    _accelerometerMagnitudes.clear();
    SecureLogger.logInfo('Smart Alarm: Started accelerometer tracking for alarm ${alarm.id}');
    notifyListeners();

    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = userAccelerometerEvents.listen((UserAccelerometerEvent event) {
      final double magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      _accelerometerMagnitudes.add(magnitude);
      
      if (_accelerometerMagnitudes.length > 50) {
        _accelerometerMagnitudes.removeAt(0);
      }

      if (_accelerometerMagnitudes.length >= 15) {
        final avg = _accelerometerMagnitudes.sublist(_accelerometerMagnitudes.length - 15)
            .reduce((a, b) => a + b) / 15.0;
        
        if (avg > 0.8) {
          SecureLogger.logInfo('Smart Alarm: Movement detected ($avg > 0.8). Waking up gently!');
          _triggerAlarm(alarm, movementDetected: true);
        }
      }
    });
  }

  void _stopAccelerometerTracking() {
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
    _isTrackingSmartAlarm = false;
    SecureLogger.logInfo('Smart Alarm: Stopped accelerometer tracking');
    notifyListeners();
  }

  void _triggerAlarm(SleepAlarm alarm, {required bool movementDetected}) {
    _stopAccelerometerTracking();
    _activeFiringAlarm = alarm;
    notifyListeners();

    final title = movementDetected 
        ? 'Smart Alarm ⏰ (Lighter Sleep)' 
        : 'Wake Up Alarm ⏰ (End of Window)';
    final body = movementDetected 
        ? 'Good morning! We noticed you moving and woke you up gently.' 
        : 'Rise and shine — your wake window has ended!';
        
    _notifications.sendNotification(title, body);
  }

  void dismissActiveAlarm() {
    _activeFiringAlarm = null;
    notifyListeners();
  }

  // Periodic alarm checks
  void _startAlarmCheckLoop() {
    _alarmTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      final now = DateTime.now();
      final minuteString = '${now.year}-${now.month}-${now.day} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      if (minuteString == _lastFiredMinute) return; 

      final currentHourMin = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      final dayOfWeek = now.weekday; 
      final currMin = now.hour * 60 + now.minute;

      for (final alarm in _alarms) {
        if (!alarm.isEnabled) continue;
        if (!alarm.repeatDays.contains(dayOfWeek)) continue;

        if (alarm.bedtimeHour == currentHourMin) {
          _lastFiredMinute = minuteString;
          _notifications.sendNotification(
            'Bedtime Reminder 🌙',
            'Time to wind down! Sleep target: ${calculateDuration(alarm.bedtimeHour, alarm.wakeHour)} hours. Avoid screens.',
          );
        }

        if (alarm.isSmartAlarm) {
          final startMin = _parseTimeToMinutes(alarm.smartAlarmWindowStart ?? alarm.wakeHour);
          final endMin = _parseTimeToMinutes(alarm.wakeHour);
          
          if (currMin >= startMin && currMin < endMin) {
            if (!_isTrackingSmartAlarm) {
              _startAccelerometerTracking(alarm);
            }
          } else if (currMin >= endMin) {
            if (_isTrackingSmartAlarm) {
              _lastFiredMinute = minuteString;
              _triggerAlarm(alarm, movementDetected: false);
            } else {
              if (alarm.wakeHour == currentHourMin) {
                _lastFiredMinute = minuteString;
                _triggerAlarm(alarm, movementDetected: false);
              }
            }
          }
        } else {
          if (alarm.wakeHour == currentHourMin) {
            _lastFiredMinute = minuteString;
            _triggerAlarm(alarm, movementDetected: false);
          }
        }
      }
    });
  }
}
