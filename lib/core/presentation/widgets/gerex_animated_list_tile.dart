import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';
import 'gerex_staggered_list_view.dart';

class GerexListTileAction {
  final IconData icon;
  final Color color;
  final String? label;
  final VoidCallback onTap;

  const GerexListTileAction({
    required this.icon,
    required this.color,
    this.label,
    required this.onTap,
  });
}

class GerexAnimatedListTile extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData leadingIcon;
  final int? index;
  final double? progress;
  final Widget? expandedContent;
  final List<GerexListTileAction> actions;
  final VoidCallback? onTap;
  final Widget? leadingWidget; // Optional custom leading widget to preserve image previews

  const GerexAnimatedListTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.leadingIcon,
    this.index,
    this.progress,
    this.expandedContent,
    this.actions = const [],
    this.onTap,
    this.leadingWidget,
  });

  @override
  State<GerexAnimatedListTile> createState() => _GerexAnimatedListTileState();
}

class _GerexAnimatedListTileState extends State<GerexAnimatedListTile>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  
  // Animation Controllers
  late AnimationController _entranceController;
  late AnimationController _pressController;
  late AnimationController _progressController;
  late AnimationController _swipeController;

  // Animations
  late Animation<double> _entranceFade;
  late Animation<double> _entranceSlide;
  late Animation<double> _pressScale;
  late Animation<double> _pressGlow;
  late Animation<double> _progressAnimation;

  // Gesture/Swipe States
  double _dragOffset = 0.0;
  bool _isPressed = false;
  bool _isExpanded = false;
  bool _isEntranceTriggered = false;

  // Cache actions size
  final double _actionButtonWidth = 72.0;
  double get _maxSwipeWidth => widget.actions.length * _actionButtonWidth;

  @override
  bool get wantKeepAlive => true; // Keep alive during scrolls to prevent animation restarts

  @override
  void initState() {
    super.initState();

    // 1. Entrance Animation Set Up
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    _entranceFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );

    _entranceSlide = Tween<double>(begin: 24.0, end: 0.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );

    // 2. Press Feedback Scale / Glow Set Up
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

    _pressScale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOut),
    );

    _pressGlow = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOut),
    );

    // 3. Progress Ring Animation Set Up
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: widget.progress ?? 0.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
    );

    // 4. Swipe controller for snapping transitions
    _swipeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    if (widget.progress != null) {
      _progressController.forward();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isEntranceTriggered) {
      _isEntranceTriggered = true;
      _triggerStaggeredEntrance();
    }
  }

  void _triggerStaggeredEntrance() {
    // Respect system reduced motion settings
    final contextMobile = context;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(contextMobile) ?? false;
    if (reduceMotion) {
      _entranceController.value = 1.0;
      return;
    }

    // Resolve index from provider if null
    final resolvedIndex = widget.index ?? StaggerIndexProvider.of(context) ?? 0;
    final delay = (resolvedIndex * 60).clamp(0, 600);

    Future.delayed(Duration(milliseconds: delay), () {
      if (mounted) {
        _entranceController.forward();
      }
    });
  }

  @override
  void didUpdateWidget(covariant GerexAnimatedListTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress && widget.progress != null) {
      _progressAnimation = Tween<double>(
        begin: _progressAnimation.value,
        end: widget.progress!,
      ).animate(
        CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
      );
      _progressController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _pressController.dispose();
    _progressController.dispose();
    _swipeController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    setState(() => _isPressed = true);
    _pressController.forward();
  }

  void _onTapUp(TapUpDetails _) {
    setState(() => _isPressed = false);
    _pressController.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _pressController.reverse();
  }

  // Handle Swipe Reveal Logic
  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (widget.actions.isEmpty) return;
    setState(() {
      _dragOffset = (_dragOffset + details.delta.dx).clamp(-_maxSwipeWidth, 0.0);
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (widget.actions.isEmpty) return;
    
    final halfPoint = -_maxSwipeWidth / 2;
    final targetOffset = _dragOffset < halfPoint ? -_maxSwipeWidth : 0.0;

    final startOffset = _dragOffset;
    final tween = Tween<double>(begin: startOffset, end: targetOffset);

    _swipeController.stop();
    _swipeController.reset();
    
    final Animation<double> animation = tween.animate(
      CurvedAnimation(parent: _swipeController, curve: Curves.easeOut),
    );

    animation.addListener(() {
      setState(() {
        _dragOffset = animation.value;
      });
    });

    _swipeController.forward();
  }

  void _toggleExpand() {
    if (widget.expandedContent == null) return;
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Outer Border Glow / Emerald Outline based on press state
    final glowColor = AppColors.accentEmeraldLight.withValues(alpha: 0.4);
    final defaultBorderColor = isDark
        ? AppColors.cardDarkGlass.withValues(alpha: 0.4)
        : Colors.white.withValues(alpha: 0.3);

    return AnimatedBuilder(
      animation: Listenable.merge([_entranceController, _pressController]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _entranceSlide.value),
          child: Opacity(
            opacity: _entranceFade.value,
            child: Transform.scale(
              scale: _pressScale.value,
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: _isPressed
                      ? [
                          BoxShadow(
                            color: glowColor,
                            blurRadius: 16 * _pressGlow.value,
                            spreadRadius: 2 * _pressGlow.value,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : [],
                ),
                child: child,
              ),
            ),
          ),
        );
      },
      child: Stack(
        clipBehavior: Clip.antiAlias,
        children: [
          // Background Swipe Actions Panel
          if (widget.actions.isNotEmpty)
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: widget.actions.map((act) {
                    return GestureDetector(
                      onTap: () {
                        act.onTap();
                        // Auto-close actions on tap
                        _onHorizontalDragEnd(DragEndDetails());
                      },
                      child: Container(
                        width: _actionButtonWidth,
                        height: double.infinity,
                        color: act.color,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(act.icon, color: Colors.white, size: 20),
                            if (act.label != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                act.label!,
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

          // Foreground Sliding Card Container
          GestureDetector(
            onHorizontalDragUpdate: _onHorizontalDragUpdate,
            onHorizontalDragEnd: _onHorizontalDragEnd,
            onTapDown: widget.onTap != null ? _onTapDown : null,
            onTapUp: widget.onTap != null ? _onTapUp : null,
            onTapCancel: widget.onTap != null ? _onTapCancel : null,
            onTap: widget.onTap,
            child: Transform.translate(
              offset: Offset(_dragOffset, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: isDark ? GerexGradients.darkGlassCard : null,
                      color: isDark ? null : Colors.white.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _isPressed
                            ? AppColors.accentEmeraldLight
                            : defaultBorderColor,
                        width: _isPressed ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Main ListTile contents
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                          child: Row(
                            children: [
                              // Leading Icon / Widget with Progress Ring
                              _buildLeading(theme),
                              const SizedBox(width: 16),

                              // Title + Subtitle
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.title,
                                      style: GoogleFonts.outfit(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? AppColors.textDarkHeading : AppColors.textLightHeading,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      widget.subtitle,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: isDark ? AppColors.textDarkMuted : AppColors.textLightBody.withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Expand Chevron or Spacer
                              if (widget.expandedContent != null)
                                GestureDetector(
                                  onTap: _toggleExpand,
                                  child: AnimatedRotation(
                                    turns: _isExpanded ? 0.5 : 0.0,
                                    duration: const Duration(milliseconds: 280),
                                    curve: Curves.easeOutCubic,
                                    child: const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: AppColors.accentEmeraldLight,
                                      size: 24,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Expandable body content
                        if (widget.expandedContent != null)
                          AnimatedSize(
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeOutCubic,
                            child: _isExpanded
                                ? Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      border: Border(
                                        top: BorderSide(
                                          color: defaultBorderColor,
                                          width: 0.5,
                                        ),
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(16.0),
                                    child: widget.expandedContent,
                                  )
                                : const SizedBox(width: double.infinity, height: 0),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeading(ThemeData theme) {
    // If a custom leading widget (like an image) is provided, render it.
    final hasProgress = widget.progress != null;

    final leadingContent = widget.leadingWidget ??
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.cardDarkGlass.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              widget.leadingIcon,
              color: AppColors.accentEmeraldLight,
              size: 20,
            ),
          ),
        );

    if (!hasProgress) return leadingContent;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Animated Progress Ring behind/around leading icon
        AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, _) {
            return SizedBox(
              width: 52,
              height: 52,
              child: CircularProgressIndicator(
                value: _progressAnimation.value,
                strokeWidth: 2.5,
                backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.1),
                color: AppColors.accentEmeraldLight,
              ),
            );
          },
        ),
        leadingContent,
      ],
    );
  }
}
