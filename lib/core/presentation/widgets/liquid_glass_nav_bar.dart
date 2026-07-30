import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class LiquidGlassNavBarItem {
  final IconData icon;
  final String label;

  const LiquidGlassNavBarItem({
    required this.icon,
    required this.label,
  });
}

class LiquidGlassNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<LiquidGlassNavBarItem> items;

  const LiquidGlassNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;



    return Container(
      height: 70,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.grey).withValues(alpha: isDark ? 0.45 : 0.15),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.08 : 0.03),
            blurRadius: 16,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 28.0, sigmaY: 28.0),
          child: CustomPaint(
            foregroundPainter: PrismaticBorderPainter(
              radius: 30.0,
              isDark: isDark,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final segmentWidth = constraints.maxWidth / items.length;
                final activeWidth = segmentWidth - 12;
                final activeLeft = (segmentWidth * currentIndex) + 6;

                return Stack(
                  children: [
                    // 1. Crystal iridescent sheen background
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0F172A).withValues(alpha: 0.35)
                              : Colors.white.withValues(alpha: 0.45),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF60A5FA).withValues(alpha: isDark ? 0.06 : 0.04),
                              const Color(0xFFC084FC).withValues(alpha: isDark ? 0.06 : 0.04),
                              const Color(0xFFF472B6).withValues(alpha: isDark ? 0.06 : 0.04),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    ),

                    // 2. Sliding morphing active indicator
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOutCubic,
                      left: activeLeft,
                      top: 6,
                      width: activeWidth,
                      height: 58,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          gradient: GerexGradients.primaryCTA,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                    ),

                // 3. Tab bar buttons
                Positioned.fill(
                  child: Row(
                    children: List.generate(items.length, (idx) {
                      final item = items[idx];
                      final isActive = currentIndex == idx;
                      return Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onTap(idx),
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 300),
                              style: TextStyle(
                                color: isActive
                                    ? Colors.white
                                    : (isDark
                                        ? Colors.white.withValues(alpha: 0.45)
                                        : const Color(0xFF14181F).withValues(alpha: 0.5)),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      item.icon,
                                      size: isActive ? 18 : 16,
                                      color: isActive
                                          ? Colors.white
                                          : (isDark
                                              ? Colors.white.withValues(alpha: 0.45)
                                              : const Color(0xFF14181F).withValues(alpha: 0.5)),
                                    ),
                                    AnimatedSize(
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeOutCubic,
                                      child: Row(
                                        children: [
                                          if (isActive) ...[
                                            const SizedBox(width: 8),
                                            Text(item.label),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class PrismaticBorderPainter extends CustomPainter {
  final double radius;
  final bool isDark;

  PrismaticBorderPainter({
    required this.radius,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.25;

    // Thin, bright top-edge highlight catching light, fading vertically
    paint.shader = LinearGradient(
      colors: isDark
          ? [
              Colors.white.withValues(alpha: 0.35),
              Colors.white.withValues(alpha: 0.03),
            ]
          : [
              Colors.white.withValues(alpha: 0.75),
              Colors.black.withValues(alpha: 0.03),
            ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(rect);

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
