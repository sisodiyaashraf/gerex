import 'package:flutter/material.dart';
import '../../../workout/domain/entities/workout_entities.dart';
import '../../domain/entities/metrics_entities.dart';
import '../../domain/repositories/metrics_repository.dart';
import 'package:gerex/core/utils/logger.dart';

class MetricsProvider extends ChangeNotifier {
  final MetricsRepository _metricsRepository;

  MetricsProvider(this._metricsRepository);

  List<BodyMetric> _weightLogs = [];
  List<ProgressDataPoint> _volumeLogs = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Streak State
  int _currentStreak = 0;
  int _longestStreak = 0;
  final Set<String> _workoutDates = {}; // Format 'YYYY-MM-DD'
  int _streakFreezesActive = 0;
  bool _lastStreakProtected = false;

  List<BodyMetric> get weightLogs => _weightLogs;
  List<ProgressDataPoint> get volumeLogs => _volumeLogs;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get currentStreak => _currentStreak;
  int get longestStreak => _longestStreak;
  Set<String> get workoutDates => _workoutDates;
  int get streakFreezesActive => _streakFreezesActive;
  bool get lastStreakProtected => _lastStreakProtected;
  
  // ----------------------------------------------------
  // Body Metrics
  // ----------------------------------------------------
  
  Future<void> fetchWeightLogs() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _metricsRepository.getMetrics('weight');

