import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../domain/repositories/ai_repository.dart';
import '../../../../core/config/rate_limit_config.dart';
import '../../../../core/utils/logger.dart';

class AIProvider extends ChangeNotifier {
  final AIRepository _aiRepository;

  AIProvider(this._aiRepository);

  Future<bool> _checkAndRecordAiCall() async {
    try {
      final prefs = di.sl<SharedPreferences>();
      final now = DateTime.now();
      const windowDuration = Duration(hours: RateLimitConfig.aiCallsWindowHours);

      // Load existing call history
      final List<String> history = prefs.getStringList('ai_calls_history') ?? [];
      
      // Parse and filter history to include only calls within the rate limit window
      final List<DateTime> validCalls = history
          .map((t) => DateTime.tryParse(t))
          .whereType<DateTime>()
          .where((dt) => now.difference(dt).compareTo(windowDuration) <= 0)
          .toList();

      if (validCalls.length >= RateLimitConfig.aiMaxCallsPerHour) {
        return false;
      }

      // Add current call and persist
      validCalls.add(now);
      final newHistory = validCalls.map((dt) => dt.toIso8601String()).toList();
      await prefs.setStringList('ai_calls_history', newHistory);
      return true;
    } catch (_) {
      // If SharedPreferences fails, allow call to avoid blocking users
      return true;
    }
  }

  // Cache Generated Plan state
  String? _generatedWorkoutPlan;
  bool _isPlanLoading = false;
  String? _planError;

  // Coach Chat state
  final List<Map<String, String>> _chatMessages = [];
  bool _isChatLoading = false;
  String? _chatError;

  // Daily Insight state
  String? _dailyInsight;
  bool _isInsightLoading = false;
  String? _insightError;

  // Progress Summary state
  String? _progressSummary;
  bool _isSummaryLoading = false;
  String? _summaryError;

  // Getters
  String? get generatedWorkoutPlan => _generatedWorkoutPlan;
  bool get isPlanLoading => _isPlanLoading;
  String? get planError => _planError;

  List<Map<String, String>> get chatMessages => _chatMessages;
  bool get isChatLoading => _isChatLoading;
  String? get chatError => _chatError;

  String? get dailyInsight => _dailyInsight;
  bool get isInsightLoading => _isInsightLoading;
  String? get insightError => _insightError;

  String? get progressSummary => _progressSummary;
  bool get isSummaryLoading => _isSummaryLoading;
  String? get summaryError => _summaryError;

  // ----------------------------------------------------
  // Workout Plan Generator
  // ----------------------------------------------------

  Future<void> generatePlan({
    required String goal,
    required String equipment,
    required String experienceLevel,
    bool forceRefresh = false,
  }) async {
    // If already generated and not forcing refresh, return cached plan!
    if (_generatedWorkoutPlan != null && !forceRefresh) return;

    _isPlanLoading = true;
    _planError = null;
    notifyListeners();

    // Check AI call rate limits
    final allowed = await _checkAndRecordAiCall();
    if (!allowed) {
      _planError = 'AI plan call limit reached. Please wait a bit and try again.';
      _isPlanLoading = false;
      notifyListeners();
      return;
    }

    final result = await _aiRepository.generateWorkoutPlan(
      goal: goal,
      equipment: equipment,
      experienceLevel: experienceLevel,
    );

    result.fold(
      onSuccess: (plan) {
        _generatedWorkoutPlan = plan;
        _isPlanLoading = false;
      },
      onFailure: (failure) {
        SecureLogger.logError('generatePlan failed', failure.message);
        _planError = SecureLogger.sanitizeException(failure.message);
        _isPlanLoading = false;
      },
    );
    notifyListeners();
  }

  void clearCachedPlan() {
    _generatedWorkoutPlan = null;
    notifyListeners();
  }

  // ----------------------------------------------------
  // Coach Chat
  // ----------------------------------------------------

