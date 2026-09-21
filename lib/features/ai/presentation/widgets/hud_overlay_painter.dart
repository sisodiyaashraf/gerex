import 'dart:math';
import 'package:flutter/material.dart';
import 'package:gerex/core/theme/app_theme.dart';

/// Lightweight particle model for rep completion spark bursts
class RepParticle {
  Offset position;
  Offset velocity;
  double radius;
  double opacity;
  double maxLifetime;
  double age;
  Color color;

  RepParticle({
    required this.position,
    required this.velocity,
    required this.radius,
    required this.opacity,
    required this.maxLifetime,
    this.age = 0.0,
    required this.color,
  });

  bool get isDead => age >= maxLifetime;

  void update(double dt) {
    age += dt;
    position += velocity * dt;
    // Fade out as age increases
    opacity = (1.0 - (age / maxLifetime)).clamp(0.0, 1.0);
  }
}

/// Particle Burst Overlay Painter - cheap lightweight animated spark dots on rep completion
class ParticleBurstPainter extends CustomPainter {
  final List<RepParticle> particles;
  static final Paint _cachedParticlePaint = Paint()..style = PaintingStyle.fill;

  ParticleBurstPainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    if (particles.isEmpty) return;
    for (final p in particles) {
      if (p.isDead) continue;
      _cachedParticlePaint.color = p.color.withValues(alpha: p.opacity);
      canvas.drawCircle(p.position, p.radius * p.opacity, _cachedParticlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant ParticleBurstPainter oldDelegate) {
    return particles.isNotEmpty || oldDelegate.particles.isNotEmpty;
  }
}

/// HUD Corner Brackets Painter - Sci-fi targeting reticle corner brackets
class HUDCornerBracketsPainter extends CustomPainter {
  final Color bracketColor;
  final double animationValue;

  // Cached Paint objects to avoid per-frame allocation
  static final Paint _bracketGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4.0
    ..strokeCap = StrokeCap.square;

  static final Paint _bracketCorePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0
    ..strokeCap = StrokeCap.square;

  static final Paint _dotPaint = Paint()..style = PaintingStyle.fill;

  HUDCornerBracketsPainter({
    this.bracketColor = AppColors.accentEmeraldLight,
    this.animationValue = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double bracketLength = min(size.width, size.height) * 0.12;
    const double margin = 16.0;

    _bracketGlowPaint.color = bracketColor.withValues(alpha: 0.35 * animationValue);
    _bracketCorePaint.color = bracketColor.withValues(alpha: 0.9 * animationValue);
    _dotPaint.color = bracketColor.withValues(alpha: 0.8 * animationValue);

    final double w = size.width;
    final double h = size.height;

    // Helper to draw bracket pair (glow + core)
    void drawBracket(Path path) {
      canvas.drawPath(path, _bracketGlowPaint);
      canvas.drawPath(path, _bracketCorePaint);
    }

    // Top-Left Corner
    final Path tl = Path()
      ..moveTo(margin, margin + bracketLength)
      ..lineTo(margin, margin)
      ..lineTo(margin + bracketLength, margin);
    drawBracket(tl);

    // Top-Right Corner
    final Path tr = Path()
      ..moveTo(w - margin - bracketLength, margin)
      ..lineTo(w - margin, margin)
      ..lineTo(w - margin, margin + bracketLength);
    drawBracket(tr);

    // Bottom-Left Corner
    final Path bl = Path()
      ..moveTo(margin, h - margin - bracketLength)
      ..lineTo(margin, h - margin)
      ..lineTo(margin + bracketLength, h - margin);
    drawBracket(bl);

    // Bottom-Right Corner
    final Path br = Path()
      ..moveTo(w - margin - bracketLength, h - margin)
      ..lineTo(w - margin, h - margin)
      ..lineTo(w - margin, h - margin - bracketLength);
    drawBracket(br);

    // Subtle corner targeting dots
    canvas.drawCircle(Offset(margin + 4, margin + 4), 2.5, _dotPaint);
    canvas.drawCircle(Offset(w - margin - 4, margin + 4), 2.5, _dotPaint);
    canvas.drawCircle(Offset(margin + 4, h - margin - 4), 2.5, _dotPaint);
    canvas.drawCircle(Offset(w - margin - 4, h - margin - 4), 2.5, _dotPaint);
  }

  @override
  bool shouldRepaint(covariant HUDCornerBracketsPainter oldDelegate) {
    return oldDelegate.bracketColor != bracketColor ||
        (oldDelegate.animationValue - animationValue).abs() > 0.01;
  }
}

/// HUD Scan-Line Painter - Sweeping sci-fi scanline during calibration state
class HUDScanLinePainter extends CustomPainter {
  final double progress; // 0.0 to 1.0 vertical sweep position
  final Color scanColor;

  static final Paint _linePaint = Paint()..style = PaintingStyle.stroke;
  static final Paint _gradientGlowPaint = Paint()..style = PaintingStyle.fill;

  HUDScanLinePainter({
    required this.progress,
    this.scanColor = AppColors.accentEmeraldLight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double y = size.height * progress;

    // Glowing vertical gradient trailing the scanline
    const double glowHeight = 35.0;
    final Rect glowRect = Rect.fromLTRB(0, max(0, y - glowHeight), size.width, y);
    _gradientGlowPaint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        scanColor.withValues(alpha: 0.0),
        scanColor.withValues(alpha: 0.25),
      ],
    ).createShader(glowRect);

    canvas.drawRect(glowRect, _gradientGlowPaint);

    // Sharp scan line
    _linePaint.color = scanColor.withValues(alpha: 0.85);
    _linePaint.strokeWidth = 2.0;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), _linePaint);
  }

  @override
  bool shouldRepaint(covariant HUDScanLinePainter oldDelegate) {
    return (oldDelegate.progress - progress).abs() > 0.005 ||
        oldDelegate.scanColor != scanColor;
  }
}

/// Live Form Quality Ring Painter - HUD circular status frame showing form quality/confidence
class HUDFormQualityRingPainter extends CustomPainter {
  final bool isGoodForm;
  final double confidence; // 0.0 to 1.0

  static final Paint _ringBackgroundPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3.0
    ..color = Colors.white10;

  static final Paint _ringForegroundPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3.5
    ..strokeCap = StrokeCap.round;

  HUDFormQualityRingPainter({
    required this.isGoodForm,
    this.confidence = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = min(size.width, size.height) * 0.48;
    final Offset center = Offset(size.width / 2, size.height / 2);

    // Color shift along Emerald -> Amber -> Red spectrum
    final Color ringColor = isGoodForm
        ? (confidence > 0.8 ? AppColors.accentEmeraldLight : Colors.amber)
        : Colors.redAccent;

    _ringForegroundPaint.color = ringColor.withValues(alpha: 0.65);

    // Draw background track ring
    canvas.drawCircle(center, radius, _ringBackgroundPaint);

    // Draw active arc segment
    final double sweepAngle = 2 * pi * confidence.clamp(0.1, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      _ringForegroundPaint,
    );
  }

  @override
  bool shouldRepaint(covariant HUDFormQualityRingPainter oldDelegate) {
    return oldDelegate.isGoodForm != isGoodForm ||
        (oldDelegate.confidence - confidence).abs() > 0.02;
  }
}
