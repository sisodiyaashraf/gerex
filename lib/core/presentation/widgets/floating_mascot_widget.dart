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
  AnimationController? _lapController;
  AnimationController? _idleBobController;
  Animation<double>? _idleBobAnimation;
  Animation<double>? _idleScaleAnimation;

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

            final double xRight = (trackWidth - mascotSize - 8).clamp(
              0.0,
              double.infinity,
            );
            const double xLeft = 8.0;

            final animList = <Listenable>[];
            if (_lapController != null) animList.add(_lapController!);
            if (_idleBobController != null) animList.add(_idleBobController!);

            return AnimatedBuilder(
              animation: Listenable.merge(animList),
              builder: (context, child) {
                double currentX;
                double currentY;
                bool facingRight;

                if (_isLapInProgress) {
                  final double rawProgress = _lapController?.value ?? 0.0;
                  final double progress = Curves.easeInOut.transform(rawProgress);
                  if (progress <= 0.5) {
                    // Phase 1: Run right-to-left across top line with easeInOut
                    final double t = progress / 0.5;
                    currentX = xRight - t * (xRight - xLeft);
                    facingRight = false;
                  } else {
                    // Phase 2: Turn around and run left-to-right across top line back to resting spot
                    final double t = (progress - 0.5) / 0.5;
                    currentX = xLeft + t * (xRight - xLeft);
                    facingRight = true;
                  }
                  currentY = 0.0;
                } else {
                  // Resting state at right side of top line with subtle floating bob
                  currentX = xRight;
                  currentY = _idleBobAnimation?.value ?? 0.0;
                  facingRight = true;
                }

                // Snap computed position to whole integer pixels (prevents sub-pixel shimmer)
                final double snappedX = currentX.roundToDouble();
                final double snappedY = currentY.roundToDouble();

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
                      state == MascotState.walking,
                  width: mascotSize,
                  height: mascotSize,
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

                const double shadowWidth = 28.0;
                const double shadowHeight = 5.0;
                final double shadowScale = (1.0 - (snappedY.abs() / 16.0)).clamp(0.6, 1.0);

                return Stack(
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
                            color: Colors.black.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.all(
                              Radius.elliptical(shadowWidth / 2, shadowHeight / 2),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Robot Mascot Sprite Widget (zero gap flush placement)
                    Positioned(
                      left: snappedX,
                      bottom: 0 + (-snappedY),
                      child: Transform.scale(
                        scale: _isLapInProgress ? 1.0 : scaleVal,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _handleTap(mascotController),
                          child: SizedBox(
                            width: mascotSize,
                            height: mascotSize,
                            child: Center(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
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
