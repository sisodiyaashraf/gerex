import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/ai_provider.dart';
import 'package:gerex/core/presentation/widgets/pastel_gradient_card.dart';
import 'package:gerex/core/presentation/widgets/gerex_scaffold.dart';
import 'package:gerex/core/theme/app_theme.dart';

class GoalOption {
  final String title;
  final String description;
  final dynamic icon;
  GoalOption(this.title, this.description, this.icon);
}

class EquipmentOption {
  final String title;
  final String description;
  final dynamic icon;
  EquipmentOption(this.title, this.description, this.icon);
}

class ExperienceOption {
  final String title;
  final String description;
  final dynamic icon;
  ExperienceOption(this.title, this.description, this.icon);
}

class AIPlanGeneratorScreen extends StatefulWidget {
  const AIPlanGeneratorScreen({super.key});

  @override
  State<AIPlanGeneratorScreen> createState() => _AIPlanGeneratorScreenState();
}

class _AIPlanGeneratorScreenState extends State<AIPlanGeneratorScreen> {
  String _goal = 'Muscle Gain';
  String _equipment = 'Full Gym';
  String _experience = 'Intermediate';

  final List<GoalOption> _goalOptions = [
    GoalOption(
      'Muscle Gain',
      'Build hypertrophy & raw muscle size',
      FontAwesomeIcons.dumbbell,
    ),
    GoalOption(
      'Fat Loss',
      'Torch calories & lean out fat tissues',
      FontAwesomeIcons.fire,
    ),
    GoalOption(
      'Strength & Endurance',
      'Optimize maximum lifts & conditioning',
      FontAwesomeIcons.bolt,
    ),
  ];

  final List<EquipmentOption> _equipmentOptions = [
    EquipmentOption(
      'Full Gym',
      'Complete access to heavy machines & racks',
      FontAwesomeIcons.building,
    ),
    EquipmentOption(
      'Dumbbells Only',
      'Free-weight training from home setups',
      FontAwesomeIcons.handFist,
    ),
    EquipmentOption(
      'Bodyweight Only',
      'No gear required, calisthenics & core resistance',
      FontAwesomeIcons.personRunning,
    ),
  ];

