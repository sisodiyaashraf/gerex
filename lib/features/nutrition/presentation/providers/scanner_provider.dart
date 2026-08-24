import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/entities/scan_result.dart';
import '../../domain/usecases/analyze_food_image_usecase.dart';
import 'meal_provider.dart';

class ScannerProvider extends ChangeNotifier {
  final AnalyzeFoodImageUseCase _analyzeFoodImageUseCase;
  final ImagePicker _picker = ImagePicker();

  ScannerProvider(this._analyzeFoodImageUseCase);

  File? _image;
  File? get image => _image;

  bool _isAnalyzing = false;
  bool get isAnalyzing => _isAnalyzing;

  ScanResult? _scanResult;
  ScanResult? get scanResult => _scanResult;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void setImage(File imageFile) {
    _image = imageFile;
    _scanResult = null;
    _errorMessage = null;
    notifyListeners();
    analyzeImage();
  }

  Future<void> pickImageFromGallery() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setImage(File(pickedFile.path));
      }
    } catch (e) {
      _errorMessage = 'Failed to select image from gallery';
      notifyListeners();
    }
  }

  Future<void> pickImageFromCamera() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        setImage(File(pickedFile.path));
      }
    } catch (e) {
      _errorMessage = 'Failed to take photo';
      notifyListeners();
    }
  }

  Future<void> analyzeImage() async {
    if (_image == null) return;

    _isAnalyzing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _scanResult = await _analyzeFoodImageUseCase(_image!);
    } catch (e) {
      _errorMessage = 'Failed to analyze image. Please try again.';
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }

  void updatePortionAndCalories({
    required double portionSize,
    required double calories,
    required double protein,
    required double carbs,
    required double fat,
  }) {
    if (_scanResult == null) return;
    _scanResult = _scanResult!.copyWith(
      portionSize: portionSize,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
    );
    notifyListeners();
  }

  void logMeal({
    required BuildContext context,
    required MealProvider mealProvider,
    required String mealType,
  }) {
    final result = _scanResult;
    if (result == null) return;

    mealProvider.addCustomMealEntry(
      name: result.foodName,
      mealType: mealType,
      calories: result.calories,
      protein: result.protein,
      carbs: result.carbs,
      fat: result.fat,
      date: DateTime.now(),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Logged ${result.foodName} to $mealType!'),
        backgroundColor: const Color(0xFF10B981),
      ),
    );

    reset();
  }

  void reset() {
    _image = null;
    _isAnalyzing = false;
    _scanResult = null;
    _errorMessage = null;
    notifyListeners();
  }
}
