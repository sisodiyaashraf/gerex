import 'dart:async';
import 'package:flutter/material.dart';
import '../../domain/entities/exercise.dart';
import '../../../../services/exercise_service.dart';
import '../../../../core/utils/logger.dart';

class ExerciseProvider extends ChangeNotifier {
  final ExerciseService _exerciseService;

  ExerciseProvider(this._exerciseService);

  List<Exercise> _exercises = [];
  List<Exercise> _filteredExercises = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Filter States
  String? _selectedMuscle;
  String? _selectedEquipment;
  String? _selectedCategory;
  String? _selectedLevel;
  String _searchQuery = '';

  // Getters
  List<Exercise> get exercises => _filteredExercises.isEmpty && _searchQuery.isEmpty && _selectedMuscle == null && _selectedEquipment == null && _selectedCategory == null && _selectedLevel == null
      ? _exercises
      : _filteredExercises;
  
  List<Exercise> get allRawExercises => _exercises;
  List<Exercise> get filteredExercises => _filteredExercises;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get error => _errorMessage;

  // Active filter state getters
  String? get selectedMuscle => _selectedMuscle;
  String? get selectedEquipment => _selectedEquipment;
  String? get selectedCategory => _selectedCategory;
  String? get selectedLevel => _selectedLevel;
  String get searchQuery => _searchQuery;

  // Backwards compatibility getter (used by some old screens)
  String get selectedMuscleGroup => _selectedMuscle ?? 'All';

  Future<void> loadExercises() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final loaded = await _exerciseService.loadExercises();
      _exercises = loaded;
      _applyFilters();
    } catch (e) {
      SecureLogger.logError('loadExercises failed', e.toString());
      _errorMessage = SecureLogger.sanitizeException(e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void filterByMuscle(String? muscle) {
    _selectedMuscle = (muscle == 'All' || muscle == '') ? null : muscle;
    _applyFilters();
  }

  void filterByEquipment(String? equipment) {
    _selectedEquipment = (equipment == 'All' || equipment == '') ? null : equipment;
    _applyFilters();
  }

  void filterByCategory(String? category) {
    _selectedCategory = (category == 'All' || category == '') ? null : category;
    _applyFilters();
  }

  void filterByLevel(String? level) {
    _selectedLevel = (level == 'All' || level == '') ? null : level;
    _applyFilters();
  }

  void search(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void clearFilters() {
    _selectedMuscle = null;
    _selectedEquipment = null;
    _selectedCategory = null;
    _selectedLevel = null;
    _searchQuery = '';
    _filteredExercises = List.from(_exercises);
    notifyListeners();
  }

  void _applyFilters() {
    List<Exercise> results = List.from(_exercises);

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      results = results.where((e) => e.name.toLowerCase().contains(query)).toList();
    }

    if (_selectedMuscle != null && _selectedMuscle != 'All') {
      final muscle = _selectedMuscle!.toLowerCase();
      results = results.where((e) =>
          e.primaryMuscles.any((m) => m.toLowerCase() == muscle) ||
          e.secondaryMuscles.any((m) => m.toLowerCase() == muscle)).toList();
    }

    if (_selectedEquipment != null && _selectedEquipment != 'All') {
      final eq = _selectedEquipment!.toLowerCase();
      results = results.where((e) => e.equipment.toLowerCase() == eq).toList();
    }

    if (_selectedCategory != null && _selectedCategory != 'All') {
      final cat = _selectedCategory!.toLowerCase();
      results = results.where((e) => e.category.toLowerCase() == cat).toList();
    }

    if (_selectedLevel != null && _selectedLevel != 'All') {
      final lvl = _selectedLevel!.toLowerCase();
      results = results.where((e) => e.level.toLowerCase() == lvl).toList();
    }

    _filteredExercises = results;
    notifyListeners();
  }

  // --- Backwards Compatibility Wrappers ---

  Future<void> fetchExercises() async {
    if (_exercises.isEmpty) {
      await loadExercises();
    }
  }

  void updateSearchQuery(String query) {
    search(query);
  }

  void updateMuscleGroup(String muscleGroup) {
    filterByMuscle(muscleGroup);
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

    try {
      final custom = Exercise(
        id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        primaryMuscles: [muscleGroup.toLowerCase()],
        secondaryMuscles: [],
        equipment: equipment.toLowerCase(),
        category: 'strength',
        level: 'beginner',
        instructions: instructions,
        images: imagePath != null ? [imagePath] : [],
      );

      // Add custom exercise locally in memory
      _exercises.insert(0, custom);
      _applyFilters();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      SecureLogger.logError('addCustomExercise failed', e.toString());
      _errorMessage = SecureLogger.sanitizeException(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
