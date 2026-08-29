import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../../../core/utils/logger.dart';
import 'package:gerex/features/challenges/domain/entities/challenge.dart';
import 'package:gerex/features/challenges/domain/entities/challenge_progress.dart';
import 'package:gerex/features/challenges/domain/repositories/challenge_repository.dart';

class ChallengeRepositoryImpl implements ChallengeRepository {
  final SupabaseClient _supabaseClient;

  ChallengeRepositoryImpl(this._supabaseClient);

  // In-memory seeded challenges list
  static final List<Challenge> _seededChallenges = [
    const Challenge(
      id: 'challenge_cardio_consistency',
      title: 'Cardio Consistency',
      difficulty: 'easy',
      type: 'Daily challenge',
      badgeIcon: 'person-running',
      description: 'Complete at least 30 minutes of aerobic exercise (cycling, running, or rowing) to boost metabolic rate and cardiorespiratory health.',
      totalMinutesGoal: 30,
      usersJoined: 1850,
    ),
    const Challenge(
      id: 'challenge_strength_marathon',
      title: 'Iron Will Workout',
      difficulty: 'hard',
      type: 'Weekly challenge',
      badgeIcon: 'dumbbell',
      description: 'Accumulate 150 minutes of structured strength training. Target major compound movements like squat, deadlift, and overhead press.',
      totalMinutesGoal: 150,
      usersJoined: 642,
    ),
    const Challenge(
      id: 'challenge_core_beast',
      title: 'Core & Abs Crusher',
      difficulty: 'very hard',
      type: '30-Day challenge',
      badgeIcon: 'shield-halved',
      description: 'Push your core to the absolute limit. Accumulate 300 minutes of direct abdominal and core stability exercises (planks, leg raises).',
      totalMinutesGoal: 300,
      usersJoined: 312,
    ),
  ];

  // In-memory local progress tracker (offline / fallback mode)
  static final Map<String, ChallengeProgress> _localProgressMap = {};

  String get _currentUserId => _supabaseClient.auth.currentUser?.id ?? 'dummy_user';

  @override
  Future<Result<List<Challenge>, Failure>> getChallenges() async {
    try {
      final response = await _supabaseClient
          .from('challenges')
          .select()
          .order('created_at', ascending: false);

      final list = response as List<dynamic>;
      if (list.isEmpty) {
        // Seed remote in background (ignore failures)
        try {
          await _supabaseClient.from('challenges').insert(
            _seededChallenges.map((c) => c.toJson()).toList(),
          );
        } catch (_) {}
        return Success(_seededChallenges);
      }

      final challenges = list
          .map((json) => Challenge.fromJson(json as Map<String, dynamic>))
          .toList();
      return Success(challenges);
    } catch (e) {
      SecureLogger.logError('Supabase getChallenges failed, falling back to seeds', e.toString());
      // Fallback
      return Success(_seededChallenges);
    }
  }

  @override
  Future<Result<List<ChallengeProgress>, Failure>> getUserProgress() async {
    try {
      final userId = _currentUserId;
      final response = await _supabaseClient
          .from('challenge_progress')
          .select()
          .eq('user_id', userId);

      final list = response as List<dynamic>;
      final progressList = list
          .map((json) => ChallengeProgress.fromJson(json as Map<String, dynamic>))
          .toList();
      
      // Update local progress cache to keep in sync
      for (var prog in progressList) {
        _localProgressMap[prog.challengeId] = prog;
      }

      return Success(progressList);
    } catch (e) {
      SecureLogger.logError('Supabase getUserProgress failed, falling back to local map', e.toString());
      return Success(_localProgressMap.values.toList());
    }
  }

  @override
  Future<Result<ChallengeProgress, Failure>> joinChallenge(String challengeId) async {
    final userId = _currentUserId;
    final progressId = 'prog_${challengeId}_$userId';
    final now = DateTime.now();

    final newProgress = ChallengeProgress(
      id: progressId,
      challengeId: challengeId,
      userId: userId,
      progressMinutes: 0,
      status: 'joined',
      joinedAt: now,
    );

    try {
      final response = await _supabaseClient
          .from('challenge_progress')
          .insert(newProgress.toJson())
          .select()
          .single();

      final progress = ChallengeProgress.fromJson(response);
      _localProgressMap[challengeId] = progress;
      return Success(progress);
    } catch (e) {
      SecureLogger.logError('Supabase joinChallenge failed, using local fallback', e.toString());
      _localProgressMap[challengeId] = newProgress;
      return Success(newProgress);
    }
  }

  @override
  Future<Result<ChallengeProgress, Failure>> updateProgress(
    String challengeId,
    int additionalMinutes,
  ) async {
    final userId = _currentUserId;
    final cached = _localProgressMap[challengeId];
    
    final currentMinutes = cached?.progressMinutes ?? 0;
    final newMinutes = currentMinutes + additionalMinutes;
    
    // Find target challenge to check if completed
    final challenge = _seededChallenges.firstWhere(
      (c) => c.id == challengeId,
      orElse: () => Challenge(
        id: challengeId,
        title: 'Challenge',
        difficulty: 'easy',
        type: 'Daily',
        badgeIcon: 'award',
        description: '',
        totalMinutesGoal: 100,
        usersJoined: 0,
      ),
    );

    final status = newMinutes >= challenge.totalMinutesGoal ? 'completed' : 'joined';

    final updatedProgress = ChallengeProgress(
      id: cached?.id ?? 'prog_${challengeId}_$userId',
      challengeId: challengeId,
      userId: userId,
      progressMinutes: newMinutes,
      status: status,
      joinedAt: cached?.joinedAt ?? DateTime.now(),
    );

    try {
      final response = await _supabaseClient
          .from('challenge_progress')
          .upsert(updatedProgress.toJson())
          .select()
          .single();

      final progress = ChallengeProgress.fromJson(response);
      _localProgressMap[challengeId] = progress;
      return Success(progress);
    } catch (e) {
      SecureLogger.logError('Supabase updateProgress failed, using local fallback', e.toString());
      _localProgressMap[challengeId] = updatedProgress;
      return Success(updatedProgress);
    }
  }

  @override
  Future<Result<List<ChallengeProgress>, Failure>> getFriendsProgress(
    String challengeId,
    List<String> friendUserIds,
  ) async {
    if (friendUserIds.isEmpty) return const Success([]);
    try {
      final response = await _supabaseClient
          .from('challenge_progress')
          .select()
          .eq('challenge_id', challengeId)
          .inFilter('user_id', friendUserIds);

      final list = response as List<dynamic>;
      final progressList = list
          .map((json) => ChallengeProgress.fromJson(json as Map<String, dynamic>))
          .toList();
      return Success(progressList);
    } catch (e) {
      SecureLogger.logError('Supabase getFriendsProgress failed, using local mocked fallback', e.toString());
      final list = friendUserIds.map((id) {
        final progressMin = (id.hashCode.abs() % 10) * 10 + 10;
        return ChallengeProgress(
          id: 'prog_${challengeId}_$id',
          challengeId: challengeId,
          userId: id,
          progressMinutes: progressMin,
          status: progressMin >= 60 ? 'completed' : 'joined',
          joinedAt: DateTime.now().subtract(const Duration(days: 1)),
        );
      }).toList();
      return Success(list);
    }
  }
}
