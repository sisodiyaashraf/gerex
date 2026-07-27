import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class IconMedallion extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color? backgroundColor;
  final Color iconColor;
  final bool isGold;

  const IconMedallion({
    super.key,
    required this.icon,
    this.size = 48.0,
    this.backgroundColor,
    this.iconColor = const Color(0xFF0B1220),
    this.isGold = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? (isGold ? AppColors.badgeGoldAccent : Colors.white);

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SunburstPainter(
          backgroundColor: bg,
          rayColor: isGold
              ? const Color(0xFFE5A800).withValues(alpha: 0.25)
              : AppColors.accentEmeraldLight.withValues(alpha: 0.2),
        ),
        child: Center(
          child: Icon(
            icon,
            size: size * 0.48,
            color: iconColor,
          ),
        ),
      ),
    );
  }
}

class _SunburstPainter extends CustomPainter {
  final Color backgroundColor;
  final Color rayColor;

  _SunburstPainter({
    required this.backgroundColor,
    required this.rayColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;

    // Draw main circular base
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    // Draw radial rays pattern inside clip
    canvas.save();
    final clipPath = Path()..addOval(Rect.fromCircle(center: center, radius: radius));
    canvas.clipPath(clipPath);

    final rayPaint = Paint()
      ..color = rayColor
      ..style = PaintingStyle.fill;

    const numRays = 12;
    const sweep = (2 * pi) / (numRays * 2);

    for (int i = 0; i < numRays; i++) {
      final startAngle = i * (2 * sweep);
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(
          Rect.fromCircle(center: center, radius: radius * 1.2),
          startAngle,
          sweep,
          false,
        )
        ..lineTo(center.dx, center.dy)
        ..close();
      canvas.drawPath(path, rayPaint);
    }

    canvas.restore();

    // Subtle outer ring
    final ringPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius - 1, ringPaint);
  }

  @override
  bool shouldRepaint(covariant _SunburstPainter oldDelegate) {
    return oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.rayColor != rayColor;
  }
}
