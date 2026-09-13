import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/mascot_controller.dart';
import 'sprite_animator.dart';
import 'mascot_ai_hub_sheet.dart';

typedef RobotMascot = FloatingMascotWidget;

/// Frame-animated Robot Mascot Widget positioned relative to the bottom nav bar.
/// Slices horizontal sprite sheets using [SpriteAnimator] and runs a perimeter lap
/// around the navigation bar when tapped before opening the AI Hub sheet.
class FloatingMascotWidget extends StatefulWidget {
  final VoidCallback? onSelectMealTab;

  const FloatingMascotWidget({super.key, this.onSelectMealTab});

  @override
  State<FloatingMascotWidget> createState() => _FloatingMascotWidgetState();
}

class _FloatingMascotWidgetState extends State<FloatingMascotWidget>
    with TickerProviderStateMixin {
  AnimationController? _lapController;
  AnimationController? _idleBobController;
  Animation<double>? _idleBobAnimation;
  Animation<double>? _idleScaleAnimation;

  final bool _isFacingRight = true;
  bool _isLapInProgress = false;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    // 1. Lap animation controller around the navbar perimeter (~1.8s total duration)
    _lapController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 1800),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            _onLapCompleted();
          }
        });

    // 2. Continuous idle bobbing & breathing scale pulse in resting state
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

  @override
  void dispose() {
    _lapController?.dispose();
    _idleBobController?.dispose();
    super.dispose();
  }

  void _handleTap(MascotController mascotController) {
    if (_isLapInProgress) {
      // Rapid re-tap handling: cancel lap & open sheet immediately without stacking
      _lapController?.stop();
      _isLapInProgress = false;
      mascotController.resetToIdle();
      _openHubSheet(mascotController);
      return;
    }

    // Start perimeter lap
    _isLapInProgress = true;
    mascotController.triggerRunning();
    _lapController?.forward(from: 0.0);
  }

  void _onLapCompleted() {
    _isLapInProgress = false;
    final mascotController = Provider.of<MascotController>(
      context,
      listen: false,
    );
    mascotController.resetToIdle();
    _openHubSheet(mascotController);
  }

  void _openHubSheet(MascotController mascotController) {
    mascotController.triggerWave();
    MascotAiHubBottomSheet.show(
      context,
      onSelectMealTab: widget.onSelectMealTab,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer<MascotController>(
      builder: (context, mascotController, child) {
        final state = mascotController.currentState;

        return LayoutBuilder(
          builder: (context, constraints) {
            final double trackWidth = constraints.maxWidth;
            const double mascotSize = 54.0;

            // Container height is 120px. Nav bar sits at bottom (y: 48..120).
            // Top rim of nav bar is at y = 48 - mascotSize (resting spot top-right).
            final Offset p0 = Offset(
              trackWidth - mascotSize - 8,
              48 - mascotSize,
            ); // Resting spot (Top-Right)
            const Offset p1 = Offset(8, 48 - mascotSize); // Top-Left
            const Offset p2 = Offset(8, 120 - mascotSize - 4); // Bottom-Left
            final Offset p3 = Offset(
              trackWidth - mascotSize - 8,
              120 - mascotSize - 4,
            ); // Bottom-Right

            final double d0 = (p1.dx - p0.dx).abs();
            final double d1 = (p2.dy - p1.dy).abs();
            final double d2 = (p3.dx - p2.dx).abs();
            final double d3 = (p0.dy - p3.dy).abs();
            final double totalDist = d0 + d1 + d2 + d3;

            final animList = <Listenable>[];
            if (_lapController != null) animList.add(_lapController!);
            if (_idleBobController != null) animList.add(_idleBobController!);

            return AnimatedBuilder(
              animation: Listenable.merge(animList),
              builder: (context, child) {
                Offset currentPos;
                bool facingRight = _isFacingRight;

                if (_isLapInProgress && totalDist > 0) {
                  final double lapProgress = _lapController?.value ?? 0.0;
                  final double dist = lapProgress * totalDist;
                  if (dist <= d0) {
                    final double u = dist / d0;
                    currentPos = Offset(
                      p0.dx + u * (p1.dx - p0.dx),
                      p0.dy + u * (p1.dy - p0.dy),
                    );
                    facingRight = false; // Moving Left along top edge
                  } else if (dist <= d0 + d1) {
                    final double u = (dist - d0) / d1;
                    currentPos = Offset(
                      p1.dx + u * (p2.dx - p1.dx),
                      p1.dy + u * (p2.dy - p1.dy),
                    );
                    facingRight = false; // Moving Down left edge
                  } else if (dist <= d0 + d1 + d2) {
                    final double u = (dist - d0 - d1) / d2;
                    currentPos = Offset(
                      p2.dx + u * (p3.dx - p2.dx),
                      p2.dy + u * (p3.dy - p2.dy),
                    );
                    facingRight = true; // Moving Right along bottom edge
                  } else {
                    final double u = (dist - d0 - d1 - d2) / d3;
                    currentPos = Offset(
                      p3.dx + u * (p0.dx - p3.dx),
                      p3.dy + u * (p0.dy - p3.dy),
                    );
                    facingRight = true; // Moving Up right edge to resting spot
                  }
                } else {
                  // Resting state position with gentle vertical bobbing
                  final double bobVal = _idleBobAnimation?.value ?? 0.0;
                  currentPos = Offset(p0.dx, p0.dy + bobVal);
                  facingRight = true;
                }

                Widget mascotWidget = SpriteAnimator(
                  key: ValueKey('${state.assetPath}_${state.frameCount}'),
                  assetPath: state.assetPath,
                  frameCount: state.frameCount,
                  frameDuration: state.frameDuration,
                  loop:
                      state == MascotState.idle ||
                      state == MascotState.smiling ||
                      state == MascotState.running ||
                      state == MascotState.walking,
                  width: 40,
                  height: 40,
                  mascotStateName: state.name,
                  onComplete: () {
                    if (state == MascotState.exercise ||
                        state == MascotState.sweating ||
                        state == MascotState.sweatingAndTired ||
                        state == MascotState.tired) {
                      mascotController.resetToIdle();
                    }
                  },
                );

                if (!facingRight) {
                  mascotWidget = Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(pi),
                    child: mascotWidget,
                  );
                }

                final double scaleVal = _idleScaleAnimation?.value ?? 1.0;

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: currentPos.dx,
                      top: currentPos.dy,
                      child: Transform.scale(
                        scale: _isLapInProgress ? 1.0 : scaleVal,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _handleTap(mascotController),
                          child: Container(
                            width: mascotSize,
                            height: mascotSize,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: isDark
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xFF1E1B4B),
                                        Color(0xFF312E81),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : const LinearGradient(
                                      colors: [
                                        Color(0xFFEEF2FF),
                                        Color(0xFFE0E7FF),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                              border: Border.all(
                                color: const Color(
                                  0xFF6366F1,
                                ).withValues(alpha: isDark ? 0.6 : 0.4),
                                width: 2.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF6366F1,
                                  ).withValues(alpha: isDark ? 0.45 : 0.25),
                                  blurRadius: 14,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                child: KeyedSubtree(
                                  key: ValueKey(state.assetPath),
                                  child: mascotWidget,
                                ),
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
          },
        );
      },
    );
  }
}
