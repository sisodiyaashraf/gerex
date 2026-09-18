import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/mascot_controller.dart';
import 'sprite_animator.dart';
import 'mascot_ai_hub_sheet.dart';

typedef RobotMascot = FloatingMascotWidget;

/// Frame-animated Robot Mascot Widget positioned relative to the bottom nav bar.
///
/// Behavior:
/// - On Homescreen (Tab 0: Workouts): Robot stays PERMANENTLY VISIBLE in resting idle/smiling pose.
/// - On Other Tabs (Explore, Meals, Analytics): Robot walks/runs to the tapped tab icon,
///   plays a sweating/tired recovery pose above that icon for 1.4s, then smoothly disappears (fades out).
/// - When returning to Homescreen: Robot walks back to Tab 0 position and STAYS VISIBLE.
class FloatingMascotWidget extends StatefulWidget {
  final VoidCallback? onSelectHomeTab;
  final VoidCallback? onSelectMealTab;

  const FloatingMascotWidget({
    super.key,
    this.onSelectHomeTab,
    this.onSelectMealTab,
  });

  @override
  State<FloatingMascotWidget> createState() => _FloatingMascotWidgetState();
}

class _FloatingMascotWidgetState extends State<FloatingMascotWidget>
    with TickerProviderStateMixin {
  late final AnimationController _moveController;
  late final AnimationController _fadeController;
  late final AnimationController _idleBobController;
  Animation<double>? _idleBobAnimation;
  Animation<double>? _idleScaleAnimation;

  Timer? _disappearTimer;

  double _currentX = 0.0;
  double _startX = 0.0;
  double _targetX = 0.0;
  bool _facingRight = true;
  bool _isNavigating = false;
  int _lastNavTriggerCount = -1;
  int _currentTabIndex = 0;
  int _tapCount = 0;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    // 1. Move animation controller along the nav bar top line
    _moveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _onNavigationArrival();
        }
      });

    // 2. Fade opacity controller (1.0 = visible, 0.0 = disappeared)
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
      value: 1.0, // Start visible on Homescreen
    );

    // 3. Continuous idle bobbing & breathing scale pulse
    final idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _idleBobAnimation = Tween<double>(
      begin: 0.0,
      end: -4.0,
    ).animate(CurvedAnimation(parent: idleController, curve: Curves.easeInOut));

    _idleScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.04,
    ).animate(CurvedAnimation(parent: idleController, curve: Curves.easeInOut));

    _idleBobController = idleController..repeat(reverse: true);
  }

  void _scheduleDisappearTimer({int holdMs = 1000}) {
    _disappearTimer?.cancel();
    // On Homescreen (Tab 0), NEVER disappear! Keep opacity fully visible (1.0)
    if (_currentTabIndex == 0) {
      if (_fadeController.value < 1.0) {
        _fadeController.forward();
      }
      return;
    }

    // On non-Home tabs (Explore, Meals, Analytics), stand for holdMs, then fade out!
    _disappearTimer = Timer(Duration(milliseconds: holdMs), () {
      if (mounted && !_isNavigating && _currentTabIndex != 0) {
        _fadeController.reverse(); // Fade out and disappear smoothly on non-Home tabs!
      }
    });
  }

  @override
  void dispose() {
    _disappearTimer?.cancel();
    _moveController.dispose();
    _fadeController.dispose();
    _idleBobController.dispose();
    super.dispose();
  }

  void _checkStateTrigger(MascotController mascotController, double trackWidth, double mascotSize) {
    if (_lastNavTriggerCount != mascotController.navTriggerCount) {
      _lastNavTriggerCount = mascotController.navTriggerCount;
      final targetIndex = mascotController.targetTabIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _startNavigationToTab(targetIndex, mascotController, trackWidth, mascotSize);
        }
      });
    }
  }

  void _startNavigationToTab(
    int targetIndex,
    MascotController mascotController,
    double trackWidth,
    double mascotSize,
  ) {
    _disappearTimer?.cancel();
    _currentTabIndex = targetIndex;

    // 4 tabs evenly spaced along trackWidth
    final double tabWidth = trackWidth / 4.0;
    final double newTargetX = ((targetIndex + 0.5) * tabWidth - mascotSize / 2.0)
        .clamp(0.0, trackWidth - mascotSize);

    _startX = _currentX;
    _targetX = newTargetX;

    if (_targetX > _startX + 1.0) {
      _facingRight = true;
    } else if (_targetX < _startX - 1.0) {
      _facingRight = false;
    }

    final double distance = (_targetX - _startX).abs();
    final bool isRunning = mascotController.currentState == MascotState.running;
    final int speedFactor = isRunning ? 320 : 700;
    final int baseOffset = isRunning ? 220 : 400;
    final int moveMs = (distance / (trackWidth > 0 ? trackWidth : 1) * speedFactor + baseOffset).toInt();

    _moveController.duration = Duration(milliseconds: moveMs);

    // Fade in immediately when navigating to any tab
    if (_fadeController.value < 1.0) {
      _fadeController.forward();
    }

    if (distance > 4.0) {
      _isNavigating = true;
      _moveController.forward(from: 0.0);
    } else {
      _onNavigationArrival();
    }
  }

  void _onNavigationArrival() {
    _isNavigating = false;
    _currentX = _targetX;

    final mascotController = Provider.of<MascotController>(
      context,
      listen: false,
    );

    final bool wasRunning = mascotController.currentState == MascotState.running;

    if (wasRunning) {
      // Trigger sweating & tired recovery animation ONLY on multiple nav clicks!
      mascotController.triggerPose(
        MascotState.sweatingAndTired,
        duration: const Duration(milliseconds: 1800),
      );
      _scheduleDisappearTimer(holdMs: 1800);
    } else {
      // Single click navigation -> happy idle pose!
      mascotController.resetToIdle();
      _scheduleDisappearTimer(holdMs: 1000);
    }
  }

  void _handleTap(MascotController mascotController) {
    _disappearTimer?.cancel();
    if (_fadeController.value < 1.0) {
      _fadeController.forward();
    }

    _tapCount++;
    final mode = _tapCount % 5;

    if (mode == 1) {
      mascotController.triggerWalking();
      _scheduleDisappearTimer(holdMs: 2800);
    } else if (mode == 2) {
      mascotController.triggerRunning();
      _scheduleDisappearTimer(holdMs: 2200);
    } else if (mode == 3) {
      mascotController.triggerPushup();
    } else if (mode == 4) {
      mascotController.triggerWorkoutCompletion();
    } else {
      _openHubSheet(mascotController);
    }
  }

  void _openHubSheet(MascotController mascotController) {
    mascotController.triggerWave();
    MascotAiHubBottomSheet.show(
      context,
      onSelectHomeTab: widget.onSelectHomeTab,
      onSelectMealTab: widget.onSelectMealTab,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MascotController>(
      builder: (context, mascotController, child) {
        final state = mascotController.currentState;

        return LayoutBuilder(
          builder: (context, constraints) {
            final double trackWidth = constraints.maxWidth;
            const double mascotSize = 52.0;

            // Initialize default X to tab 0 center if unset
            if (_startX == 0.0 && _targetX == 0.0 && _currentX == 0.0 && trackWidth > 0) {
              final double tabWidth = trackWidth / 4.0;
              final double initX = ((0 + 0.5) * tabWidth - mascotSize / 2.0)
                  .clamp(0.0, trackWidth - mascotSize);
              _startX = initX;
              _targetX = initX;
              _currentX = initX;
            }

            _checkStateTrigger(mascotController, trackWidth, mascotSize);

            final animList = <Listenable>[
              _moveController,
              _fadeController,
              _idleBobController,
            ];

            return AnimatedBuilder(
              animation: Listenable.merge(animList),
              builder: (context, child) {
                double renderX;
                double renderY;

                if (_isNavigating) {
                  final double t = Curves.easeInOut.transform(_moveController.value);
                  renderX = _startX + t * (_targetX - _startX);
                  _currentX = renderX;
                  renderY = 0.0;
                } else {
                  renderX = _targetX;
                  _currentX = renderX;
                  renderY = _idleBobAnimation?.value ?? 0.0;
                }

                // Snap computed position to whole integer pixels (prevents sub-pixel shimmer)
                final double snappedX = renderX.roundToDouble();
                final double snappedY = renderY.roundToDouble();

                final double renderMascotSize = state.displaySize;
                final double sizeOffset = (renderMascotSize - mascotSize) / 2.0;

                Widget mascotWidget = SpriteAnimator(
                  key: ValueKey('${state.assetPath}_${state.frameCount}'),
                  assetPath: state.assetPath,
                  frameCount: state.frameCount,
                  columns: state.columns,
                  rows: state.rows,
                  frameDuration: state.frameDuration,
                  loop:
                      state == MascotState.idle ||
                      state == MascotState.smiling ||
                      state == MascotState.running ||
                      state == MascotState.walking ||
                      state == MascotState.sweating ||
                      state == MascotState.sweatingAndTired ||
                      state == MascotState.tired ||
                      state == MascotState.pushup,
                  width: renderMascotSize,
                  height: renderMascotSize,
                  mascotStateName: state.name,
                  onComplete: () {
                    if (state == MascotState.exercise ||
                        state == MascotState.sweating ||
                        state == MascotState.sweatingAndTired ||
                        state == MascotState.tired ||
                        state == MascotState.pushup) {
                      mascotController.resetToIdle();
                      _scheduleDisappearTimer();
                    }
                  },
                );

                if (!_facingRight) {
                  mascotWidget = Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(pi),
                    child: mascotWidget,
                  );
                }

                final double scaleVal = _idleScaleAnimation?.value ?? 1.0;

                const double shadowWidth = 28.0;
                const double shadowHeight = 5.0;
                final double shadowScale = (1.0 - (snappedY.abs() / 16.0)).clamp(0.6, 1.0);
                final double opacityVal = _fadeController.value;

                return FadeTransition(
                  opacity: _fadeController,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Flat grounding drop shadow fixed on top edge of nav bar
                      Positioned(
                        left: snappedX + (mascotSize - shadowWidth) / 2,
                        bottom: 0,
                        child: Transform.scale(
                          scaleX: shadowScale,
                          scaleY: shadowScale,
                          child: Container(
                            width: shadowWidth,
                            height: shadowHeight,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.35 * opacityVal),
                              borderRadius: const BorderRadius.all(
                                Radius.elliptical(14.0, 2.5),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Robot Mascot Sprite Widget (zero gap flush placement)
                      Positioned(
                        left: snappedX - sizeOffset,
                        bottom: 0 + (-snappedY),
                        child: Transform.scale(
                          scale: _isNavigating ? 1.0 : scaleVal,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _handleTap(mascotController),
                            child: SizedBox(
                              width: renderMascotSize,
                              height: renderMascotSize,
                              child: Center(
                                child: KeyedSubtree(
                                  key: ValueKey(state.assetPath),
                                  child: mascotWidget,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
