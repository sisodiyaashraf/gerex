import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gerex/core/di/injection_container.dart' as di;
import 'package:gerex/core/utils/logger.dart';
import '../../domain/entities/scan_result.dart';
import '../../domain/usecases/analyze_food_image_usecase.dart';
import '../../domain/entities/draft_meal.dart';
import '../../data/services/on_device_nutrition_classifier.dart';
import '../../data/services/barcode_cache_service.dart';
import 'meal_provider.dart';

class ScannerProvider extends ChangeNotifier {
  final AnalyzeFoodImageUseCase _analyzeFoodImageUseCase;
  final ImagePicker _picker = ImagePicker();
  
  late final OnDeviceNutritionClassifier _classifier;
  late final BarcodeCacheService _barcodeCache;

  ScannerProvider(this._analyzeFoodImageUseCase) {
    _classifier = OnDeviceNutritionClassifier();
    _barcodeCache = BarcodeCacheService(di.sl<SharedPreferences>());
  }

  File? _image;
  File? get image => _image;

  bool _isAnalyzing = false;
  bool get isAnalyzing => _isAnalyzing;

  bool _isCloudRunning = false;
  bool get isCloudRunning => _isCloudRunning;

  bool _isBarcodeLoading = false;
  bool get isBarcodeLoading => _isBarcodeLoading;

  ScanResult? _scanResult;
  ScanResult? get scanResult => _scanResult;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<DraftMealItem> _draftItems = [];
  List<DraftMealItem> get draftItems => _draftItems;

