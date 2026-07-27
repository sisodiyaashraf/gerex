import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class GerexLineChartPoint {
  final String label;
  final double value;

  const GerexLineChartPoint({required this.label, required this.value});
}

class GerexLineChart extends StatefulWidget {
  final List<GerexLineChartPoint> data;
  final String? unit;
  final double height;
  final int? selectedIndex;
  final ValueChanged<int>? onPointSelected;

  const GerexLineChart({
    super.key,
    required this.data,
    this.unit,
    this.height = 200.0,
    this.selectedIndex,
    this.onPointSelected,
  });

  @override
  State<GerexLineChart> createState() => _GerexLineChartState();
}

class _GerexLineChartState extends State<GerexLineChart> {
  int _activeIdx = 0;

  @override
  void initState() {
    super.initState();
    _activeIdx = widget.selectedIndex ?? (widget.data.isNotEmpty ? widget.data.length - 1 : 0);
  }

  @override
  void didUpdateWidget(covariant GerexLineChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != null && widget.selectedIndex != _activeIdx) {
      _activeIdx = widget.selectedIndex!;
    }
  }

  void _handleTouch(Offset localPosition, Size size) {
    if (widget.data.isEmpty) return;
    const double paddingLeft = 32.0;
    const double paddingRight = 16.0;
    final double chartWidth = size.width - paddingLeft - paddingRight;
    final double stepX = widget.data.length > 1 ? chartWidth / (widget.data.length - 1) : chartWidth;

    final touchX = localPosition.dx - paddingLeft;
    int idx = (touchX / stepX).round().clamp(0, widget.data.length - 1);
    if (idx != _activeIdx) {
      setState(() => _activeIdx = idx);
      if (widget.onPointSelected != null) {
        widget.onPointSelected!(idx);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: const Center(
          child: Text(
            'No data points available',
            style: TextStyle(color: AppColors.textDarkMuted),
          ),
        ),
      );
    }

    final activePoint = widget.data[_activeIdx.clamp(0, widget.data.length - 1)];

    return SizedBox(
      height: widget.height,
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onPanUpdate: (details) => _handleTouch(details.localPosition, constraints.biggest),
                  onPanDown: (details) => _handleTouch(details.localPosition, constraints.biggest),
                  onTapUp: (details) => _handleTouch(details.localPosition, constraints.biggest),
                  child: CustomPaint(
                    size: constraints.biggest,
                    painter: _GerexWavePainter(
                      data: widget.data,
                      selectedIndex: _activeIdx,
                      unit: widget.unit,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GerexWavePainter extends CustomPainter {
  final List<GerexLineChartPoint> data;
  final int selectedIndex;
  final String? unit;

  _GerexWavePainter({
    required this.data,
    required this.selectedIndex,
    this.unit,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    const double paddingLeft = 32.0;
    const double paddingRight = 16.0;
    const double paddingTop = 40.0;
    const double paddingBottom = 28.0;

    final double width = size.width - paddingLeft - paddingRight;
    final double height = size.height - paddingTop - paddingBottom;

    final values = data.map((d) => d.value).toList();
    double maxVal = values.reduce((curr, next) => curr > next ? curr : next);
    double minVal = values.reduce((curr, next) => curr < next ? curr : next);

    if (maxVal == minVal) {
      maxVal += 5.0;
      minVal = (minVal - 5.0).clamp(0.0, double.infinity);
    } else {
      final range = maxVal - minVal;
      maxVal += range * 0.15;
      minVal = (minVal - range * 0.15).clamp(0.0, double.infinity);
    }

    final double valRange = maxVal - minVal;

    // Draw horizontal grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..strokeWidth = 1.0;

    final labelStyle = GoogleFonts.inter(
      fontSize: 10,
      color: AppColors.textDarkMuted,
    );

    for (int i = 0; i <= 2; i++) {
      final y = paddingTop + height * (i / 2.0);
      canvas.drawLine(
        Offset(paddingLeft, y),
        Offset(size.width - paddingRight, y),
        gridPaint,
      );
    }

    // Compute point coordinates
    final points = <Offset>[];
    final double stepX = data.length > 1 ? width / (data.length - 1) : width;

    for (int i = 0; i < data.length; i++) {
      final x = paddingLeft + i * stepX;
      final y = paddingTop + height * (1.0 - (data[i].value - minVal) / valRange);
      points.add(Offset(x, y));
    }

    // Smooth cubic bezier path for wave line
    final pathLine = Path();
    final pathArea = Path();

    if (points.length == 1) {
      pathLine.moveTo(points.first.dx - 10, points.first.dy);
      pathLine.lineTo(points.first.dx + 10, points.first.dy);
    } else {
      pathLine.moveTo(points.first.dx, points.first.dy);
      pathArea.moveTo(points.first.dx, size.height - paddingBottom);
      pathArea.lineTo(points.first.dx, points.first.dy);

      for (int i = 0; i < points.length - 1; i++) {
        final p0 = points[i];
        final p1 = points[i + 1];
        final controlX1 = p0.dx + (p1.dx - p0.dx) / 2;
        final controlY1 = p0.dy;
        final controlX2 = p0.dx + (p1.dx - p0.dx) / 2;
        final controlY2 = p1.dy;

        pathLine.cubicTo(controlX1, controlY1, controlX2, controlY2, p1.dx, p1.dy);
        pathArea.cubicTo(controlX1, controlY1, controlX2, controlY2, p1.dx, p1.dy);
      }

      pathArea.lineTo(points.last.dx, size.height - paddingBottom);
      pathArea.close();

      // Draw soft gradient fill underneath line
      final areaPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.accentEmeraldLight.withValues(alpha: 0.35),
            AppColors.accentEmeraldDeep.withValues(alpha: 0.0),
          ],
        ).createShader(
          Rect.fromLTRB(paddingLeft, paddingTop, size.width - paddingRight, size.height - paddingBottom),
        );
      canvas.drawPath(pathArea, areaPaint);
    }

    // Draw main smooth stroke line
    final linePaint = Paint()
      ..color = AppColors.accentEmeraldLight
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(pathLine, linePaint);

    // Draw x-axis labels
    for (int i = 0; i < data.length; i++) {
      final p = points[i];
      final isSelected = i == selectedIndex;
      final textPainter = TextPainter(
        text: TextSpan(
          text: data[i].label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? AppColors.accentEmeraldLight : AppColors.textDarkMuted,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(p.dx - textPainter.width / 2, size.height - paddingBottom + 8),
      );
    }

    // Draw selected active point, guide line, and callout pill
    if (selectedIndex >= 0 && selectedIndex < points.length) {
      final activeP = points[selectedIndex];

      // Vertical dashed guide line
      final dashedPaint = Paint()
        ..color = AppColors.accentEmeraldLight.withValues(alpha: 0.5)
        ..strokeWidth = 1.5;

      const double dashHeight = 4, dashSpace = 4;
      double startY = activeP.dy;
      while (startY < size.height - paddingBottom) {
        canvas.drawLine(
          Offset(activeP.dx, startY),
          Offset(activeP.dx, (startY + dashHeight).clamp(startY, size.height - paddingBottom)),
          dashedPaint,
        );
        startY += dashHeight + dashSpace;
      }

      // Outer glowing ring
      final glowPaint = Paint()
        ..color = AppColors.accentEmeraldLight.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(activeP, 12, glowPaint);

      // Node circle: White center with emerald outer border
      final outerNodePaint = Paint()..color = AppColors.accentEmeraldLight;
      final innerNodePaint = Paint()..color = Colors.white;

      canvas.drawCircle(activeP, 7.0, outerNodePaint);
      canvas.drawCircle(activeP, 4.5, innerNodePaint);

      // Floating Callout Pill above node
      final valStr = data[selectedIndex].value % 1 == 0
          ? data[selectedIndex].value.toInt().toString()
          : data[selectedIndex].value.toStringAsFixed(1);
      final calloutText = unit != null ? '$valStr $unit' : valStr;

      final textSpan = TextSpan(
        text: calloutText,
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.accentEmeraldLight,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      final pillPaddingH = 10.0;
      final pillPaddingV = 5.0;
      final pillWidth = textPainter.width + pillPaddingH * 2;
      final pillHeight = textPainter.height + pillPaddingV * 2;

      double pillX = activeP.dx - pillWidth / 2;
      pillX = pillX.clamp(paddingLeft, size.width - paddingRight - pillWidth);
      final pillY = (activeP.dy - pillHeight - 12).clamp(4.0, size.height - pillHeight);

      final pillRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(pillX, pillY, pillWidth, pillHeight),
        const Radius.circular(12),
      );

      // Draw Callout background
      final pillBgPaint = Paint()
        ..color = AppColors.badgeDarkNavy
        ..style = PaintingStyle.fill;
      canvas.drawRRect(pillRRect, pillBgPaint);

      final pillBorderPaint = Paint()
        ..color = AppColors.accentEmeraldLight.withValues(alpha: 0.5)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      canvas.drawRRect(pillRRect, pillBorderPaint);

      textPainter.paint(
        canvas,
        Offset(pillX + pillPaddingH, pillY + pillPaddingV),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GerexWavePainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.unit != unit;
  }
}
