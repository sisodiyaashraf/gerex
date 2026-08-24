import 'dart:io';
import '../entities/scan_result.dart';
import '../repositories/food_scanner_repository.dart';

class AnalyzeFoodImageUseCase {
  final FoodScannerRepository repository;

  AnalyzeFoodImageUseCase(this.repository);

  Future<ScanResult> call(File image) {
    return repository.analyzeFoodImage(image);
  }
}
