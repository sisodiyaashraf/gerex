import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/scanner_provider.dart';
import '../providers/meal_provider.dart';
import 'scanner_camera_view.dart';
import '../widgets/scan_result_card.dart';
import 'package:gerex/core/presentation/widgets/gerex_button.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  String _selectedMealType = 'Breakfast';
  bool _useCamera = false;

  @override
  Widget build(BuildContext context) {
    final scannerProvider = Provider.of<ScannerProvider>(context);
    final mealProvider = Provider.of<MealProvider>(context, listen: false);

    Widget body;
    if (scannerProvider.isAnalyzing) {
      body = _buildAnalyzingView();
    } else if (scannerProvider.scanResult != null) {
      body = _buildResultView(scannerProvider, mealProvider);
    } else if (_useCamera) {
      body = ScannerCameraView(
        onImageCaptured: (file) {
          setState(() => _useCamera = false);
          scannerProvider.setImage(file);
        },
      );
    } else {
      body = _buildInitialView(scannerProvider);
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F1319),
      appBar: AppBar(
        title: Text('AI Food Scanner', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
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

  Widget _buildInitialView(ScannerProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.photo_camera_rounded, size: 72, color: Color(0xFF50C19D)),
            ),
            const SizedBox(height: 24),
            Text('Snap & Log Your Meal', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 12),
            Text('Point your camera at any meal to instantly estimate calories and track macros.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 14, color: Colors.white70)),
            const SizedBox(height: 40),
            GerexButton(
              text: 'Use Camera',
              icon: Icons.camera_alt_rounded,
              onPressed: () => setState(() => _useCamera = true),
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
          Text('Analyzing meal image...', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Text('Identifying food items and calculating macros', style: GoogleFonts.outfit(fontSize: 12, color: Colors.white60)),
        ],
      ),
    );
  }

  Widget _buildResultView(ScannerProvider scannerProvider, MealProvider mealProvider) {
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
          ScanResultCard(result: scannerProvider.scanResult!),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            initialValue: _selectedMealType,
            dropdownColor: const Color(0xFF151729),
            style: GoogleFonts.outfit(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Meal Category',
              labelStyle: const TextStyle(color: Colors.white60),
              enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white12), borderRadius: BorderRadius.circular(16)),
              focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFF50C19D)), borderRadius: BorderRadius.circular(16)),
            ),
            items: ['Breakfast', 'Lunch', 'Dinner', 'Snack']
                .map((category) => DropdownMenuItem(value: category, child: Text(category)))
                .toList(),
            onChanged: (val) => setState(() => _selectedMealType = val ?? 'Breakfast'),
          ),
          const SizedBox(height: 24),
          GerexButton(
            text: 'Log this meal',
            icon: Icons.check_circle_outline_rounded,
            onPressed: () {
              scannerProvider.logMeal(
                context: context,
                mealProvider: mealProvider,
                mealType: _selectedMealType,
              );
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: scannerProvider.reset,
            child: Text('Retake Photo / Scan Again', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
