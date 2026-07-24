import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/repositories/exercise_repository.dart';

class ExerciseRepositoryImpl implements ExerciseRepository {
  final SupabaseClient _supabaseClient;

  ExerciseRepositoryImpl(this._supabaseClient);

  static final List<Map<String, dynamic>> _defaultSeedRaw = [
    {
      'id': 'seed_bench_press',
      'name': 'Bench Press',
      'muscle_group': 'Chest',
      'equipment': 'Barbell',
      'instructions': ['Lie flat on the bench', 'Grip the bar slightly wider than shoulder width', 'Lower the bar to your chest', 'Push the bar back up to lockout']
    },
    {
      'id': 'seed_incline_db_press',
      'name': 'Incline Dumbbell Press',
      'muscle_group': 'Chest',
      'equipment': 'Dumbbell',
      'instructions': ['Adjust bench to a 30-45 degree incline', 'Hold dumbbells at chest height', 'Press them straight up above your chest', 'Lower under control']
    },
    {
      'id': 'seed_deadlift',
      'name': 'Deadlift',
      'muscle_group': 'Back',
      'equipment': 'Barbell',
      'instructions': ['Stand with feet hip-width apart', 'Bend at hips and knees to grip the bar', 'Keep chest up and back flat', 'Drive through heels to stand up straight']
    },
    {
      'id': 'seed_pullup',
      'name': 'Pull-up',
      'muscle_group': 'Back',
      'equipment': 'Bodyweight',
      'instructions': ['Grip the pull-up bar with palms facing away', 'Pull your chest up to the bar', 'Lower your body slowly to full extension']
    },
    {
      'id': 'seed_squat',
      'name': 'Squat',
      'muscle_group': 'Legs',
      'equipment': 'Barbell',
      'instructions': ['Rest the bar on your upper traps', 'Stand with feet shoulder-width apart', 'Lower hips down keeping back straight', 'Drive back up to standing']
    },
    {
      'id': 'seed_romanian_deadlift',
      'name': 'Romanian Deadlift',
      'muscle_group': 'Legs',
      'equipment': 'Barbell',
      'instructions': ['Stand tall with barbell in hands', 'Hinge at the hips keeping knees slightly bent', 'Lower the bar down the front of shins', 'Squeeze glutes to return to start']
    },
    {
      'id': 'seed_overhead_press',
      'name': 'Overhead Press',
      'muscle_group': 'Shoulders',
      'equipment': 'Barbell',
      'instructions': ['Hold the barbell at shoulder height', 'Brace core and press the bar overhead', 'Lower back down to collarbone height']
    },
    {
      'id': 'seed_bicep_curl',
      'name': 'Bicep Curl',
      'muscle_group': 'Arms',
      'equipment': 'Dumbbell',
      'instructions': ['Hold dumbbells at sides with palms facing forward', 'Curl weights up toward shoulders keeping elbows tucked', 'Lower back down slowly']
    },
    {
      'id': 'seed_tricep_pushdown',
      'name': 'Tricep Pushdown',
      'muscle_group': 'Arms',
      'equipment': 'Cable',
      'instructions': ['Hold attachment at chest level', 'Extend elbows pushing bar down to thighs', 'Return slowly to chest level']
    },
    {
      'id': 'seed_plank',
      'name': 'Plank',
      'muscle_group': 'Core',
      'equipment': 'Bodyweight',
      'instructions': ['Rest forearms on the ground, body straight', 'Squeeze abs and glutes', 'Hold position for desired duration']
    }
  ];

  @override
  Future<Result<List<Exercise>, Failure>> getExercises({
    String? query,
    String? muscleGroup,
  }) async {
    try {
      var builder = _supabaseClient.from('exercises').select();

      if (muscleGroup != null &&
          muscleGroup.isNotEmpty &&
          muscleGroup != 'All') {
        builder = builder.eq('muscle_group', muscleGroup);
      }

      if (query != null && query.isNotEmpty) {
        builder = builder.ilike('name', '%$query%');
      }

      final data = await builder.order('name', ascending: true);
      final list = data as List<dynamic>;
      var exercises = list
          .map((json) => Exercise.fromJson(json as Map<String, dynamic>))
          .toList();

      if (exercises.isEmpty) {
        final localSeeds = _defaultSeedRaw.map((json) => Exercise.fromJson(json)).toList();
        
        // Seed remote in background (ignore failures)
        try {
          final insertPayload = _defaultSeedRaw.map((e) {
            final map = Map<String, dynamic>.from(e);
            map.remove('id');
            return map;
          }).toList();
          await _supabaseClient.from('exercises').insert(insertPayload);
        } catch (_) {}

        // Apply filters locally
        if (muscleGroup != null && muscleGroup.isNotEmpty && muscleGroup != 'All') {
          exercises = localSeeds.where((e) => e.muscleGroup.toLowerCase() == muscleGroup.toLowerCase()).toList();
        } else {
          exercises = localSeeds;
        }

        if (query != null && query.isNotEmpty) {
          exercises = exercises.where((e) => e.name.toLowerCase().contains(query.toLowerCase())).toList();
        }
      }

      return Success(exercises);
    } catch (e) {
      // Offline / Timeout fallback
      final localSeeds = _defaultSeedRaw.map((json) => Exercise.fromJson(json)).toList();
      var exercises = localSeeds;
      
      if (muscleGroup != null && muscleGroup.isNotEmpty && muscleGroup != 'All') {
        exercises = localSeeds.where((e) => e.muscleGroup.toLowerCase() == muscleGroup.toLowerCase()).toList();
      }
      if (query != null && query.isNotEmpty) {
        exercises = exercises.where((e) => e.name.toLowerCase().contains(query.toLowerCase())).toList();
      }
      
      return Success(exercises);
    }
  }

  @override
  Future<Result<Exercise, Failure>> createCustomExercise(
    Exercise exercise,
  ) async {
    try {
      final jsonPayload = exercise.toJson();
      final response = await _supabaseClient
          .from('exercises')
          .insert(jsonPayload)
          .select()
          .single();
      final created = Exercise.fromJson(response);
      return Success(created);
    } catch (e) {
      return FailureResult(ServerFailure(e.toString()));
    }
  }
}
