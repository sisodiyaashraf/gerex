import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class BigStatNumber extends StatelessWidget {
  final String number;
  final String label;
  final String? unit;
  final bool isDarkCard;
  final double fontSize;

  const BigStatNumber({
    super.key,
    required this.number,
    required this.label,
    this.unit,
    this.isDarkCard = false,
    this.fontSize = 36.0,
  });

  @override
  Widget build(BuildContext context) {
    final defaultColor = isDarkCard ? AppColors.textDarkHeading : AppColors.textLightHeading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        RichText(
          text: TextSpan(
            style: GoogleFonts.outfit(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              color: defaultColor,
              height: 1.0,
            ),
            children: _buildNumberSpans(number, defaultColor),
          ),
        ),
        if (unit != null && unit!.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            unit!,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.accentEmeraldLight,
            ),
          ),
        ],
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: isDarkCard ? AppColors.textDarkMuted : AppColors.textLightBody,
          ),
        ),
      ],
    );
  }

  List<TextSpan> _buildNumberSpans(String val, Color baseColor) {
    if (val.isEmpty) return [TextSpan(text: val, style: TextStyle(color: baseColor))];
    
    // Split coloring across digits: first part base color, last digits in emerald accent
    if (val.length > 2) {
      final mid = val.length - 2;
      return [
        TextSpan(text: val.substring(0, mid), style: TextStyle(color: baseColor)),
        TextSpan(
          text: val.substring(mid),
          style: const TextStyle(color: AppColors.accentEmeraldLight),
        ),
      ];
    } else {
      return [
        TextSpan(text: val.substring(0, 1), style: TextStyle(color: baseColor)),
        if (val.length > 1)
          TextSpan(
            text: val.substring(1),
            style: const TextStyle(color: AppColors.accentEmeraldLight),
          ),
      ];
    }
  }
}
