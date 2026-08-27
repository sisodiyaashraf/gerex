import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/sleep_provider.dart';
import 'package:gerex/core/presentation/widgets/pastel_gradient_card.dart';
import 'package:gerex/core/presentation/widgets/gerex_scaffold.dart';
import 'package:gerex/core/theme/app_theme.dart';

class SleepScheduleScreen extends StatefulWidget {
  const SleepScheduleScreen({super.key});

  @override
  State<SleepScheduleScreen> createState() => _SleepScheduleScreenState();
}

class _SleepScheduleScreenState extends State<SleepScheduleScreen> {
  int _selectedDayIndex = DateTime.now().weekday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sleepProvider = Provider.of<SleepProvider>(context);

    final activeAlarmsForDay = sleepProvider.alarms.where((a) => a.repeatDays.contains(_selectedDayIndex)).toList();

    return GerexScaffold(
      appBar: AppBar(
        title: Text(
          'Sleep Schedule',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textDarkHeading,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                  // Ideal Hours card
                  PastelGradientCard(
                    type: PastelCardType.violet,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                          child: FaIcon(FontAwesomeIcons.circleCheck, color: theme.colorScheme.primary, size: 16),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Ideal Hours for Sleep',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Maintain 7.5 - 9.0 hours of daily sleep for optimal athletic muscle recovery.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: const Color(0xFF14181F).withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Horizontal weekday selector
                  const Text(
                    'Select Day of Week',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 64,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 7,
                      itemBuilder: (context, index) {
                        final dayIndex = index + 1; // Mon=1, Sun=7
                        final isSelected = dayIndex == _selectedDayIndex;
                        const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedDayIndex = dayIndex),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              width: 52,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: isSelected ? GerexGradients.primaryCTA : null,
                                color: isSelected ? null : theme.colorScheme.surface.withValues(alpha: 0.05),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.transparent
                                      : theme.colorScheme.onSurface.withValues(alpha: 0.1),
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    dayNames[index],
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: isSelected ? Colors.white : theme.colorScheme.primary.withValues(alpha: 0.6),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Schedule List Header
                  Text(
                    'Alarms Active Tonight',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  if (activeAlarmsForDay.isEmpty) ...[
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            FaIcon(FontAwesomeIcons.clock, size: 36, color: theme.colorScheme.onSurface.withValues(alpha: 0.15)),
                            const SizedBox(height: 12),
                            Text(
                              'No active alarms for this day.',
                              style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else
                    ...activeAlarmsForDay.map((alarm) {
                      final duration = sleepProvider.calculateDuration(alarm.bedtimeHour, alarm.wakeHour);
                      final progress = (duration / sleepProvider.sleepGoalHours).clamp(0.0, 1.0);

                      return Card(
                        color: Colors.transparent,
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 0,
                        child: PastelGradientCard(
                          type: PastelCardType.violet,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const FaIcon(FontAwesomeIcons.bed, size: 14, color: Colors.indigoAccent),
                                      const SizedBox(width: 8),
                                      Text(
                                        alarm.bedtimeHour,
                                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, fontFamily: 'Outfit'),
                                      ),
                                      const SizedBox(width: 12),
                                      const Icon(Icons.arrow_forward, size: 14, color: Colors.grey),
                                      const SizedBox(width: 12),
                                      const FaIcon(FontAwesomeIcons.bell, size: 14, color: Colors.orangeAccent),
                                      const SizedBox(width: 8),
                                      Text(
                                        alarm.wakeHour,
                                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, fontFamily: 'Outfit'),
                                      ),
                                    ],
                                  ),
                                  PopupMenuButton<String>(
                                    onSelected: (val) {
                                      if (val == 'delete') {
                                        sleepProvider.deleteAlarm(alarm.id);
                                      }
                                    },
                                    itemBuilder: (c) => const [
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Delete Alarm', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (alarm.isSmartAlarm) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.sensors_rounded, size: 12, color: const Color(0xFF10B981)),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Smart Window: ${alarm.smartAlarmWindowStart} - ${alarm.wakeHour}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF10B981),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Projected Sleep: $duration hrs',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '${(progress * 100).toInt()}% of goal',
                                    style: TextStyle(fontSize: 10, color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 6,
                                  backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: GerexGradients.primaryCTA,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              elevation: 0,
                            ),
                            onPressed: () => context.push('/add-alarm'),
                            child: const Text('Add Bedtime Alarm'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 80),
                ]),
              ),
            ),
          ],
        ),
    );
  }
}
