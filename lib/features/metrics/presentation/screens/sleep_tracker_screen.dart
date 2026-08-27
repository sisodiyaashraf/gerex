import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/sleep_provider.dart';
import '../../domain/entities/sleep_entities.dart';
import '../../../ai/presentation/providers/ai_provider.dart';
import 'package:gerex/core/presentation/widgets/glass_container.dart';
import 'package:gerex/core/presentation/widgets/pastel_gradient_card.dart';
import 'package:gerex/core/presentation/widgets/gerex_scaffold.dart';
import 'package:gerex/core/presentation/widgets/hero_mint_card.dart';
import 'package:gerex/core/presentation/widgets/big_stat_number.dart';
import 'package:gerex/core/presentation/widgets/gerex_line_chart.dart';
import 'package:gerex/core/theme/app_theme.dart';

class SleepTrackerScreen extends StatefulWidget {
  const SleepTrackerScreen({super.key});

  @override
  State<SleepTrackerScreen> createState() => _SleepTrackerScreenState();
}

class _SleepTrackerScreenState extends State<SleepTrackerScreen> {
  bool _showDurationChart = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SleepProvider>().fetchLatestSleepData();
      context.read<AIProvider>().loadSleepInsight();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sleepProvider = Provider.of<SleepProvider>(context);
    final aiProvider = Provider.of<AIProvider>(context);

    final lastLog = sleepProvider.sleepLogs.isNotEmpty ? sleepProvider.sleepLogs.last : null;
    final averageSleep = sleepProvider.sleepLogs.isNotEmpty
        ? (sleepProvider.sleepLogs.map((l) => l.hours).reduce((a, b) => a + b) / sleepProvider.sleepLogs.length)
        : 0.0;

    final List<GerexLineChartPoint> sleepChartPoints = sleepProvider.sleepLogs.map((log) {
      final dt = log.date;
      return GerexLineChartPoint(
        label: '${dt.month}/${dt.day}',
        value: _showDurationChart ? log.hours : log.quality,
      );
    }).toList();

    // Sleep Stage Proportions
    double deepPct = 0.0;
    double remPct = 0.0;
    double lightPct = 0.0;
    double awakePct = 0.0;
    bool hasStages = false;

    if (sleepProvider.activeSource == SleepSource.health && sleepProvider.syncedSleepData != null) {
      final synced = sleepProvider.syncedSleepData!;
      if (synced.hasStages && synced.totalHours > 0) {
        hasStages = true;
        deepPct = synced.deepHours / synced.totalHours;
        remPct = synced.remHours / synced.totalHours;
        lightPct = synced.lightHours / synced.totalHours;
        awakePct = synced.awakeHours / synced.totalHours;
      }
    } else if (lastLog != null) {
      // Estimated proportions fallback
      deepPct = (lastLog.quality / 100 * 0.08 + 0.12).clamp(0.10, 0.22);
      remPct = (lastLog.quality / 100 * 0.07 + 0.15).clamp(0.12, 0.25);
      lightPct = 1.0 - deepPct - remPct;
    }

