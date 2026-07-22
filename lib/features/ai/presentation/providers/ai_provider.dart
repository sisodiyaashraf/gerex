import 'package:flutter/material.dart';
import '../../domain/repositories/ai_repository.dart';

class AIProvider extends ChangeNotifier {
  final AIRepository _aiRepository;

  AIProvider(this._aiRepository);

  // Cache Generated Plan state
  String? _generatedWorkoutPlan;
  bool _isPlanLoading = false;
  String? _planError;

  // Coach Chat state
  final List<Map<String, String>> _chatMessages = [];
  bool _isChatLoading = false;
  String? _chatError;

  // Getters
  String? get generatedWorkoutPlan => _generatedWorkoutPlan;
  bool get isPlanLoading => _isPlanLoading;
  String? get planError => _planError;

  List<Map<String, String>> get chatMessages => _chatMessages;
  bool get isChatLoading => _isChatLoading;
  String? get chatError => _chatError;

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
        _planError = failure.message;
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
        _chatError = failure.message;
        _isChatLoading = false;
        // Optionally add a system error bubble
        _chatMessages.add({
          'role': 'model',
          'text': 'Sorry, I hit an issue: ${failure.message}. Please check your connection or retry.',
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
}
