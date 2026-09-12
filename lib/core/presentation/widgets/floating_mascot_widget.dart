import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/mascot_controller.dart';
import 'sprite_animator.dart';
import 'mascot_ai_hub_sheet.dart';

/// Floating 8-bit Robot Mascot Widget positioned above the navigation shell.
/// Features a gentle vertical float animation, glow drop-shadow, state-driven
/// sprite sheet rendering, and quick-access AI Hub launch on tap.
class FloatingMascotWidget extends StatefulWidget {
  final VoidCallback? onSelectMealTab;

  const FloatingMascotWidget({
    super.key,
    this.onSelectMealTab,
  });

  @override
  State<FloatingMascotWidget> createState() => _FloatingMascotWidgetState();
}

class _FloatingMascotWidgetState extends State<FloatingMascotWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _bobbingController;
  late final Animation<double> _bobbingAnimation;

  @override
  void initState() {
    super.initState();
    _bobbingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _bobbingAnimation = Tween<double>(begin: 0.0, end: -6.0).animate(
      CurvedAnimation(
        parent: _bobbingController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _bobbingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer<MascotController>(
      builder: (context, mascotController, child) {
        final config = mascotController.activeConfig;

        return AnimatedBuilder(
          animation: _bobbingAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _bobbingAnimation.value),
              child: GestureDetector(
                onTap: () {
                  mascotController.triggerWave();
                  MascotAiHubBottomSheet.show(
                    context,
                    onSelectMealTab: widget.onSelectMealTab,
                  );
                },
                child: Container(
                  width: 54,
                  height: 54,
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
                    child: SpriteAnimator(
                      key: ValueKey('${config.assetPath}_${mascotController.currentState}'),
                      assetPath: config.assetPath,
                      frameWidth: config.frameWidth,
                      frameHeight: config.frameHeight,
                      frameCount: config.frameCount,
                      columns: config.columns,
                      frameDuration: config.frameDuration,
                      loop: config.loop,
                      width: 40,
                      height: 40,
                      mascotStateName: mascotController.currentState.name,
                      onComplete: () {
                        mascotController.resetToIdle();
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
