import 'dart:math';
import 'package:flutter/material.dart';

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

    final baseBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final blob1Color = theme.colorScheme.primary.withValues(
      alpha: isDark ? 0.10 : 0.06,
    );
    final blob2Color = theme.colorScheme.secondary.withValues(
      alpha: isDark ? 0.08 : 0.05,
    );

    return Scaffold(
      backgroundColor: baseBg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Animated Blobs in Background
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final angle = _controller.value * 2 * pi;
              final x1 = sin(angle) * 60;
              final y1 = cos(angle) * 90;
              final x2 = cos(angle + pi / 3) * 80;
              final y2 = sin(angle + pi / 3) * 60;

              return Stack(
                children: [
                  // Blob 1
                  Positioned(
                    top: 80 + y1,
                    left: -60 + x1,
                    child: Container(
                      width: 260,
                      height: 260,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: blob1Color,
                      ),
                    ),
                  ),
                  // Blob 2
                  Positioned(
                    bottom: 120 + y2,
                    right: -80 + x2,
                    child: Container(
                      width: 320,
                      height: 320,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: blob2Color,
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