    final double totalHours = lastLog != null ? lastLog.hours : 0.0;
    final deepHours = totalHours * deepPct;
    final remHours = totalHours * remPct;
    final lightHours = totalHours * lightPct;
    final awakeHours = totalHours * awakePct;

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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDarkHeading),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 100.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 1. Wind-Down Sanctuary Entry Card
                _buildWindDownCard(context),
                const SizedBox(height: 16),

                // 2. Last Night Sleep Hero Mint Card
                HeroMintCard(
                  margin: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            sleepProvider.activeSource == SleepSource.health
                                ? 'Last Night Sleep (OS Synced)'
                                : 'Last Night Sleep',
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
                            ? 'Sleep Score: ${lastLog.quality.toInt()}%'
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
                      const SizedBox(height: 16),
                      Text(
                        hasStages ? 'Actual Sleep Stages' : 'Estimated Sleep Stages',
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
                                flex: (deepPct * 100).round().clamp(1, 100),
                                child: Container(color: const Color(0xFF3B82F6)),
                              ),
                              Expanded(
                                flex: (remPct * 100).round().clamp(1, 100),
                                child: Container(color: const Color(0xFF06B6D4)),
                              ),
                              Expanded(
                                flex: (lightPct * 100).round().clamp(1, 100),
                                child: Container(color: const Color(0xFFA855F7)),
                              ),
                              if (awakePct > 0)
                                Expanded(
                                  flex: (awakePct * 100).round().clamp(1, 100),
                                  child: Container(color: const Color(0xFFF59E0B)),
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
                          if (awakePct > 0)
                            _buildLegendItem('Awake', '${awakeHours.toStringAsFixed(1)}h', const Color(0xFFF59E0B)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Smartwatch estimates are best-effort measurements, not clinical-grade medical diagnosis.',
                        style: GoogleFonts.outfit(
                          fontSize: 9,
                          fontStyle: FontStyle.italic,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),

                // 3. Sleep Score Breakdown Card
                if (lastLog != null) ...[
                  _buildSleepScoreBreakdownCard(sleepProvider, lastLog),
                  const SizedBox(height: 20),
                ],

                // 4. AI Sleep Insights Card
                _buildAiSleepInsightCard(aiProvider),
                const SizedBox(height: 20),

                // 5. OS Health Sync Settings Card
                _buildHealthSyncCard(context, sleepProvider),
                const SizedBox(height: 20),

                // 6. Sleep Analytics Section (Chart)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Sleep Analytics',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDarkHeading,
                        fontSize: 16,
                      ),
                    ),
                    Row(
                      children: [
                        _buildChartToggleButton('Duration', _showDurationChart),
                        const SizedBox(width: 8),
                        _buildChartToggleButton('Score', !_showDurationChart),
                      ],
                    ),
                  ],
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
                          unit: _showDurationChart ? 'hrs' : 'pts',
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

                // 7. Bedtime & Alarms Alerters Section
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
                                child: Icon(
                                  alarm.isSmartAlarm ? Icons.sensors_rounded : Icons.alarm_rounded,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      alarm.isSmartAlarm
                                          ? 'Smart Window: ${alarm.smartAlarmWindowStart} - ${alarm.wakeHour}'
                                          : 'Wake up at: ${alarm.wakeHour}',
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
                        label: Text('Log Sleep Manually', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                        onPressed: () => _showLogSleepDialog(context, sleepProvider),
                      ),
                    ),
                  ],
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWindDownCard(BuildContext context) {
    return PastelGradientCard(
      type: PastelCardType.indigo,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.indigo.shade50,
            child: const Icon(Icons.spa_rounded, color: Colors.indigoAccent),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Wind-Down Sanctuary',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Ambient sound loops and box-breathing guided exercises to relax your mind.',
                  style: TextStyle(fontSize: 11, color: Colors.black87),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
            onPressed: () => context.push('/wind-down'),
          ),
        ],
      ),
    );
  }

  Widget _buildSleepScoreBreakdownCard(SleepProvider sleepProvider, SleepLog lastLog) {
    final breakdown = sleepProvider.calculateScoreBreakdown(lastLog);
    final score = breakdown.totalScore;

    String scoreStatus = 'Poor';
    Color scoreColor = Colors.redAccent;
    if (score >= 90) {
      scoreStatus = 'Excellent 🏆';
      scoreColor = AppColors.accentEmeraldLight;
    } else if (score >= 80) {
      scoreStatus = 'Good 🧘';
      scoreColor = Colors.indigoAccent;
    } else if (score >= 60) {
      scoreStatus = 'Fair 😴';
      scoreColor = Colors.orangeAccent;
    }

    return PastelGradientCard(
      type: PastelCardType.mint,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                height: 64,
                width: 64,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: score / 100.0,
                      strokeWidth: 6,
                      color: scoreColor,
                      backgroundColor: Colors.black.withValues(alpha: 0.05),
                    ),
                    Text(
                      '${score.toInt()}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sleep Recovery Score',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Quality Status: $scoreStatus',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: scoreColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Colors.black12),
          const SizedBox(height: 12),
          _buildBreakdownRow('Duration Goal Factor', breakdown.durationScore, 50, Colors.emerald),
          const SizedBox(height: 8),
          _buildBreakdownRow('Bedtime Consistency', breakdown.consistencyScore, 30, Colors.indigo),
          const SizedBox(height: 8),
          _buildBreakdownRow('Sleep Stage Quality', breakdown.qualityScore, 20, Colors.purple),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, double score, double maxScore, Color color) {
    final progress = score / maxScore;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
            Text('${score.toInt()}/${maxScore.toInt()} pts', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 4,
            color: color,
            backgroundColor: Colors.black.withValues(alpha: 0.05),
          ),
        ),
      ],
    );
  }

  Widget _buildAiSleepInsightCard(AIProvider aiProvider) {
    if (aiProvider.isSleepInsightLoading) {
      return const PastelGradientCard(
        type: PastelCardType.slate,
        padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.indigoAccent),
            ),
            SizedBox(width: 16),
            Text('AI Coach analyzing sleep data...'),
          ],
        ),
      );
    }

    if (aiProvider.sleepInsight != null) {
      return PastelGradientCard(
        type: PastelCardType.rose,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.insights_rounded, color: Colors.redAccent, size: 18),
                SizedBox(width: 8),
                Text(
                  'Gerex AI Sleep Insights',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              aiProvider.sleepInsight!,
              style: const TextStyle(fontSize: 13, color: Color(0xFF14181F), height: 1.4),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildHealthSyncCard(BuildContext context, SleepProvider provider) {
    final isHealthActive = provider.connectionState == SleepConnectionState.live &&
        provider.activeSource == SleepSource.health;

    return GlassContainer(
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sync_rounded, color: Colors.blueAccent, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'OS Health Sync Integration',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Sync sleep session duration & stages automatically from Android Health Connect or iOS HealthKit.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          if (provider.healthConnectError != null) ...[
            const SizedBox(height: 12),
            Text(
              provider.healthConnectError!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 11),
            ),
            const SizedBox(height: 8),
            if (!provider.isHealthConnectInstalled)
              ElevatedButton(
                onPressed: () => provider.installHealthConnect(),
                child: const Text('Install Health Connect'),
              )
            else if (provider.isHealthConnectDeniedPermanently)
              ElevatedButton(
                onPressed: () => provider.openHealthConnectPermissions(),
                child: const Text('Configure Health Connect Settings'),
              ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isHealthActive ? Colors.indigoAccent.withValues(alpha: 0.1) : Colors.indigoAccent,
                foregroundColor: isHealthActive ? Colors.indigoAccent : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: Icon(isHealthActive ? Icons.check_circle_rounded : Icons.sync_rounded, size: 16),
              label: Text(isHealthActive ? 'Active OS Syncing' : 'Enable OS Health Sync'),
              onPressed: isHealthActive
                  ? () => provider.disconnectHealthSync()
                  : () => provider.startHealthConnectPolling(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartToggleButton(String label, bool active) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showDurationChart = label == 'Duration';
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active ? Colors.indigoAccent : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : Colors.grey.shade600,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
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