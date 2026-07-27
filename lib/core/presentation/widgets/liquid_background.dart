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
    const blob1Color = Color(0x1F50C19D); // accentEmeraldLight 12%
    const blob2Color = Color(0x1F178C6D); // accentEmeraldDeep 12%

    return Scaffold(
      backgroundColor: AppColors.bgDarkPrimary,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: GerexGradients.scaffoldBackground,
        ),
        child: Stack(
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
                        decoration: const BoxDecoration(
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
                        decoration: const BoxDecoration(
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
      ),
    );
  }
}
