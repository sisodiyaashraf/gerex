import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MacroRingWidget extends StatelessWidget {
  final String label;
  final double value;
  final double percentage; // Ratio from 0.0 to 1.0+
  final Color color;
  final String unit;

  const MacroRingWidget({
    super.key,
    required this.label,
    required this.value,
    required this.percentage,
    required this.color,
    this.unit = 'g',
  });

  @override
  Widget build(BuildContext context) {
    final cleanPercent = percentage.clamp(0.0, 1.0);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: cleanPercent),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutBack,
      builder: (context, animValue, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Background Track
                SizedBox(
                  width: 65,
                  height: 65,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 6,
                    color: color.withValues(alpha: 0.15),
                  ),
                ),
                // Animated Progress Ring
                SizedBox(
                  width: 65,
                  height: 65,
                  child: CircularProgressIndicator(
                    value: animValue,
                    strokeWidth: 6,
                    color: color,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                // Value text inside
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${value.toInt()}',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      unit,
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
          ],
        );
      },
    );
  }
}