  final List<ExperienceOption> _experienceOptions = [
    ExperienceOption(
      'Beginner',
      'New to fitness, focus on execution forms',
      FontAwesomeIcons.seedling,
    ),
    ExperienceOption(
      'Intermediate',
      'Familiar with core lifts, medium capacity',
      FontAwesomeIcons.medal,
    ),
    ExperienceOption(
      'Advanced',
      'High intensity workouts, complete fatigue targets',
      FontAwesomeIcons.trophy,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<AIProvider>(context);

    return GerexScaffold(
      appBar: AppBar(
        title: Text(
          'AI Plan Generator',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textDarkHeading,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: AppColors.textDarkHeading,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: provider.isPlanLoading
          ? _buildLoadingState(theme)
          : provider.generatedWorkoutPlan != null
          ? _buildPlanDisplay(theme, provider)
          : _buildGeneratorForm(theme, provider),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PulsingLoadingIndicator(),
            SizedBox(height: 32),
            Text(
              'Assembling Your Weekly Plan...',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppColors.textDarkHeading,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Gemini is analyzing your selections to construct optimal gym splits, target sets volume, and rest metrics.',
              style: TextStyle(
                color: AppColors.textDarkMuted,
                fontSize: 13,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanDisplay(ThemeData theme, AIProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 100.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Your Custom Program',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDarkHeading,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton.icon(
                        icon: const Icon(
                          Icons.copy_all_rounded,
                          color: AppColors.accentEmeraldLight,
                          size: 16,
                        ),
                        label: const Text(
                          'Copy Plan',
                          style: TextStyle(
                            color: AppColors.accentEmeraldLight,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(
                              text: provider.generatedWorkoutPlan ?? '',
                            ),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Plan copied to clipboard!'),
                              backgroundColor: AppColors.accentEmeraldDeep,
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        icon: const Icon(
                          Icons.refresh_rounded,
                          color: Colors.grey,
                          size: 16,
                        ),
                        label: const Text(
                          'Reset',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        onPressed: () => provider.clearCachedPlan(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: PastelGradientCard(
              type: PastelCardType.indigo,
              padding: const EdgeInsets.all(18.0),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Text(
                  provider.generatedWorkoutPlan!,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: Color(0xFF14181F),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneratorForm(ThemeData theme, AIProvider provider) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 100.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.accentEmeraldLight.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.accentEmeraldLight.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
              child: const Center(
                child: FaIcon(
                  FontAwesomeIcons.wandMagicSparkles,
                  color: AppColors.accentEmeraldLight,
                  size: 28,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Weekly Workout Program',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: AppColors.textDarkHeading,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Configure your fitness parameters to receive a custom training program built on Gemini.',
            style: TextStyle(color: AppColors.textDarkMuted, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          // Error Display
          if (provider.planError != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.destructiveRed.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.destructiveRed.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Text(
                provider.planError!,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Goal selection
          _buildSectionHeader('1. Select Training Goal'),
          const SizedBox(height: 10),
          ..._goalOptions.map(
            (opt) => SelectorCard(
              title: opt.title,
              description: opt.description,
              icon: opt.icon,
              isSelected: _goal == opt.title,
              onTap: () => setState(() => _goal = opt.title),
            ),
          ),
          const SizedBox(height: 20),

          // Equipment selection
          _buildSectionHeader('2. Available Equipment'),
          const SizedBox(height: 10),
          ..._equipmentOptions.map(
            (opt) => SelectorCard(
              title: opt.title,
              description: opt.description,
              icon: opt.icon,
              isSelected: _equipment == opt.title,
              onTap: () => setState(() => _equipment = opt.title),
            ),
          ),
          const SizedBox(height: 20),

          // Experience level selection
          _buildSectionHeader('3. Experience Level'),
          const SizedBox(height: 10),
          ..._experienceOptions.map(
            (opt) => SelectorCard(
              title: opt.title,
              description: opt.description,
              icon: opt.icon,
              isSelected: _experience == opt.title,
              onTap: () => setState(() => _experience = opt.title),
            ),
          ),
          const SizedBox(height: 32),

          // Submit CTA
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: GerexGradients.primaryCTA,
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentEmeraldLight.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () {
                provider.generatePlan(
                  goal: _goal,
                  equipment: _equipment,
                  experienceLevel: _experience,
                );
              },
              child: const Text(
                'Generate Weekly Program',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14,
        color: Color(0xFF0D807B),
        letterSpacing: 0.5,
      ),
    );
  }
}

class SelectorCard extends StatelessWidget {
  final String title;
  final String description;
  final dynamic icon;
  final bool isSelected;
  final VoidCallback onTap;

  const SelectorCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: isSelected ? 1.015 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          child: PastelGradientCard(
            type: isSelected ? PastelCardType.mint : PastelCardType.slate,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            borderRadius: 16,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF14181F).withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: FaIcon(
                      icon as FaIconData,
                      color: const Color(0xFF14181F),
                      size: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF14181F),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 11,
                          color: const Color(0xFF14181F).withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF0D807B),
                    size: 18,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PulsingLoadingIndicator extends StatefulWidget {
  const PulsingLoadingIndicator({super.key});

  @override
  State<PulsingLoadingIndicator> createState() =>
      _PulsingLoadingIndicatorState();
}

class _PulsingLoadingIndicatorState extends State<PulsingLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              AppColors.accentEmeraldLight.withValues(alpha: 0.25),
              Colors.transparent,
            ],
          ),
        ),
        child: const Center(
          child: FaIcon(
            FontAwesomeIcons.wandMagicSparkles,
            color: AppColors.accentEmeraldLight,
            size: 32,
          ),
        ),
      ),
    );
  }
}