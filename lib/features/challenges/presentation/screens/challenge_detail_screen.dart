import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gerex/core/presentation/widgets/glass_container.dart';
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
  int _minutesToLog = 15;

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
    final challengeProvider = Provider.of<ChallengeProvider>(context);
    final progress = challengeProvider.getProgress(widget.challenge.id);
    final isJoined = challengeProvider.isJoined(widget.challenge.id);
    final difficultyColor = widget.challenge.getDifficultyColor(context);

    final currentProgress = progress?.progressMinutes ?? 0;
    final totalGoal = widget.challenge.totalMinutesGoal;
    final percent = totalGoal > 0 ? (currentProgress / totalGoal).clamp(0.0, 1.0) : 0.0;
    final illustrationAsset = _getIllustrationAsset(widget.challenge.badgeIcon);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFFEEF2F6),
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GlassContainer(
                borderRadius: 40,
                padding: EdgeInsets.zero,
                type: GlassContainerType.slate,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                  onPressed: () => context.pop(),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Main solid background
                  Container(
                    color: const Color(0xFFF1F5F9),
                  ),
                  // Difficulty color-based blurred decorative circle
                  Positioned(
                    top: -40,
                    left: -20,
                    width: 180,
                    height: 180,
                    child: Container(
                      decoration: BoxDecoration(
                        color: difficultyColor.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  // Secondary contrast decorative circle
                  Positioned(
                    bottom: 30,
                    right: 40,
                    width: 140,
                    height: 140,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  // Apply blur filter to generate mesh background
                  Positioned.fill(
                    child: ClipRRect(
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 45, sigmaY: 45),
                        child: Container(color: Colors.transparent),
                      ),
                    ),
                  ),
                  // Floating transparent exercise illustration
                  Positioned(
                    right: 24,
                    bottom: 24,
                    top: 64,
                    width: 150,
                    child: Image.asset(
                      illustrationAsset,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: FaIcon(
                          FontAwesomeIcons.award,
                          size: 48,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 24,
                    bottom: 24,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: difficultyColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: difficultyColor.withValues(alpha: 0.3), width: 1.5),
                      ),
                      child: Text(
                        widget.challenge.difficultyLabel.toUpperCase(),
                        style: TextStyle(
                          color: difficultyColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.orange, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      widget.challenge.type.toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.challenge.title,
                  style: GoogleFonts.outfit(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0B1220),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: GlassContainer(
                        type: GlassContainerType.normal,
                        padding: const EdgeInsets.all(16),
                        borderRadius: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.people_outline_rounded, color: Color(0xFF10B981), size: 24),
                            const SizedBox(height: 12),
                            Text(
                              '${widget.challenge.usersJoined + (isJoined ? 1 : 0)}',
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0B1220),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Joined Athletes',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: const Color(0xFF1E293B).withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GlassContainer(
                        type: GlassContainerType.normal,
                        padding: const EdgeInsets.all(16),
                        borderRadius: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 24),
                            const SizedBox(height: 12),
                            Text(
                              '${widget.challenge.totalMinutesGoal} min',
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0B1220),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Target Goal',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: const Color(0xFF1E293B).withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'About Challenge',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0B1220),
                  ),
                ),
                const SizedBox(height: 10),
                GlassContainer(
                  type: GlassContainerType.normal,
                  padding: const EdgeInsets.all(16),
                  borderRadius: 16,
                  child: Text(
                    widget.challenge.description,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      height: 1.5,
                      color: const Color(0xFF1E293B).withValues(alpha: 0.9),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                if (isJoined) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Your Contribution Progress',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0B1220),
                        ),
                      ),
                      Text(
                        '$currentProgress / $totalGoal mins',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 12,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.05),
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
                                    color: const Color(0xFF10B981).withValues(alpha: 0.3),
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
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B).withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Log Workout Contribution',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0B1220),
                    ),
                  ),
                  const SizedBox(height: 12),
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
                            color: isSel ? const Color(0xFF10B981).withValues(alpha: 0.12) : Colors.white,
                            borderWidth: isSel ? 1.5 : 1.0,
                            borderGradient: isSel ? GerexGradients.primaryCTA : null,
                            child: Center(
                              child: Text(
                                '+$mins m',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isSel ? const Color(0xFF10B981) : const Color(0xFF1E293B),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 28),
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
                            backgroundColor: const Color(0xFF10B981),
                          ),
                        );
                      }
                    },
                  ),
                ] else ...[
                  const SizedBox(height: 28),
                  SlideToConfirmButton(
                    label: 'Slide to Join Challenge',
                    onConfirm: () async {
                      final success = await challengeProvider.joinChallenge(widget.challenge.id);
                      if (success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Welcome to the challenge! Log minutes to beat the goal.'),
                            backgroundColor: Color(0xFF10B981),
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
    );
  }
}