    result.fold(
      onSuccess: (data) {
        _weightLogs = data;
        _isLoading = false;
      },
      onFailure: (failure) {
        SecureLogger.logError('fetchWeightLogs failed', failure.message);
        _errorMessage = SecureLogger.sanitizeException(failure.message);
        _isLoading = false;
      },
    );
    notifyListeners();
  }

  Future<bool> logWeight(double val) async {
    _isLoading = true;
    notifyListeners();

    final metric = BodyMetric(
      id: '',
      metricType: 'weight',
      value: val,
      loggedAt: DateTime.now(),
    );

    final result = await _metricsRepository.logMetric(metric);

    return result.fold(
      onSuccess: (logged) {
        _weightLogs.add(logged);
        _weightLogs.sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
        _isLoading = false;
        notifyListeners();
        return true;
      },
      onFailure: (failure) {
        SecureLogger.logError('logWeight failed', failure.message);
        _errorMessage = SecureLogger.sanitizeException(failure.message);
        _isLoading = false;
        notifyListeners();
        return false;
      },
    );
  }

  // ----------------------------------------------------
  // Volume progression
  // ----------------------------------------------------

  Future<void> fetchVolumeProgression(String exerciseId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _metricsRepository.getVolumeProgression(exerciseId);

    result.fold(
      onSuccess: (data) {
        _volumeLogs = data;
        _isLoading = false;
      },
      onFailure: (failure) {
        SecureLogger.logError('fetchVolumeProgression failed', failure.message);
        _errorMessage = SecureLogger.sanitizeException(failure.message);
        _isLoading = false;
      },
    );
    notifyListeners();
  }

  // ----------------------------------------------------
  // Consistency Calendar & Streaks Ticker
  // ----------------------------------------------------

  void computeStreaks(List<WorkoutSession> sessions) {
    _workoutDates.clear();
    _lastStreakProtected = false;

    if (sessions.isEmpty) {
      _currentStreak = 0;
      _longestStreak = 0;
      _streakFreezesActive = 0;
      notifyListeners();
      return;
    }

    final List<DateTime> sortedDates = [];
    for (final s in sessions) {
      if (s.completedAt != null) {
        final date = s.completedAt!;
        final dateString =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        _workoutDates.add(dateString);

        final parsedOnlyDate = DateTime(date.year, date.month, date.day);
        if (!sortedDates.contains(parsedOnlyDate)) {
          sortedDates.add(parsedOnlyDate);
        }
      }
    }

    sortedDates.sort((a, b) => a.compareTo(b));

    if (sortedDates.isEmpty) {
      _currentStreak = 0;
      _longestStreak = 0;
      _streakFreezesActive = 0;
      notifyListeners();
      return;
    }

    int longest = 1;
    int current = 1;
    int tokens = 1; // start with 1 token to be supportive
    const int maxTokens = 2;

    // Helper to get Monday of a date
    DateTime getMonday(DateTime date) {
      return DateTime(date.year, date.month, date.day).subtract(Duration(days: date.weekday - 1));
    }

    // Keep track of workouts per calendar week (Monday representation)
    final Map<DateTime, int> weeklyWorkoutCounts = {};
    for (final d in sortedDates) {
      final mon = getMonday(d);
      weeklyWorkoutCounts[mon] = (weeklyWorkoutCounts[mon] ?? 0) + 1;
    }

    // Let's trace chronologically and simulate the streak & freeze consumption
    int tempStreak = 1;
    DateTime lastDate = sortedDates.first;
    
    // Set to keep track of weeks we have already awarded tokens for
    final Set<DateTime> awardedWeeks = {};

    for (int i = 1; i < sortedDates.length; i++) {
      final currentDate = sortedDates[i];
      final diff = currentDate.difference(lastDate).inDays;

      // Check if we crossed into a new week, and award token for the previous week if it had >= 3 workouts
      final prevMonday = getMonday(lastDate);
      final currentMonday = getMonday(currentDate);
      if (currentMonday.isAfter(prevMonday)) {
        if (!awardedWeeks.contains(prevMonday)) {
          final count = weeklyWorkoutCounts[prevMonday] ?? 0;
          if (count >= 3) {
            tokens = (tokens + 1).clamp(0, maxTokens);
            awardedWeeks.add(prevMonday);
          }
        }
      }

      if (diff == 1) {
        tempStreak++;
      } else if (diff == 2) {
        // Missed exactly 1 day. Use streak freeze if available!
        if (tokens > 0) {
          tokens--;
          tempStreak++; // streak is preserved/continued
          if (i == sortedDates.length - 1) {
            _lastStreakProtected = true;
          }
        } else {
          if (tempStreak > longest) {
            longest = tempStreak;
          }
          tempStreak = 1;
        }
      } else {
        // Gap of > 1 day - streak breaks
        if (tempStreak > longest) {
          longest = tempStreak;
        }
        tempStreak = 1;
      }
      lastDate = currentDate;
    }

    // Award token for the last week in the list if applicable
    final lastMonday = getMonday(lastDate);
    if (!awardedWeeks.contains(lastMonday)) {
      final count = weeklyWorkoutCounts[lastMonday] ?? 0;
      if (count >= 3) {
        tokens = (tokens + 1).clamp(0, maxTokens);
        awardedWeeks.add(lastMonday);
      }
    }

    if (tempStreak > longest) {
      longest = tempStreak;
    }

    // Calculate current streak relative to today
    final today = DateTime.now();
    final todayDateOnly = DateTime(today.year, today.month, today.day);
    final daysSinceLastWorkout = todayDateOnly.difference(lastDate).inDays;

    if (daysSinceLastWorkout == 0) {
      current = tempStreak;
    } else if (daysSinceLastWorkout == 1) {
      current = tempStreak; // Active today because they worked out yesterday
    } else if (daysSinceLastWorkout == 2) {
      // Missed yesterday! If they have a token, auto-consume to protect it for today
      if (tokens > 0) {
        tokens--;
        current = tempStreak;
        _lastStreakProtected = true;
      } else {
        current = 0;
      }
    } else {
      current = 0;
    }

    if (current > longest) {
      longest = current;
    }

    _currentStreak = current;
    _longestStreak = longest;
    _streakFreezesActive = tokens;

    // Save latest tokens to SharedPreferences
    try {
      final prefs = di.sl<SharedPreferences>();
      prefs.setInt('streak_freezes_active_count', tokens);
      prefs.setBool('last_streak_protected_by_freeze', _lastStreakProtected);
    } catch (_) {}

    notifyListeners();
  }
}
