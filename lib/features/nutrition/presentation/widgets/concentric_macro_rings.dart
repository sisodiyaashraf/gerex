import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ConcentricMacroRingsPainter extends CustomPainter {
  final double caloriesProgress;
  final double proteinProgress;
  final double carbsProgress;
  final double fatProgress;
  
  final Color caloriesColor;
  final Color proteinColor;
  final Color carbsColor;
  final Color fatColor;

  ConcentricMacroRingsPainter({
    required this.caloriesProgress,
    required this.proteinProgress,
    required this.carbsProgress,
    required this.fatProgress,
    required this.caloriesColor,
    required this.proteinColor,
    required this.carbsColor,
    required this.fatColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) / 2;
    
    const strokeWidth = 9.0;
    const spacing = 4.0;
    
    // Draw rings from outer to inner
    _drawRing(canvas, center, maxRadius - strokeWidth / 2, strokeWidth, caloriesProgress, caloriesColor);
    _drawRing(canvas, center, maxRadius - strokeWidth * 1.5 - spacing, strokeWidth, proteinProgress, proteinColor);
    _drawRing(canvas, center, maxRadius - strokeWidth * 2.5 - spacing * 2, strokeWidth, carbsProgress, carbsColor);
    _drawRing(canvas, center, maxRadius - strokeWidth * 3.5 - spacing * 3, strokeWidth, fatProgress, fatColor);
  }

  void _drawRing(Canvas canvas, Offset center, double radius, double strokeWidth, double progress, Color color) {
    final rect = Rect.fromCircle(center: center, radius: radius);
    
    // Background track
    final trackPaint = Paint()
      ..color = color.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);
    
    // Animated progress arc
    if (progress > 0) {
      final arcPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      
      final sweepAngle = (progress * 2 * math.pi).clamp(0.0, 1.999 * math.pi);
      canvas.drawArc(rect, -math.pi / 2, sweepAngle, false, arcPaint);
    }
  }

  @override
  bool shouldRepaint(covariant ConcentricMacroRingsPainter oldDelegate) {
    return oldDelegate.caloriesProgress != caloriesProgress ||
        oldDelegate.proteinProgress != proteinProgress ||
        oldDelegate.carbsProgress != carbsProgress ||
        oldDelegate.fatProgress != fatProgress;
  }
}

class ConcentricMacroRings extends StatelessWidget {
  final double calories;
  final double caloriesGoal;
  final double protein;
  final double proteinGoal;
  final double carbs;
  final double carbsGoal;
  final double fat;
  final double fatGoal;

  const ConcentricMacroRings({
    super.key,
    required this.calories,
    required this.caloriesGoal,
    required this.protein,
    required this.proteinGoal,
    required this.carbs,
    required this.carbsGoal,
    required this.fat,
    required this.fatGoal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final double caloriesRatio = (caloriesGoal > 0 ? calories / caloriesGoal : 0.0).clamp(0.0, 1.0);
    final double proteinRatio = (proteinGoal > 0 ? protein / proteinGoal : 0.0).clamp(0.0, 1.0);
    final double carbsRatio = (carbsGoal > 0 ? carbs / carbsGoal : 0.0).clamp(0.0, 1.0);
    final double fatRatio = (fatGoal > 0 ? fat / fatGoal : 0.0).clamp(0.0, 1.0);

    const caloriesColor = Color(0xFFF97316); // Orange/Sunset
    const proteinColor = Color(0xFF10B981);  // Mint/Emerald
    const carbsColor = Color(0xFF3B82F6);    // Blue/Indigo
    const fatColor = Color(0xFFEC4899);      // Pink/Fuchsia

    return Row(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 1400),
          curve: Curves.easeOutCubic,
          builder: (context, animValue, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(110, 110),
                  painter: ConcentricMacroRingsPainter(
                    caloriesProgress: caloriesRatio * animValue,
                    proteinProgress: proteinRatio * animValue,
                    carbsProgress: carbsRatio * animValue,
                    fatProgress: fatRatio * animValue,
                    caloriesColor: caloriesColor,
                    proteinColor: proteinColor,
                    carbsColor: carbsColor,
                    fatColor: fatColor,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${calories.toInt()}',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'kcal',
                      style: GoogleFonts.outfit(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white60 : Colors.black45,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(context, 'Calories', calories, caloriesGoal, 'kcal', caloriesColor, isDark),
              const SizedBox(height: 6),
              _buildLegendItem(context, 'Protein', protein, proteinGoal, 'g', proteinColor, isDark),
              const SizedBox(height: 6),
              _buildLegendItem(context, 'Carbohydrates', carbs, carbsGoal, 'g', carbsColor, isDark),
              const SizedBox(height: 6),
              _buildLegendItem(context, 'Fats', fat, fatGoal, 'g', fatColor, isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(
    BuildContext context,
    String label,
    double value,
    double goal,
    String unit,
    Color color,
    bool isDark,
  ) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  Text(
                    '${value.toInt()}/${goal.toInt()} $unit',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: goal > 0 ? (value / goal).clamp(0.0, 1.0) : 0.0,
                  minHeight: 3,
                  backgroundColor: color.withOpacity(0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
