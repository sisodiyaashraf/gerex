import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../domain/repositories/ai_repository.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/providers/notification_provider.dart';

class AIProvider extends ChangeNotifier {
  final AIRepository _aiRepository;

  bool _isOfflineOnly = false;
  bool _isModelDownloaded = false;

  bool get isOfflineOnly => _isOfflineOnly;
  bool get isModelDownloaded => _isModelDownloaded;

  AIProvider(this._aiRepository) {
    _loadOfflineState();
  }

  void _loadOfflineState() {
    try {
      final prefs = di.sl<SharedPreferences>();
      _isOfflineOnly = prefs.getBool('offline_only_ai_assistant') ?? false;
      _isModelDownloaded = prefs.getBool('offline_gemma_model_downloaded') ?? false;
      SecureLogger.logInfo('AIProvider: Loaded offline_only_ai_assistant: $_isOfflineOnly');
    } catch (e) {
      SecureLogger.logError('AIProvider: Failed to load offline state', e.toString());
    }
  }

  Future<void> setOfflineOnly(bool value) async {
    _isOfflineOnly = value;
    notifyListeners();
    try {
      final prefs = di.sl<SharedPreferences>();
      await prefs.setBool('offline_only_ai_assistant', value);
      SecureLogger.logInfo('AIProvider: Saved offline_only_ai_assistant: $value');
    } catch (e) {
      SecureLogger.logError('AIProvider: Failed to save offline_only_ai_assistant', e.toString());
    }
  }

  Future<void> setOfflineModelDownloaded(bool value) async {
    _isModelDownloaded = value;
    notifyListeners();
    try {
      final prefs = di.sl<SharedPreferences>();
      await prefs.setBool('offline_gemma_model_downloaded', value);
    } catch (_) {}
  }

  Future<bool> _checkAndRecordAiCall() async {
    // Centralized cloud call checking is now handled directly by the AIRouter
    return true;
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

    // 2. Prepare context history
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
        final isOffline = _aiRepository.lastCallWasOffline;
        _chatMessages.add({
          'role': 'model',
          'text': reply,
          'source': isOffline ? 'offline' : 'online',
        });
        _isChatLoading = false;
      },
      onFailure: (failure) {
        SecureLogger.logError('sendMessageToCoach failed', failure.message);
        final sanitized = SecureLogger.sanitizeException(failure.message);
        _chatError = sanitized;
        _isChatLoading = false;
        final isOffline = _aiRepository.lastCallWasOffline;

        if (failure.message.contains('CLOUD_LIMIT_REACHED')) {
          _chatMessages.add({
            'role': 'model',
            'text': 'Cloud request limit reached. Please check your offline model or try again later.',
            'source': 'online',
          });
        } else {
          _chatMessages.add({
            'role': 'model',
            'text': 'Sorry, I hit an issue: $sanitized Please try again.',
            'source': isOffline ? 'offline' : 'online',
          });
        }
      },
    );
    notifyListeners();
  }

  Future<void> escalateMessageToCoach(String text) async {
    if (text.trim().isEmpty) return;

    _isChatLoading = true;
    _chatError = null;
    notifyListeners();

    final historyForApi = _chatMessages
        .sublist(0, _chatMessages.length - 1)
        .map((m) => {'role': m['role']!, 'text': m['text']!})
        .toList();

    final result = await _aiRepository.getCoachResponse(
      prompt: text,
      chatHistory: historyForApi,
      forceEscalate: true,
    );

    result.fold(
      onSuccess: (reply) {
        _chatMessages.add({
          'role': 'model',
          'text': reply,
          'source': 'online',
        });
        _isChatLoading = false;
      },
      onFailure: (failure) {
        SecureLogger.logError('escalateMessageToCoach failed', failure.message);
        final sanitized = SecureLogger.sanitizeException(failure.message);
        _chatError = sanitized;
        _isChatLoading = false;
        
        if (failure.message.contains('CLOUD_LIMIT_REACHED')) {
          _chatMessages.add({
            'role': 'model',
            'text': 'Cloud request limit reached. Please try again later.',
            'source': 'online',
          });
        } else {
          _chatMessages.add({
            'role': 'model',
            'text': 'Sorry, I hit an issue: $sanitized Please try again.',
            'source': 'online',
          });
        }
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
          di.sl<NotificationProvider>().sendNotification(
            'AI Coach Advice Generated',
            'Your virtual Coach Gerex has parsed your recent routines and updated today\'s advice!',
          );
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

  // ----------------------------------------------------
  // Weekly Training Story
  // ----------------------------------------------------
  String? _weeklyTrainingStory;
  bool _isStoryLoading = false;
  String? _storyError;

  String? get weeklyTrainingStory => _weeklyTrainingStory;
  bool get isStoryLoading => _isStoryLoading;
  String? get storyError => _storyError;

  Future<void> loadWeeklyTrainingStory(List<dynamic> sessions, {bool forceRefresh = false}) async {
    final cacheKey = 'weekly_story_${sessions.length}_${sessions.isNotEmpty ? (sessions.last.completedAt?.toIso8601String() ?? '') : ''}';
    
    try {
      final prefs = di.sl<SharedPreferences>();
      final cachedKey = prefs.getString('weekly_story_cache_key');
      final cachedText = prefs.getString('weekly_story_text');
      
      if (cachedKey == cacheKey && cachedText != null && !forceRefresh) {
        _weeklyTrainingStory = cachedText;
        notifyListeners();
        return;
      }
    } catch (_) {}

    _isStoryLoading = true;
    _storyError = null;
    notifyListeners();

    final allowed = await _checkAndRecordAiCall();
    if (!allowed) {
      _storyError = 'AI quota reached for this hour.';
      _isStoryLoading = false;
      _weeklyTrainingStory = 'You started off strong this week, maintaining your consistency and hitting key personal records! Keep pushing forward and logging those routines.';
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

    final result = await _aiRepository.getWeeklyTrainingStory(
      sessionsSummary: sessionsSummary,
    );

    result.fold(
      onSuccess: (story) {
        _weeklyTrainingStory = story;
        _isStoryLoading = false;
        try {
          final prefs = di.sl<SharedPreferences>();
          prefs.setString('weekly_story_cache_key', cacheKey);
          prefs.setString('weekly_story_text', story);
        } catch (_) {}
      },
      onFailure: (failure) {
        SecureLogger.logError('loadWeeklyTrainingStory failed', failure.message);
        _storyError = SecureLogger.sanitizeException(failure.message);
        _isStoryLoading = false;
        _weeklyTrainingStory = 'You started off strong this week, maintaining your consistency and hitting key personal records! Keep pushing forward and logging those routines.';
      },
    );
    notifyListeners();
  }
}
