import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../domain/entities/draft_meal.dart';
import '../providers/scanner_provider.dart';
import '../providers/meal_provider.dart';
import 'scanner_camera_view.dart';
import 'package:gerex/core/presentation/widgets/gerex_button.dart';
import 'package:gerex/core/presentation/widgets/glass_container.dart';
import 'package:gerex/core/theme/app_theme.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  String _selectedMealType = 'Breakfast';
  bool _useCamera = false;

  void _showEditItemDialog(BuildContext context, ScannerProvider scannerProvider, int index, DraftMealItem item) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: item.name);
    final portionCtrl = TextEditingController(text: item.portionGrams.toInt().toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF151729),
        title: Text('Edit Item', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Name', labelStyle: TextStyle(color: Colors.white70)),
                validator: (val) => val == null || val.trim().isEmpty ? 'Invalid name' : null,
              ),
              TextFormField(
                controller: portionCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Portion (grams)', labelStyle: TextStyle(color: Colors.white70)),
                validator: (val) => val == null || double.tryParse(val) == null || double.parse(val) <= 0 ? 'Invalid portion' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                final newPortion = double.parse(portionCtrl.text);
                scannerProvider.updateDraftItem(
                  index,
                  item.copyWith(
                    name: nameCtrl.text.trim(),
                    portionGrams: newPortion,
                  ),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Save', style: TextStyle(color: Color(0xFF50C19D), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAddItemDialog(BuildContext context, ScannerProvider scannerProvider) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final portionCtrl = TextEditingController(text: '100');
    final calsCtrl = TextEditingController(text: '150');
    final proteinCtrl = TextEditingController(text: '10');
    final carbsCtrl = TextEditingController(text: '15');
    final fatCtrl = TextEditingController(text: '2');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF151729),
        title: Text('Add Item to Draft', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Item Name', labelStyle: TextStyle(color: Colors.white70)),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: portionCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Portion (g)', labelStyle: TextStyle(color: Colors.white70)),
                  validator: (val) => val == null || double.tryParse(val) == null || double.parse(val) <= 0 ? 'Required' : null,
                ),
                TextFormField(
                  controller: calsCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Calories per 100g (kcal)', labelStyle: TextStyle(color: Colors.white70)),
                  validator: (val) => val == null || double.tryParse(val) == null ? 'Required' : null,
                ),
                TextFormField(
                  controller: proteinCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Protein per 100g (g)', labelStyle: TextStyle(color: Colors.white70)),
                  validator: (val) => val == null || double.tryParse(val) == null ? 'Required' : null,
                ),
                TextFormField(
                  controller: carbsCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Carbs per 100g (g)', labelStyle: TextStyle(color: Colors.white70)),
                  validator: (val) => val == null || double.tryParse(val) == null ? 'Required' : null,
                ),
                TextFormField(
                  controller: fatCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Fat per 100g (g)', labelStyle: TextStyle(color: Colors.white70)),
                  validator: (val) => val == null || double.tryParse(val) == null ? 'Required' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                scannerProvider.addDraftItem(
                  DraftMealItem(
                    name: nameCtrl.text.trim(),
                    portionGrams: double.parse(portionCtrl.text),
                    caloriesPer100g: double.parse(calsCtrl.text),
                    proteinPer100g: double.parse(proteinCtrl.text),
                    carbsPer100g: double.parse(carbsCtrl.text),
                    fatPer100g: double.parse(fatCtrl.text),
                  ),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Add', style: TextStyle(color: Color(0xFF50C19D), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showBarcodeConfirmDialog(
    BuildContext context,
    ScannerProvider scannerProvider,
    Map<String, dynamic> product,
    MealProvider mealProvider,
  ) {
    final formKey = GlobalKey<FormState>();
    final portionCtrl = TextEditingController(text: '100');
    String selectedMealType = _selectedMealType;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final double portion = double.tryParse(portionCtrl.text) ?? 100.0;
            final double calories = ((product['caloriesPer100g'] as double) * portion) / 100.0;
            final double protein = ((product['proteinPer100g'] as double) * portion) / 100.0;
            final double carbs = ((product['carbsPer100g'] as double) * portion) / 100.0;
            final double fat = ((product['fatPer100g'] as double) * portion) / 100.0;

            return AlertDialog(
              backgroundColor: const Color(0xFF151729),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text(
                product['name'],
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Nutrition details found! Confirm serving size to log.',
                        style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: portionCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Portion Eaten (grams)',
                          labelStyle: TextStyle(color: Colors.white70),
                          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF50C19D))),
                        ),
                        onChanged: (_) => setState(() {}),
                        validator: (val) => val == null || double.tryParse(val) == null || double.parse(val) <= 0 ? 'Invalid serving size' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: selectedMealType,
                        dropdownColor: const Color(0xFF151729),
                        style: GoogleFonts.outfit(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Meal Category',
                          labelStyle: TextStyle(color: Colors.white70),
                        ),
                        items: ['Breakfast', 'Lunch', 'Dinner', 'Snack']
                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            selectedMealType = val;
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Scaled Nutrition:',
                              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            const SizedBox(height: 8),
                            Text('Calories: ${calories.toInt()} kcal', style: const TextStyle(color: Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                            Text('Protein: ${protein.toStringAsFixed(1)}g', style: const TextStyle(color: Colors.greenAccent, fontSize: 12)),
                            Text('Carbs: ${carbs.toStringAsFixed(1)}g', style: const TextStyle(color: Colors.blueAccent, fontSize: 12)),
                            Text('Fats: ${fat.toStringAsFixed(1)}g', style: const TextStyle(color: Colors.pinkAccent, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                ),
                TextButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      mealProvider.addCustomMealEntry(
                        name: product['name'],
                        mealType: selectedMealType,
                        calories: calories,
                        protein: protein,
                        carbs: carbs,
                        fat: fat,
                        date: DateTime.now(),
                      );
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Logged ${product['name']} to $selectedMealType!'),
                          backgroundColor: const Color(0xFF10B981),
                        ),
                      );
                    }
                  },
                  child: const Text('Log Meal', style: TextStyle(color: Color(0xFF50C19D), fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scannerProvider = Provider.of<ScannerProvider>(context);
    final mealProvider = Provider.of<MealProvider>(context, listen: false);

    Widget body;
    if (scannerProvider.isBarcodeLoading) {
      body = _buildBarcodeLoadingView();
    } else if (scannerProvider.isAnalyzing) {
      body = _buildAnalyzingView();
    } else if (scannerProvider.draftItems.isNotEmpty || scannerProvider.image != null) {
      body = _buildResultView(scannerProvider, mealProvider);
    } else if (_useCamera) {
      body = ScannerCameraView(
        onImageCaptured: (file) {
          setState(() => _useCamera = false);
          scannerProvider.setImage(file);
        },
      );
    } else {
      body = _buildInitialView(scannerProvider, mealProvider);
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F1319),
      appBar: AppBar(
        title: Text('Gerex Nutrition Scanner', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            scannerProvider.reset();
            Navigator.pop(context);
          },
        ),
        actions: [
          if (_useCamera)
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white),
              onPressed: () => setState(() => _useCamera = false),
            )
        ],
      ),
      body: SafeArea(child: body),
    );
  }

  Widget _buildInitialView(ScannerProvider provider, MealProvider mealProvider) {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.photo_camera_rounded, size: 72, color: Color(0xFF50C19D)),
            ),
            const SizedBox(height: 24),
            Text('Snap or Scan Your Food', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 12),
            Text('Take a photo of your meal or scan any product barcode to instantly log nutrition details.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 14, color: Colors.white70)),
            const SizedBox(height: 40),
            GerexButton(
              text: 'Snap a Meal',
              icon: Icons.camera_alt_rounded,
              onPressed: () => setState(() => _useCamera = true),
            ),
            const SizedBox(height: 16),
            GerexButton(
              text: 'Scan Barcode',
              icon: Icons.qr_code_scanner_rounded,
              style: GerexButtonStyle.whitePill,
              onPressed: () async {
                final barcode = await context.push('/meal-barcode-scanner');
                if (barcode != null && barcode is String) {
                  final product = await provider.lookupBarcode(barcode);
                  if (mounted && product != null) {
                    _showBarcodeConfirmDialog(context, provider, product, mealProvider);
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(provider.errorMessage ?? 'Product not found. Try logging manually.'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 16),
            GerexButton(
              text: 'Choose from Gallery',
              icon: Icons.photo_library_rounded,
              style: GerexButtonStyle.whitePill,
              onPressed: provider.pickImageFromGallery,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyzingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(color: Color(0xFF50C19D), strokeWidth: 5),
          ),
          const SizedBox(height: 32),
          Text('Running On-Device AI...', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Text('Identifying foods and matching ingredient database', style: GoogleFonts.outfit(fontSize: 13, color: Colors.white60)),
        ],
      ),
    );
  }

  Widget _buildBarcodeLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(color: Colors.orangeAccent, strokeWidth: 5),
          ),
          const SizedBox(height: 32),
          Text('Searching Open Food Facts...', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Text('Fetching online nutrition database...', style: GoogleFonts.outfit(fontSize: 13, color: Colors.white60)),
        ],
      ),
    );
  }

  Widget _buildResultView(ScannerProvider scannerProvider, MealProvider mealProvider) {
    final double totalCals = scannerProvider.draftItems.fold(0.0, (sum, i) => sum + i.calories);
    final double totalProtein = scannerProvider.draftItems.fold(0.0, (sum, i) => sum + i.protein);
    final double totalCarbs = scannerProvider.draftItems.fold(0.0, (sum, i) => sum + i.carbs);
    final double totalFat = scannerProvider.draftItems.fold(0.0, (sum, i) => sum + i.fat);

    final itemNames = scannerProvider.draftItems.map((item) => item.name).join(' + ');

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (scannerProvider.image != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                scannerProvider.image!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 16),
          
          Text(
            'Looks like:',
            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            itemNames.isNotEmpty ? itemNames : 'Unrecognized Food Plate',
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Meal Draft Breakdown', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF50C19D)),
                      onPressed: () => _showAddItemDialog(context, scannerProvider),
                    ),
                  ],
                ),
                const Divider(color: Colors.white24),
                if (scannerProvider.draftItems.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        scannerProvider.errorMessage ?? 'No food items in list. Add some manually.',
                        style: const TextStyle(color: Colors.white60, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: scannerProvider.draftItems.length,
                    itemBuilder: (context, index) {
                      final item = scannerProvider.draftItems[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(item.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Text(
                          '${item.portionGrams.toInt()}g • ${item.calories.toInt()} kcal (P: ${item.protein.toInt()}g C: ${item.carbs.toInt()}g F: ${item.fat.toInt()}g)',
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_rounded, color: Colors.white70, size: 18),
                              onPressed: () => _showEditItemDialog(context, scannerProvider, index, item),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline_rounded, color: Colors.pinkAccent, size: 18),
                              onPressed: () => scannerProvider.removeDraftItem(index),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                const Divider(color: Colors.white24),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Estimated Macros:', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                    Text('${totalCals.toInt()} kcal', style: GoogleFonts.outfit(color: Colors.orangeAccent, fontSize: 15, fontWeight: FontWeight.w900)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Protein: ${totalProtein.toStringAsFixed(1)}g', style: const TextStyle(color: Colors.greenAccent, fontSize: 11)),
                    Text('Carbs: ${totalCarbs.toStringAsFixed(1)}g', style: const TextStyle(color: Colors.blueAccent, fontSize: 11)),
                    Text('Fat: ${totalFat.toStringAsFixed(1)}g', style: const TextStyle(color: Colors.pinkAccent, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          if (scannerProvider.isCloudRunning)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: CircularProgressIndicator(color: Color(0xFF50C19D)),
              ),
            )
          else ...[
            TextButton.icon(
              onPressed: scannerProvider.escalateToCloudFallback,
              icon: const Icon(Icons.cloud_upload_rounded, color: Color(0xFF50C19D), size: 18),
              label: Text('Refine with Gerex AI (Cloud Fallback)', style: GoogleFonts.outfit(color: const Color(0xFF50C19D), fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            if (scannerProvider.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  scannerProvider.errorMessage!,
                  style: const TextStyle(color: Colors.orangeAccent, fontSize: 11, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
          
          const SizedBox(height: 20),
          
          DropdownButtonFormField<String>(
            initialValue: _selectedMealType,
            dropdownColor: const Color(0xFF151729),
            style: GoogleFonts.outfit(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Meal Category',
              labelStyle: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
              enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white24), borderRadius: BorderRadius.circular(16)),
              focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFF50C19D)), borderRadius: BorderRadius.circular(16)),
            ),
            items: ['Breakfast', 'Lunch', 'Dinner', 'Snack']
                .map((category) => DropdownMenuItem(value: category, child: Text(category)))
                .toList(),
            onChanged: (val) => setState(() => _selectedMealType = val ?? 'Breakfast'),
          ),
          const SizedBox(height: 24),
          GerexButton(
            text: 'Confirm & Log Meal',
            icon: Icons.check_circle_outline_rounded,
            onPressed: () async {
              await scannerProvider.confirmAndLogMeal(
                context: context,
                mealProvider: mealProvider,
                mealType: _selectedMealType,
              );
              if (mounted) Navigator.pop(context);
            },
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: scannerProvider.reset,
            child: Text('Retake Photo / Scan Again', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
