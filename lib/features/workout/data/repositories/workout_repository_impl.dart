import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/workout_entities.dart';
import '../../domain/repositories/workout_repository.dart';

class WorkoutRepositoryImpl implements WorkoutRepository {
  final SupabaseClient _supabaseClient;

  WorkoutRepositoryImpl(this._supabaseClient);

  @override
  Future<Result<List<Workout>, Failure>> getWorkouts() async {
    try {
      final workoutsData = await _supabaseClient
          .from('workouts')
          .select('*, workout_exercises(*, exercises(*))')
          .order('created_at', ascending: false);

      final list = workoutsData as List<dynamic>;
      final workouts = list.map((workoutJson) {
        final exerciseJsonList =
            workoutJson['workout_exercises'] as List<dynamic>? ?? [];
        final exercises = exerciseJsonList
            .map(
              (exJson) => WorkoutExercise.fromJson(exJson as Map<String, dynamic>),
            )
            .toList();
        return Workout.fromJson(workoutJson as Map<String, dynamic>, exercises);
      }).toList();

      return Success(workouts);
    } catch (e) {
      return FailureResult(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<Workout, Failure>> createWorkout(
    Workout workout,
    List<WorkoutExercise> exercises,
  ) async {
    try {
      // 1. Insert Workout
      final workoutResponse = await _supabaseClient
          .from('workouts')
          .insert(workout.toJson())
          .select()
          .single();

      final newWorkoutId = workoutResponse['id'] as String;

      // 2. Prepare exercises with new workout ID
      final exercisesPayload = exercises.map((ex) {
        return {
          'workout_id': newWorkoutId,
          'exercise_id': ex.exerciseId,
          'sets': ex.sets,
          'reps': ex.reps,
          'weight': ex.weight,
          'rest_time': ex.restTime,
          'sequence_order': ex.sequenceOrder,
        };
      }).toList();

      // 3. Batch insert exercises
      final exercisesResponse = await _supabaseClient
          .from('workout_exercises')
          .insert(exercisesPayload)
          .select('*, exercises(*)');

      final list = exercisesResponse as List<dynamic>;
      final newExercises = list
          .map((json) => WorkoutExercise.fromJson(json as Map<String, dynamic>))
          .toList();

      final createdWorkout = Workout.fromJson(workoutResponse, newExercises);
      return Success(createdWorkout);
    } catch (e) {
      return FailureResult(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<WorkoutSession, Failure>> saveWorkoutSession(
    WorkoutSession session,
    List<LoggedSet> loggedSets,
  ) async {
    try {
      // 1. Insert session
      final sessionResponse = await _supabaseClient
          .from('workout_sessions')
          .insert(session.toJson())
          .select()
          .single();

      final newSessionId = sessionResponse['id'] as String;

      // 2. Prepare logged sets with session ID
      final setsPayload = loggedSets.map((s) {
        return {
          'session_id': newSessionId,
          'exercise_id': s.exerciseId,
          'set_number': s.setNumber,
          'reps': s.reps,
          'weight': s.weight,
          'is_completed': s.isCompleted,
        };
      }).toList();

      // 3. Batch insert logged sets
      final setsResponse = await _supabaseClient
          .from('workout_sets_logged')
          .insert(setsPayload)
          .select('*, exercises(*)');

      final list = setsResponse as List<dynamic>;
      final newSets = list
          .map((json) => LoggedSet.fromJson(json as Map<String, dynamic>))
          .toList();

      final createdSession = WorkoutSession.fromJson(sessionResponse, newSets);
      return Success(createdSession);
    } catch (e) {
      return FailureResult(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<WorkoutSession>, Failure>> getWorkoutSessions() async {
    try {
      final sessionsData = await _supabaseClient
          .from('workout_sessions')
          .select('*, workout_sets_logged(*, exercises(*))')
          .order('started_at', ascending: false);

      final list = sessionsData as List<dynamic>;
      final sessions = list.map((sessionJson) {
        final setsJsonList =
            sessionJson['workout_sets_logged'] as List<dynamic>? ?? [];
        final loggedSets = setsJsonList
            .map((sJson) => LoggedSet.fromJson(sJson as Map<String, dynamic>))
            .toList();
        return WorkoutSession.fromJson(
          sessionJson as Map<String, dynamic>,
          loggedSets,
        );
      }).toList();

      return Success(sessions);
    } catch (e) {
      return FailureResult(ServerFailure(e.toString()));
    }
  }
}
