import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import 'mascot_ai_hub_sheet.dart';

class LiquidGlassNavBarItem {
  final dynamic icon; // IconData, FaIconData, or String (SVG/Image asset path)
  final String label;

  const LiquidGlassNavBarItem({
    required this.icon,
    this.label = '',
  });
}

/// Organic Blob / Metaball Bottom Navigation Bar,
/// featuring 60fps organic Bezier metaball contour morphing,
/// enlarged active tab lobe with inverted brand emerald coloring,
/// center AI mascot hub node, and 100% accessible contrast.
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

class _LiquidGlassNavBarState extends State<LiquidGlassNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _slotAnimation;
  double _currentSlot = 0.0;
  double _targetSlot = 0.0;

  @override
  void initState() {
    super.initState();
    final initialSlot = _mapTabToSlot(widget.currentIndex);
    _currentSlot = initialSlot.toDouble();
    _targetSlot = _currentSlot;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _slotAnimation = AlwaysStoppedAnimation(_currentSlot);
  }

  int _mapTabToSlot(int tabIndex) {
    final safeTab = tabIndex.clamp(0, 3);
    // 5 visual slots:
    // Slot 0: Tab 0 (Workouts)
    // Slot 1: Tab 1 (Explore)
    // Slot 2: Mascot AI Hub Center Action Node
    // Slot 3: Tab 2 (Meals)
    // Slot 4: Tab 3 (Analytics)
    return safeTab < 2 ? safeTab : safeTab + 1;
  }

  @override
  void didUpdateWidget(covariant LiquidGlassNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      final newSlot = _mapTabToSlot(widget.currentIndex).toDouble();
      if (newSlot != _targetSlot) {
        final startSlot = _currentSlot;
        _targetSlot = newSlot;

        _animController.stop();
        _slotAnimation = Tween<double>(
          begin: startSlot,
          end: _targetSlot,
        ).animate(CurvedAnimation(
          parent: _animController,
          curve: Curves.fastOutSlowIn,
        ))..addListener(() {
            setState(() {
              _currentSlot = _slotAnimation.value;
            });
          });

        _animController.forward(from: 0.0);
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    const navBarHeight = 72.0;

    // Organic Metaball container colors
    final barBgColor = isDark
        ? const Color(0xFF0F131F) // Deep obsidian navy
        : const Color(0xFF1E293B); // Sleek slate tone in light mode for maximum organic blob contrast

    final barBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.15)
        : Colors.white.withValues(alpha: 0.22);

    final inactiveIconColor = isDark
        ? Colors.white.withValues(alpha: 0.72)
        : const Color(0xFFCBD5E1); // High contrast crisp light slate

    return SizedBox(
      height: navBarHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          final slotWidth = totalWidth / 5.0;

          // Compute continuous active lobe X position
          final activeLobeCenterX = (_currentSlot + 0.5) * slotWidth;
          const activeLobeRadius = 26.0;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. Organic Bezier Metaball Blob Background Surface
              Positioned.fill(
                child: CustomPaint(
                  painter: OrganicBlobPainter(
                    activeSlotProgress: _currentSlot,
                    bgColor: barBgColor,
                    borderColor: barBorderColor,
                    isDark: isDark,
                  ),
                ),
              ),

              // 2. Enlarged Active Tab Inverted Bubble Indicator (Floating Lobe)
              Positioned(
                left: activeLobeCenterX - activeLobeRadius,
                top: (navBarHeight - activeLobeRadius * 2) / 2.0,
                width: activeLobeRadius * 2,
                height: activeLobeRadius * 2,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.accentEmeraldLight,
                        AppColors.accentEmeraldDeep,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentEmeraldLight.withValues(alpha: 0.50),
                        blurRadius: 16.0,
                        spreadRadius: 1.0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Interactive Touch Slots & Icons Layer
              Positioned.fill(
                child: Row(
                  children: [
                    // Slot 0: Workouts (Tab 0)
                    Expanded(
                      child: _buildSlot(
                        item: widget.items.isNotEmpty ? widget.items[0] : null,
                        isActive: widget.currentIndex == 0,
                        inactiveColor: inactiveIconColor,
                        onTap: () => widget.onTap(0),
                      ),
                    ),

                    // Slot 1: Explore (Tab 1)
                    Expanded(
                      child: _buildSlot(
                        item: widget.items.length > 1 ? widget.items[1] : null,
                        isActive: widget.currentIndex == 1,
                        inactiveColor: inactiveIconColor,
                        onTap: () => widget.onTap(1),
                      ),
                    ),

                    // Slot 2: Mascot AI Hub Center Action Node
                    Expanded(
                      child: _buildCenterMascotNode(context),
                    ),

                    // Slot 3: Meals (Tab 2)
                    Expanded(
                      child: _buildSlot(
                        item: widget.items.length > 2 ? widget.items[2] : null,
                        isActive: widget.currentIndex == 2,
                        inactiveColor: inactiveIconColor,
                        onTap: () => widget.onTap(2),
                      ),
                    ),

                    // Slot 4: Analytics (Tab 3)
                    Expanded(
                      child: _buildSlot(
                        item: widget.items.length > 3 ? widget.items[3] : null,
                        isActive: widget.currentIndex == 3,
                        inactiveColor: inactiveIconColor,
                        onTap: () => widget.onTap(3),
                      ),
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

  Widget _buildSlot({
    required LiquidGlassNavBarItem? item,
    required bool isActive,
    required Color inactiveColor,
    required VoidCallback onTap,
  }) {
    if (item == null) return const SizedBox.shrink();

    // Active item icon gets inverted high-contrast dark green / obsidian color
    final iconColor = isActive ? const Color(0xFF042F2E) : inactiveColor;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedScale(
            scale: isActive ? 1.15 : 1.0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            child: _buildIconWidget(item.icon, iconColor, isActive),
          ),
          if (item.label.isNotEmpty && !isActive) ...[
            const SizedBox(height: 2),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: inactiveColor,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIconWidget(dynamic icon, Color targetColor, bool isActive) {
    final size = isActive ? 22.0 : 18.0;

    if (icon is IconData) {
      return FaIcon(
        icon as FaIconData,
        size: size,
        color: targetColor,
      );
    } else if (icon is String) {
      if (icon.endsWith('.svg')) {
        return SvgPicture.asset(
          icon,
          width: size,
          height: size,
          colorFilter: ColorFilter.mode(targetColor, BlendMode.srcIn),
        );
      } else {
        return Image.asset(
          icon,
          width: size,
          height: size,
          fit: BoxFit.contain,
          color: targetColor,
          colorBlendMode: BlendMode.srcIn,
        );
      }
    }
    return Icon(
      Icons.circle,
      size: size,
      color: targetColor,
    );
  }

  Widget _buildCenterMascotNode(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => MascotAiHubBottomSheet.show(context),
      child: Center(
        child: Container(
          width: 44.0,
          height: 44.0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [
                Color(0xFF8B5CF6), // Vibrant Violet
                Color(0xFFEC4899), // Neon Pink AI Accent
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.50),
                blurRadius: 12.0,
                spreadRadius: 1.0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Center(
            child: FaIcon(
              FontAwesomeIcons.wandMagicSparkles,
              size: 18.0,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom Painter calculating a continuous organic metaball contour
/// with smooth concave Bezier fillets between slot lobes.
class OrganicBlobPainter extends CustomPainter {
  final double activeSlotProgress; // continuous index 0.0 .. 4.0
  final Color bgColor;
  final Color borderColor;
  final bool isDark;

  OrganicBlobPainter({
    required this.activeSlotProgress,
    required this.bgColor,
    required this.borderColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final midY = height / 2.0;
    const numSlots = 5;
    final slotWidth = width / numSlots;

    // Center X of each slot lobe
    final List<double> cx = List.generate(
      numSlots,
      (i) => (i + 0.5) * slotWidth,
    );

    // Calculate dynamic upper & lower radius at each slot center
    final List<double> r = List.generate(numSlots, (i) {
      final distToActive = (i - activeSlotProgress).abs();
      // Active lobe swells to 31.0, inactive is 22.0, center mascot is 25.0
      double baseR = (i == 2) ? 25.0 : 22.0;
      double activeBoost = 9.0 * (1.0 - distToActive.clamp(0.0, 1.0));
      return baseR + activeBoost;
    });

    const bridgeR = 17.5; // Concave valley radius between lobes

    final path = Path();

    // 1. Start at Left Outer Cap (Slot 0 left)
    path.moveTo(cx[0] - r[0], midY);
    // Upper arc around slot 0 left side
    path.cubicTo(
      cx[0] - r[0], midY - r[0] * 0.55,
      cx[0] - r[0] * 0.55, midY - r[0],
      cx[0], midY - r[0],
    );

    // 2. Trace Top Contour through smooth concave Bezier valleys
    for (int i = 0; i < numSlots - 1; i++) {
      final nextI = i + 1;
      final midX = (cx[i] + cx[nextI]) / 2.0;
      final dx = (cx[nextI] - cx[i]) / 2.0;

      // Curve from slot i top peak down to valley midpoint
      path.cubicTo(
        cx[i] + dx * 0.45, midY - r[i],
        midX - dx * 0.45, midY - bridgeR,
        midX, midY - bridgeR,
      );

      // Curve from valley midpoint up to slot i+1 top peak
      path.cubicTo(
        midX + dx * 0.45, midY - bridgeR,
        cx[nextI] - dx * 0.45, midY - r[nextI],
        cx[nextI], midY - r[nextI],
      );
    }

    // 3. Upper Right Cap around slot 4 right side
    path.cubicTo(
      cx[4] + r[4] * 0.55, midY - r[4],
      cx[4] + r[4], midY - r[4] * 0.55,
      cx[4] + r[4], midY,
    );

    // 4. Lower Right Cap
    path.cubicTo(
      cx[4] + r[4], midY + r[4] * 0.55,
      cx[4] + r[4] * 0.55, midY + r[4],
      cx[4], midY + r[4],
    );

    // 5. Trace Bottom Contour back from right to left
    for (int i = numSlots - 1; i > 0; i--) {
      final prevI = i - 1;
      final midX = (cx[i] + cx[prevI]) / 2.0;
      final dx = (cx[i] - cx[prevI]) / 2.0;

      // Curve from slot i bottom peak down/up to valley midpoint
      path.cubicTo(
        cx[i] - dx * 0.45, midY + r[i],
        midX + dx * 0.45, midY + bridgeR,
        midX, midY + bridgeR,
      );

      // Curve from valley midpoint to slot i-1 bottom peak
      path.cubicTo(
        midX - dx * 0.45, midY + bridgeR,
        cx[prevI] + dx * 0.45, midY + r[prevI],
        cx[prevI], midY + r[prevI],
      );
    }

    // 6. Lower Left Cap back to start
    path.cubicTo(
      cx[0] - r[0] * 0.55, midY + r[0],
      cx[0] - r[0], midY + r[0] * 0.55,
      cx[0] - r[0], midY,
    );

    path.close();

    // Draw Drop Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: isDark ? 0.45 : 0.20)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14.0);

    canvas.save();
    canvas.translate(0, 4);
    canvas.drawPath(path, shadowPaint);
    canvas.restore();

    // Draw Main Blob Body
    final bodyPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, bodyPaint);

    // Draw Smooth Border Outline
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant OrganicBlobPainter oldDelegate) {
    return oldDelegate.activeSlotProgress != activeSlotProgress ||
        oldDelegate.bgColor != bgColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.isDark != isDark;
  }
}


