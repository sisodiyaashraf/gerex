import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double borderRadius;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderWidth;
  final Gradient? borderGradient;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 12.0,
    this.borderRadius = 20.0,
    this.color,
    this.padding,
    this.margin,
    this.borderWidth = 1.0,
    this.borderGradient,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.05),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: CustomPaint(
            foregroundPainter: GlassDecorationPainter(
              radius: borderRadius,
              borderWidth: borderWidth,
              borderGradient: borderGradient ??
                  (isDark
                      ? GerexGradients.accentBorder
                      : LinearGradient(
                          colors: [
                            Colors.black.withValues(alpha: 0.08),
                            Colors.black.withValues(alpha: 0.02),
                          ],
                        )),
              isDark: isDark,
            ),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                color: color ??
                    (isDark
                        ? Colors.white.withValues(alpha: 0.03)
                        : Colors.black.withValues(alpha: 0.015)),
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class GlassDecorationPainter extends CustomPainter {
  final double radius;
  final double borderWidth;
  final Gradient borderGradient;
  final bool isDark;

  GlassDecorationPainter({
    required this.radius,
    required this.borderWidth,
    required this.borderGradient,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    // Paint gradient border
    final borderPaint = Paint()
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke
      ..shader = borderGradient.createShader(rect);
    canvas.drawRRect(rrect, borderPaint);

    // Paint subtle inner highlight
    final innerHighlightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: isDark ? 0.05 : 0.15),
          Colors.transparent,
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rect);
    canvas.drawRRect(rrect, innerHighlightPaint);
  }

  @override
  bool shouldRepaint(covariant GlassDecorationPainter oldDelegate) {
    return oldDelegate.radius != radius ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.borderGradient != borderGradient ||
        oldDelegate.isDark != isDark;
  }
}