  Future<void> sendMessageToCoach(String text) async {
    if (text.trim().isEmpty) return;

    // 1. Add user message to history
    _chatMessages.add({'role': 'user', 'text': text});
    _isChatLoading = true;
    _chatError = null;
    notifyListeners();

    // Rate Limit Check
    final allowed = await _checkAndRecordAiCall();
    if (!allowed) {
      _chatError = 'AI call limit reached.';
      _chatMessages.add({
        'role': 'model',
        'text': 'You have reached the maximum number of coach queries allowed per hour. Please wait a bit before asking again.',
      });
      _isChatLoading = false;
      notifyListeners();
      return;
    }

    // 2. Prepare context history (excluding system prompt helper)
    final historyForApi = _chatMessages
        .sublist(0, _chatMessages.length - 1)
        .map((m) => {'role': m['role']!, 'text': m['text']!})
        .toList();

    // 3. Request AI response
    final result = await _aiRepository.getCoachResponse(
      prompt: text,
      chatHistory: historyForApi,
    );

    result.fold(
      onSuccess: (reply) {
        _chatMessages.add({'role': 'model', 'text': reply});
        _isChatLoading = false;
      },
      onFailure: (failure) {
        SecureLogger.logError('sendMessageToCoach failed', failure.message);
        final sanitized = SecureLogger.sanitizeException(failure.message);
        _chatError = sanitized;
        _isChatLoading = false;
        _chatMessages.add({
          'role': 'model',
          'text': 'Sorry, I hit an issue: $sanitized Please try again.',
        });
      },
    );
    notifyListeners();
  }

  void clearChat() {
    _chatMessages.clear();
    _chatError = null;
    _isChatLoading = false;
    notifyListeners();
  }

  // ----------------------------------------------------
  // Daily Insight
  // ----------------------------------------------------

  Future<void> loadDailyInsight(List<dynamic> sessions, {bool forceRefresh = false}) async {
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    
    try {
      final prefs = di.sl<SharedPreferences>();
      final cachedDate = prefs.getString('daily_insight_date');
      final cachedText = prefs.getString('daily_insight_text');
      
      if (cachedDate == todayStr && cachedText != null && !forceRefresh) {
        _dailyInsight = cachedText;
        notifyListeners();
        return;
      }
    } catch (_) {}

    _isInsightLoading = true;
    _insightError = null;
    notifyListeners();

    final allowed = await _checkAndRecordAiCall();
    if (!allowed) {
      _insightError = 'AI quota reached for this hour.';
      _isInsightLoading = false;
      _dailyInsight = 'Fuel your body with proper nutrition, prioritize recovery sleep, and target progressive overload for today\'s training session!';
      notifyListeners();
      return;
    }

    final recentSessions = sessions.take(5).toList();
    final recentSummary = recentSessions.map((s) {
      final name = s.name ?? 'Workout';
      final date = s.completedAt != null ? s.completedAt.toIso8601String().substring(0, 10) : 'recent';
      return '$name completed on $date';
    }).toList();

    if (recentSummary.isEmpty) {
      recentSummary.add('No recent workouts logged yet.');
    }

    final result = await _aiRepository.getDailyInsight(
      recentWorkoutsSummary: recentSummary,
    );

    result.fold(
      onSuccess: (insight) {
        _dailyInsight = insight;
        _isInsightLoading = false;
        try {
          final prefs = di.sl<SharedPreferences>();
          prefs.setString('daily_insight_date', todayStr);
          prefs.setString('daily_insight_text', insight);
        } catch (_) {}
      },
      onFailure: (failure) {
        SecureLogger.logError('loadDailyInsight failed', failure.message);
        _insightError = SecureLogger.sanitizeException(failure.message);
        _isInsightLoading = false;
        _dailyInsight = 'Fuel your body with proper nutrition, prioritize recovery sleep, and target progressive overload for today\'s training session!';
      },
    );
    notifyListeners();
  }

  // ----------------------------------------------------
  // Progress Summary
  // ----------------------------------------------------

