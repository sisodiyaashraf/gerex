import 'dart:io';
import '../../domain/entities/scan_result.dart';
import '../../domain/repositories/food_scanner_repository.dart';

class FoodScannerRepositoryImpl implements FoodScannerRepository {
  @override
  Future<ScanResult> analyzeFoodImage(File image) async {
    // Simulate network analysis latency
    await Future.delayed(const Duration(seconds: 2));

    // Return realistic fitness-oriented mock scan results
    return const ScanResult(
      foodName: 'Grilled Salmon Salad',
      calories: 420.0,
      protein: 32.0,
      carbs: 20.0,
      fat: 18.0,
      portionSize: 250.0,
    );
  }
}
