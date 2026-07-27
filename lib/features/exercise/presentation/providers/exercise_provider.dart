import 'dart:async';
import 'package:flutter/material.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/repositories/exercise_repository.dart';
import '../../../../core/utils/logger.dart';

class ExerciseProvider extends ChangeNotifier {
  final ExerciseRepository _exerciseRepository;

  ExerciseProvider(this._exerciseRepository);

  List<Exercise> _exercises = [];
  bool _isLoading = false;
  String? _errorMessage;

  String _searchQuery = '';
  String _selectedMuscleGroup = 'All';

  List<Exercise> get exercises => _exercises;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get selectedMuscleGroup => _selectedMuscleGroup;

  Timer? _searchDebounce;

  Future<void> fetchExercises() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _exerciseRepository.getExercises(
      query: _searchQuery,
      muscleGroup: _selectedMuscleGroup,
    );

    result.fold(
      onSuccess: (data) {
        _exercises = data;
        _isLoading = false;
      },
      onFailure: (failure) {
        SecureLogger.logError('fetchExercises failed', failure.message);
        _errorMessage = SecureLogger.sanitizeException(failure.message);
        _isLoading = false;
      },
    );
    notifyListeners();
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      fetchExercises();
    });
  }

  void updateMuscleGroup(String muscleGroup) {
    _selectedMuscleGroup = muscleGroup;
    fetchExercises();
  }

  Future<bool> addCustomExercise({
    required String name,
    required String muscleGroup,
    required String equipment,
    required List<String> instructions,
    String? imagePath,
    bool removeBackground = false,
  }) async {
    _isLoading = true;
    notifyListeners();

    final exercise = Exercise(
      id: '',
      name: name,
      muscleGroup: muscleGroup,
      equipment: equipment,
      instructions: instructions,
      imagePath: imagePath,
      removeBackground: removeBackground,
    );

    final result = await _exerciseRepository.createCustomExercise(exercise);

    return result.fold(
      onSuccess: (newExercise) {
        _exercises.insert(0, newExercise);
        _isLoading = false;
        notifyListeners();
        return true;
      },
      onFailure: (failure) {
        SecureLogger.logError('addCustomExercise failed', failure.message);
        _errorMessage = SecureLogger.sanitizeException(failure.message);
        _isLoading = false;
        notifyListeners();
        return false;
      },
    );
  }
}
