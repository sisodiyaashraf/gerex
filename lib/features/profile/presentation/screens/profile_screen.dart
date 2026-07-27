import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../workout/presentation/providers/workout_provider.dart';
import '../../../metrics/presentation/providers/metrics_provider.dart';
import '../providers/profile_provider.dart';
import 'package:gerex/features/ai/presentation/providers/ai_provider.dart';
import 'package:gerex/core/presentation/widgets/glass_container.dart';
import 'package:gerex/core/presentation/widgets/liquid_background.dart';
import 'package:gerex/core/theme/app_theme.dart';
import '../../../../core/presentation/providers/theme_provider.dart';
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

    // Weight and Trend
    final weightLogs = metricsProvider.weightLogs;
    double? currentWeight;
    String trendText = 'Stable';
    dynamic trendIcon = FontAwesomeIcons.minus;
    Color trendColor = theme.colorScheme.onSurface.withValues(alpha: 0.5);

    if (weightLogs.isNotEmpty) {
      currentWeight = weightLogs.last.value;
      if (weightLogs.length >= 2) {
        final last = weightLogs.last.value;
        final prev = weightLogs[weightLogs.length - 2].value;
        final diff = last - prev;
        
        if (diff > 0.01) {
          trendText = '+${diff.toStringAsFixed(1)} kg';
          trendIcon = FontAwesomeIcons.arrowUp;
          trendColor = Colors.redAccent;
        } else if (diff < -0.01) {
          trendText = '${diff.toStringAsFixed(1)} kg';
          trendIcon = FontAwesomeIcons.arrowDown;
          trendColor = Colors.greenAccent;
        }
      }
    }

    // Convert values if Unit preference is Lb
    final displayUnit = profileProvider.units;
    String formatWeight(double? kgs) {
      if (kgs == null) return '--';
      if (displayUnit == 'lb') {
        final lbs = kgs * 2.20462;
        return '${lbs.toStringAsFixed(1)} lb';
      }
      return '${kgs.toStringAsFixed(1)} kg';
    }

    String formatVolume(double kgs) {
      if (displayUnit == 'lb') {
        final lbs = kgs * 2.20462;
        return '${(lbs / 1000).toStringAsFixed(1)}k lbs';
      }
      return '${(kgs / 1000).toStringAsFixed(1)}k kg';
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
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Confirm Sign Out',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Are you sure you want to sign out? Your local data will be saved but offline sync will be suspended.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          Navigator.pop(context); // close modal sheet
                          await authProvider.signOut();
                          if (context.mounted) {
                            context.go('/login');
                          }
                        },
                        child: const Text('Sign Out'),
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

    return Scaffold(
      body: LiquidBackground(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Collapse-safe Sliver App Bar
            SliverAppBar(
              expandedHeight: 180.0,
              floating: false,
              pinned: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Profile Settings',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                centerTitle: true,
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Base visual gradient
                    Container(
                      decoration: const BoxDecoration(
                        gradient: GerexGradients.darkBaseBackground,
                      ),
                    ),
                    // Light overlay for styling
                    Container(
                      color: theme.colorScheme.primary.withValues(alpha: 0.05),
                    ),
                  ],
                ),
              ),
            ),

            // Profile Content body
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // User Details Header Glass Card
                  GlassContainer(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        // Avatar Photo
                        CircleAvatar(
                          radius: 46,
                          backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                          child: photoUrl == null
                              ? Text(
                                  initials,
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          displayName,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                Text(
                                  '${activity.userHeight.toInt()} cm',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                Text(
                                  'Height',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                            Container(width: 1, height: 24, color: theme.colorScheme.onSurface.withValues(alpha: 0.15)),
                            Column(
                              children: [
                                Text(
                                  formatWeight(currentWeight),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                Text(
                                  'Weight',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                            Container(width: 1, height: 24, color: theme.colorScheme.onSurface.withValues(alpha: 0.15)),
                            Column(
                              children: [
                                const Text(
                                  '24 yrs',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                Text(
                                  'Age',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stats Dashboard Row
                  Row(
                    children: [
                      Expanded(
                        child: GlassContainer(
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
                        child: GlassContainer(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                          child: Column(
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '$streak d',
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    fontFamily: 'Outfit',
                                    fontWeight: FontWeight.w900,
                                    color: Colors.orangeAccent,
                                    fontSize: context.sp(28),
                                  ),
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
                        child: GlassContainer(
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
                  const SizedBox(height: 16),

                  // Body Weight Metrics Card
                  GestureDetector(
                    onTap: () => context.push('/analytics'), // redirect to metrics dashboard tab
                    child: GlassContainer(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              FaIcon(
                                FontAwesomeIcons.weightScale,
                                color: theme.colorScheme.primary,
                                size: 22,
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Body Weight Metric',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Latest Weight: ${formatWeight(currentWeight)}',
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (weightLogs.length >= 2)
                            Row(
                              children: [
                                FaIcon(trendIcon, color: trendColor, size: 14.0),
                                const SizedBox(width: 6),
                                Text(
                                  trendText,
                                  style: TextStyle(
                                    color: trendColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
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
                          content: Text('Name: $displayName\nEmail: $email\nHeight: ${activity.userHeight.toInt()} cm\nWeight: ${currentWeight ?? 70.0} kg'),
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
                  const SizedBox(height: 8),
                  _buildSettingsRow(
                    icon: FontAwesomeIcons.award,
                    title: 'Achievements Badges',
                    trailing: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                      size: 14,
                    ),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (c) => Dialog(
                          backgroundColor: Colors.transparent,
                          child: GlassContainer(
                            padding: const EdgeInsets.all(20),
                            borderRadius: 24,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'My Achievements Badges',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                _buildBadgeRow(
                                  theme,
                                  title: 'Consistency Champion',
                                  description: 'Keep a workout streak of 3+ days.',
                                  unlocked: streak >= 3,
                                  icon: FontAwesomeIcons.fire,
                                  color: Colors.orangeAccent,
                                ),
                                const SizedBox(height: 12),
                                _buildBadgeRow(
                                  theme,
                                  title: 'Iron Initiate',
                                  description: 'Log 5+ completed workouts in total.',
                                  unlocked: workoutsCount >= 5,
                                  icon: FontAwesomeIcons.dumbbell,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(height: 12),
                                 _buildBadgeRow(
                                   theme,
                                   title: 'AI Disciple',
                                   description: 'Leverage AI Coach or Plan Generation.',
                                   unlocked: true,
                                   icon: FontAwesomeIcons.wandMagicSparkles,
                                   color: const Color(0xFF818CF8),
                                 ),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(c),
                                  child: const Text('Awesome'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildSettingsRow(
                    icon: FontAwesomeIcons.calendarCheck,
                    title: 'Activity History Log',
                    trailing: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                      size: 14,
                    ),
                    onTap: () => context.push('/activity-tracker'),
                  ),
                  const SizedBox(height: 8),
                  _buildSettingsRow(
                    icon: FontAwesomeIcons.chartLine,
                    title: 'Workout Progress Chart',
                    trailing: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                      size: 14,
                    ),
                    onTap: () => context.push('/workout-tracker'),
                  ),
                  const SizedBox(height: 8),
                  _buildSettingsRow(
                    icon: FontAwesomeIcons.images,
                    title: 'Progress Photos Gallery',
                    trailing: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                      size: 14,
                    ),
                    onTap: () => context.push('/progress-photos'),
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
                      onChanged: (bool value) {
                        profileProvider.toggleNotifications(value);
                      },
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Theme Selection settings item
                  _buildSettingsRow(
                    icon: FontAwesomeIcons.circleHalfStroke,
                    title: 'App Theme',
                    trailing: DropdownButton<String>(
                      value: profileProvider.themeMode,
                      underline: const SizedBox.shrink(),
                      items: const [
                        DropdownMenuItem(value: 'system', child: Text('System')),
                        DropdownMenuItem(value: 'light', child: Text('Light')),
                        DropdownMenuItem(value: 'dark', child: Text('Dark')),
                      ],
                      onChanged: (String? val) {
                        if (val != null) {
                          profileProvider.setThemeMode(val);
                          final mode = val == 'dark'
                              ? ThemeMode.dark
                              : val == 'light'
                                  ? ThemeMode.light
                                  : ThemeMode.system;
                          Provider.of<ThemeProvider>(context, listen: false).setThemeMode(mode);
                        }
                      },
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

                  // Subscription Plan settings item
                  _buildSettingsRow(
                    icon: FontAwesomeIcons.creditCard,
                    title: 'Subscription Plan',
                    trailing: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                      size: 14,
                    ),
                    onTap: () => context.push('/select-plan'),
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
                    child: GlassContainer(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      color: Colors.redAccent.withValues(alpha: 0.1),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FaIcon(
                            FontAwesomeIcons.rightFromBracket,
                            color: Colors.redAccent,
                            size: 18,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Sign Out',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                ]),
              ),
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
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                FaIcon(
                  icon,
                  size: 16.0,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeRow(
    ThemeData theme, {
    required String title,
    required String description,
    required bool unlocked,
    required dynamic icon,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (unlocked ? color : Colors.grey).withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: unlocked ? color : Colors.grey.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Center(
              child: FaIcon(
                icon,
                color: unlocked ? color : Colors.grey,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: unlocked ? null : Colors.grey,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          Text(
            unlocked ? 'Unlocked' : 'Locked',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: unlocked ? theme.colorScheme.primary : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
