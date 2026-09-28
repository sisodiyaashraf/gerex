import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'mascot_ai_hub_sheet.dart';

class LiquidGlassNavBarItem {
  final dynamic icon; // IconData, FaIconData, or String (SVG/Image asset path)
  final String label;

  const LiquidGlassNavBarItem({
    required this.icon,
    this.label = '',
  });
}

/// OrganicConnected liquid metaball Bottom Navigation Bar widget,
/// matching the custom fluid capsule & circle geometry design.
class LiquidGlassNavBar extends StatefulWidget {
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
  State<LiquidGlassNavBar> createState() => _LiquidGlassNavBarState();
}

class _LiquidGlassNavBarState extends State<LiquidGlassNavBar> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    const navBarHeight = 62.0;
    // Sleek dark organic container color matching reference image
    final navBgColor = isDark ? const Color(0xFF12141C) : const Color(0xFF1E222D);

    return SizedBox(
      height: navBarHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final itemCount = widget.items.length;

          // Compute exact horizontal center for each nav item
          final List<double> itemCenterXList = [];
          double centerNodeX = width / 2;

          if (itemCount == 4) {
            final leftPillWidth = centerNodeX - 30.0;
            final rightPillStart = centerNodeX + 30.0;

            itemCenterXList.add(leftPillWidth * 0.32);
            itemCenterXList.add(leftPillWidth * 0.72);
            itemCenterXList.add(rightPillStart + (width - rightPillStart) * 0.28);
            itemCenterXList.add(rightPillStart + (width - rightPillStart) * 0.68);
          } else if (itemCount == 5) {
            final leftPillWidth = centerNodeX - 30.0;
            final rightPillStart = centerNodeX + 30.0;

            itemCenterXList.add(leftPillWidth * 0.30);
            itemCenterXList.add(leftPillWidth * 0.75);
            itemCenterXList.add(centerNodeX);
            itemCenterXList.add(rightPillStart + (width - rightPillStart) * 0.25);
            itemCenterXList.add(rightPillStart + (width - rightPillStart) * 0.70);
          } else {
            final segWidth = width / itemCount;
            for (int i = 0; i < itemCount; i++) {
              itemCenterXList.add(segWidth * i + segWidth / 2);
            }
          }

          final safeIndex = widget.currentIndex.clamp(0, itemCount - 1);
          final activeX = itemCenterXList.isNotEmpty ? itemCenterXList[safeIndex] : 0.0;

          return Stack(
            children: [
              // 1. Organic Connected Metaball Shape Background
              Positioned.fill(
                child: CustomPaint(
                  painter: _LiquidMetaballPainter(
                    bgColor: navBgColor,
                    itemCount: itemCount,
                  ),
                ),
              ),

              // 2. Animated Active White Circular Highlight Pill
              AnimatedPositioned(
                duration: const Duration(milliseconds: 280),
                curve: Curves.fastOutSlowIn,
                left: activeX - 22.0,
                top: (navBarHeight - 44.0) / 2,
                child: Container(
                  width: 44.0,
                  height: 44.0,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.28),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Tap Target Icons
              Positioned.fill(
                child: itemCount == 4
                    ? Stack(
                        children: [
                          // Left Pill Items (0 & 1)
                          Positioned(
                            left: 0,
                            top: 0,
                            bottom: 0,
                            width: centerNodeX - 30.0,
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () => widget.onTap(0),
                                    child: Center(
                                      child: _buildItemIcon(widget.items[0].icon, isActive: widget.currentIndex == 0),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () => widget.onTap(1),
                                    child: Center(
                                      child: _buildItemIcon(widget.items[1].icon, isActive: widget.currentIndex == 1),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Center Node Action (AI Mascot Hub)
                          Positioned(
                            left: centerNodeX - 22.0,
                            top: (navBarHeight - 44.0) / 2,
                            width: 44.0,
                            height: 44.0,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => MascotAiHubBottomSheet.show(context),
                              child: const Center(
                                child: FaIcon(
                                  FontAwesomeIcons.arrowsRotate,
                                  size: 17.0,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),

                          // Right Pill Items (2 & 3)
                          Positioned(
                            left: centerNodeX + 30.0,
                            top: 0,
                            bottom: 0,
                            right: 0,
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () => widget.onTap(2),
                                    child: Center(
                                      child: _buildItemIcon(widget.items[2].icon, isActive: widget.currentIndex == 2),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () => widget.onTap(3),
                                    child: Center(
                                      child: _buildItemIcon(widget.items[3].icon, isActive: widget.currentIndex == 3),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: List.generate(itemCount, (idx) {
                          final item = widget.items[idx];
                          final isActive = widget.currentIndex == idx;

                          return Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => widget.onTap(idx),
                              child: Center(
                                child: _buildItemIcon(
                                  item.icon,
                                  isActive: isActive,
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
    );
  }

  Widget _buildItemIcon(dynamic icon, {required bool isActive}) {
    final color = isActive ? const Color(0xFF12141C) : Colors.white.withValues(alpha: 0.90);

    if (icon is IconData) {
      return FaIcon(
        icon as FaIconData,
        size: isActive ? 20.0 : 18.0,
        color: color,
      );
    } else if (icon is String) {
      if (icon.endsWith('.svg')) {
        return SvgPicture.asset(
          icon,
          width: isActive ? 24.0 : 22.0,
          height: isActive ? 24.0 : 22.0,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        );
      } else {
        // PNG Asset Images (explore_icon.png, meal_icon.png, analytics_icon.png)
        // Render original artwork with 100% detail and visibility without tinting!
        return Opacity(
          opacity: isActive ? 1.0 : 0.85,
          child: Image.asset(
            icon,
            width: isActive ? 26.0 : 24.0,
            height: isActive ? 26.0 : 24.0,
            fit: BoxFit.contain,
          ),
        );
      }
    }
    return Icon(Icons.circle, size: 18, color: color);
  }
}

/// CustomPainter rendering connected metaball liquid container with smooth concave waist curves
class _LiquidMetaballPainter extends CustomPainter {
  final Color bgColor;
  final int itemCount;

  _LiquidMetaballPainter({
    required this.bgColor,
    required this.itemCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final r = h / 2;

    final paint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    final path = Path();

    if (itemCount >= 4) {
      final cx = w / 2;
      const rCenter = 27.0; // Center circle node radius
      const bridgeInset = 14.0;

      final leftPillEnd = cx - rCenter - bridgeInset;
      final rightPillStart = cx + rCenter + bridgeInset;

      // Top edge left capsule
      path.moveTo(r, 0);
      path.lineTo(leftPillEnd, 0);

      // Concave waist into top-left center circle
      path.cubicTo(
        cx - rCenter - 2, 0,
        cx - rCenter, h * 0.20,
        cx - rCenter + 2, h * 0.24,
      );

      // Arc over top of center circle
      path.arcToPoint(
        Offset(cx + rCenter - 2, h * 0.24),
        radius: const Radius.circular(rCenter),
        clockwise: true,
      );

      // Concave waist out to top-right pill
      path.cubicTo(
        cx + rCenter, h * 0.20,
        cx + rCenter + 2, 0,
        rightPillStart, 0,
      );

      // Top edge right capsule
      path.lineTo(w - r, 0);

      // Right cap arc
      path.arcToPoint(
        Offset(w - r, h),
        radius: Radius.circular(r),
        clockwise: true,
      );

      // Bottom edge right capsule
      path.lineTo(rightPillStart, h);

      // Concave waist into bottom-right center circle
      path.cubicTo(
        cx + rCenter + 2, h,
        cx + rCenter, h * 0.80,
        cx + rCenter - 2, h * 0.76,
      );

      // Arc under bottom of center circle
      path.arcToPoint(
        Offset(cx - rCenter + 2, h * 0.76),
        radius: const Radius.circular(rCenter),
        clockwise: true,
      );

      // Concave waist out to bottom-left pill
      path.cubicTo(
        cx - rCenter, h * 0.80,
        cx - rCenter - 2, h,
        leftPillEnd, h,
      );

      // Bottom edge left capsule
      path.lineTo(r, h);

      // Left cap arc
      path.arcToPoint(
        Offset(r, 0),
        radius: Radius.circular(r),
        clockwise: true,
      );

      path.close();
    } else {
      path.addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, w, h),
        Radius.circular(r),
      ));
    }

    // Draw shadow then fill path
    canvas.drawPath(path.shift(const Offset(0, 6)), shadowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LiquidMetaballPainter oldDelegate) {
    return oldDelegate.bgColor != bgColor || oldDelegate.itemCount != itemCount;
  }
}
