import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gerex/features/exercise/domain/entities/exercise.dart';
import 'package:gerex/features/workout/domain/entities/workout_entities.dart';
import 'package:gerex/features/workout/domain/repositories/workout_repository.dart';
import 'package:gerex/core/utils/logger.dart';
import 'package:gerex/core/di/injection_container.dart' as di;
import 'package:gerex/core/providers/notification_provider.dart';
import 'package:gerex/features/metrics/presentation/providers/metrics_provider.dart';
import 'package:gerex/core/services/voice_coach_service.dart';

class PrCelebrationEvent {
  final String exerciseName;
  final double weight;
  final int reps;
  PrCelebrationEvent({required this.exerciseName, required this.weight, required this.reps});
}

class WorkoutProvider extends ChangeNotifier {
  final WorkoutRepository _workoutRepository;

  WorkoutProvider(this._workoutRepository) {
    loadSurpriseBadges();
  }

  List<Workout> _workouts = [];
  List<WorkoutSession> _sessions = [];
  bool _isLoading = false;
  String? _errorMessage;

  Set<String> _unlockedSurpriseBadges = {};
  Set<String> get unlockedSurpriseBadges => _unlockedSurpriseBadges;

  // Active Live Session State
  Workout? _activeTemplate;
  String _activeSessionName = '';
  DateTime? _sessionStartedAt;
  int _sessionDurationSeconds = 0;
  Timer? _sessionTimer;
  bool _aiTrackingEnabled = false;

  // Live Sets Logging: Exercise ID -> List of LoggedSets
  final Map<String, List<LoggedSet>> _liveSets = {};
  final List<Exercise> _liveExercisesOrder = [];

  // Rest Timer State
  int _restTimeRemaining = 0;
  int _restTimerTotal = 0;
  Timer? _restTimer;
  bool _isRestActive = false;

  // PR Celebration State
  PrCelebrationEvent? _lastPrCelebration;
  PrCelebrationEvent? get lastPrCelebration => _lastPrCelebration;

  void clearPrCelebration() {
    _lastPrCelebration = null;
    notifyListeners();
  }

  Map<String, dynamic>? getPersonalRecordForExercise(String exerciseId) {
    double maxWeight = 0.0;
    int maxRepsForMaxWeight = 0;

    for (final session in _sessions) {
      for (final loggedSet in session.loggedSets) {
        if (loggedSet.exerciseId == exerciseId && loggedSet.isCompleted) {
          if (loggedSet.weight > maxWeight) {
            maxWeight = loggedSet.weight;
            maxRepsForMaxWeight = loggedSet.reps;
          } else if (loggedSet.weight == maxWeight && loggedSet.reps > maxRepsForMaxWeight) {
            maxRepsForMaxWeight = loggedSet.reps;
          }
        }
      }
    }

    if (maxWeight == 0.0 && maxRepsForMaxWeight == 0) {
      return null;
    }
    return {
      'weight': maxWeight,
      'reps': maxRepsForMaxWeight,
    };
  }

  // Getters
  List<Workout> get workouts => _workouts;
  List<WorkoutSession> get sessions => _sessions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isSessionActive => _sessionStartedAt != null;
  String get activeSessionName => _activeSessionName;
  int get sessionDurationSeconds => _sessionDurationSeconds;
  List<Exercise> get liveExercises => _liveExercisesOrder;
  Map<String, List<LoggedSet>> get liveSets => _liveSets;
  bool get aiTrackingEnabled => _aiTrackingEnabled;

  int get restTimeRemaining => _restTimeRemaining;
  int get restTimerTotal => _restTimerTotal;
  bool get isRestActive => _isRestActive;

  void setAiTrackingEnabled(bool value) {
    _aiTrackingEnabled = value;
    notifyListeners();
  }

  // ----------------------------------------------------
  // Templates & Sessions Data Fetching
  // ----------------------------------------------------

  Future<void> fetchWorkouts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _workoutRepository.getWorkouts();

