import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/entities/scan_result.dart';
import '../providers/scanner_provider.dart';
import '../providers/meal_provider.dart';
import 'macro_ring_widget.dart';
import 'package:gerex/core/presentation/widgets/glass_container.dart';

class ScanResultCard extends StatelessWidget {
  final ScanResult result;
  const ScanResultCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final mealProvider = Provider.of<MealProvider>(context);
    final scannerProvider = Provider.of<ScannerProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final textColor = isDark ? Colors.white : const Color(0xFF0B1220);
    final subtitleColor = isDark ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF1E293B);
    final calorieColor = isDark ? const Color(0xFF50C19D) : const Color(0xFF178C6D);

    final today = DateTime.now();
    final todayMeals = mealProvider.mealPlan.where((m) =>
        m.date.day == today.day && m.date.month == today.month && m.date.year == today.year).toList();

    double loggedCals = todayMeals.fold(0.0, (sum, m) => sum + m.calories);
    double loggedP = todayMeals.fold(0.0, (sum, m) => sum + m.protein);
    double loggedC = todayMeals.fold(0.0, (sum, m) => sum + m.carbs);
    double loggedF = todayMeals.fold(0.0, (sum, m) => sum + m.fat);

    return GlassContainer(
      type: GlassContainerType.slate,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.foodName,
                      style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Portion Size: ${result.portionSize.toInt()}g',
                      style: GoogleFonts.outfit(fontSize: 14, color: subtitleColor),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: Color(0xFF50C19D), size: 24),
                onPressed: () => _showEditDialog(context, scannerProvider, isDark),
              ),
            ],
          ),
          Divider(color: isDark ? Colors.white24 : Colors.black12, height: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${result.calories.toInt()} kcal',
                style: GoogleFonts.outfit(fontSize: 36, fontWeight: FontWeight.w900, color: calorieColor),
              ),
              Text(
                'Estimated Calories',
                style: GoogleFonts.outfit(fontSize: 13, color: subtitleColor, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              MacroRingWidget(label: 'Protein', value: result.protein, percentage: result.protein / 150, color: Colors.greenAccent),
              MacroRingWidget(label: 'Carbs', value: result.carbs, percentage: result.carbs / 300, color: Colors.blueAccent),
              MacroRingWidget(label: 'Fats', value: result.fat, percentage: result.fat / 80, color: Colors.pinkAccent),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Daily Goal Impact',
            style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
          ),
          const SizedBox(height: 12),
          _buildImpactBar('Calories', loggedCals, result.calories, 2500, 'kcal', calorieColor, subtitleColor, isDark),
          _buildImpactBar('Protein', loggedP, result.protein, 150, 'g', Colors.greenAccent, subtitleColor, isDark),
          _buildImpactBar('Carbs', loggedC, result.carbs, 300, 'g', Colors.blueAccent, subtitleColor, isDark),
          _buildImpactBar('Fats', loggedF, result.fat, 80, 'g', Colors.pinkAccent, subtitleColor, isDark),
        ],
      ),
    );
  }

  Widget _buildImpactBar(String label, double current, double added, double target, String unit, Color color, Color textCol, bool isDark) {
    double total = current + added;
    double currentRatio = (current / target).clamp(0.0, 1.0);
    double addedRatio = (added / target).clamp(0.0, 1.0);
    if (currentRatio + addedRatio > 1.0) addedRatio = 1.0 - currentRatio;

    int currentFlex = (currentRatio * 1000).toInt();
    int addedFlex = (addedRatio * 1000).toInt();
    int remainingFlex = 1000 - (currentFlex + addedFlex);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$label: ${total.toInt()}/${target.toInt()} $unit',
                style: GoogleFonts.outfit(fontSize: 12, color: textCol, fontWeight: FontWeight.w500),
              ),
              Text(
                '+${added.toInt()} $unit',
                style: GoogleFonts.outfit(fontSize: 12, color: color, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 6,
              child: Row(
                children: [
                  if (currentFlex > 0) Expanded(flex: currentFlex, child: Container(color: isDark ? Colors.white30 : Colors.black26)),
                  if (addedFlex > 0) Expanded(flex: addedFlex, child: Container(color: color)),
                  if (remainingFlex > 0) Expanded(flex: remainingFlex, child: Container(color: isDark ? Colors.white10 : Colors.black12)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, ScannerProvider provider, bool isDark) {
    final formKey = GlobalKey<FormState>();
    final portionCtrl = TextEditingController(text: result.portionSize.toInt().toString());
    final calsCtrl = TextEditingController(text: result.calories.toInt().toString());
    final pCtrl = TextEditingController(text: result.protein.toInt().toString());
    final cCtrl = TextEditingController(text: result.carbs.toInt().toString());
    final fCtrl = TextEditingController(text: result.fat.toInt().toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF151729),
        title: Text('Adjust Scanned Values', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildField('Portion (g)', portionCtrl),
                _buildField('Calories (kcal)', calsCtrl),
                _buildField('Protein (g)', pCtrl),
                _buildField('Carbs (g)', cCtrl),
                _buildField('Fats (g)', fCtrl),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white70))),
          TextButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                provider.updatePortionAndCalories(
                  portionSize: double.parse(portionCtrl.text),
                  calories: double.parse(calsCtrl.text),
                  protein: double.parse(pCtrl.text),
                  carbs: double.parse(cCtrl.text),
                  fat: double.parse(fCtrl.text),
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

  Widget _buildField(String label, TextEditingController ctrl) {
    return TextFormField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60, fontSize: 12),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF50C19D))),
      ),
      validator: (val) => val == null || double.tryParse(val) == null ? 'Invalid' : null,
    );
  }
}
