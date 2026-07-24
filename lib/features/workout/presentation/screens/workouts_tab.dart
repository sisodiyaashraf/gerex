import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/workout_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../ai/presentation/providers/ai_provider.dart';
import 'package:gerex/core/presentation/widgets/glass_container.dart';
import 'package:gerex/core/presentation/widgets/liquid_background.dart';
import 'package:gerex/core/presentation/widgets/animated_tappable.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gerex/core/theme/app_theme.dart';

class WorkoutsTab extends StatefulWidget {
  const WorkoutsTab({super.key});

  @override
  State<WorkoutsTab> createState() => _WorkoutsTabState();
}

class _WorkoutsTabState extends State<WorkoutsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final wp = context.read<WorkoutProvider>();
      await wp.fetchWorkouts();
      await wp.fetchSessions();
      if (mounted) {
        context.read<AIProvider>().loadDailyInsight(wp.sessions);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<WorkoutProvider>(context);

    String formatDuration(int totalSeconds) {
      final mins = totalSeconds ~/ 60;
      return '$mins min';
    }

    return Scaffold(
      body: LiquidBackground(
        child: RefreshIndicator(
          onRefresh: () async {
            final ai = context.read<AIProvider>();
            await provider.fetchWorkouts();
            await provider.fetchSessions();
            await ai.loadDailyInsight(provider.sessions, forceRefresh: true);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverAppBar.large(
                title: const Text('Gerex Workout'),
                backgroundColor: Colors.transparent,
                scrolledUnderElevation: 0,
                elevation: 0,
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: Consumer<AuthProvider>(
                      builder: (context, auth, _) {
                        final photoUrl = auth.user?.userMetadata?['avatar_url'] ??
                            auth.user?.userMetadata?['picture'];
                        final displayName = auth.user?.userMetadata?['full_name'] ??
                            auth.user?.userMetadata?['name'] ??
                            auth.user?.email ??
                            '';
                        final initials = displayName.isNotEmpty
                            ? displayName.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
                            : 'G';

                        return GestureDetector(
                          onTap: () => context.push('/profile'),
                          child: CircleAvatar(
                            radius: 18,
                            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                            child: photoUrl == null
                                ? Text(
                                    initials,
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 100.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Live Session Alert Banner if active
                    if (provider.isSessionActive) ...[
                      GlassContainer(
                        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.15),
                        child: ListTile(
                          leading: FaIcon(
                            FontAwesomeIcons.dumbbell,
                            color: theme.colorScheme.primary,
                          ),
                          title: Text(
                            'Workout in Progress',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          subtitle: Text(
                            'Active Session: ${provider.activeSessionName}',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: theme.colorScheme.primary,
                            size: 16,
                          ),
                          onTap: () {
                            context.push('/session');
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // AI Daily Insight Card
                    Consumer<AIProvider>(
                      builder: (context, ai, _) {
                        if (ai.isInsightLoading) {
                          return GlassContainer(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  'Generating coach insight...',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        if (ai.dailyInsight != null) {
                          return GlassContainer(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    FaIcon(
                                      FontAwesomeIcons.wandMagicSparkles,
                                      color: theme.colorScheme.primary,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Daily Coach Insight',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  ai.dailyInsight!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return const SizedBox.shrink();
                      },
                    ),

                    // Quick Actions Row
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              provider.startEmptyWorkoutSession();
                              context.push('/session');
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                gradient: GerexGradients.primaryCTA,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  FaIcon(FontAwesomeIcons.bolt, color: Colors.white, size: 16),
                                  SizedBox(width: 8),
                                  Text(
                                    'Quick Start',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: FaIcon(FontAwesomeIcons.circlePlus, color: theme.colorScheme.primary, size: 16),
                            label: const Text('New Template'),
                            onPressed: () {
                              context.push('/builder');
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'AI Training Assistant',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: AnimatedTappable(
                            onTap: () => context.push('/coach'),
                            child: const GlassContainer(
                              padding: EdgeInsets.symmetric(vertical: 16.0),
                              child: Column(
                                children: [
                                  FaIcon(FontAwesomeIcons.solidCommentDots, size: 20),
                                  SizedBox(height: 8),
                                  Text(
                                    'AI Coach',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AnimatedTappable(
                            onTap: () => context.push('/ai-plan'),
                            child: const GlassContainer(
                              padding: EdgeInsets.symmetric(vertical: 16.0),
                              child: Column(
                                children: [
                                  FaIcon(FontAwesomeIcons.wandMagicSparkles, size: 20),
                                  SizedBox(height: 8),
                                  Text(
                                    'Plan Gen',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AnimatedTappable(
                            onTap: () => context.push('/pose-feedback'),
                            child: const GlassContainer(
                              padding: EdgeInsets.symmetric(vertical: 16.0),
                              child: Column(
                                children: [
                                  FaIcon(FontAwesomeIcons.video, size: 20),
                                  SizedBox(height: 8),
                                  Text(
                                    'Form Check',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Templates Section
                    Text(
                      'My Templates',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (provider.isLoading && provider.workouts.isEmpty)
                      const Center(child: CircularProgressIndicator())
                    else if (provider.workouts.isEmpty)
                      GlassContainer(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          'No templates saved. Create one to standardise your routines!',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: provider.workouts.length,
                        itemBuilder: (context, index) {
                          final workout = provider.workouts[index];
                          return AnimatedTappable(
                            onTap: () {
                              provider.startWorkoutSession(workout);
                              context.push('/session');
                            },
                            child: GlassContainer(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          workout.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${workout.exercises.length} exercises',
                                          style: TextStyle(
                                            color: theme.colorScheme.onSurface
                                                .withValues(alpha: 0.5),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.play_arrow_rounded,
                                    color: theme.colorScheme.primary,
                                    size: 28,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 24),

                    // Sessions History Log Section
                    Text(
                      'Workout History Log',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (provider.isLoading && provider.sessions.isEmpty)
                      const Center(child: CircularProgressIndicator())
                    else if (provider.sessions.isEmpty)
                      GlassContainer(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          'No completed workouts in history yet.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: provider.sessions.length,
                        itemBuilder: (context, index) {
                          final session = provider.sessions[index];
                          final date = session.completedAt ?? session.startedAt;
                          return GlassContainer(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Theme(
                              data: theme.copyWith(dividerColor: Colors.transparent),
                              child: ExpansionTile(
                                iconColor: theme.colorScheme.primary,
                                collapsedIconColor: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                title: Text(
                                  session.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  '${date.day}/${date.month}/${date.year} • ${formatDuration(session.durationSeconds)}',
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        if (session.loggedSets.isEmpty)
                                          const Text('No logged sets.')
                                        else
                                          ...session.loggedSets.map((setLog) {
                                            return Padding(
                                              padding: const EdgeInsets.only(bottom: 6),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    setLog.exercise?.name ?? 'Exercise',
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Set ${setLog.setNumber}: ${setLog.weight} kg x ${setLog.reps}',
                                                  ),
                                                ],
                                              ),
                                            );
                                          }),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 40),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
