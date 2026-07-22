import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/workout_provider.dart';
import 'package:gerex/core/presentation/widgets/glass_container.dart';
import 'package:gerex/core/presentation/widgets/liquid_background.dart';
import 'package:gerex/core/presentation/widgets/animated_tappable.dart';

class WorkoutsTab extends StatefulWidget {
  const WorkoutsTab({super.key});

  @override
  State<WorkoutsTab> createState() => _WorkoutsTabState();
}

class _WorkoutsTabState extends State<WorkoutsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkoutProvider>().fetchWorkouts();
      context.read<WorkoutProvider>().fetchSessions();
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
      appBar: AppBar(
        title: const Text('Gerex Workout'),
      ),
      body: LiquidBackground(
        child: RefreshIndicator(
        onRefresh: () async {
          await provider.fetchWorkouts();
          await provider.fetchSessions();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Live Session Alert Banner if active
              if (provider.isSessionActive) ...[
                Card(
                  color: theme.colorScheme.primaryContainer,
                  child: ListTile(
                    leading: Icon(
                      Icons.fitness_center_rounded,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    title: Text(
                      'Workout in Progress',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    subtitle: Text(
                      'Active Session: ${provider.activeSessionName}',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer
                            .withValues(alpha: 0.8),
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    onTap: () {
                      context.push('/session');
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Quick Actions Row
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.flash_on),
                      label: const Text('Quick Start'),
                      onPressed: () {
                        provider.startEmptyWorkoutSession();
                        context.push('/session');
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.playlist_add),
                      label: const Text('New Template'),
                      onPressed: () {
                        context.push('/builder');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'AI Training Assistant',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: AnimatedTappable(
                      onTap: () => context.push('/coach'),
                      child: const GlassContainer(
                        padding: EdgeInsets.symmetric(vertical: 12.0),
                        child: Column(
                          children: [
                            Icon(Icons.chat_bubble_outline_rounded),
                            SizedBox(height: 6),
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
                        padding: EdgeInsets.symmetric(vertical: 12.0),
                        child: Column(
                          children: [
                            Icon(Icons.auto_awesome_outlined),
                            SizedBox(height: 6),
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
                        padding: EdgeInsets.symmetric(vertical: 12.0),
                        child: Column(
                          children: [
                            Icon(Icons.camera_alt_outlined),
                            SizedBox(height: 6),
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
                Card(
                  child: Padding(
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
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ExpansionTile(
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
                    );
                  },
                ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    ),
    );
  }
}
