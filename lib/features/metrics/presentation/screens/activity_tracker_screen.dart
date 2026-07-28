import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gerex/core/providers/activity_provider.dart';
import 'package:gerex/core/utils/relative_time.dart';
import 'package:gerex/core/presentation/widgets/glass_container.dart';
import 'package:gerex/core/presentation/widgets/gerex_scaffold.dart';
import 'package:gerex/core/presentation/widgets/hero_mint_card.dart';
import 'package:gerex/core/presentation/widgets/big_stat_number.dart';
import 'package:gerex/core/presentation/widgets/gerex_line_chart.dart';
import 'package:gerex/core/presentation/widgets/segmented_pill_nav.dart';
import 'package:gerex/core/theme/app_theme.dart';

class ActivityTrackerScreen extends StatefulWidget {
  const ActivityTrackerScreen({super.key});

  @override
  State<ActivityTrackerScreen> createState() => _ActivityTrackerScreenState();
}

class _ActivityTrackerScreenState extends State<ActivityTrackerScreen> {
  int _selectedNavIdx = 0; // 0 = Weekly, 1 = Monthly

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activity = Provider.of<ActivityProvider>(context);

    const List<GerexLineChartPoint> weeklyPoints = [
      GerexLineChartPoint(label: 'Mon', value: 450),
      GerexLineChartPoint(label: 'Tue', value: 620),
      GerexLineChartPoint(label: 'Wed', value: 380),
      GerexLineChartPoint(label: 'Thu', value: 750),
      GerexLineChartPoint(label: 'Fri', value: 540),
      GerexLineChartPoint(label: 'Sat', value: 890),
      GerexLineChartPoint(label: 'Sun', value: 410),
    ];

    const List<GerexLineChartPoint> monthlyPoints = [
      GerexLineChartPoint(label: 'W1', value: 3200),
      GerexLineChartPoint(label: 'W2', value: 4100),
      GerexLineChartPoint(label: 'W3', value: 3800),
      GerexLineChartPoint(label: 'W4', value: 4900),
    ];

    final chartPoints = _selectedNavIdx == 0 ? weeklyPoints : monthlyPoints;

    return GerexScaffold(
      appBar: AppBar(
        title: Text(
          'Activity Tracker',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textDarkHeading,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Mint Header Card
            HeroMintCard(
              margin: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Daily Goal Target',
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
                        child: const Text(
                          '85% Completed',
                          style: TextStyle(
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
                    number: '${activity.stepsCount}',
                    label: 'Foot Steps Completed Today',
                    unit: 'STEPS',
                    isDarkCard: false,
                  ),
                ],
              ),
            ),

            // 1. Today Target with quick-add actions
            Row(
              children: [
                Expanded(
                  child: GlassContainer(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const FaIcon(
                              FontAwesomeIcons.glassWater,
                              color: AppColors.accentEmeraldLight,
                              size: 18,
                            ),
                            IconButton(
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                              icon: const Icon(
                                Icons.add_circle_outline_rounded,
                                color: AppColors.accentEmeraldLight,
                              ),
                              onPressed: () {
                                activity.addWater(250);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Added 250ml of Water!'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Water Intake',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDarkHeading,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${activity.waterIntake} ml / ${activity.waterTarget} ml',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textDarkMuted,
                          ),
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: (activity.waterIntake / activity.waterTarget).clamp(0.0, 1.0),
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          color: AppColors.accentEmeraldLight,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GlassContainer(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const FaIcon(
                              FontAwesomeIcons.personRunning,
                              color: AppColors.accentEmeraldLight,
                              size: 18,
                            ),
                            IconButton(
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                              icon: const Icon(
                                Icons.add_circle_outline_rounded,
                                color: AppColors.accentEmeraldLight,
                              ),
                              onPressed: () {
                                activity.addSteps(1000);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Logged 1,000 steps!'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Foot Steps',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDarkHeading,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${activity.stepsCount} / ${activity.stepsTarget} steps',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textDarkMuted,
                          ),
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: (activity.stepsCount / activity.stepsTarget).clamp(0.0, 1.0),
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          color: AppColors.accentEmeraldLight,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 2. Activity Progress Chart Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Activity Progress',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDarkHeading,
                  ),
                ),
                SizedBox(
                  width: 170,
                  child: SegmentedPillNav(
                    items: const [
                      SegmentedPillItem(label: 'Weekly'),
                      SegmentedPillItem(label: 'Monthly'),
                    ],
                    selectedIndex: _selectedNavIdx,
                    onSelected: (idx) {
                      setState(() => _selectedNavIdx = idx);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GlassContainer(
              padding: const EdgeInsets.all(16),
              child: GerexLineChart(
                data: chartPoints,
                unit: 'kcal',
                height: 190,
              ),
            ),
            const SizedBox(height: 24),

            // 3. Latest Activity log list
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Latest Activity Logs',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDarkHeading,
                  ),
                ),
                if (activity.logs.isNotEmpty)
                  TextButton(
                    onPressed: () => activity.clearLogs(),
                    child: const Text('Clear Log', style: TextStyle(color: AppColors.accentEmeraldLight)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (activity.logs.isEmpty)
              const GlassContainer(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No activities logged today. Tap "+" above to log water or steps.',
                  style: TextStyle(
                    color: AppColors.textDarkMuted,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            if (activity.logs.isNotEmpty) ...[
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activity.logs.length,
                itemBuilder: (context, index) {
                  final log = activity.logs[index];
                  return GlassContainer(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.accentEmeraldLight.withValues(alpha: 0.15),
                          child: FaIcon(
                            log.type == 'water' 
                                ? FontAwesomeIcons.glassWater 
                                : FontAwesomeIcons.personWalking,
                            color: AppColors.accentEmeraldLight,
                            size: 14,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                log.description,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDarkHeading),
                              ),
                              Text(
                                RelativeTimeFormatter.format(log.timestamp),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textDarkMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
