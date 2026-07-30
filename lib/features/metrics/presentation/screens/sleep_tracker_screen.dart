import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/sleep_provider.dart';
import 'package:gerex/core/presentation/widgets/glass_container.dart';
import 'package:gerex/core/presentation/widgets/pastel_gradient_card.dart';
import 'package:gerex/core/presentation/widgets/gerex_scaffold.dart';
import 'package:gerex/core/presentation/widgets/hero_mint_card.dart';
import 'package:gerex/core/presentation/widgets/big_stat_number.dart';
import 'package:gerex/core/presentation/widgets/gerex_line_chart.dart';
import 'package:gerex/core/theme/app_theme.dart';

class SleepTrackerScreen extends StatelessWidget {
  const SleepTrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sleepProvider = Provider.of<SleepProvider>(context);

    final lastLog = sleepProvider.sleepLogs.isNotEmpty ? sleepProvider.sleepLogs.last : null;
    final averageSleep = sleepProvider.sleepLogs.isNotEmpty
        ? (sleepProvider.sleepLogs.map((l) => l.hours).reduce((a, b) => a + b) / sleepProvider.sleepLogs.length)
        : 0.0;

    final List<GerexLineChartPoint> sleepChartPoints = sleepProvider.sleepLogs.map((log) {
      final dt = log.date;
      return GerexLineChartPoint(
        label: '${dt.month}/${dt.day}',
        value: log.hours,
      );
    }).toList();

    return GerexScaffold(
      appBar: AppBar(
        title: Text(
          'Sleep Tracker',
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
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Summary Hero Mint Card
                HeroMintCard(
                  margin: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Last Night Sleep',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textLightBody.withValues(alpha: 0.7),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.badgeDarkNavy,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              (lastLog != null && lastLog.hours >= sleepProvider.sleepGoalHours)
                                  ? 'Goal Reached'
                                  : 'Goal: ${sleepProvider.sleepGoalHours}h',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.accentEmeraldLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      BigStatNumber(
                        number: lastLog != null ? '${lastLog.hours}' : '0.0',
                        label: lastLog != null ? 'Sleep Quality: ${lastLog.quality.toInt()}%' : 'No logs recorded',
                        unit: 'HOURS',
                        isDarkCard: false,
                      ),
                    ],
                  ),
                ),

                // Chart
                Text(
                  'Sleep Analytics (Last 7 Days)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDarkHeading,
                  ),
                ),
                const SizedBox(height: 12),
                PastelGradientCard(
                  type: PastelCardType.slate,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (sleepChartPoints.isEmpty)
                        SizedBox(
                          height: 160,
                          child: Center(
                            child: Text(
                              'No sleep data available.',
                              style: TextStyle(color: const Color(0xFF14181F).withValues(alpha: 0.6)),
                            ),
                          ),
                        )
                      else
                        GerexLineChart(
                          data: sleepChartPoints,
                          unit: 'hrs',
                          height: 180,
                        ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'Average Sleep Duration',
                              style: TextStyle(fontSize: 12, color: const Color(0xFF14181F).withValues(alpha: 0.6)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${averageSleep.toStringAsFixed(1)} hrs/day',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Color(0xFF14181F),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                  // Today alarm schedule list
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Bedtime & Alarm Alerters',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        icon: const FaIcon(FontAwesomeIcons.calendarDay, size: 12),
                        label: const Text('Manage Schedule'),
                        onPressed: () => context.push('/sleep-schedule'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (sleepProvider.alarms.isEmpty) ...[
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          'No alarms configured.',
                          style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                        ),
                      ),
                    ),
                  ] else
                    ...sleepProvider.alarms.map((alarm) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: PastelGradientCard(
                            type: PastelCardType.violet,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                                  child: Icon(Icons.alarm_rounded, color: theme.colorScheme.primary),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Wake up at: ${alarm.wakeHour}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Bedtime: ${alarm.bedtimeHour} • ${_formatRepeatDays(alarm.repeatDays)}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: const Color(0xFF14181F).withValues(alpha: 0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch.adaptive(
                                  value: alarm.isEnabled,
                                  onChanged: (val) {
                                    sleepProvider.toggleAlarm(alarm.id, val);
                                  },
                                ),
                              ],
                            ),
                          ),
                        )),

                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const FaIcon(FontAwesomeIcons.clock, size: 14),
                          label: const Text('Log Sleep'),
                          onPressed: () => _showLogSleepDialog(context, sleepProvider),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 100),
                ]),
              ),
            ),
          ],
        ),
    );
  }

  String _formatRepeatDays(List<int> days) {
    if (days.length == 7) return 'Everyday';
    if (days.length == 5 && days.contains(1) && days.contains(2) && days.contains(3) && days.contains(4) && days.contains(5)) {
      return 'Weekdays';
    }
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days.map((d) => names[d - 1]).join(', ');
  }

  void _showLogSleepDialog(BuildContext context, SleepProvider provider) {
    double selectedHours = 8.0;
    double selectedQuality = 80.0;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.transparent,
        contentPadding: EdgeInsets.zero,
        content: StatefulBuilder(
          builder: (context, setLocalState) => GlassContainer(
            borderRadius: 24,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Log Last Night Sleep',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Text(
                  'Sleep Duration: ${selectedHours.toStringAsFixed(1)} hours',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Slider(
                  value: selectedHours,
                  min: 3.0,
                  max: 14.0,
                  divisions: 22,
                  onChanged: (val) {
                    setLocalState(() => selectedHours = val);
                  },
                ),
                const SizedBox(height: 12),
                Text(
                  'Sleep Quality: ${selectedQuality.toInt()}%',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Slider(
                  value: selectedQuality,
                  min: 10.0,
                  max: 100.0,
                  divisions: 90,
                  onChanged: (val) {
                    setLocalState(() => selectedQuality = val);
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        provider.addSleepLog(DateTime.now().subtract(const Duration(days: 1)), selectedHours, selectedQuality);
                        Navigator.pop(ctx);
                      },
                      child: const Text('Log'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}