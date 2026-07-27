import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../entities/challenge.dart';
import '../entities/challenge_progress.dart';

abstract class ChallengeRepository {
  Future<Result<List<Challenge>, Failure>> getChallenges();
  Future<Result<List<ChallengeProgress>, Failure>> getUserProgress();
  Future<Result<ChallengeProgress, Failure>> joinChallenge(String challengeId);
  Future<Result<ChallengeProgress, Failure>> updateProgress(String challengeId, int additionalMinutes);
}
