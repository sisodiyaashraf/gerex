import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LiquidGlassNavBarItem {
  final dynamic icon; // Can be IconData or String (SVG path)
  final String label;

  const LiquidGlassNavBarItem({
    required this.icon,
    required this.label,
  });
}

class BouncingIcon extends StatefulWidget {
  final Widget child;
  final bool isActive;

  const BouncingIcon({
    super.key,
    required this.child,
    required this.isActive,
  });

  @override
  State<BouncingIcon> createState() => _BouncingIconState();
}

class _BouncingIconState extends State<BouncingIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.25)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.25, end: 1.0)
            .chain(CurveTween(curve: Curves.bounceOut)),
        weight: 60,
      ),
    ]).animate(_controller);

    if (widget.isActive) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant BouncingIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: widget.child,
    );
  }
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

    // Premium dual-color linear gradient backgrounds
    final barBgGradient = isDark
        ? LinearGradient(
            colors: [
              const Color(0xFF12132A).withValues(alpha: 0.95),
              const Color(0xFF1E2142).withValues(alpha: 0.95),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : LinearGradient(
            colors: [
              const Color(0xFFFFFFFF).withValues(alpha: 0.95),
              const Color(0xFFE2E8F0).withValues(alpha: 0.95),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.08);

    final activePillGradient = _getActivePillGradient(currentIndex, isDark);
    final activeShadowColor = _getActiveShadowColor(currentIndex);

    return Container(
      height: 72, // Sleeker height
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
          child: Container(
            decoration: BoxDecoration(
              gradient: barBgGradient,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: borderColor, width: 1.0),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final segmentWidth = constraints.maxWidth / items.length;
                // Active pill geometry: sitting with 7dp margin top/bottom and 8dp margin left/right
                final activeWidth = segmentWidth - 16;
                final activeLeft = (segmentWidth * currentIndex) + 8;

                return Stack(
                  children: [
                    // Sliding & Morphing Active Indicator
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      left: activeLeft,
                      top: 7,
                      width: activeWidth,
                      height: 58, // 72 - 14
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: activePillGradient,
                          boxShadow: [
                            BoxShadow(
                              color: activeShadowColor.withValues(alpha: isDark ? 0.35 : 0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Tab buttons
                    Positioned.fill(
                      child: Row(
                        children: List.generate(items.length, (idx) {
                          final item = items[idx];
                          final isActive = currentIndex == idx;

                          final labelColor = isActive
                              ? Colors.white
                              : (isDark
                                  ? const Color(0xFFE2E8F0).withValues(alpha: 0.85)
                                  : const Color(0xFF475569).withValues(alpha: 0.85));

                          return Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => onTap(idx),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  BouncingIcon(
                                    isActive: isActive,
                                    child: _buildIcon(item.icon, isActive, isDark),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    item.label,
                                    style: TextStyle(
                                      color: labelColor,
                                      fontSize: 10.5,
                                      fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                                      letterSpacing: 0.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
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

  LinearGradient _getActivePillGradient(int index, bool isDark) {
    switch (index) {
      case 0: // Workouts - Green/Emerald
        return isDark
            ? const LinearGradient(
                colors: [Color(0xFF178C6D), Color(0xFF50C19D)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : const LinearGradient(
                colors: [Color(0xFF178C6D), Color(0xFF3CA987)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              );
      case 1: // Explore - Indigo/Violet
        return const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        );
      case 2: // Meals - Sunset/Amber/Coral
        return const LinearGradient(
          colors: [Color(0xFFD97706), Color(0xFFDC2626)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        );
      case 3: // Analytics - Sky/Royal Blue
      default:
        return const LinearGradient(
          colors: [Color(0xFF0284C7), Color(0xFF2563EB)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        );
    }
  }

  Color _getActiveShadowColor(int index) {
    switch (index) {
      case 0:
        return const Color(0xFF10B981);
      case 1:
        return const Color(0xFF8B5CF6);
      case 2:
        return const Color(0xFFF59E0B);
      case 3:
      default:
        return const Color(0xFF0EA5E9);
    }
  }

  Widget _buildIcon(dynamic iconData, bool isActive, bool isDark) {
    final Color color = isActive
        ? Colors.white
        : (isDark
            ? const Color(0xFFE2E8F0).withValues(alpha: 0.85)
            : const Color(0xFF475569).withValues(alpha: 0.85));

    if (iconData is String) {
      return SvgPicture.asset(
        iconData,
        width: 20,
        height: 20,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      );
    } else if (iconData is IconData) {
      return Icon(
        iconData,
        size: 20,
        color: color,
      );
    }
    return const SizedBox.shrink();
  }
}
