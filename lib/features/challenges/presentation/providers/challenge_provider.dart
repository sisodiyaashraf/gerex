import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gerex/core/di/injection_container.dart' as di;
import '../../domain/entities/challenge.dart';
import '../../domain/entities/challenge_progress.dart';
import '../../domain/repositories/challenge_repository.dart';

class ChallengeProvider extends ChangeNotifier {
  final ChallengeRepository _challengeRepository;

  ChallengeProvider(this._challengeRepository);

  List<Challenge> _challenges = [];
  final Map<String, ChallengeProgress> _progressMap = {};
  bool _isLoading = false;
  String? _errorMessage;
  List<ChallengeProgress> _friendsProgress = [];

  List<Challenge> get challenges => _challenges;
  Map<String, ChallengeProgress> get progressMap => _progressMap;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<ChallengeProgress> get friendsProgress => _friendsProgress;

  Future<void> fetchChallenges() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Fetch challenges definition
    final challengesResult = await _challengeRepository.getChallenges();
    challengesResult.fold(
      onSuccess: (data) {
        _challenges = data;
      },
      onFailure: (failure) {
        _errorMessage = failure.message;
      },
    );

    // Fetch user progress
    final progressResult = await _challengeRepository.getUserProgress();
    progressResult.fold(
      onSuccess: (data) {
        _progressMap.clear();
        for (var prog in data) {
          _progressMap[prog.challengeId] = prog;
        }
      },
      onFailure: (failure) {
        // Suppress progress fetching failure since we fallback to cached locally
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> joinChallenge(String challengeId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _challengeRepository.joinChallenge(challengeId);
    bool success = false;

    result.fold(
      onSuccess: (data) {
        _progressMap[challengeId] = data;
        success = true;
      },
      onFailure: (failure) {
        _errorMessage = failure.message;
      },
    );

    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> logProgress(String challengeId, int minutes) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _challengeRepository.updateProgress(challengeId, minutes);
    bool success = false;

    result.fold(
      onSuccess: (data) {
        _progressMap[challengeId] = data;
        success = true;
      },
      onFailure: (failure) {
        _errorMessage = failure.message;
      },
    );

    _isLoading = false;
    notifyListeners();
    return success;
  }

  ChallengeProgress? getProgress(String challengeId) {
    return _progressMap[challengeId];
  }

  bool isJoined(String challengeId) {
    return _progressMap.containsKey(challengeId);
  }

  Future<void> fetchFriendsProgress(String challengeId) async {
    try {
      final prefs = di.sl<SharedPreferences>();
      final friendCodes = prefs.getStringList('linked_friends_user_ids') ?? [];
      if (friendCodes.isEmpty) {
        _friendsProgress = [];
        notifyListeners();
        return;
      }
      final result = await _challengeRepository.getFriendsProgress(challengeId, friendCodes);
      result.fold(
        onSuccess: (data) {
          _friendsProgress = data;
        },
        onFailure: (failure) {
          // Suppress
        },
      );
    } catch (_) {}
    notifyListeners();
  }

  Future<bool> linkFriend(String friendCode) async {
    final cleanCode = friendCode.trim();
    if (cleanCode.isEmpty) return false;
    try {
      final prefs = di.sl<SharedPreferences>();
      final friendCodes = prefs.getStringList('linked_friends_user_ids') ?? [];
      if (!friendCodes.contains(cleanCode)) {
        friendCodes.add(cleanCode);
        await prefs.setStringList('linked_friends_user_ids', friendCodes);
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }
}
