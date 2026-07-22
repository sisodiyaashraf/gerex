import 'package:gerex/features/exercise/domain/entities/exercise.dart';

class Workout {
  final String id;
  final String name;
  final String? userId;
  final DateTime createdAt;
  final List<WorkoutExercise> exercises;

  const Workout({
    required this.id,
    required this.name,
    this.userId,
    required this.createdAt,
    required this.exercises,
  });

  factory Workout.fromJson(
    Map<String, dynamic> json, [
    List<WorkoutExercise> exercisesList = const [],
  ]) {
    return Workout(
      id: json['id'] as String,
      name: json['name'] as String,
      userId: json['user_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      exercises: exercisesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (userId != null) 'user_id': userId,
    };
  }
}

class WorkoutExercise {
  final String id;
  final String workoutId;
  final String exerciseId;
  final Exercise? exercise;
  final int sets;
  final int reps;
  final double weight;
  final int restTime; // in seconds
  final int sequenceOrder;

  const WorkoutExercise({
    required this.id,
    required this.workoutId,
    required this.exerciseId,
    this.exercise,
    required this.sets,
    required this.reps,
    required this.weight,
    required this.restTime,
    required this.sequenceOrder,
  });

  factory WorkoutExercise.fromJson(Map<String, dynamic> json, [Exercise? ex]) {
    return WorkoutExercise(
      id: json['id'] as String,
      workoutId: json['workout_id'] as String,
      exerciseId: json['exercise_id'] as String,
      exercise: ex ??
          (json['exercises'] != null
              ? Exercise.fromJson(json['exercises'] as Map<String, dynamic>)
              : null),
      sets: json['sets'] as int,
      reps: json['reps'] as int,
      weight: (json['weight'] as num).toDouble(),
      restTime: json['rest_time'] as int,
      sequenceOrder: json['sequence_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'workout_id': workoutId,
      'exercise_id': exerciseId,
      'sets': sets,
      'reps': reps,
      'weight': weight,
      'rest_time': restTime,
      'sequence_order': sequenceOrder,
    };
  }
}

class WorkoutSession {
  final String id;
  final String? workoutId;
  final String name;
  final String? userId;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int durationSeconds;
  final List<LoggedSet> loggedSets;

  const WorkoutSession({
    required this.id,
    this.workoutId,
    required this.name,
    this.userId,
    required this.startedAt,
    this.completedAt,
    required this.durationSeconds,
    required this.loggedSets,
  });

  factory WorkoutSession.fromJson(
    Map<String, dynamic> json, [
    List<LoggedSet> loggedSetsList = const [],
  ]) {
    return WorkoutSession(
      id: json['id'] as String,
      workoutId: json['workout_id'] as String?,
      name: json['name'] as String,
      userId: json['user_id'] as String?,
      startedAt: DateTime.parse(json['started_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      durationSeconds: json['duration_seconds'] as int? ?? 0,
      loggedSets: loggedSetsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (workoutId != null) 'workout_id': workoutId,
      'name': name,
      if (userId != null) 'user_id': userId,
      'started_at': startedAt.toIso8601String(),
      if (completedAt != null) 'completed_at': completedAt!.toIso8601String(),
      'duration_seconds': durationSeconds,
    };
  }
}

class LoggedSet {
  final String id;
  final String sessionId;
  final String exerciseId;
  final Exercise? exercise;
  final int setNumber;
  final int reps;
  final double weight;
  final bool isCompleted;

  const LoggedSet({
    required this.id,
    required this.sessionId,
    required this.exerciseId,
    this.exercise,
    required this.setNumber,
    required this.reps,
    required this.weight,
    required this.isCompleted,
  });

  factory LoggedSet.fromJson(Map<String, dynamic> json, [Exercise? ex]) {
    return LoggedSet(
      id: json['id'] as String,
      sessionId: json['session_id'] as String,
      exerciseId: json['exercise_id'] as String,
      exercise: ex ??
          (json['exercises'] != null
              ? Exercise.fromJson(json['exercises'] as Map<String, dynamic>)
              : null),
      setNumber: json['set_number'] as int,
      reps: json['reps'] as int,
      weight: (json['weight'] as num).toDouble(),
      isCompleted: json['is_completed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'exercise_id': exerciseId,
      'set_number': setNumber,
      'reps': reps,
      'weight': weight,
      'is_completed': isCompleted,
    };
  }
}
