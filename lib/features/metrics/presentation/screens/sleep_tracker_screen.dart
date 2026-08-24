import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/sleep_provider.dart';
import '../../domain/entities/sleep_entities.dart';
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

    // Sleep Stage Proportions based on Log Quality
    final deepPct = lastLog != null ? (lastLog.quality / 100 * 0.08 + 0.12).clamp(0.10, 0.22) : 0.0;
    final remPct = lastLog != null ? (lastLog.quality / 100 * 0.07 + 0.15).clamp(0.12, 0.25) : 0.0;
    final lightPct = lastLog != null ? 1.0 - deepPct - remPct : 0.0;

    final deepHours = lastLog != null ? lastLog.hours * deepPct : 0.0;
    final remHours = lastLog != null ? lastLog.hours * remPct : 0.0;
    final lightHours = lastLog != null ? lastLog.hours * lightPct : 0.0;

    return GerexScaffold(
      appBar: AppBar(
        title: Text(
          'Sleep Tracker',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: AppColors.textDarkHeading,
            fontSize: 18,
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
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textLightBody.withValues(alpha: 0.7),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _showChangeGoalDialog(context, sleepProvider),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.badgeDarkNavy,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    (lastLog != null && lastLog.hours >= sleepProvider.sleepGoalHours)
                                        ? 'Goal Reached'
                                        : 'Goal: ${sleepProvider.sleepGoalHours}h',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.accentEmeraldLight,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.edit, color: AppColors.accentEmeraldLight, size: 10),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      BigStatNumber(
                        number: lastLog != null ? '${lastLog.hours}' : '0.0',
                        label: lastLog != null
                            ? 'Sleep Quality: ${lastLog.quality.toInt()}%'
                            : 'No logs recorded',
                        unit: 'HOURS',
                        isDarkCard: false,
                      ),
                      if (lastLog != null && lastLog.wakeUpMood != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Wake-up Mood: ${lastLog.wakeUpMood} ${_getMoodEmoji(lastLog.wakeUpMood)}',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                        ),
                      ],
                      if (lastLog != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Estimated Sleep Cycle Stages',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: SizedBox(
                            height: 10,
                            width: double.infinity,
                            child: Row(
                              children: [
                                Expanded(
                                  flex: (deepPct * 100).toInt(),
                                  child: Container(color: const Color(0xFF3B82F6)), // Deep - Blue
                                ),
                                Expanded(
                                  flex: (remPct * 100).toInt(),
                                  child: Container(color: const Color(0xFF06B6D4)), // REM - Cyan
                                ),
                                Expanded(
                                  flex: (lightPct * 100).toInt(),
                                  child: Container(color: const Color(0xFFA855F7)), // Light - Purple
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildLegendItem('Deep', '${deepHours.toStringAsFixed(1)}h', const Color(0xFF3B82F6)),
                            _buildLegendItem('REM', '${remHours.toStringAsFixed(1)}h', const Color(0xFF06B6D4)),
                            _buildLegendItem('Light', '${lightHours.toStringAsFixed(1)}h', const Color(0xFFA855F7)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Insights panel
                if (sleepProvider.sleepLogs.isNotEmpty) ...[
                  Text(
                    'Sleep Recovery Insights',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDarkHeading,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildInsightsCard(averageSleep, lastLog),
                  const SizedBox(height: 24),
                ],

                // Chart
                Text(
                  'Sleep Analytics (Last 7 Days)',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDarkHeading,
                    fontSize: 16,
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

                // Alarms
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Bedtime & Alarm Alerters',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: const FaIcon(FontAwesomeIcons.calendarDay, size: 12),
                      label: Text('Schedule', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold)),
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        icon: const FaIcon(FontAwesomeIcons.clock, size: 14),
                        label: Text('Log Sleep', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                        onPressed: () => _showLogSleepDialog(context, sleepProvider),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 60),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  String _getMoodEmoji(String? mood) {
    switch (mood) {
      case 'Energized':
        return '⚡';
      case 'Rested':
        return '🧘';
      case 'Tired':
        return '😴';
      case 'Sore':
        return '🤒';
      default:
        return '';
    }
  }

  Widget _buildLegendItem(String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          '$label: $value',
          style: GoogleFonts.outfit(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF475569),
          ),
        ),
      ],
    );
  }

  Widget _buildInsightsCard(double averageSleep, SleepLog? lastLog) {
    String recoveryMsg = 'Averages indicate good sleep duration.';
    IconData recoveryIcon = Icons.check_circle_outline_rounded;
    Color iconColor = const Color(0xFF10B981);

    if (averageSleep < 7.0) {
      recoveryMsg = 'Your average sleep is under 7.0h. Muscle repair, recovery, and strength gains might be hindered.';
      recoveryIcon = Icons.warning_amber_rounded;
      iconColor = Colors.orange;
    } else if (averageSleep >= 7.5) {
      recoveryMsg = 'Great average duration! Your muscles are receiving optimal protein synthesis and recovery windows.';
      recoveryIcon = Icons.stars_rounded;
      iconColor = Colors.amber;
    }

    String hygieneMsg = 'Maintain wind-down routines for better deep sleep stages.';
    if (lastLog != null && lastLog.quality < 75.0) {
      hygieneMsg = 'Last night\'s quality was low (${lastLog.quality.toInt()}%). Avoid blue screens 1h before bed.';
    }

    return GlassContainer(
      type: GlassContainerType.normal,
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(recoveryIcon, color: iconColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Muscle & Recovery',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF0B1220)),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      recoveryMsg,
                      style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF475569), height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.black12, height: 1),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.wb_sunny_outlined, color: Colors.blueAccent, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sleep Hygiene Advice',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF0B1220)),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hygieneMsg,
                      style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF475569), height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatRepeatDays(List<int> days) {
    if (days.length == 7) return 'Everyday';
    if (days.length == 5 &&
        days.contains(1) &&
        days.contains(2) &&
        days.contains(3) &&
        days.contains(4) &&
        days.contains(5)) {
      return 'Weekdays';
    }
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days.map((d) => names[d - 1]).join(', ');
  }

  void _showChangeGoalDialog(BuildContext context, SleepProvider provider) {
    double currentGoal = provider.sleepGoalHours;
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
                  'Adjust Daily Sleep Goal',
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0B1220)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Text(
                  'Target Hours: ${currentGoal.toStringAsFixed(1)} hours',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF1E293B)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Slider(
                  value: currentGoal,
                  min: 6.0,
                  max: 10.0,
                  divisions: 8,
                  activeColor: const Color(0xFF10B981),
                  onChanged: (val) {
                    setLocalState(() => currentGoal = val);
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('Cancel', style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        provider.updateSleepGoal(currentGoal);
                        Navigator.pop(ctx);
                      },
                      child: Text('Save', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
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

  void _showLogSleepDialog(BuildContext context, SleepProvider provider) {
    double selectedHours = 8.0;
    double selectedQuality = 80.0;
    String selectedMood = 'Rested';

    final moods = [
      ('Energized', '⚡'),
      ('Rested', '🧘'),
      ('Tired', '😴'),
      ('Sore', '🤒'),
    ];

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
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0B1220)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Text(
                  'Sleep Duration: ${selectedHours.toStringAsFixed(1)} hours',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF1E293B)),
                ),
                Slider(
                  value: selectedHours,
                  min: 3.0,
                  max: 14.0,
                  divisions: 22,
                  activeColor: const Color(0xFF10B981),
                  onChanged: (val) {
                    setLocalState(() => selectedHours = val);
                  },
                ),
                const SizedBox(height: 12),
                Text(
                  'Sleep Quality: ${selectedQuality.toInt()}%',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF1E293B)),
                ),
                Slider(
                  value: selectedQuality,
                  min: 10.0,
                  max: 100.0,
                  divisions: 90,
                  activeColor: const Color(0xFF10B981),
                  onChanged: (val) {
                    setLocalState(() => selectedQuality = val);
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Wake-up Mood:',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF1E293B)),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: moods.map((moodInfo) {
                    final isSelected = selectedMood == moodInfo.$1;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setLocalState(() => selectedMood = moodInfo.$1),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF10B981).withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF10B981) : Colors.grey.shade300,
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(moodInfo.$2, style: const TextStyle(fontSize: 20)),
                              const SizedBox(height: 4),
                              Text(
                                moodInfo.$1,
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? const Color(0xFF10B981) : const Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('Cancel', style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        provider.addSleepLog(
                          DateTime.now().subtract(const Duration(days: 1)),
                          selectedHours,
                          selectedQuality,
                          selectedMood,
                        );
                        Navigator.pop(ctx);
                      },
                      child: Text('Log', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
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