import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/exercise.dart';

class ExerciseService {
  List<Exercise> _cachedExercises = [];

  Future<List<Exercise>> loadExercises() async {
    if (_cachedExercises.isNotEmpty) {
      return _cachedExercises;
    }

    try {
      final jsonString = await rootBundle.loadString('assets/data/exercises.json');
      final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
      _cachedExercises = jsonList.map((item) {
        try {
          if (item is Map<String, dynamic>) {
            return Exercise.fromJson(item);
          }
          return null;
        } catch (e) {
          // Defensively skip malformed entries to prevent crashes
          return null;
        }
      }).whereType<Exercise>().toList();
    } catch (e) {
      _cachedExercises = [];
    }

    return _cachedExercises;
  }

  Future<List<Exercise>> filterByMuscle(String muscle) async {
    final list = await loadExercises();
    final lowerMuscle = muscle.toLowerCase();
    return list.where((e) =>
        e.primaryMuscles.any((m) => m.toLowerCase() == lowerMuscle) ||
        e.secondaryMuscles.any((m) => m.toLowerCase() == lowerMuscle)).toList();
  }

  Future<List<Exercise>> filterByEquipment(String equipment) async {
    final list = await loadExercises();
    final lowerEquipment = equipment.toLowerCase();
    return list.where((e) => e.equipment.toLowerCase() == lowerEquipment).toList();
  }

  Future<List<Exercise>> filterByCategory(String category) async {
    final list = await loadExercises();
    final lowerCategory = category.toLowerCase();
    return list.where((e) => e.category.toLowerCase() == lowerCategory).toList();
  }

  Future<List<Exercise>> filterByLevel(String level) async {
    final list = await loadExercises();
    final lowerLevel = level.toLowerCase();
    return list.where((e) => e.level.toLowerCase() == lowerLevel).toList();
  }

  Future<List<Exercise>> searchByName(String query) async {
    final list = await loadExercises();
    final lowerQuery = query.toLowerCase();
    return list.where((e) => e.name.toLowerCase().contains(lowerQuery)).toList();
  }

  Future<Exercise?> findById(String id) async {
    final list = await loadExercises();
    try {
      return list.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }
}
