import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/sleep_entities.dart';
import 'package:gerex/core/providers/notification_provider.dart';
import 'package:gerex/core/utils/logger.dart';

class SleepProvider extends ChangeNotifier {
  final SharedPreferences _prefs;
  final NotificationProvider _notifications;
  Timer? _alarmTimer;
  String _lastFiredMinute = '';

  SleepProvider(this._prefs, this._notifications) {
    _loadSleepLogs();
    _loadAlarms();
    _startAlarmCheckLoop();
  }

  List<SleepLog> _sleepLogs = [];
  List<SleepLog> get sleepLogs => _sleepLogs;

  List<SleepAlarm> _alarms = [];
  List<SleepAlarm> get alarms => _alarms;

  final double _sleepGoalHours = 8.0;
  double get sleepGoalHours => _sleepGoalHours;

  @override
  void dispose() {
    _alarmTimer?.cancel();
    super.dispose();
  }

  void _loadSleepLogs() {
    final list = _prefs.getStringList('cached_sleep_logs') ?? [];
    if (list.isEmpty) {
      // Seed default logs for past 7 days to wow the user with a beautiful chart on first run!
      final now = DateTime.now();
      _sleepLogs = List.generate(7, (idx) {
        final date = now.subtract(Duration(days: 6 - idx));
        // Random hours between 6.0 and 9.0
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
    final list = _sleepLogs.map((log) => '${log.id}:::${log.date.toIso8601String()}:::${log.hours}:::${log.quality}').toList();
    await _prefs.setStringList('cached_sleep_logs', list);
  }

  void _loadAlarms() {
    final list = _prefs.getStringList('cached_sleep_alarms') ?? [];
    if (list.isEmpty) {
      // Add default weekday alarm (22:30 to 06:30)
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
          return SleepAlarm(
            id: parts[0],
            bedtimeHour: parts[1],
            wakeHour: parts[2],
            repeatDays: days,
            isEnabled: parts[4] == '1',
            vibrate: parts[5] == '1',
          );
        }).toList();
      } catch (e) {
        SecureLogger.logError('Failed to parse alarms list', e);
      }
    }
    notifyListeners();
  }

  Future<void> _saveAlarms() async {
    final list = _alarms.map((a) => '${a.id}:::${a.bedtimeHour}:::${a.wakeHour}:::${a.repeatDays.join(',')}:::${a.isEnabled ? '1' : '0'}:::${a.vibrate ? '1' : '0'}').toList();
    await _prefs.setStringList('cached_sleep_alarms', list);
  }

  // Calculate projected sleep hours between bedtime (HH:mm) and wake time (HH:mm)
  double calculateDuration(String bedtime, String wake) {
    try {
      final bParts = bedtime.split(':').map(int.parse).toList();
      final wParts = wake.split(':').map(int.parse).toList();

      final bMin = bParts[0] * 60 + bParts[1];
      final wMin = wParts[0] * 60 + wParts[1];

      int diff = wMin - bMin;
      if (diff < 0) {
        diff += 24 * 60; // Crosses midnight
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
  }) async {
    // Validate duration range (must be between 2 and 16 hours)
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
    );

    _alarms.add(newAlarm);
    await _saveAlarms();
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
      );
      await _saveAlarms();
      notifyListeners();
    }
  }

  Future<void> deleteAlarm(String id) async {
    _alarms.removeWhere((a) => a.id == id);
    await _saveAlarms();
    notifyListeners();
  }

  Future<void> addSleepLog(DateTime date, double hours, double quality) async {
    final newLog = SleepLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: date,
      hours: hours,
      quality: quality,
    );
    _sleepLogs.add(newLog);
    // Keep max 30 entries
    if (_sleepLogs.length > 30) {
      _sleepLogs.removeAt(0);
    }
    await _saveSleepLogs();
    notifyListeners();
  }

  // Periodic alarm checks
  void _startAlarmCheckLoop() {
    _alarmTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      final now = DateTime.now();
      final minuteString = '${now.year}-${now.month}-${now.day} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      if (minuteString == _lastFiredMinute) return; // Prevent double alerts inside the same minute

      final currentHourMin = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      final dayOfWeek = now.weekday; // Mon=1, Sun=7

      for (final alarm in _alarms) {
        if (!alarm.isEnabled) continue;
        if (!alarm.repeatDays.contains(dayOfWeek)) continue;

        if (alarm.bedtimeHour == currentHourMin) {
          _lastFiredMinute = minuteString;
          _notifications.sendNotification(
            'Bedtime Reminder 🌙',
            'Time to wind down! Sleep target: ${calculateDuration(alarm.bedtimeHour, alarm.wakeHour)} hours. Avoid screens.',
          );
        } else if (alarm.wakeHour == currentHourMin) {
          _lastFiredMinute = minuteString;
          _notifications.sendNotification(
            'Wake Up Alarm ⏰',
            'Rise and shine! Ready to tackle your body health today?',
          );
        }
      }
    });
  }
}
