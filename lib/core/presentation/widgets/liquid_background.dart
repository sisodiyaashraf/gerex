import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class LiquidBackground extends StatefulWidget {
  final Widget child;

  const LiquidBackground({super.key, required this.child});

  @override
  State<LiquidBackground> createState() => _LiquidBackgroundState();
}

class _LiquidBackgroundState extends State<LiquidBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark
        ? AppColors.bgDarkPrimary
        : theme.scaffoldBackgroundColor;

    final blob1Color = isDark
        ? const Color(0x2650C19D) // accentEmeraldLight 15%
        : const Color(0x2210B981); // Emerald 13%
    final blob2Color = isDark
        ? const Color(0x26178C6D) // accentEmeraldDeep 15%
        : const Color(0x226366F1); // Indigo 13%
    final blob3Color = isDark
        ? const Color(0x2030377B) // Glass dark indigo 12%
        : const Color(0x1F0EA5E9); // Sky blue 12%

    return Container(
      color: bgColor,
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Animated Liquid Blobs in Background
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final angle = _controller.value * 2 * pi;
              final x1 = sin(angle) * 70;
              final y1 = cos(angle) * 100;
              final x2 = cos(angle + pi / 3) * 90;
              final y2 = sin(angle + pi / 3) * 70;
              final x3 = sin(angle + pi * 2 / 3) * 60;
              final y3 = cos(angle + pi * 2 / 3) * 80;

              return Stack(
                children: [
                  // Blob 1 Top Left
                  Positioned(
                    top: 60 + y1,
                    left: -70 + x1,
                    child: Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: blob1Color,
                        boxShadow: [
                          BoxShadow(
                            color: blob1Color,
                            blurRadius: 80,
                            spreadRadius: 30,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Blob 2 Bottom Right
                  Positioned(
                    bottom: 100 + y2,
                    right: -90 + x2,
                    child: Container(
                      width: 340,
                      height: 340,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: blob2Color,
                        boxShadow: [
                          BoxShadow(
                            color: blob2Color,
                            blurRadius: 90,
                            spreadRadius: 40,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Blob 3 Center Right
                  Positioned(
                    top: 320 + y3,
                    right: 40 + x3,
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: blob3Color,
                        boxShadow: [
                          BoxShadow(
                            color: blob3Color,
                            blurRadius: 70,
                            spreadRadius: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // Foreground child content
          SafeArea(child: widget.child),
        ],
      ),
    );
  }
}

