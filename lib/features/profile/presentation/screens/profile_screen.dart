import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../challenges/presentation/providers/challenge_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../workout/presentation/providers/workout_provider.dart';
import '../../../metrics/presentation/providers/metrics_provider.dart';
import '../../../metrics/presentation/widgets/streak_flame_widget.dart';
import '../providers/profile_provider.dart';
import 'package:gerex/core/presentation/widgets/pastel_gradient_card.dart';
import 'package:gerex/core/presentation/widgets/hero_mint_card.dart';
import 'package:gerex/core/presentation/widgets/gerex_avatar.dart';
import 'package:gerex/core/theme/app_theme.dart';
import 'package:gerex/core/presentation/utils/responsive_helper.dart';
import 'package:gerex/core/providers/activity_provider.dart';
import 'package:gerex/core/presentation/widgets/gerex_app_bar.dart';

/// Focused Athlete Profile Screen.
/// Dedicated to user identity, body metrics, training progress, achievements, and progress links.
/// All app settings/preferences are accessed via the gear icon action button leading to SettingsScreen.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  double _calculateTotalVolume(List<dynamic> sessions) {
    double total = 0.0;
    for (final s in sessions) {
      if (s.loggedSets != null) {
        for (final setLog in s.loggedSets) {
          if (setLog.isCompleted == true) {
            total += (setLog.weight ?? 0.0) * (setLog.reps ?? 0);
          }
        }
      }
    }
    return total;
  }

  double _calculateBmi(double weightKg, double heightCm) {
    if (heightCm <= 0) return 0.0;
    final heightM = heightCm / 100.0;
    return weightKg / (heightM * heightM);
  }

  String _getBmiStatus(double bmi) {
    if (bmi <= 0) return 'Unknown';
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25.0) return 'Normal Weight';
    if (bmi < 30.0) return 'Overweight';
    return 'Obese';
  }

  Color _getBmiColor(double bmi) {
    if (bmi < 18.5) return AppColors.accentEmeraldLight;
    if (bmi < 25.0) return AppColors.accentEmeraldLight;
    if (bmi < 30.0) return const Color(0xFFF59E0B);
    return AppColors.destructiveRed;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final authProvider = Provider.of<AuthProvider>(context);
    final workoutProvider = Provider.of<WorkoutProvider>(context);
    final metricsProvider = Provider.of<MetricsProvider>(context);
    final profileProvider = Provider.of<ProfileProvider>(context);
    final activity = Provider.of<ActivityProvider>(context);
    final challengeProvider = Provider.of<ChallengeProvider>(context);

    // Profile Details
    final user = authProvider.user;
    final displayName = user?.userMetadata?['full_name'] ??
        user?.userMetadata?['name'] ??
        user?.email?.split('@').first ??
        'Gerex Athlete';
    final email = user?.email ?? 'athlete@gerex.com';
    final photoUrl = user?.userMetadata?['avatar_url'] ??
        user?.userMetadata?['picture'];

    final initials = displayName.isNotEmpty
        ? displayName.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : 'G';

    // Stats
    final workoutsCount = workoutProvider.sessions.length;
    final streak = metricsProvider.currentStreak;
    final totalVolume = _calculateTotalVolume(workoutProvider.sessions);

    // Body Metrics
    final double latestWeight = metricsProvider.weightLogs.isNotEmpty
        ? metricsProvider.weightLogs.last.value
        : 72.0;
    final double userHeight = activity.userHeight;
    final int userAge = user?.userMetadata?['age'] as int? ?? 25;
    final double bmiValue = _calculateBmi(latestWeight, userHeight);
    final String bmiStatus = _getBmiStatus(bmiValue);
    final Color bmiColor = _getBmiColor(bmiValue);

    // Unit conversion
    final displayUnit = profileProvider.units;

    String formatVolume(double kgs) {
      if (displayUnit == 'lb') {
        final lbs = kgs * 2.20462;
        if (lbs >= 1000) {
          return '${(lbs / 1000).toStringAsFixed(1)}k lb';
        }
        return '${lbs.toInt()} lb';
      }
      if (kgs >= 1000) {
        return '${(kgs / 1000).toStringAsFixed(1)}k kg';
      }
      return '${kgs.toInt()} kg';
    }

    String formatWeight(double kgs) {
      if (displayUnit == 'lb') {
        return '${(kgs * 2.20462).round()} lb';
      }
      return '${kgs.round()} kg';
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: GerexAppBar.standard(
        title: 'Athlete Profile',
        subtitle: displayName,
        showBackButton: true,
        actions: [
          IconButton(
            icon: FaIcon(
              FontAwesomeIcons.gear,
              size: 18,
              color: isDark ? Colors.white70 : const Color(0xFF334155),
            ),
            tooltip: 'Settings & Preferences',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF0F1319), const Color(0xFF14181F)]
                : [const Color(0xFFF8FAFC), const Color(0xFFEEF2F6)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 40.0),
          children: [
            // ================= 1. HERO PROFILE CARD =================
            HeroMintCard(
              margin: const EdgeInsets.only(bottom: 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      GerexAvatar(
                        imageUrl: photoUrl,
                        initials: initials,
                        size: 64,
                        hasNotification: false,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textLightHeading,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              email,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textLightBody,
                              ),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (c) => AlertDialog(
                                    title: const Text('Edit Athlete Profile'),
                                    content: Text('Name: $displayName\nEmail: $email\nHeight: ${userHeight.toInt()} cm\nWeight: ${formatWeight(latestWeight)}'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(c),
                                        child: const Text('Close'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    FaIcon(FontAwesomeIcons.penToSquare, size: 11, color: AppColors.textLightHeading),
                                    SizedBox(width: 6),
                                    Text('Edit Profile', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textLightHeading)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const FaIcon(FontAwesomeIcons.shareFromSquare, color: AppColors.textLightHeading, size: 18),
                        tooltip: 'Share Card',
                        onPressed: () {
                          _showShareCardDialog(
                            context,
                            displayName,
                            streak,
                            workoutsCount,
                            totalVolume,
                            displayUnit,
                            photoUrl,
                            initials,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ================= 2. BODY METRICS ROW =================
            Row(
              children: [
                Expanded(
                  child: _buildMetricPill(
                    theme,
                    label: 'Height',
                    value: '${userHeight.toInt()} cm',
                    icon: FontAwesomeIcons.rulerVertical,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricPill(
                    theme,
                    label: 'Weight',
                    value: formatWeight(latestWeight),
                    icon: FontAwesomeIcons.weightScale,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricPill(
                    theme,
                    label: 'Age',
                    value: '$userAge yrs',
                    icon: FontAwesomeIcons.calendar,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ================= 3. KEY TRAINING STATS =================
            Row(
              children: [
                Expanded(
                  child: PastelGradientCard(
                    type: PastelCardType.mint,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                    child: Column(
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '$workoutsCount',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w900,
                              color: theme.colorScheme.primary,
                              fontSize: context.sp(26),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('Workouts', style: TextStyle(fontSize: context.sp(12))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: PastelGradientCard(
                    type: PastelCardType.sunset,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                    child: Column(
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (profileProvider.streakFlameEnabled) ...[
                                StreakFlameWidget(
                                  streakCount: streak,
                                  isTodayLogged: metricsProvider.workoutDates.contains(
                                    '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}'
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              Text(
                                '$streak d',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontFamily: 'Outfit',
                                  fontWeight: FontWeight.w900,
                                  color: Colors.orangeAccent,
                                  fontSize: context.sp(26),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('Streak', style: TextStyle(fontSize: context.sp(12))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: PastelGradientCard(
                    type: PastelCardType.indigo,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                    child: Column(
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            formatVolume(totalVolume),
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF818CF8),
                              fontSize: context.sp(26),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('Volume', style: TextStyle(fontSize: context.sp(12))),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ================= 4. BMI SUMMARY CARD =================
            PastelGradientCard(
              type: PastelCardType.sky,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: bmiColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        bmiValue > 0 ? bmiValue.toStringAsFixed(1) : '--',
                        style: TextStyle(fontWeight: FontWeight.w900, color: bmiColor, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Body Mass Index (BMI)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF14181F))),
                        const SizedBox(height: 2),
                        Text('Status: $bmiStatus', style: TextStyle(fontSize: 12, color: bmiColor, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => context.push('/metrics'),
                    icon: const Text('View Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                    label: const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF0284C7)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ================= 5. QUICK NAVIGATION LINKS =================
            Text('Activity & Progress Details', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => context.push('/activity-tracker'),
                    borderRadius: BorderRadius.circular(16),
                    child: const PastelGradientCard(
                      type: PastelCardType.slate,
                      padding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FaIcon(FontAwesomeIcons.clockRotateLeft, size: 14, color: Color(0xFF14181F)),
                          SizedBox(width: 8),
                          Text('Activity History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF14181F))),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () => context.push('/progress-photos'),
                    borderRadius: BorderRadius.circular(16),
                    child: const PastelGradientCard(
                      type: PastelCardType.slate,
                      padding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FaIcon(FontAwesomeIcons.cameraRetro, size: 14, color: Color(0xFF14181F)),
                          SizedBox(width: 8),
                          Text('Progress Snaps', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF14181F))),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ================= 6. ACHIEVEMENTS & BADGES GRID =================
            Text('My Badges & Achievements', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            GridView.count(
              padding: EdgeInsets.zero,
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.25,
              children: [
                _buildBadgeCard(
                  theme,
                  title: 'Consistency Flame',
                  description: 'Reach a streak of 7+ days.',
                  unlocked: metricsProvider.longestStreak >= 7 || metricsProvider.currentStreak >= 7,
                  icon: FontAwesomeIcons.fire,
                  color: Colors.orangeAccent,
                ),
                _buildBadgeCard(
                  theme,
                  title: 'Conqueror',
                  description: 'Complete first challenge.',
                  unlocked: challengeProvider.progressMap.values.any((p) => p.status == 'completed'),
                  icon: FontAwesomeIcons.trophy,
                  color: Colors.amber,
                ),
                _buildBadgeCard(
                  theme,
                  title: 'Iron Centurion',
                  description: 'Log 100+ workouts total.',
                  unlocked: workoutsCount >= 100,
                  icon: FontAwesomeIcons.dumbbell,
                  color: theme.colorScheme.primary,
                ),
                _buildBadgeCard(
                  theme,
                  title: 'Early Bird',
                  description: 'Trained before 9:00 AM.',
                  unlocked: workoutProvider.sessions.any((s) => s.startedAt.hour < 9),
                  icon: FontAwesomeIcons.cloudSun,
                  color: const Color(0xFF38BDF8),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ================= 7. SURPRISE RECOGNITION REWARDS =================
            Text('Surprise Recognition Rewards', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            GridView.count(
              padding: EdgeInsets.zero,
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.25,
              children: [
                _buildBadgeCard(
                  theme,
                  title: 'Great Session!',
                  description: 'A surprise reward for finishing a session.',
                  unlocked: workoutProvider.unlockedSurpriseBadges.contains('surprise_great_session'),
                  icon: FontAwesomeIcons.gift,
                  color: Colors.amber,
                ),
                _buildBadgeCard(
                  theme,
                  title: 'Spark of Energy',
                  description: 'A surprise nod for taking consistency action.',
                  unlocked: workoutProvider.unlockedSurpriseBadges.contains('surprise_energy_spark'),
                  icon: FontAwesomeIcons.bolt,
                  color: const Color(0xFF10B981),
                ),
                _buildBadgeCard(
                  theme,
                  title: 'Mindful Momentum',
                  description: 'A surprise reward for keeping habit loop alive.',
                  unlocked: workoutProvider.unlockedSurpriseBadges.contains('surprise_momentum'),
                  icon: FontAwesomeIcons.circleCheck,
                  color: const Color(0xFF38BDF8),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricPill(ThemeData theme, {required String label, required String value, required dynamic icon}) {
    return PastelGradientCard(
      type: PastelCardType.slate,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      child: Column(
        children: [
          FaIcon(icon, size: 14, color: const Color(0xFF14181F)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF14181F))),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _buildBadgeCard(
    ThemeData theme, {
    required String title,
    required String description,
    required bool unlocked,
    required dynamic icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: unlocked
            ? color.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: unlocked
              ? color.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.05),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: unlocked ? color.withValues(alpha: 0.15) : Colors.white10,
            ),
            child: FaIcon(
              icon,
              color: unlocked ? color : Colors.grey.withValues(alpha: 0.4),
              size: 18,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 11,
              color: unlocked ? theme.colorScheme.onSurface : Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            description,
            style: TextStyle(
              fontSize: 9,
              color: unlocked
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.6)
                  : Colors.grey.withValues(alpha: 0.4),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _showShareCardDialog(
    BuildContext context,
    String name,
    int streak,
    int workouts,
    double totalVolume,
    String unit,
    String? photoUrl,
    String initials,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Share Training Card'),
          content: Text('Athlete: $name\nStreak: $streak days\nWorkouts: $workouts\nTotal Volume: ${totalVolume.toInt()} kg'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                Share.share('Check out my Gerex fitness progress! Streak: $streak days, $workouts workouts completed.');
              },
              child: const Text('Share Text'),
            ),
          ],
        );
      },
    );
  }
}