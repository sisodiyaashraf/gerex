import 'dart:io';
import '../entities/scan_result.dart';

abstract class FoodScannerRepository {
  Future<ScanResult> analyzeFoodImage(File image);
}
