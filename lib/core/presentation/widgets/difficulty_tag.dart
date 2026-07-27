import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

enum DifficultyLevel { easy, beginner, medium, intermediate, hard, veryHard }

class DifficultyTag extends StatelessWidget {
  final String label;
  final DifficultyLevel? level;

  const DifficultyTag({
    super.key,
    required this.label,
    this.level,
  });

  factory DifficultyTag.fromText(String text) {
    final lower = text.toLowerCase();
    DifficultyLevel lvl = DifficultyLevel.medium;
    if (lower.contains('easy') || lower.contains('beginner')) {
      lvl = DifficultyLevel.easy;
    } else if (lower.contains('very hard') || lower.contains('extreme') || lower.contains('advanced')) {
      lvl = DifficultyLevel.veryHard;
    } else if (lower.contains('hard')) {
      lvl = DifficultyLevel.hard;
    } else if (lower.contains('medium') || lower.contains('intermediate')) {
      lvl = DifficultyLevel.medium;
    }
    return DifficultyTag(label: text, level: lvl);
  }

  @override
  Widget build(BuildContext context) {
    final lvl = level ?? DifficultyLevel.medium;
    Color textColor;
    Color bgColor;

    switch (lvl) {
      case DifficultyLevel.easy:
      case DifficultyLevel.beginner:
        textColor = AppColors.accentEmeraldLight;
        bgColor = AppColors.chipGreenBg;
        break;
      case DifficultyLevel.medium:
      case DifficultyLevel.intermediate:
        textColor = AppColors.badgeTealText;
        bgColor = AppColors.chipTealBg;
        break;
      case DifficultyLevel.hard:
        textColor = const Color(0xFFF59E0B);
        bgColor = AppColors.chipAmberBg;
        break;
      case DifficultyLevel.veryHard:
        textColor = AppColors.destructiveRed;
        bgColor = AppColors.chipRedBg;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: textColor.withValues(alpha: 0.3),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: textColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
