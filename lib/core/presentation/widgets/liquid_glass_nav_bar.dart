import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'mascot_ai_hub_sheet.dart';

class LiquidGlassNavBarItem {
  final dynamic icon; // IconData, FaIconData, or String (SVG/Image asset path)
  final String label;

  const LiquidGlassNavBarItem({
    required this.icon,
    this.label = '',
  });
}

/// Dynamic Frosted Glass Bottom Navigation Bar Dock,
/// featuring adaptive light/dark mode glassmorphism blur,
/// vibrant emerald active pill glow indicator, and crisp 100% visible icons.
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

    const navBarHeight = 64.0;
    const activePillWidth = 52.0;
    const activePillHeight = 40.0;

    // Adaptive Glass colors
    final glassBgColor = isDark
        ? const Color(0xCC151729) // Translucent obsidian navy
        : const Color(0xFDF8FAFC); // Clean frosted white / porcelain

    final glassBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.08);

    final inactiveIconColor = isDark
        ? Colors.white.withValues(alpha: 0.65)
        : const Color(0xFF475569);

    final safeTab = widget.currentIndex.clamp(0, 3);

    return Container(
      height: navBarHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 20.0,
            spreadRadius: 0,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
          child: Container(
            decoration: BoxDecoration(
              color: glassBgColor,
              borderRadius: BorderRadius.circular(32.0),
              border: Border.all(
                color: glassBorderColor,
                width: 1.2,
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final totalWidth = constraints.maxWidth;
                final slotWidth = totalWidth / 5.0;

                // 5 visual slots:
                // Slot 0: Tab 0 (Workouts)
                // Slot 1: Tab 1 (Explore)
                // Slot 2: Mascot AI Hub Center Action
                // Slot 3: Tab 2 (Meals)
                // Slot 4: Tab 3 (Analytics)
                final activeSlotIndex = safeTab < 2 ? safeTab : safeTab + 1;
                final activePillLeft = (activeSlotIndex * slotWidth) + (slotWidth - activePillWidth) / 2.0;
                final activePillTop = (navBarHeight - activePillHeight) / 2.0;

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // 1. Animated Emerald Active Glowing Pill Indicator
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.fastOutSlowIn,
                      left: activePillLeft,
                      top: activePillTop,
                      child: Container(
                        width: activePillWidth,
                        height: activePillHeight,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20.0),
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.accentEmeraldDeep,
                              AppColors.accentEmeraldLight,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accentEmeraldLight.withValues(alpha: 0.45),
                              blurRadius: 12.0,
                              spreadRadius: 1.0,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 2. Interactive Navigation Items Row
                    Row(
                      children: [
                        // Slot 0: Workouts
                        Expanded(
                          child: _buildNavItem(
                            item: widget.items[0],
                            isActive: safeTab == 0,
                            inactiveColor: inactiveIconColor,
                            onTap: () => widget.onTap(0),
                          ),
                        ),

                        // Slot 1: Explore
                        Expanded(
                          child: _buildNavItem(
                            item: widget.items[1],
                            isActive: safeTab == 1,
                            inactiveColor: inactiveIconColor,
                            onTap: () => widget.onTap(1),
                          ),
                        ),

                        // Slot 2: Mascot AI Hub Action Node (Center)
                        Expanded(
                          child: _buildCenterActionNode(context, isDark),
                        ),

                        // Slot 3: Meals
                        Expanded(
                          child: _buildNavItem(
                            item: widget.items[2],
                            isActive: safeTab == 2,
                            inactiveColor: inactiveIconColor,
                            onTap: () => widget.onTap(2),
                          ),
                        ),

                        // Slot 4: Analytics
                        Expanded(
                          child: _buildNavItem(
                            item: widget.items[3],
                            isActive: safeTab == 3,
                            inactiveColor: inactiveIconColor,
                            onTap: () => widget.onTap(3),
                          ),
                        ),
                      ],
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

  Widget _buildNavItem({
    required LiquidGlassNavBarItem item,
    required bool isActive,
    required Color inactiveColor,
    required VoidCallback onTap,
  }) {
    final iconColor = isActive ? Colors.white : inactiveColor;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildIconWidget(item.icon, iconColor, isActive),
          if (item.label.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? Colors.white : inactiveColor,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIconWidget(dynamic icon, Color targetColor, bool isActive) {
    final size = isActive ? 20.0 : 18.0;

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
          colorFilter: ColorFilter.mode(targetColor, BlendMode.srcIn),
        );
      }
    }
    return Icon(
      Icons.circle,
      size: size,
      color: targetColor,
    );
  }

  Widget _buildCenterActionNode(BuildContext context, bool isDark) {
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
                blurRadius: 10.0,
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

