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

/// Organic connected metaball Bottom Navigation Bar widget,
/// matching the exact custom liquid capsule & circle geometry design.
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
    const navBarHeight = 58.0;
    // Sleek solid dark obsidian container color matching reference image exactly
    const navBgColor = Color(0xFF131419);

    return SizedBox(
      height: navBarHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final cx = width / 2;
          const rCenter = 26.0;
          const bridgeInset = 12.0;

          final leftPillEnd = cx - rCenter - bridgeInset;
          final rightPillStart = cx + rCenter + bridgeInset;
          final rightPillWidth = width - rightPillStart;

          // 5 exact node center X positions matching metaball geometry:
          // Node 0: Left pill left item
          // Node 1: Left pill right item
          // Node 2: Center circle node (AI Hub action)
          // Node 3: Right pill left item
          // Node 4: Right pill right item
          final List<double> nodeCenterX = [
            leftPillEnd * 0.32,
            leftPillEnd * 0.72,
            cx,
            rightPillStart + rightPillWidth * 0.28,
            rightPillStart + rightPillWidth * 0.68,
          ];

          // Map active tab (0, 1, 2, 3) to node index (0, 1, 3, 4)
          final safeTab = widget.currentIndex.clamp(0, 3);
          final activeNodeIndex = safeTab == 0
              ? 0
              : safeTab == 1
                  ? 1
                  : safeTab == 2
                      ? 3
                      : 4;

          final activeX = nodeCenterX[activeNodeIndex];

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. Organic Connected Metaball Shape Background
              Positioned.fill(
                child: CustomPaint(
                  painter: _LiquidMetaballPainter(
                    bgColor: navBgColor,
                  ),
                ),
              ),

              // 2. Animated Active White Circular Highlight Pill
              AnimatedPositioned(
                duration: const Duration(milliseconds: 280),
                curve: Curves.fastOutSlowIn,
                left: activeX - 21.0,
                top: (navBarHeight - 42.0) / 2,
                child: Container(
                  width: 42.0,
                  height: 42.0,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Five Interactive Nodes Layer
              Positioned.fill(
                child: Stack(
                  children: [
                    // Node 0: Workouts (Left Pill, Item 0)
                    _buildNodeTapArea(
                      centerX: nodeCenterX[0],
                      navBarHeight: navBarHeight,
                      onTap: () => widget.onTap(0),
                      child: _buildIcon(widget.items[0].icon, isActive: safeTab == 0),
                    ),

                    // Node 1: Explore (Left Pill, Item 1)
                    _buildNodeTapArea(
                      centerX: nodeCenterX[1],
                      navBarHeight: navBarHeight,
                      onTap: () => widget.onTap(1),
                      child: _buildIcon(widget.items[1].icon, isActive: safeTab == 1),
                    ),

                    // Node 2: Center Action Node (Mascot AI Hub)
                    _buildNodeTapArea(
                      centerX: nodeCenterX[2],
                      navBarHeight: navBarHeight,
                      onTap: () => MascotAiHubBottomSheet.show(context),
                      child: const FaIcon(
                        FontAwesomeIcons.arrowsRotate,
                        size: 18.0,
                        color: Colors.white,
                      ),
                    ),

                    // Node 3: Meals (Right Pill, Item 2)
                    _buildNodeTapArea(
                      centerX: nodeCenterX[3],
                      navBarHeight: navBarHeight,
                      onTap: () => widget.onTap(2),
                      child: _buildIcon(widget.items[2].icon, isActive: safeTab == 2),
                    ),

                    // Node 4: Analytics (Right Pill, Item 3)
                    _buildNodeTapArea(
                      centerX: nodeCenterX[4],
                      navBarHeight: navBarHeight,
                      onTap: () => widget.onTap(3),
                      child: _buildIcon(widget.items[3].icon, isActive: safeTab == 3),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNodeTapArea({
    required double centerX,
    required double navBarHeight,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return Positioned(
      left: centerX - 24.0,
      top: 0,
      width: 48.0,
      height: navBarHeight,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(child: child),
      ),
    );
  }

  Widget _buildIcon(dynamic icon, {required bool isActive}) {
    const activeColor = Color(0xFF131419);
    final inactiveColor = Colors.white.withValues(alpha: 0.90);

    if (icon is IconData) {
      return FaIcon(
        icon as FaIconData,
        size: isActive ? 20.0 : 18.0,
        color: isActive ? activeColor : inactiveColor,
      );
    } else if (icon is String) {
      final size = isActive ? 22.0 : 20.0;
      if (icon.endsWith('.svg')) {
        return SvgPicture.asset(
          icon,
          width: size,
          height: size,
          colorFilter: ColorFilter.mode(
            isActive ? activeColor : inactiveColor,
            BlendMode.srcIn,
          ),
        );
      } else {
        // PNG Asset Images: High contrast stencil color filter for 100% visibility
        return Image.asset(
          icon,
          width: size,
          height: size,
          fit: BoxFit.contain,
          colorFilter: ColorFilter.mode(
            isActive ? activeColor : inactiveColor,
            BlendMode.srcIn,
          ),
        );
      }
    }
    return Icon(
      Icons.circle,
      size: 18,
      color: isActive ? activeColor : inactiveColor,
    );
  }
}

/// CustomPainter rendering exact organic connected metaball container with smooth concave waists
class _LiquidMetaballPainter extends CustomPainter {
  final Color bgColor;

  _LiquidMetaballPainter({
    required this.bgColor,
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
      ..color = Colors.black.withValues(alpha: 0.40)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);

    final path = Path();
    final cx = w / 2;
    const rCenter = 26.0; // Center circle node radius
    const bridgeInset = 12.0;

    final leftPillEnd = cx - rCenter - bridgeInset;
    final rightPillStart = cx + rCenter + bridgeInset;

    // Top edge left capsule
    path.moveTo(r, 0);
    path.lineTo(leftPillEnd, 0);

    // Concave waist into top-left center circle
    path.cubicTo(
      cx - rCenter - 2, 0,
      cx - rCenter, h * 0.18,
      cx - rCenter + 2, h * 0.22,
    );

    // Arc over top of center circle
    path.arcToPoint(
      Offset(cx + rCenter - 2, h * 0.22),
      radius: const Radius.circular(rCenter),
      clockwise: true,
    );

    // Concave waist out to top-right pill
    path.cubicTo(
      cx + rCenter, h * 0.18,
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
      cx + rCenter, h * 0.82,
      cx + rCenter - 2, h * 0.78,
    );

    // Arc under bottom of center circle
    path.arcToPoint(
      Offset(cx - rCenter + 2, h * 0.78),
      radius: const Radius.circular(rCenter),
      clockwise: true,
    );

    // Concave waist out to bottom-left pill
    path.cubicTo(
      cx - rCenter, h * 0.82,
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

    // Draw shadow then fill path
    canvas.drawPath(path.shift(const Offset(0, 6)), shadowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LiquidMetaballPainter oldDelegate) {
    return oldDelegate.bgColor != bgColor;
  }
}
