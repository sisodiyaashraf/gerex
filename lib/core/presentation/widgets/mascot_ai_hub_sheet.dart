import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/mascot_controller.dart';
import 'sprite_animator.dart';

class MascotAiHubBottomSheet extends StatefulWidget {
  final VoidCallback? onSelectHomeTab;
  final VoidCallback? onSelectMealTab;

  const MascotAiHubBottomSheet({
    super.key,
    this.onSelectHomeTab,
    this.onSelectMealTab,
  });

  static void show(
    BuildContext context, {
    VoidCallback? onSelectHomeTab,
    VoidCallback? onSelectMealTab,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => MascotAiHubBottomSheet(
        onSelectHomeTab: onSelectHomeTab,
        onSelectMealTab: onSelectMealTab,
      ),
    );
  }

  @override
  State<MascotAiHubBottomSheet> createState() => _MascotAiHubBottomSheetState();
}

class _MascotAiHubBottomSheetState extends State<MascotAiHubBottomSheet> {
  bool _showDebugMenu = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final sheetBg = isDark
        ? const Color(0xFF131525).withValues(alpha: 0.94)
        : const Color(0xFFF8FAFC).withValues(alpha: 0.94);

    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.08);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: 24 + MediaQuery.of(context).padding.bottom,
          ),
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withValues(alpha: isDark ? 0.25 : 0.12),
                blurRadius: 28,
                spreadRadius: 4,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white30 : Colors.black26,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Mascot Header Avatar + Title
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF0F172A),
                        ),
                        child: Center(
                          child: SpriteAnimator(
                            assetPath: MascotState.smiling.assetPath,
                            frameCount: MascotState.smiling.frameCount,
                            columns: MascotState.smiling.columns,
                            rows: MascotState.smiling.rows,
                            mascotStateName: MascotState.smiling.name,
                            width: 38,
                            height: 38,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Gerex AI Hub',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6366F1).withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                                  ),
                                ),
                                child: const Text(
                                  '8-BIT AI',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF6366F1),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Quick intelligent launchers & suggestions',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close_rounded,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Quick Action Cards
                _buildOptionCard(
                  context,
                  icon: FontAwesomeIcons.house,
                  gradientColors: const [Color(0xFF10B981), Color(0xFF059669)],
                  title: 'Home Dashboard',
                  subtitle: 'Jump to main workouts dashboard',
                  onTap: () {
                    Navigator.of(context).pop();
                    if (widget.onSelectHomeTab != null) {
                      widget.onSelectHomeTab!();
                    } else {
                      context.go('/');
                    }
                  },
                ),
                const SizedBox(height: 10),
                _buildOptionCard(
                  context,
                  icon: FontAwesomeIcons.robot,
                  gradientColors: const [Color(0xFF6366F1), Color(0xFF4F46E5)],
                  title: 'AI Chat Coach',
                  subtitle: 'Ask questions & get instant workout tips',
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push('/coach');
                  },
                ),
                const SizedBox(height: 10),
                _buildOptionCard(
                  context,
                  imageAsset: 'assets/images/robot_mascot/ai_face_detector.png',
                  icon: FontAwesomeIcons.wandMagicSparkles,
                  gradientColors: const [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                  title: 'AI Suggestions',
                  subtitle: 'Smart daily insights & exercise swap plans',
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push('/ai-plan');
                  },
                ),
                const SizedBox(height: 10),
                _buildOptionCard(
                  context,
                  icon: FontAwesomeIcons.utensils,
                  gradientColors: const [Color(0xFFD97706), Color(0xFFDC2626)],
                  title: 'Diet & Meal Planner',
                  subtitle: 'Track today\'s macros & custom recipes',
                  onTap: () {
                    Navigator.of(context).pop();
                    if (widget.onSelectMealTab != null) {
                      widget.onSelectMealTab!();
                    } else {
                      context.push('/meal-planner');
                    }
                  },
                ),

                const SizedBox(height: 16),

                // Dev Debug Menu Toggle & Panel
                InkWell(
                  onTap: () => setState(() => _showDebugMenu = !_showDebugMenu),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _showDebugMenu
                              ? Icons.bug_report_rounded
                              : Icons.bug_report_outlined,
                          size: 16,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _showDebugMenu
                              ? 'Hide Mascot Pose Debugger'
                              : 'Mascot State Debugger (Dev)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                        ),
                        Icon(
                          _showDebugMenu
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ],
                    ),
                  ),
                ),

                if (_showDebugMenu) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Test Mascot States in Isolation:',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: MascotState.values.map((s) {
                            return ActionChip(
                              label: Text(
                                s.name,
                                style: const TextStyle(fontSize: 11),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              onPressed: () {
                                final controller = Provider.of<MascotController>(
                                  context,
                                  listen: false,
                                );
                                switch (s) {
                                  case MascotState.idle:
                                    controller.resetToIdle();
                                    break;
                                  case MascotState.smiling:
                                    controller.triggerWave();
                                    break;
                                  case MascotState.walking:
                                    controller.triggerWalking();
                                    break;
                                  case MascotState.running:
                                    controller.triggerRunning();
                                    break;
                                  case MascotState.exercise:
                                    controller.triggerWorkoutCompletion();
                                    break;
                                  case MascotState.pushup:
                                    controller.triggerPushup();
                                    break;
                                  default:
                                    controller.triggerPose(s, duration: const Duration(seconds: 4));
                                    break;
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Triggered mascot state: ${s.name}'),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    dynamic icon,
    String? imageAsset,
    required List<Color> gradientColors,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.03),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: gradientColors.first.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: imageAsset != null
                      ? Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Image.asset(
                            imageAsset,
                            fit: BoxFit.contain,
                            width: 28,
                            height: 28,
                            errorBuilder: (_, __, ___) => FaIcon(
                              icon ?? FontAwesomeIcons.robot,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        )
                      : FaIcon(
                          icon,
                          color: Colors.white,
                          size: 20,
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? Colors.white60 : Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