  void setImage(File imageFile) {
    _image = imageFile;
    _scanResult = null;
    _draftItems = [];
    _errorMessage = null;
    notifyListeners();
    runOnDeviceLabeling();
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

  Future<void> runOnDeviceLabeling() async {
    if (_image == null) return;

    _isAnalyzing = true;
    _errorMessage = null;
    _draftItems = [];
    notifyListeners();

    try {
      _draftItems = await _classifier.classifyImage(_image!);
      if (_draftItems.isEmpty) {
        _errorMessage = 'No recognizable food items found. Tap refine or enter manually.';
      }
    } catch (e) {
      SecureLogger.logError('ScannerProvider: image labeling failed', e);
      _errorMessage = 'Failed to analyze photo locally. Try refining with Gerex AI.';
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }

  Future<void> escalateToCloudFallback() async {
    if (_image == null) return;

    _isCloudRunning = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Rate limiting: 10 calls per hour
      final allowed = await _checkAndRecordCloudCall();
      if (!allowed) {
        _errorMessage = 'Cloud refinement limit reached (10 requests per hour). Adjust estimate manually.';
        return;
      }

      final result = await _analyzeFoodImageUseCase(_image!);
      if (result.isFood) {
        _scanResult = result;
        // Convert single AI prediction into an editable draft item
        _draftItems = [
          DraftMealItem(
            name: result.foodName,
            portionGrams: result.portionSize,
            caloriesPer100g: result.portionSize > 0 ? (result.calories * 100.0) / result.portionSize : 0.0,
            proteinPer100g: result.portionSize > 0 ? (result.protein * 100.0) / result.portionSize : 0.0,
            carbsPer100g: result.portionSize > 0 ? (result.carbs * 100.0) / result.portionSize : 0.0,
            fatPer100g: result.portionSize > 0 ? (result.fat * 100.0) / result.portionSize : 0.0,
          )
        ];
      } else {
        _errorMessage = 'Gerex AI identified a non-food item: ${result.foodName}.';
      }
    } catch (e) {
      SecureLogger.logError('ScannerProvider: Cloud refinement failed', e);
      _errorMessage = 'Cloud refinement failed. Please check connection and try again.';
    } finally {
      _isCloudRunning = false;
      notifyListeners();
    }
  }

  Future<bool> _checkAndRecordCloudCall() async {
    try {
      final prefs = di.sl<SharedPreferences>();
      final now = DateTime.now();
      const windowDuration = Duration(hours: 1);

      final List<String> history = prefs.getStringList('ai_food_calls_history') ?? [];
      final List<DateTime> validCalls = history
          .map((t) => DateTime.tryParse(t))
          .whereType<DateTime>()
          .where((dt) => now.difference(dt).compareTo(windowDuration) <= 0)
          .toList();

      if (validCalls.length >= 10) {
        return false;
      }

      validCalls.add(now);
      final newHistory = validCalls.map((dt) => dt.toIso8601String()).toList();
      await prefs.setStringList('ai_food_calls_history', newHistory);
      return true;
    } catch (_) {
      return true;
    }
  }

  Future<Map<String, dynamic>?> lookupBarcode(String barcode) async {
    _isBarcodeLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Check cache first
      final cached = _barcodeCache.getCachedProduct(barcode);
      if (cached != null) {
        _isBarcodeLoading = false;
        notifyListeners();
        return cached;
      }

      // Online lookup
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 6);
      final uri = Uri.parse('https://world.openfoodfacts.org/api/v2/product/$barcode.json');
      final request = await client.getUrl(uri);
      final response = await request.close();

      if (response.statusCode == 200) {
        final bodyStr = await response.transform(utf8.decoder).join();
        final Map<String, dynamic> data = json.decode(bodyStr) as Map<String, dynamic>;
        
        if (data['status'] == 1 && data['product'] != null) {
          final prod = data['product'];
          final nut = prod['nutriments'] ?? {};
          final name = prod['product_name'] ?? 'Scanned packaged food';

          final Map<String, dynamic> productData = {
            'name': name,
            'caloriesPer100g': (nut['energy-kcal_100g'] as num?)?.toDouble() ?? 0.0,
            'proteinPer100g': (nut['proteins_100g'] as num?)?.toDouble() ?? 0.0,
            'carbsPer100g': (nut['carbohydrates_100g'] as num?)?.toDouble() ?? 0.0,
            'fatPer100g': (nut['fat_100g'] as num?)?.toDouble() ?? 0.0,
          };

          await _barcodeCache.cacheProduct(barcode, productData);
          _isBarcodeLoading = false;
          notifyListeners();
          return productData;
        }
      }
      _errorMessage = 'Product not found in Open Food Facts.';
    } catch (e) {
      SecureLogger.logError('ScannerProvider: Barcode lookup failed', e);
      _errorMessage = 'Barcode lookup failed. Device is offline or network timed out.';
    } finally {
      _isBarcodeLoading = false;
      notifyListeners();
    }
    return null;
  }

  void addDraftItem(DraftMealItem item) {
    _draftItems.add(item);
    notifyListeners();
  }

  void removeDraftItem(int index) {
    if (index >= 0 && index < _draftItems.length) {
      _draftItems.removeAt(index);
      notifyListeners();
    }
  }

  void updateDraftItem(int index, DraftMealItem item) {
    if (index >= 0 && index < _draftItems.length) {
      _draftItems[index] = item;
      notifyListeners();
    }
  }

  Future<void> confirmAndLogMeal({
    required BuildContext context,
    required MealProvider mealProvider,
    required String mealType,
  }) async {
    if (_draftItems.isEmpty) return;

    try {
      String? savedPath;

      if (_image != null) {
        // File upload safety validation
        final bytes = await _image!.length();
        if (bytes > 5 * 1024 * 1024) {
          throw Exception('File size exceeds the 5MB limit.');
        }

        final fileExt = p.extension(_image!.path).toLowerCase();
        if (fileExt != '.jpg' && fileExt != '.jpeg' && fileExt != '.png') {
          throw Exception('Unsupported photo format. Only JPG, JPEG, and PNG are allowed.');
        }

        final appDocDir = await getApplicationDocumentsDirectory();
        final fileName = 'meal_snap_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedFile = await _image!.copy(p.join(appDocDir.path, fileName));
        savedPath = savedFile.path;
      }

      double totalCalories = _draftItems.fold(0.0, (sum, item) => sum + item.calories);
      double totalProtein = _draftItems.fold(0.0, (sum, item) => sum + item.protein);
      double totalCarbs = _draftItems.fold(0.0, (sum, item) => sum + item.carbs);
      double totalFat = _draftItems.fold(0.0, (sum, item) => sum + item.fat);
      String combinedName = _draftItems.map((item) => item.name).join(' + ');

      if (combinedName.length > 60) {
        combinedName = '${combinedName.substring(0, 57)}...';
      }

      mealProvider.addCustomMealEntry(
        name: combinedName,
        mealType: mealType,
        calories: totalCalories,
        protein: totalProtein,
        carbs: totalCarbs,
        fat: totalFat,
        date: DateTime.now(),
        imagePath: savedPath,
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logged "$combinedName" to $mealType!'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );

      reset();
    } catch (e) {
      SecureLogger.logError('ScannerProvider: Confirm meal logging failed', e);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception:', '').trim()}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
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
    _isCloudRunning = false;
    _isBarcodeLoading = false;
    _scanResult = null;
    _draftItems = [];
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _classifier.dispose();
    super.dispose();
  }
}
