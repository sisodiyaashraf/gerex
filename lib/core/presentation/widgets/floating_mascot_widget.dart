import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/mascot_controller.dart';
import 'mascot_ai_hub_sheet.dart';

typedef RobotMascot = FloatingMascotWidget;

/// Transform-driven Robot Mascot Widget positioned along the top edge of the bottom nav bar.
/// Uses Flutter animation primitives (translate, footstep cadence bobbing, scale breathing,
/// direction flipping, and fade transitions) on high-resolution single static PNG assets.
class FloatingMascotWidget extends StatefulWidget {
  final VoidCallback? onSelectMealTab;

  const FloatingMascotWidget({
    super.key,
    this.onSelectMealTab,
  });

  @override
  State<FloatingMascotWidget> createState() => _FloatingMascotWidgetState();
}

class _FloatingMascotWidgetState extends State<FloatingMascotWidget>
    with TickerProviderStateMixin {
  late final AnimationController _horizontalController;
  late final AnimationController _idleBobController;
  late final AnimationController _footstepBobController;

  late final Animation<double> _idleBobAnimation;
  late final Animation<double> _idleScaleAnimation;
  late final Animation<double> _footstepBobAnimation;

  bool _isFacingRight = true;
  double _lastHorizontalValue = 0.0;

  @override
  void initState() {
    super.initState();

    // 1. Horizontal movement controller across the track
    _horizontalController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    );

    _horizontalController.addListener(() {
      final currentValue = _horizontalController.value;
      if (currentValue > _lastHorizontalValue) {
        if (!_isFacingRight) {
          setState(() {
            _isFacingRight = true;
          });
        }
      } else if (currentValue < _lastHorizontalValue) {
        if (_isFacingRight) {
          setState(() {
            _isFacingRight = false;
          });
        }
      }
      _lastHorizontalValue = currentValue;
    });

    _horizontalController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _horizontalController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _horizontalController.forward();
      }
    });

    // 2. Idle vertical bobbing & breathing pulse
    _idleBobController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _idleBobAnimation = Tween<double>(begin: 0.0, end: -4.0).animate(
      CurvedAnimation(parent: _idleBobController, curve: Curves.easeInOut),
    );

    _idleScaleAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _idleBobController, curve: Curves.easeInOut),
    );

    // 3. Footstep cadence bobbing during walk/run
    _footstepBobController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _footstepBobAnimation = Tween<double>(begin: 0.0, end: -5.0).animate(
      CurvedAnimation(parent: _footstepBobController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    _idleBobController.dispose();
    _footstepBobController.dispose();
    super.dispose();
  }

  void _updateAnimationStates(MascotState state) {
    switch (state) {
      case MascotState.walking:
        if (_horizontalController.duration != const Duration(milliseconds: 3400)) {
          _horizontalController.duration = const Duration(milliseconds: 3400);
        }
        if (!_horizontalController.isAnimating) {
          _horizontalController.forward(from: _horizontalController.value);
        }
        if (_footstepBobController.duration != const Duration(milliseconds: 400)) {
          _footstepBobController.duration = const Duration(milliseconds: 400);
          _footstepBobController.repeat(reverse: true);
        } else if (!_footstepBobController.isAnimating) {
          _footstepBobController.repeat(reverse: true);
        }
        break;

      case MascotState.running:
        if (_horizontalController.duration != const Duration(milliseconds: 1600)) {
          _horizontalController.duration = const Duration(milliseconds: 1600);
        }
        if (!_horizontalController.isAnimating) {
          _horizontalController.forward(from: _horizontalController.value);
        }
        if (_footstepBobController.duration != const Duration(milliseconds: 210)) {
          _footstepBobController.duration = const Duration(milliseconds: 210);
          _footstepBobController.repeat(reverse: true);
        } else if (!_footstepBobController.isAnimating) {
          _footstepBobController.repeat(reverse: true);
        }
        break;

      case MascotState.idle:
      case MascotState.smiling:
      case MascotState.exercise:
      case MascotState.sweating:
      case MascotState.sweatingAndTired:
      case MascotState.tired:
        if (_horizontalController.isAnimating) {
          _horizontalController.stop();
        }
        if (_footstepBobController.isAnimating) {
          _footstepBobController.stop();
        }
        if (!_idleBobController.isAnimating) {
          _idleBobController.repeat(reverse: true);
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer<MascotController>(
      builder: (context, mascotController, child) {
        final state = mascotController.currentState;
        _updateAnimationStates(state);

        final bool isMoving = state == MascotState.walking || state == MascotState.running;

        return LayoutBuilder(
          builder: (context, constraints) {
            final double trackWidth = constraints.maxWidth;
            const double mascotWidth = 56.0;
            const double mascotHeight = 56.0;

            final double maxX = (trackWidth - mascotWidth).clamp(0.0, double.infinity);
            final double currentX = isMoving ? _horizontalController.value * maxX : maxX * 0.85;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedBuilder(
                  animation: Listenable.merge([
                    _horizontalController,
                    _idleBobController,
                    _footstepBobController,
                  ]),
                  builder: (context, child) {
                    final double verticalOffset = isMoving
                        ? _footstepBobAnimation.value
                        : _idleBobAnimation.value;

                    final double scaleValue = isMoving ? 1.0 : _idleScaleAnimation.value;

                    Widget mascotImage = Image.asset(
                      state.assetPath,
                      width: 44,
                      height: 44,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.smart_toy_rounded,
                          size: 38,
                          color: Color(0xFF6366F1),
                        );
                      },
                    );

                    // Flip horizontally when traveling left
                    if (!_isFacingRight) {
                      mascotImage = Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.rotationY(pi),
                        child: mascotImage,
                      );
                    }

                    return Positioned(
                      left: currentX,
                      bottom: 0,
                      child: Transform.translate(
                        offset: Offset(0, verticalOffset),
                        child: Transform.scale(
                          scale: scaleValue,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              mascotController.triggerWave();
                              MascotAiHubBottomSheet.show(
                                context,
                                onSelectMealTab: widget.onSelectMealTab,
                              );
                            },
                            child: Container(
                              width: mascotWidth,
                              height: mascotHeight,
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: isDark
                                    ? const LinearGradient(
                                        colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : const LinearGradient(
                                        colors: [Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                border: Border.all(
                                  color: const Color(0xFF6366F1).withValues(alpha: isDark ? 0.6 : 0.4),
                                  width: 2.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF6366F1).withValues(alpha: isDark ? 0.45 : 0.25),
                                    blurRadius: 14,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  transitionBuilder: (child, animation) {
                                    return ScaleTransition(
                                      scale: Tween<double>(begin: 0.82, end: 1.0).animate(
                                        CurvedAnimation(
                                          parent: animation,
                                          curve: Curves.easeOutCubic,
                                        ),
                                      ),
                                      child: FadeTransition(
                                        opacity: animation,
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: KeyedSubtree(
                                    key: ValueKey(state.assetPath),
                                    child: mascotImage,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}

