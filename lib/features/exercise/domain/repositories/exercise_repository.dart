import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../entities/exercise.dart';

abstract class ExerciseRepository {
  Future<Result<List<Exercise>, Failure>> getExercises({
    String? query,
    String? muscleGroup,
  });
  Future<Result<Exercise, Failure>> createCustomExercise(Exercise exercise);
}