    result.fold(
      onSuccess: (data) {
        _workouts = data;
        _isLoading = false;
      },
      onFailure: (failure) {
        SecureLogger.logError('fetchWorkouts failed', failure.message);
        _errorMessage = SecureLogger.sanitizeException(failure.message);
        _isLoading = false;
      },
    );
    notifyListeners();
  }

  Future<void> fetchSessions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _workoutRepository.getWorkoutSessions();

    result.fold(
      onSuccess: (data) {
        _sessions = data;
        _isLoading = false;
        try {
          di.sl<MetricsProvider>().computeStreaks(data);
        } catch (_) {}
      },
      onFailure: (failure) {
        SecureLogger.logError('fetchSessions failed', failure.message);
        _errorMessage = SecureLogger.sanitizeException(failure.message);
        _isLoading = false;
      },
    );
    notifyListeners();
  }

  Future<bool> createWorkoutTemplate(
    String name,
    List<WorkoutExercise> exercises,
  ) async {
    _isLoading = true;
    notifyListeners();

    final workout = Workout(
      id: '',
      name: name,
      createdAt: DateTime.now(),
      exercises: const [],
    );

    final result = await _workoutRepository.createWorkout(workout, exercises);

    return result.fold(
      onSuccess: (newWorkout) {
        _workouts.insert(0, newWorkout);
        _isLoading = false;
        notifyListeners();
        return true;
      },
      onFailure: (failure) {
        SecureLogger.logError('createWorkoutTemplate failed', failure.message);
        _errorMessage = SecureLogger.sanitizeException(failure.message);
        _isLoading = false;
        notifyListeners();
        return false;
      },
    );
  }

  // ----------------------------------------------------
  // Live Workout Session Controller
  // ----------------------------------------------------

  void startWorkoutSession(Workout template, {bool enableAiTracking = false}) {
    if (isSessionActive) return; // session already running

    _activeTemplate = template;
    _activeSessionName = template.name;
    _sessionStartedAt = DateTime.now();
    _sessionDurationSeconds = 0;
    _aiTrackingEnabled = enableAiTracking;

    _liveSets.clear();
    _liveExercisesOrder.clear();

    for (final templateEx in template.exercises) {
      if (templateEx.exercise == null) continue;
      final exercise = templateEx.exercise!;
      _liveExercisesOrder.add(exercise);

      final sets = List.generate(
        templateEx.sets,
        (index) => LoggedSet(
          id: '',
          sessionId: '',
          exerciseId: exercise.id,
          exercise: exercise,
          setNumber: index + 1,
          reps: templateEx.reps,
          weight: templateEx.weight,
          isCompleted: false,
        ),
      );
      _liveSets[exercise.id] = sets;
    }

    _startDurationTimer();
    notifyListeners();
  }

  void startEmptyWorkoutSession() {
    if (isSessionActive) return;

    _activeTemplate = null;
    _activeSessionName = 'Custom Quick Workout';
    _sessionStartedAt = DateTime.now();
    _sessionDurationSeconds = 0;

    _liveSets.clear();
    _liveExercisesOrder.clear();

    _startDurationTimer();
    notifyListeners();
  }

  void addExerciseToSession(Exercise exercise) {
    if (!isSessionActive) return;
    if (_liveSets.containsKey(exercise.id)) return; // already added

    _liveExercisesOrder.add(exercise);
    _liveSets[exercise.id] = [
      LoggedSet(
        id: '',
        sessionId: '',
        exerciseId: exercise.id,
        exercise: exercise,
        setNumber: 1,
        reps: 10,
        weight: 0,
        isCompleted: false,
      ),
    ];
    notifyListeners();
  }

  void addSetToExercise(String exerciseId) {
    final sets = _liveSets[exerciseId];
    if (sets == null || sets.isEmpty) return;

    final lastSet = sets.last;
    sets.add(
      LoggedSet(
        id: '',
        sessionId: '',
        exerciseId: exerciseId,
        exercise: lastSet.exercise,
        setNumber: sets.length + 1,
        reps: lastSet.reps,
        weight: lastSet.weight,
        isCompleted: false,
      ),
    );
    notifyListeners();
  }

  void removeSetFromExercise(String exerciseId, int index) {
    final sets = _liveSets[exerciseId];
    if (sets == null || sets.length <= 1) return;

    sets.removeAt(index);
    // Re-index sets
    for (int i = 0; i < sets.length; i++) {
      sets[i] = LoggedSet(
        id: sets[i].id,
        sessionId: sets[i].sessionId,
        exerciseId: sets[i].exerciseId,
        exercise: sets[i].exercise,
        setNumber: i + 1,
        reps: sets[i].reps,
        weight: sets[i].weight,
        isCompleted: sets[i].isCompleted,
      );
    }
    notifyListeners();
  }

  void updateSetValues(
    String exerciseId,
    int index, {
    int? reps,
    double? weight,
  }) {
    final sets = _liveSets[exerciseId];
    if (sets == null) return;

    final current = sets[index];
    sets[index] = LoggedSet(
      id: current.id,
      sessionId: current.sessionId,
      exerciseId: current.exerciseId,
      exercise: current.exercise,
      setNumber: current.setNumber,
      reps: reps ?? current.reps,
      weight: weight ?? current.weight,
      isCompleted: current.isCompleted,
    );

    if (reps != null && reps > current.reps) {
      int targetReps = 10;
      if (_activeTemplate != null) {
        final match = _activeTemplate!.exercises.where((e) => e.exerciseId == exerciseId);
        if (match.isNotEmpty) {
          targetReps = match.first.reps;
        }
      }
      if (reps == targetReps) {
        di.sl<VoiceCoachService>().speak("Target reached!");
      } else if (reps == targetReps - 3) {
        di.sl<VoiceCoachService>().speak("Three reps left");
      } else if (reps == targetReps - 1) {
        di.sl<VoiceCoachService>().speak("One rep left");
      }
    }

    notifyListeners();
  }

  void toggleSetComplete(String exerciseId, int index) {
    final sets = _liveSets[exerciseId];
    if (sets == null) return;

    final current = sets[index];
    final nextState = !current.isCompleted;

    sets[index] = LoggedSet(
      id: current.id,
      sessionId: current.sessionId,
      exerciseId: current.exerciseId,
      exercise: current.exercise,
      setNumber: current.setNumber,
      reps: current.reps,
      weight: current.weight,
      isCompleted: nextState,
    );

    // If completed, trigger rest timer
    if (nextState) {
      di.sl<VoiceCoachService>().speak("Set complete, nice work");
      _triggerRestTimerForExercise(exerciseId);

      // Check for New Personal Record
      final previousPr = getPersonalRecordForExercise(exerciseId);
      bool isPr = false;
      if (previousPr == null) {
        if (current.weight > 0 || current.reps > 0) {
          isPr = true;
        }
      } else {
        final double prevWeight = previousPr['weight'];
        final int prevReps = previousPr['reps'];
        if (current.weight > prevWeight) {
          isPr = true;
        } else if (current.weight == prevWeight && current.reps > prevReps) {
          isPr = true;
        }
      }

      if (isPr) {
        _lastPrCelebration = PrCelebrationEvent(
          exerciseName: current.exercise?.name ?? 'Exercise',
          weight: current.weight,
          reps: current.reps,
        );
      }
    }

    notifyListeners();
  }

  void _triggerRestTimerForExercise(String exerciseId) {
    // Check if we can find rest time in templates
    int rest = 60; // default 60s
    if (_activeTemplate != null) {
      final match = _activeTemplate!.exercises
          .where((e) => e.exerciseId == exerciseId);
      if (match.isNotEmpty) {
        rest = match.first.restTime;
      }
    }
    startRestTimer(rest);
  }

  // ----------------------------------------------------
  // Timer Helpers
  // ----------------------------------------------------

  void _startDurationTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _sessionDurationSeconds++;
      notifyListeners();
    });
  }

  void startRestTimer(int duration) {
    _restTimer?.cancel();
    _restTimerTotal = duration;
    _restTimeRemaining = duration;
    _isRestActive = true;
    notifyListeners();

    di.sl<VoiceCoachService>().speak("Rest $duration seconds");

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restTimeRemaining > 0) {
        _restTimeRemaining--;
        notifyListeners();
      } else {
        _isRestActive = false;
        _restTimer?.cancel();
        notifyListeners();
        di.sl<VoiceCoachService>().speak("Rest complete, prepare for next set");
      }
    });
  }

  void skipRestTimer() {
    _isRestActive = false;
    _restTimer?.cancel();
    _restTimeRemaining = 0;
    notifyListeners();
  }

  // ----------------------------------------------------
  // Finish Session
  // ----------------------------------------------------

  Future<bool> finishWorkoutSession() async {
    if (!isSessionActive) return false;

    _isLoading = true;
    notifyListeners();

    // 1. Gather all logged sets that are completed (or all logged sets)
    final flatSets = <LoggedSet>[];
    for (final exerciseId in _liveSets.keys) {
      final sets = _liveSets[exerciseId] ?? [];
      flatSets.addAll(sets);
    }

    final session = WorkoutSession(
      id: '',
      workoutId: _activeTemplate?.id,
      name: _activeSessionName,
      startedAt: _sessionStartedAt!,
      completedAt: DateTime.now(),
      durationSeconds: _sessionDurationSeconds,
      loggedSets: const [],
    );

    final result = await _workoutRepository.saveWorkoutSession(session, flatSets);

    return result.fold(
      onSuccess: (savedSession) {
        _sessions.insert(0, savedSession);
        _stopSessionState();
        _isLoading = false;
        notifyListeners();
        try {
          di.sl<MetricsProvider>().computeStreaks(_sessions);
        } catch (_) {}
        try {
          di.sl<NotificationProvider>().sendNotification(
            'Workout Completed!',
            'Fantastic! You completed "${savedSession.name}" in ${savedSession.durationSeconds ~/ 60} minutes.',
          );
        } catch (_) {}
        try {
          di.sl<NotificationProvider>().scheduleReengagementReminder();
        } catch (_) {}
        try {
          di.sl<VoiceCoachService>().speak("Workout complete, nice work!");
        } catch (_) {}
        return true;
      },
      onFailure: (failure) {
        SecureLogger.logError('saveWorkoutSession failed', failure.message);
        _errorMessage = SecureLogger.sanitizeException(failure.message);
        _isLoading = false;
        notifyListeners();
        return false;
      },
    );
  }

  void loadSurpriseBadges() {
    try {
      final prefs = di.sl<SharedPreferences>();
      final list = prefs.getStringList('unlocked_surprise_badges') ?? [];
      _unlockedSurpriseBadges = list.toSet();
    } catch (_) {}
  }

  String? checkAndRollSurpriseBadge() {
    loadSurpriseBadges();
    final allSurprises = ['surprise_great_session', 'surprise_energy_spark', 'surprise_momentum'];
    final locks = allSurprises.where((b) => !_unlockedSurpriseBadges.contains(b)).toList();
    if (locks.isEmpty) return null;

    // 25% chance of rolling a surprise badge
    final roll = DateTime.now().millisecond % 4 == 0;
    if (roll) {
      final badge = locks[DateTime.now().millisecond % locks.length];
      _unlockedSurpriseBadges.add(badge);
      try {
        final prefs = di.sl<SharedPreferences>();
        prefs.setStringList('unlocked_surprise_badges', _unlockedSurpriseBadges.toList());
      } catch (_) {}
      notifyListeners();
      return badge;
    }
    return null;
  }

  Future<bool> logCustomWorkoutSession(String name, int durationSeconds, List<LoggedSet> sets) async {
    _isLoading = true;
    notifyListeners();

    final session = WorkoutSession(
      id: '',
      workoutId: null,
      name: name,
      startedAt: DateTime.now().subtract(Duration(seconds: durationSeconds)),
      completedAt: DateTime.now(),
      durationSeconds: durationSeconds,
      loggedSets: const [],
    );

    final result = await _workoutRepository.saveWorkoutSession(session, sets);

    return result.fold(
      onSuccess: (savedSession) {
        _sessions.insert(0, savedSession);
        _isLoading = false;
        notifyListeners();
        try {
          di.sl<MetricsProvider>().computeStreaks(_sessions);
        } catch (_) {}
        try {
          di.sl<NotificationProvider>().sendNotification(
            'Workout Completed!',
            'Fantastic! You completed "${savedSession.name}" in ${savedSession.durationSeconds ~/ 60} minutes.',
          );
        } catch (_) {}
        try {
          di.sl<NotificationProvider>().scheduleReengagementReminder();
        } catch (_) {}
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

  void cancelWorkoutSession() {
    _stopSessionState();
    notifyListeners();
  }

  void _stopSessionState() {
    _sessionTimer?.cancel();
    _restTimer?.cancel();
    _sessionStartedAt = null;
    _sessionDurationSeconds = 0;
    _restTimeRemaining = 0;
    _isRestActive = false;
    _liveSets.clear();
    _liveExercisesOrder.clear();
    _activeTemplate = null;
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _restTimer?.cancel();
    super.dispose();
  }
}
