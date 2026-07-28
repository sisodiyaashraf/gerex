import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

enum GerexButtonStyle { emeraldGradient, whitePill, destructive }

class GerexButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final GerexButtonStyle style;
  final double height;
  final double? width;
  final bool isLoading;

  const GerexButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.style = GerexButtonStyle.emeraldGradient,
    this.height = 52.0,
    this.width,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    BoxDecoration decoration;
    Color textColor;

    switch (style) {
      case GerexButtonStyle.whitePill:
        decoration = BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        );
        textColor = AppColors.textLightHeading;
        break;

      case GerexButtonStyle.destructive:
        decoration = BoxDecoration(
          gradient: GerexGradients.destructive,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppColors.destructiveRed.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        );
        textColor = Colors.white;
        break;

      case GerexButtonStyle.emeraldGradient:
        decoration = BoxDecoration(
          gradient: GerexGradients.primaryCTA,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentEmeraldLight.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        );
        textColor = Colors.white;
        break;
    }

    return Container(
      height: height,
      width: width ?? double.infinity,
      decoration: decoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(30),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: textColor,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: textColor, size: 18),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        text,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
