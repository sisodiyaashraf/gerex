import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../../challenges/presentation/providers/challenge_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../workout/presentation/providers/workout_provider.dart';
import '../../../metrics/presentation/providers/metrics_provider.dart';
import '../../../metrics/presentation/widgets/streak_flame_widget.dart';
import '../providers/profile_provider.dart';
import 'package:gerex/features/ai/presentation/providers/ai_provider.dart';
import 'package:gerex/core/presentation/widgets/glass_container.dart';
import 'package:gerex/core/presentation/widgets/pastel_gradient_card.dart';
import 'package:gerex/core/presentation/widgets/hero_mint_card.dart';
import 'package:gerex/core/presentation/widgets/gerex_avatar.dart';
import 'package:gerex/core/presentation/widgets/gerex_button.dart';
import 'package:gerex/core/theme/app_theme.dart';
import 'package:gerex/core/providers/notification_provider.dart';
import 'package:gerex/core/notifications/notification_models.dart';
import 'package:gerex/core/notifications/content_packs.dart';

import 'package:gerex/core/presentation/utils/responsive_helper.dart';
import 'package:gerex/core/providers/activity_provider.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
        user?.email ??
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

    // Convert values if Unit preference is Lb
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

    void showLogoutConfirmation() {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return GlassContainer(
            borderRadius: 24,
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.textDarkMuted,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Confirm Sign Out',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDarkHeading,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Are you sure you want to sign out? Your local data will be saved but offline sync will be suspended.',
                  style: TextStyle(
                    color: AppColors.textDarkMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: GerexButton(
                        text: 'Cancel',
                        style: GerexButtonStyle.whitePill,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GerexButton(
                        text: 'Sign Out',
                        style: GerexButtonStyle.destructive,
                        onPressed: () async {
                          Navigator.pop(context);
                          await authProvider.signOut();
                          if (context.mounted) {
                            context.go('/login');
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    }

    final isDark = theme.brightness == Brightness.dark;
    const accentColor = Color(0xFF10B981); // Emerald Green / Profile accent

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Profile & Settings',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
        child: Stack(
          children: [
            // Decorative glow blobs
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: isDark ? 0.15 : 0.06),
                      blurRadius: 100,
                      spreadRadius: 50,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 100,
              left: -150,
              child: Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: isDark ? 0.1 : 0.04),
                      blurRadius: 120,
                      spreadRadius: 60,
                    ),
                  ],
                ),
              ),
            ),
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              16.0,
              MediaQuery.of(context).padding.top + AppBar().preferredSize.height + 12.0,
              16.0,
              12.0,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Signature Hero Mint Card Profile Summary
                HeroMintCard(
                  margin: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          GerexAvatar(
                            imageUrl: photoUrl,
                            initials: initials,
                            size: 60,
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
                                    fontSize: 18,
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
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const FaIcon(FontAwesomeIcons.shareFromSquare, color: AppColors.textLightHeading, size: 18),
                            tooltip: 'Share Training Card',
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
                const SizedBox(height: 20),



                // Stats Dashboard Row
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
                                  fontSize: context.sp(28),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Workouts',
                                style: TextStyle(fontSize: context.sp(12)),
                              ),
                            ),
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
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (profileProvider.streakFlameEnabled) ...[
                                    StreakFlameWidget(
                                      streakCount: streak,
                                      isTodayLogged: metricsProvider.workoutDates.contains(
                                        '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}'
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Text(
                                    '$streak d',
                                    style: theme.textTheme.headlineMedium?.copyWith(
                                      fontFamily: 'Outfit',
                                      fontWeight: FontWeight.w900,
                                      color: Colors.orangeAccent,
                                      fontSize: context.sp(28),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Streak',
                                style: TextStyle(fontSize: context.sp(12)),
                              ),
                            ),
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
                                  fontSize: context.sp(28),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Volume',
                                style: TextStyle(fontSize: context.sp(12)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                  const SizedBox(height: 24),

                  // Badge Achievements Grid Title
                  Text(
                    'My Badges & Achievements',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Grid of Badges
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

                  // Surprise Badges Grid Title
                  Text(
                    'Surprise Recognition Rewards',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Grid of Surprise Badges
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
                  const SizedBox(height: 24),

                  // Account Section
                  Text(
                    'Account details',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSettingsRow(
                    icon: FontAwesomeIcons.solidUser,
                    title: 'Personal Data',
                    trailing: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                      size: 14,
                    ),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: const Text('Personal Data'),
                          content: Text('Name: $displayName\nEmail: $email\nHeight: ${activity.userHeight.toInt()} cm'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(c),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),



                  const SizedBox(height: 24),

                  // Settings Section Title
                  Text(
                    'Preferences & Settings',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Unit preference row settings item
                  _buildSettingsRow(
                    icon: FontAwesomeIcons.circleQuestion,
                    title: 'Weight Units',
                    trailing: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'kg', label: Text('KG')),
                        ButtonSegment(value: 'lb', label: Text('LB')),
                      ],
                      selected: {profileProvider.units},
                      onSelectionChanged: (Set<String> selection) {
                        profileProvider.setUnits(selection.first);
                      },
                      style: const ButtonStyle(
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Push Notifications settings item
                  _buildSettingsRow(
                    icon: FontAwesomeIcons.solidBell,
                    title: 'Push Notifications',
                    trailing: Switch.adaptive(
                      value: profileProvider.notificationsEnabled,
                      onChanged: (bool value) async {
                        if (!value) { await profileProvider.toggleNotifications(false); return; }
                        final notificationProvider = context.read<NotificationProvider>();
                        final explain = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(title: const Text('Stay on track with Gerex?'), content: const Text('We use reminders for your planned meals, workouts, sleep and progress. You control the categories and can turn them off anytime.'), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Not now')), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Continue'))]));
                        if (explain == true) {
                          final granted = await notificationProvider.requestSystemPermission();
                          if (granted) await profileProvider.toggleNotifications(true);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildSettingsRow(
                    icon: FontAwesomeIcons.volumeHigh,
                    title: 'Voice Coaching',
                    trailing: Switch.adaptive(
                      value: profileProvider.voiceCoachingEnabled,
                      onChanged: (bool value) {
                        profileProvider.toggleVoiceCoaching(value);
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Consumer<NotificationProvider>(builder: (context, notifications, _) => _buildSettingsRow(
                     icon: FontAwesomeIcons.language,
                     title: 'Notification Content',
                     trailing: DropdownButton<String>(
                       value: notifications.service.contentPack.id,
                       underline: const SizedBox.shrink(),
                       dropdownColor: theme.cardColor,
                       style: const TextStyle(
                         color: Color(0xFF14181F),
                         fontWeight: FontWeight.bold,
                         fontSize: 13,
                       ),
                       items: NotificationContentPacks.all.map((pack) => DropdownMenuItem(
                         value: pack.id,
                         child: Text(
                           pack.label,
                           style: TextStyle(
                             color: theme.brightness == Brightness.dark
                                 ? Colors.white
                                 : const Color(0xFF14181F),
                           ),
                         ),
                       )).toList(),
                       onChanged: notifications.setContentPack,
                     ),
                   )),

                  const SizedBox(height: 8),
                  _buildSettingsRow(
                    icon: FontAwesomeIcons.vial,
                    title: 'Test Notification (Dev)',
                    trailing: OutlinedButton(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Theme.of(context).cardColor,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (context) => ListView(
                            shrinkWrap: true,
                            padding: const EdgeInsets.all(16),
                            children: [
                              Text(
                                'Select Notification Category',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ...NotificationCategory.values.map((cat) {
                                IconData icon;
                                String title;
                                String body;
                                String route;
                                switch (cat) {
                                  case NotificationCategory.workouts:
                                    icon = Icons.fitness_center;
                                    title = 'Chest Workout starts soon';
                                    body = '11 exercises · 32 min';
                                    route = '/workout-tracker';
                                    break;
                                  case NotificationCategory.meals:
                                    icon = Icons.restaurant;
                                    title = 'Time for Honey Pancakes';
                                    body = 'Breakfast · 230 kcal';
                                    route = '/meal-planner';
                                    break;
                                  case NotificationCategory.sleep:
                                    icon = Icons.nights_stay;
                                    title = 'Bedtime Reminder (Goal: 8.0 hrs)';
                                    body = 'Wind down now to complete your recovery goal.';
                                    route = '/sleep-tracker';
                                    break;
                                  case NotificationCategory.hydration:
                                    icon = Icons.water_drop;
                                    title = 'Hydration Nudge';
                                    body = 'Drink 250ml water to match your target.';
                                    route = '/activity-tracker';
                                    break;
                                  case NotificationCategory.progress:
                                    icon = Icons.photo_library;
                                    title = 'Progress Photo Check';
                                    body = 'Upload a new snap to compare consistency progress.';
                                    route = '/progress-photos';
                                    break;
                                  case NotificationCategory.aiCoach:
                                    icon = Icons.psychology;
                                    title = 'New AI Health Insight';
                                    body = 'Your weekly metrics logs recap is ready.';
                                    route = '/coach';
                                    break;
                                  case NotificationCategory.general:
                                    icon = Icons.emoji_events;
                                    title = 'Streak milestone reached!';
                                    body = 'You are on a 7-day streak! Keep active.';
                                    route = '/notifications';
                                    break;
                                }
                                return ListTile(
                                  leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
                                  title: Text(cat.name.toUpperCase()),
                                  subtitle: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                                  onTap: () async {
                                    Navigator.pop(context);
                                    final provider = context.read<NotificationProvider>();
                                    await provider.showCustomNotification(
                                      NotificationPayload(
                                        id: 'test_${cat.name}',
                                        title: title,
                                        body: body,
                                        category: cat,
                                        scheduledTime: DateTime.now(),
                                        deepLink: route,
                                      ),
                                    );
                                  },
                                );
                              }),
                            ],
                          ),
                        );
                      },
                      child: const Text('Test'),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Offline-Only AI toggle settings item
                  Consumer<AIProvider>(
                    builder: (context, aiProvider, _) {
                      return _buildSettingsRow(
                        icon: FontAwesomeIcons.robot,
                        title: 'Offline-Only AI Coach',
                        trailing: Switch.adaptive(
                          value: aiProvider.isOfflineOnly,
                          activeThumbColor: theme.colorScheme.primary,
                          onChanged: (val) => aiProvider.setOfflineOnly(val),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildSettingsRow(
                    icon: FontAwesomeIcons.bolt,
                    title: 'Workout Haptic Feedback',
                    trailing: Switch.adaptive(
                      value: profileProvider.hapticsEnabled,
                      onChanged: (val) => profileProvider.toggleHaptics(val),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildSettingsRow(
                    icon: FontAwesomeIcons.fire,
                    title: 'Animated Streak Flame',
                    trailing: Switch.adaptive(
                      value: profileProvider.streakFlameEnabled,
                      onChanged: (val) => profileProvider.toggleStreakFlame(val),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildSettingsRow(
                    icon: FontAwesomeIcons.gift,
                    title: 'Confetti PR Celebrations',
                    trailing: Switch.adaptive(
                      value: profileProvider.confettiEnabled,
                      onChanged: (val) => profileProvider.toggleConfetti(val),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildSettingsRow(
                    icon: FontAwesomeIcons.ghost,
                    title: 'AR Ghost Trainer Silhouette',
                    trailing: Switch.adaptive(
                      value: profileProvider.ghostTrainerEnabled,
                      onChanged: (val) => profileProvider.toggleGhostTrainer(val),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Subscription Plan settings item
                  _buildSettingsRow(
                    icon: FontAwesomeIcons.creditCard,
                    title: 'Subscription Plan',
                    trailing: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                      size: 14,
                    ),
                    onTap: () => _showSubscriptionBottomSheet(context, theme, isDark),
                  ),
                  const SizedBox(height: 8),

                  // Manage Data / Privacy settings item
                  _buildSettingsRow(
                    icon: FontAwesomeIcons.shieldHalved,
                    title: 'Privacy & Security',
                    trailing: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                      size: 14,
                    ),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Manage Data options is under development.')),
                      );
                    },
                  ),
                  const SizedBox(height: 8),

                  // Help settings item
                  _buildSettingsRow(
                    icon: FontAwesomeIcons.circleInfo,
                    title: 'Help & About',
                    trailing: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                      size: 14,
                    ),
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'Gerex',
                        applicationVersion: '1.0.0',
                        applicationLegalese: '© 2026 Gerex Dev Team',
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Sign Out button settings item
                  InkWell(
                    onTap: showLogoutConfirmation,
                    borderRadius: BorderRadius.circular(16),
                    child: const PastelGradientCard(
                      type: PastelCardType.rose,
                      padding: EdgeInsets.symmetric(vertical: 14.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FaIcon(
                            FontAwesomeIcons.rightFromBracket,
                            color: Color(0xFFC7363B),
                            size: 16,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Sign Out',
                            style: TextStyle(
                              color: Color(0xFFC7363B),
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsRow({
    required dynamic icon,
    required String title,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: PastelGradientCard(
        type: PastelCardType.slate,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF14181F).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: FaIcon(
                  icon,
                  size: 14.0,
                  color: const Color(0xFF14181F),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF14181F),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            trailing,
          ],
        ),
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
    final GlobalKey boundaryKey = GlobalKey();

    // Calculate favorite category
    final wp = Provider.of<WorkoutProvider>(context, listen: false);
    final favoriteCategory = wp.sessions.isEmpty
        ? 'General Fitness'
        : () {
            final Map<String, int> counts = {};
            for (final s in wp.sessions) {
              for (final setLog in s.loggedSets) {
                final muscle = setLog.exercise?.muscleGroup ?? 'General';
                counts[muscle] = (counts[muscle] ?? 0) + 1;
              }
            }
            if (counts.isEmpty) return 'General Fitness';
            final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
            return sorted.first.key;
          }();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RepaintBoundary(
                key: boundaryKey,
                child: Container(
                  width: 320,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.accentEmeraldLight.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          GerexAvatar(
                            imageUrl: photoUrl,
                            initials: initials,
                            size: 48,
                            hasNotification: false,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const Text(
                                  'Gerex Certified Athlete',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.accentEmeraldLight,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '🔥 Current Streak',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            Text(
                              '$streak Days',
                              style: const TextStyle(
                                color: Colors.orangeAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '💪 Total Workouts',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            Text(
                              '$workouts Logged',
                              style: const TextStyle(
                                color: AppColors.accentEmeraldLight,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '🏋️ Focus Category',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            Text(
                              favoriteCategory,
                              style: const TextStyle(
                                color: Color(0xFF818CF8),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Icon(
                        Icons.verified_user_rounded,
                        size: 36,
                        color: AppColors.accentEmeraldLight,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Gerex • Smarter Offline Fitness',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.white38,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentEmeraldLight,
                      foregroundColor: const Color(0xFF14181F),
                    ),
                    onPressed: () async {
                      try {
                        final RenderRepaintBoundary? boundary =
                            boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
                        if (boundary == null) return;
                        
                        if (boundary.debugNeedsPaint) {
                          await Future.delayed(const Duration(milliseconds: 100));
                        }
                        
                        final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
                        final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
                        final Uint8List? pngBytes = byteData?.buffer.asUint8List();
                        
                        if (pngBytes != null) {
                          final tempDir = await getTemporaryDirectory();
                          final file = await File('${tempDir.path}/gerex_training_card_${DateTime.now().millisecondsSinceEpoch}.png').create();
                          await file.writeAsBytes(pngBytes);
                          
                          await Share.shareXFiles(
                            [XFile(file.path)],
                            text: 'Check out my training stats on Gerex! 💪🔥',
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to share training card: $e')),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.share_rounded),
                    label: const Text('Share Card'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSubscriptionBottomSheet(BuildContext context, ThemeData theme, bool isDark) {
    bool isAnnual = true;
    const double monthlyPrice = 9.99;
    const double annualPrice = 89.99;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              maxChildSize: 0.9,
              minChildSize: 0.5,
              builder: (_, scrollController) {
                return GlassContainer(
                  borderRadius: 24,
                  padding: const EdgeInsets.all(24),
                  child: ListView(
                    controller: scrollController,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Choose Your Plan',
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF0B1220),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Unlock your ultimate athletic aesthetic with Gerex Premium',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: const Color(0xFF475569),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      
                      // Toggle Switch
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () => setLocalState(() => isAnnual = false),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    color: !isAnnual ? const Color(0xFF10B981) : Colors.transparent,
                                  ),
                                  child: Text(
                                    'Monthly',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: !isAnnual ? Colors.white : const Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => setLocalState(() => isAnnual = true),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    color: isAnnual ? const Color(0xFF10B981) : Colors.transparent,
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        'Annual',
                                        style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isAnnual ? Colors.white : const Color(0xFF64748B),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0F1319),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          'Save 25%',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w900,
                                            color: Color(0xFF10B981),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Plan card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              isAnnual ? 'ANNUAL MEMBERSHIP' : 'MONTHLY MEMBERSHIP',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF10B981),
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isAnnual
                                  ? '\$${annualPrice.toStringAsFixed(2)}/yr'
                                  : '\$${monthlyPrice.toStringAsFixed(2)}/mo',
                              style: GoogleFonts.outfit(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF0B1220),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isAnnual
                                  ? 'Billed once at \$${annualPrice.toStringAsFixed(2)}, renews unless cancelled'
                                  : 'Billed once at \$${monthlyPrice.toStringAsFixed(2)}, renews unless cancelled',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            if (isAnnual) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Best Value: \$7.50 / month',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF10B981),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Feature checklist
                      Text(
                        'All Unlocked Features',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0B1220),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            _buildFeatureRowItem('Unlimited Live Workout Logging'),
                            const SizedBox(height: 10),
                            _buildFeatureRowItem('Realtime Pose-Check AI coach feedback'),
                            const SizedBox(height: 10),
                            _buildFeatureRowItem('Personalized dynamic routine blueprints'),
                            const SizedBox(height: 10),
                            _buildFeatureRowItem('Detailed analytics history charts'),
                            const SizedBox(height: 10),
                            _buildFeatureRowItem('Weekly progress photos tracking'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      GerexButton(
                        text: 'Activate Subscription',
                        onPressed: () {
                          Navigator.pop(context);
                          _showComingSoonSubscriptionDialog(context);
                        },
                      ),
                      const SizedBox(height: 20),
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

  Widget _buildFeatureRowItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF1E293B)),
          ),
        ),
      ],
    );
  }

  void _showComingSoonSubscriptionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.transparent,
          content: GlassContainer(
            padding: const EdgeInsets.all(24),
            borderRadius: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.payments_outlined,
                    color: Color(0xFF10B981),
                    size: 36,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Coming Soon!',
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0B1220)),
                ),
                const SizedBox(height: 12),
                Text(
                  'Premium subscription plans are currently under development. Real payment integration will be wired up in a future update.',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: const Color(0xFF475569),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                GerexButton(
                  text: 'Got it',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}