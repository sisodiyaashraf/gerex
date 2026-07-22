import 'package:flutter/material.dart';
import '../../../workout/domain/entities/workout_entities.dart';
import '../../domain/entities/metrics_entities.dart';
import '../../domain/repositories/metrics_repository.dart';

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

  List<BodyMetric> get weightLogs => _weightLogs;
  List<ProgressDataPoint> get volumeLogs => _volumeLogs;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get currentStreak => _currentStreak;
  int get longestStreak => _longestStreak;
  Set<String> get workoutDates => _workoutDates;

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
        _errorMessage = failure.message;
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
        _errorMessage = failure.message;
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
        _errorMessage = failure.message;
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

    if (sessions.isEmpty) {
      _currentStreak = 0;
      _longestStreak = 0;
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
      notifyListeners();
      return;
    }

    // Compute streaks
    int longest = 0;
    int current = 0;

    final today = DateTime.now();
    final todayDateOnly = DateTime(today.year, today.month, today.day);
    final yesterdayDateOnly = todayDateOnly.subtract(const Duration(days: 1));

    int tempStreak = 1;
    longest = 1;

    for (int i = 1; i < sortedDates.length; i++) {
      final diff = sortedDates[i].difference(sortedDates[i - 1]).inDays;
      if (diff == 1) {
        tempStreak++;
      } else if (diff > 1) {
        if (tempStreak > longest) {
          longest = tempStreak;
        }
        tempStreak = 1;
      }
    }
    if (tempStreak > longest) {
      longest = tempStreak;
    }

    // Calculate current streak
    final lastWorkoutDate = sortedDates.last;
    if (lastWorkoutDate == todayDateOnly ||
        lastWorkoutDate == yesterdayDateOnly) {
      current = 1;
      for (int i = sortedDates.length - 2; i >= 0; i--) {
        final diff = sortedDates[i + 1].difference(sortedDates[i]).inDays;
        if (diff == 1) {
          current++;
        } else if (diff > 1) {
          break;
        }
      }
    } else {
      current = 0;
    }

    _currentStreak = current;
    _longestStreak = longest;
    notifyListeners();
  }
}
