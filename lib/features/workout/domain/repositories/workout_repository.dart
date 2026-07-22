import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../entities/workout_entities.dart';

abstract class WorkoutRepository {
  Future<Result<List<Workout>, Failure>> getWorkouts();
  Future<Result<Workout, Failure>> createWorkout(
    Workout workout,
    List<WorkoutExercise> exercises,
  );
  Future<Result<WorkoutSession, Failure>> saveWorkoutSession(
    WorkoutSession session,
    List<LoggedSet> loggedSets,
  );
  Future<Result<List<WorkoutSession>, Failure>> getWorkoutSessions();
}
