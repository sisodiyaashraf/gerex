import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

enum GlassContainerType {
  normal,
  mint,
  indigo,
  sky,
  violet,
  sunset,
  rose,
  slate,
}

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double borderRadius;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderWidth;
  final Gradient? borderGradient;
  final GlassContainerType type;

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
    this.type = GlassContainerType.normal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Gradient? resolvedGradient;
    Color? resolvedGlowColor;

    if (type != GlassContainerType.normal) {
      switch (type) {
        case GlassContainerType.mint:
          resolvedGradient = isDark
              ? LinearGradient(
                  colors: [const Color(0xFF042F22).withValues(alpha: 0.6), const Color(0xFF064E3B).withValues(alpha: 0.6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : const LinearGradient(
                  colors: [Color(0xFFA7F3D0), Color(0xFFECFDF5), Color(0xFFFFFFFF)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                );
          resolvedGlowColor = const Color(0xFF10B981);
          break;
        case GlassContainerType.indigo:
          resolvedGradient = isDark
              ? LinearGradient(
                  colors: [const Color(0xFF1E1B4B).withValues(alpha: 0.6), const Color(0xFF312E81).withValues(alpha: 0.6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : const LinearGradient(
                  colors: [Color(0xFFC7D2FE), Color(0xFFEEF2FF), Color(0xFFFFFFFF)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                );
          resolvedGlowColor = const Color(0xFF6366F1);
          break;
        case GlassContainerType.sky:
          resolvedGradient = isDark
              ? LinearGradient(
                  colors: [const Color(0xFF0C4A6E).withValues(alpha: 0.6), const Color(0xFF0284C7).withValues(alpha: 0.6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : const LinearGradient(
                  colors: [Color(0xFFBAE6FD), Color(0xFFF0F9FF), Color(0xFFFFFFFF)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                );
          resolvedGlowColor = const Color(0xFF0EA5E9);
          break;
        case GlassContainerType.violet:
          resolvedGradient = isDark
              ? LinearGradient(
                  colors: [const Color(0xFF2E1065).withValues(alpha: 0.6), const Color(0xFF4C1D95).withValues(alpha: 0.6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : const LinearGradient(
                  colors: [Color(0xFFDDD6FE), Color(0xFFF5F3FF), Color(0xFFFFFFFF)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                );
          resolvedGlowColor = const Color(0xFF8B5CF6);
          break;
        case GlassContainerType.sunset:
          resolvedGradient = isDark
              ? LinearGradient(
                  colors: [const Color(0xFF78350F).withValues(alpha: 0.6), const Color(0xFFB45309).withValues(alpha: 0.6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : const LinearGradient(
                  colors: [Color(0xFFFDE68A), Color(0xFFFEF9C3), Color(0xFFFFFFFF)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                );
          resolvedGlowColor = const Color(0xFFF59E0B);
          break;
        case GlassContainerType.rose:
          resolvedGradient = isDark
              ? LinearGradient(
                  colors: [const Color(0xFF881337).withValues(alpha: 0.6), const Color(0xFF9F1239).withValues(alpha: 0.6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : const LinearGradient(
                  colors: [Color(0xFFFECDD3), Color(0xFFFFF1F2), Color(0xFFFFFFFF)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                );
          resolvedGlowColor = const Color(0xFFF43F5E);
          break;
        case GlassContainerType.slate:
          resolvedGradient = isDark
              ? LinearGradient(
                  colors: [const Color(0xFF0F172A).withValues(alpha: 0.6), const Color(0xFF1E293B).withValues(alpha: 0.6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : const LinearGradient(
                  colors: [Color(0xFFE2E8F0), Color(0xFFF8FAFC), Color(0xFFFFFFFF)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                );
          resolvedGlowColor = const Color(0xFF64748B);
          break;
        default:
          break;
      }
    }

    final double resolvedRadius = borderRadius;

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(resolvedRadius),
        boxShadow: [
          if (resolvedGlowColor != null)
            BoxShadow(
              color: resolvedGlowColor.withValues(alpha: isDark ? 0.25 : 0.18),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(resolvedRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: CustomPaint(
            foregroundPainter: GlassDecorationPainter(
              radius: resolvedRadius,
              borderWidth: borderWidth,
              borderGradient: borderGradient ??
                  (isDark
                      ? LinearGradient(
                          colors: [
                            (resolvedGlowColor ?? AppColors.accentEmeraldLight).withValues(alpha: 0.25),
                            AppColors.cardDarkGlass.withValues(alpha: 0.4),
                          ],
                        )
                      : LinearGradient(
                          colors: [
                            (resolvedGlowColor ?? Colors.black).withValues(alpha: 0.08),
                            (resolvedGlowColor ?? Colors.black).withValues(alpha: 0.02),
                          ],
                        )),
              isDark: isDark,
            ),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                gradient: resolvedGradient,
                color: resolvedGradient != null
                    ? null
                    : (color ??
                        (isDark
                            ? AppColors.cardDarkGlass.withValues(alpha: 0.88)
                            : Colors.white.withValues(alpha: 0.9))),
                borderRadius: BorderRadius.circular(resolvedRadius),
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
