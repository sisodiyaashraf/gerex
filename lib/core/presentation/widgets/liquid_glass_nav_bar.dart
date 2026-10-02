import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';

class LiquidGlassNavBarItem {
  final dynamic icon; // IconData, FaIconData, or String (SVG/Image asset path)
  final String label;

  const LiquidGlassNavBarItem({
    required this.icon,
    this.label = '',
  });
}

class SpeedDialOption {
  final String id;
  final String title;
  final dynamic icon; // IconData or FaIconData
  final List<Color> gradient;
  final VoidCallback onTap;

  const SpeedDialOption({
    required this.id,
    required this.title,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });
}

/// Organic Blob / Metaball Bottom Navigation Bar,
/// featuring 60fps organic Bezier metaball contour morphing,
/// enlarged active tab lobe with inverted brand emerald coloring,
/// and center AI hub vertical speed-dial expansion overlay.
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
    with TickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _slotAnimation;
  double _currentSlot = 0.0;
  double _targetSlot = 0.0;

  // Speed Dial Overlay State
  final GlobalKey _centerHubKey = GlobalKey();
  OverlayEntry? _speedDialOverlayEntry;
  late AnimationController _speedDialAnimController;
  late Animation<double> _scrimFadeAnimation;
  late Animation<double> _hubRotationAnimation;
  late List<Animation<double>> _scaleAnimations;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _slideAnimations;
  bool _isSpeedDialOpen = false;

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

    // Speed Dial Animation Controller (360ms staggered expansion)
    _speedDialAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );

    _scrimFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _speedDialAnimController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _hubRotationAnimation = Tween<double>(begin: 0.0, end: 0.25).animate(
      CurvedAnimation(
        parent: _speedDialAnimController,
        curve: Curves.easeInOutCubic,
      ),
    );

    _initStaggeredAnimations(4);
  }

  void _initStaggeredAnimations(int count) {
    _scaleAnimations = [];
    _fadeAnimations = [];
    _slideAnimations = [];

    for (int i = 0; i < count; i++) {
      // Stagger start: each button enters ~50ms (0.12 normalized) after the previous
      final start = (i * 0.12).clamp(0.0, 0.55);
      final end = (start + 0.45).clamp(0.3, 1.0);

      _scaleAnimations.add(
        Tween<double>(begin: 0.3, end: 1.0).animate(
          CurvedAnimation(
            parent: _speedDialAnimController,
            curve: Interval(start, end, curve: Curves.easeOutBack),
          ),
        ),
      );

      _fadeAnimations.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _speedDialAnimController,
            curve: Interval(start, end, curve: Curves.easeOut),
          ),
        ),
      );

      _slideAnimations.add(
        Tween<Offset>(
          begin: const Offset(0.0, 0.4),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _speedDialAnimController,
            curve: Interval(start, end, curve: Curves.easeOutCubic),
          ),
        ),
      );
    }
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

  void _toggleSpeedDial(BuildContext context) {
    if (_isSpeedDialOpen) {
      _collapseSpeedDial();
    } else {
      _expandSpeedDial(context);
    }
  }

  void _expandSpeedDial(BuildContext context) {
    if (_isSpeedDialOpen) return;

    final renderBox = _centerHubKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final hubOffset = renderBox.localToGlobal(Offset.zero);
    final hubSize = renderBox.size;
    final hubCenter = Offset(
      hubOffset.dx + hubSize.width / 2.0,
      hubOffset.dy + hubSize.height / 2.0,
    );

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final options = [
      SpeedDialOption(
        id: 'home',
        title: 'Home Dashboard',
        icon: FontAwesomeIcons.house,
        gradient: const [Color(0xFF10B981), Color(0xFF059669)],
        onTap: () => widget.onTap(0),
      ),
      SpeedDialOption(
        id: 'chat',
        title: 'AI Coach Chat',
        icon: FontAwesomeIcons.robot,
        gradient: const [Color(0xFF6366F1), Color(0xFF4F46E5)],
        onTap: () => context.push('/coach'),
      ),
      SpeedDialOption(
        id: 'plan',
        title: 'AI Suggestions',
        icon: FontAwesomeIcons.wandMagicSparkles,
        gradient: const [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
        onTap: () => context.push('/ai-plan'),
      ),
      SpeedDialOption(
        id: 'diet',
        title: 'Diet & Meal Planner',
        icon: FontAwesomeIcons.utensils,
        gradient: const [Color(0xFFD97706), Color(0xFFDC2626)],
        onTap: () => widget.onTap(2),
      ),
    ];

    _speedDialOverlayEntry = OverlayEntry(
      builder: (overlayContext) {
        final screenHeight = MediaQuery.of(overlayContext).size.height;
        final bottomOffset = screenHeight - hubCenter.dy + 32.0;

        return Stack(
          children: [
            // 1. Fullscreen Dim Scrim Backdrop
            Positioned.fill(
              child: GestureDetector(
                onTap: _collapseSpeedDial,
                behavior: HitTestBehavior.opaque,
                child: FadeTransition(
                  opacity: _scrimFadeAnimation,
                  child: Container(
                    color: Colors.black.withValues(alpha: isDark ? 0.55 : 0.40),
                  ),
                ),
              ),
            ),

            // 2. Vertical Speed-Dial Stacked Option Column
            Positioned(
              bottom: bottomOffset,
              left: 0,
              right: 0,
              child: Material(
                type: MaterialType.transparency,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      for (int i = options.length - 1; i >= 0; i--)
                        _buildOptionRow(options[i], i, isDark),
                    ],
                  ),
                ),
              ),
            ),

            // 3. Pinned Center Hub Morphing Action Node
            Positioned(
              left: hubCenter.dx - (hubSize.width / 2.0),
              top: hubCenter.dy - (hubSize.height / 2.0),
              width: hubSize.width,
              height: hubSize.height,
              child: GestureDetector(
                onTap: _collapseSpeedDial,
                behavior: HitTestBehavior.opaque,
                child: RotationTransition(
                  turns: _hubRotationAnimation,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF8B5CF6),
                          Color(0xFFEC4899),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.65),
                          blurRadius: 16.0,
                          spreadRadius: 2.0,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: FaIcon(
                        FontAwesomeIcons.xmark,
                        size: 20.0,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_speedDialOverlayEntry!);
    setState(() {
      _isSpeedDialOpen = true;
    });
    _speedDialAnimController.forward(from: 0.0);
  }

  void _collapseSpeedDial() {
    if (!_isSpeedDialOpen) return;

    _speedDialAnimController.reverse().then((_) {
      _speedDialOverlayEntry?.remove();
      _speedDialOverlayEntry = null;
      if (mounted) {
        setState(() {
          _isSpeedDialOpen = false;
        });
      }
    });
  }

  Widget _buildOptionRow(SpeedDialOption option, int index, bool isDark) {
    final barBgColor = isDark
        ? const Color(0xFF0F131F)
        : const Color(0xFF1E293B);

    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.18)
        : Colors.white.withValues(alpha: 0.25);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: SlideTransition(
        position: _slideAnimations[index],
        child: FadeTransition(
          opacity: _fadeAnimations[index],
          child: ScaleTransition(
            scale: _scaleAnimations[index],
            alignment: Alignment.bottomCenter,
            child: InkWell(
              onTap: () {
                _collapseSpeedDial();
                option.onTap();
              },
              borderRadius: BorderRadius.circular(28),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Label Glass Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: barBgColor.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderColor, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.30),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      option.title,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Option Circular Lobe
                  Container(
                    width: 44.0,
                    height: 44.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: option.gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.35),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: option.gradient.first.withValues(alpha: 0.50),
                          blurRadius: 10.0,
                          spreadRadius: 1.0,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: _buildIconWidget(option.icon, Colors.white, true),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _collapseSpeedDial();
    _animController.dispose();
    _speedDialAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    const navBarHeight = 84.0;

    // Organic Metaball container colors
    final barBgColor = isDark
        ? const Color(0xFF0F131F) // Deep obsidian navy
        : const Color(0xFF1E293B); // Sleek slate tone in light mode

    final barBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.15)
        : Colors.white.withValues(alpha: 0.22);

    final inactiveIconColor = isDark
        ? Colors.white.withValues(alpha: 0.72)
        : const Color(0xFFCBD5E1);

    return SizedBox(
      height: navBarHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          final slotWidth = totalWidth / 5.0;

          // Compute continuous active lobe X position
          final activeLobeCenterX = (_currentSlot + 0.5) * slotWidth;
          const activeLobeRadius = 26.5;

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
            const SizedBox(height: 2.5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  item.label.trim(),
                  maxLines: 1,
                  style: GoogleFonts.inter(
                    fontSize: 10.0,
                    fontWeight: FontWeight.w600,
                    color: inactiveColor,
                    letterSpacing: 0.0,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIconWidget(dynamic icon, Color targetColor, bool isActive) {
    final size = isActive ? 23.5 : 21.0;

    if (icon is IconData) {
      if (icon is FaIconData) {
        return FaIcon(
          icon as FaIconData,
          size: size,
          color: targetColor,
        );
      }
      return Icon(
        icon,
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
      key: _centerHubKey,
      behavior: HitTestBehavior.opaque,
      onTap: () => _toggleSpeedDial(context),
      child: Center(
        child: AnimatedRotation(
          turns: _isSpeedDialOpen ? 0.25 : 0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          child: Container(
            width: 46.0,
            height: 46.0,
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
            child: Center(
              child: FaIcon(
                _isSpeedDialOpen ? FontAwesomeIcons.xmark : FontAwesomeIcons.wandMagicSparkles,
                size: 19.0,
                color: Colors.white,
              ),
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

    final List<double> cx = List.generate(
      numSlots,
      (i) => (i + 0.5) * slotWidth,
    );

    final List<double> r = List.generate(numSlots, (i) {
      final distToActive = (i - activeSlotProgress).abs();
      double baseR = (i == 2) ? 31.0 : 29.5;
      double activeBoost = 5.5 * (1.0 - distToActive.clamp(0.0, 1.0));
      return baseR + activeBoost;
    });

    const bridgeR = 23.5;
    const kCircle = 0.5522847;

    final path = Path();
    final r0 = r[0];
    final r4 = r[4];

    path.moveTo(cx[0] - r0, midY);
    path.cubicTo(
      cx[0] - r0, midY - r0 * kCircle,
      cx[0] - r0 * kCircle, midY - r0,
      cx[0], midY - r0,
    );

    for (int i = 0; i < numSlots - 1; i++) {
      final nextI = i + 1;
      final midX = (cx[i] + cx[nextI]) / 2.0;
      final dx = (cx[nextI] - cx[i]) / 2.0;

      path.cubicTo(
        cx[i] + dx * 0.45, midY - r[i],
        midX - dx * 0.45, midY - bridgeR,
        midX, midY - bridgeR,
      );

      path.cubicTo(
        midX + dx * 0.45, midY - bridgeR,
        cx[nextI] - dx * 0.45, midY - r[nextI],
        cx[nextI], midY - r[nextI],
      );
    }

    path.cubicTo(
      cx[4] + r4 * kCircle, midY - r4,
      cx[4] + r4, midY - r4 * kCircle,
      cx[4] + r4, midY,
    );

    path.cubicTo(
      cx[4] + r4, midY + r4 * kCircle,
      cx[4] + r4 * kCircle, midY + r4,
      cx[4], midY + r4,
    );

    for (int i = numSlots - 1; i > 0; i--) {
      final prevI = i - 1;
      final midX = (cx[i] + cx[prevI]) / 2.0;
      final dx = (cx[i] - cx[prevI]) / 2.0;

      path.cubicTo(
        cx[i] - dx * 0.45, midY + r[i],
        midX + dx * 0.45, midY + bridgeR,
        midX, midY + bridgeR,
      );

      path.cubicTo(
        midX - dx * 0.45, midY + bridgeR,
        cx[prevI] + dx * 0.45, midY + r[prevI],
        cx[prevI], midY + r[prevI],
      );
    }

    path.cubicTo(
      cx[0] - r0 * kCircle, midY + r0,
      cx[0] - r0, midY + r0 * kCircle,
      cx[0] - r0, midY,
    );

    path.close();

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: isDark ? 0.45 : 0.20)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14.0);

    canvas.save();
    canvas.translate(0, 4);
    canvas.drawPath(path, shadowPaint);
    canvas.restore();

    final bodyPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, bodyPaint);

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