  Future<void> loadProgressSummary(List<dynamic> sessions, {bool forceRefresh = false}) async {
    final cacheKey = 'progress_summary_${sessions.length}_${sessions.isNotEmpty ? (sessions.last.completedAt?.toIso8601String() ?? '') : ''}';
    
    try {
      final prefs = di.sl<SharedPreferences>();
      final cachedKey = prefs.getString('progress_summary_cache_key');
      final cachedText = prefs.getString('progress_summary_text');
      
      if (cachedKey == cacheKey && cachedText != null && !forceRefresh) {
        _progressSummary = cachedText;
        notifyListeners();
        return;
      }
    } catch (_) {}

    _isSummaryLoading = true;
    _summaryError = null;
    notifyListeners();

    final allowed = await _checkAndRecordAiCall();
    if (!allowed) {
      _summaryError = 'AI quota reached for this hour.';
      _isSummaryLoading = false;
      _progressSummary = 'Consistency is the absolute key to fitness progress! You are regularly logging workouts and staying consistent. Keep up the high volume training!';
      notifyListeners();
      return;
    }

    final sessionsSummary = sessions.map((s) {
      final name = s.name ?? 'Workout';
      final date = s.completedAt != null ? s.completedAt.toIso8601String().substring(0, 10) : 'recent';
      final duration = '${(s.durationSeconds ?? 0) ~/ 60} minutes';
      final exerciseCount = '${s.loggedSets?.length ?? 0} sets logged';
      return '$name on $date lasting $duration with $exerciseCount';
    }).toList();

    if (sessionsSummary.isEmpty) {
      sessionsSummary.add('No workouts recorded in this cycle.');
    }

    final result = await _aiRepository.getProgressSummary(
      sessionsSummary: sessionsSummary,
    );

    result.fold(
      onSuccess: (summary) {
        _progressSummary = summary;
        _isSummaryLoading = false;
        try {
          final prefs = di.sl<SharedPreferences>();
          prefs.setString('progress_summary_cache_key', cacheKey);
          prefs.setString('progress_summary_text', summary);
        } catch (_) {}
      },
      onFailure: (failure) {
        SecureLogger.logError('loadProgressSummary failed', failure.message);
        _summaryError = SecureLogger.sanitizeException(failure.message);
        _isSummaryLoading = false;
        _progressSummary = 'Consistency is the absolute key to fitness progress! You are regularly logging workouts and staying consistent. Keep up the high volume training!';
      },
    );
    notifyListeners();
  }

  // ----------------------------------------------------
  // Exercise Swap
  // ----------------------------------------------------

  Future<List<String>> getExerciseAlternatives(String exerciseName, String muscleGroup) async {
    final allowed = await _checkAndRecordAiCall();
    if (!allowed) {
      return _getFallbackAlternatives(muscleGroup);
    }

    final result = await _aiRepository.getExerciseSwap(
      exerciseName: exerciseName,
      muscleGroup: muscleGroup,
    );

    return result.fold(
      onSuccess: (alternatives) => alternatives,
      onFailure: (failure) {
        SecureLogger.logError('getExerciseAlternatives failed', failure.message);
        return _getFallbackAlternatives(muscleGroup);
      },
    );
  }

  List<String> _getFallbackAlternatives(String muscleGroup) {
    final group = muscleGroup.toLowerCase();
    if (group.contains('chest')) {
      return ['Push Up', 'Dumbbell Press', 'Chest Fly'];
    } else if (group.contains('back')) {
      return ['Pull Up', 'Dumbbell Row', 'Lat Pulldown'];
    } else if (group.contains('leg')) {
      return ['Bodyweight Squat', 'Lunge', 'Goblet Squat'];
    } else if (group.contains('shoulder')) {
      return ['Overhead Press', 'Lateral Raise', 'Front Raise'];
    } else if (group.contains('arm')) {
      return ['Bicep Curl', 'Tricep Dip', 'Hammer Curl'];
    } else if (group.contains('core')) {
      return ['Plank', 'Crunch', 'Russian Twist'];
    }
    return ['Bodyweight Squat', 'Push Up', 'Plank'];
  }
}
