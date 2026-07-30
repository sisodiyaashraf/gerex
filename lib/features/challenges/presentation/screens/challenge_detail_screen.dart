import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gerex/core/presentation/widgets/glass_container.dart';
import 'package:gerex/core/presentation/widgets/pastel_gradient_card.dart';
import 'package:gerex/core/presentation/widgets/liquid_background.dart';
import 'package:gerex/core/theme/app_theme.dart';
import 'package:gerex/core/widgets/slide_to_confirm_button.dart';
import '../providers/challenge_provider.dart';
import '../../domain/entities/challenge.dart';

class ChallengeDetailScreen extends StatefulWidget {
  final Challenge challenge;

  const ChallengeDetailScreen({
    super.key,
    required this.challenge,
  });

  @override
  State<ChallengeDetailScreen> createState() => _ChallengeDetailScreenState();
}

class _ChallengeDetailScreenState extends State<ChallengeDetailScreen> {
  int _minutesToLog = 15; // default logging increment

  String _getIllustrationAsset(String badgeIcon) {
    switch (badgeIcon) {
      case 'person-running':
        return 'assets/exercise/cycling.png';
      case 'dumbbell':
        return 'assets/exercise/kettlebell swing.png';
      case 'shield-halved':
        return 'assets/exercise/kickboxing.png';
      default:
        return 'assets/exercise/fitness dashboard.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final challengeProvider = Provider.of<ChallengeProvider>(context);
    final progress = challengeProvider.getProgress(widget.challenge.id);
    final isJoined = challengeProvider.isJoined(widget.challenge.id);
    final difficultyColor = widget.challenge.getDifficultyColor(context);

    final currentProgress = progress?.progressMinutes ?? 0;
    final totalGoal = widget.challenge.totalMinutesGoal;
    final percent = totalGoal > 0 ? (currentProgress / totalGoal).clamp(0.0, 1.0) : 0.0;
    
    final illustrationAsset = _getIllustrationAsset(widget.challenge.badgeIcon);

    return Scaffold(
      body: LiquidBackground(
        child: CustomScrollView(
          slivers: [
            // Sliver Header Image & Navigation Overlays
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              backgroundColor: Colors.transparent,
              leading: Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.black.withValues(alpha: 0.4),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => context.pop(),
                  ),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Header gradient background
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary.withValues(alpha: 0.2),
                            GerexGradients.secondaryCard.colors.first.withValues(alpha: 0.3),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    
                    // Illustration Image
                    Positioned(
                      right: 16,
                      bottom: 16,
                      top: 48,
                      width: 140,
                      child: Image.asset(
                        illustrationAsset,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback icon if asset doesn't load
                          return Center(
                            child: FaIcon(
                              FontAwesomeIcons.award,
                              size: 60,
                              color: theme.colorScheme.primary.withValues(alpha: 0.3),
                            ),
                          );
                        },
                      ),
                    ),

                    // Fade gradient on bottom
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              theme.scaffoldBackgroundColor.withValues(alpha: 0.8),
                              theme.scaffoldBackgroundColor,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Content Details
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Challenge type and Title
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: difficultyColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: difficultyColor.withValues(alpha: 0.3), width: 1.0),
                        ),
                        child: Text(
                          widget.challenge.difficultyLabel,
                          style: TextStyle(
                            color: difficultyColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.orangeAccent, size: 14),
                          const SizedBox(width: 2),
                          Text(
                            widget.challenge.type,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.challenge.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Total Users Joined Glass Stat Row
                  PastelGradientCard(
                    type: PastelCardType.indigo,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.people_alt_rounded,
                              color: theme.colorScheme.primary,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Total joined athletes',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        Text(
                          '${widget.challenge.usersJoined + (isJoined ? 1 : 0)} users',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description card
                  Text(
                    'About Challenge',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  PastelGradientCard(
                    type: PastelCardType.indigo,
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      widget.challenge.description,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Progress Bar section (only show if joined)
                  if (isJoined) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Your Progress Contribution',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '$currentProgress / $totalGoal mins',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Beautiful progress track
                    Container(
                      height: 12,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.07) : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: percent,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: GerexGradients.primaryCTA,
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${(percent * 100).toInt()}% completed',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Log contribution section
                    Text(
                      'Log Workout Contribution',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Quick selector buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [15, 30, 45, 60].map((mins) {
                        final isSel = _minutesToLog == mins;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _minutesToLog = mins),
                            child: GlassContainer(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              borderRadius: 12,
                              color: isSel 
                                  ? theme.colorScheme.primary.withValues(alpha: 0.15) 
                                  : null,
                              borderWidth: isSel ? 1.5 : 1.0,
                              borderGradient: isSel ? GerexGradients.primaryCTA : null,
                              child: Center(
                                child: Text(
                                  '+$mins m',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isSel ? theme.colorScheme.primary : null,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Slide to log progress button
                    SlideToConfirmButton(
                      label: 'Slide to Log $_minutesToLog Minutes',
                      onConfirm: () async {
                        final success = await challengeProvider.logProgress(
                          widget.challenge.id,
                          _minutesToLog,
                        );
                        if (success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Successfully logged $_minutesToLog minutes to challenge!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                    ),
                  ] else ...[
                    // Join challenge card with SlideToConfirmButton
                    const SizedBox(height: 20),
                    SlideToConfirmButton(
                      label: 'Slide to Join Challenge',
                      onConfirm: () async {
                        final success = await challengeProvider.joinChallenge(widget.challenge.id);
                        if (success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Welcome to the challenge! Log minutes to beat the goal.'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                  const SizedBox(height: 48),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
