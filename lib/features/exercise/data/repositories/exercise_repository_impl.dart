import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/repositories/exercise_repository.dart';

class ExerciseRepositoryImpl implements ExerciseRepository {
  final SupabaseClient _supabaseClient;

  ExerciseRepositoryImpl(this._supabaseClient);

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
      final exercises = list
          .map((json) => Exercise.fromJson(json as Map<String, dynamic>))
          .toList();
      return Success(exercises);
    } catch (e) {
      return FailureResult(ServerFailure(e.toString()));
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
