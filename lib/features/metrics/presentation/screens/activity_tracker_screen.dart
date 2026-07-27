import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gerex/core/providers/activity_provider.dart';
import 'package:gerex/core/utils/relative_time.dart';
import 'package:gerex/core/presentation/widgets/glass_container.dart';
import 'package:gerex/core/presentation/widgets/liquid_background.dart';

class ActivityTrackerScreen extends StatefulWidget {
  const ActivityTrackerScreen({super.key});

  @override
  State<ActivityTrackerScreen> createState() => _ActivityTrackerScreenState();
}

class _ActivityTrackerScreenState extends State<ActivityTrackerScreen> {
  bool _isWeeklySelected = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activity = Provider.of<ActivityProvider>(context);

    // Mock progress values for the bar chart
    final List<double> weeklyProgress = [0.6, 0.8, 0.45, 0.9, 0.7, 0.85, 0.5];
    final List<double> monthlyProgress = [0.7, 0.65, 0.8, 0.9, 0.75, 0.85, 0.6];
    final progressValues = _isWeeklySelected ? weeklyProgress : monthlyProgress;
    final List<String> labels = _isWeeklySelected 
        ? ['M', 'T', 'W', 'T', 'F', 'S', 'S'] 
        : ['W1', 'W2', 'W3', 'W4', 'W5', 'W6', 'W7'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Tracker'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: LiquidBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Today Target with quick-add actions
              Text(
                'Today\'s Goal Target',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GlassContainer(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              SvgPicture.asset(
                                'assets/svg icons/water-bottle.svg',
                                width: 24,
                                height: 24,
                                colorFilter: ColorFilter.mode(
                                  theme.colorScheme.primary,
                                  BlendMode.srcIn,
                                ),
                                errorBuilder: (c, e, s) => FaIcon(
                                  FontAwesomeIcons.glassWater,
                                  color: theme.colorScheme.primary,
                                  size: 18,
                                ),
                              ),
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                icon: Icon(
                                  Icons.add_circle_outline_rounded,
                                  color: theme.colorScheme.primary,
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
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${activity.waterIntake} ml / ${activity.waterTarget} ml',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: (activity.waterIntake / activity.waterTarget).clamp(0.0, 1.0),
                            backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.1),
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GlassContainer(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              SvgPicture.asset(
                                'assets/svg icons/skipping.svg',
                                width: 24,
                                height: 24,
                                errorBuilder: (c, e, s) => FaIcon(
                                  FontAwesomeIcons.personRunning,
                                  color: theme.colorScheme.secondary,
                                  size: 18,
                                ),
                              ),
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                icon: Icon(
                                  Icons.add_circle_outline_rounded,
                                  color: theme.colorScheme.secondary,
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
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${activity.stepsCount} / ${activity.stepsTarget} steps',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: (activity.stepsCount / activity.stepsTarget).clamp(0.0, 1.0),
                            backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.1),
                            color: theme.colorScheme.secondary,
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
                    ),
                  ),
                  // Toggle Selector
                  GlassContainer(
                    borderRadius: 16,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isWeeklySelected = true;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: _isWeeklySelected 
                                  ? theme.colorScheme.primary.withValues(alpha: 0.15) 
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Weekly',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _isWeeklySelected ? theme.colorScheme.primary : null,
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isWeeklySelected = false;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: !_isWeeklySelected 
                                  ? theme.colorScheme.primary.withValues(alpha: 0.15) 
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Monthly',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: !_isWeeklySelected ? theme.colorScheme.primary : null,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GlassContainer(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  height: 120,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(7, (index) {
                      final val = progressValues[index];
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Container(
                              width: 16,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Stack(
                                alignment: Alignment.bottomCenter,
                                children: [
                                  FractionallySizedBox(
                                    heightFactor: val,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            labels[index],
                            style: TextStyle(
                              fontSize: 10,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
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
                    ),
                  ),
                  if (activity.logs.isNotEmpty)
                    TextButton(
                      onPressed: () => activity.clearLogs(),
                      child: const Text('Clear Log'),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (activity.logs.isEmpty)
                GlassContainer(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'No activities logged today. Tap "+" above to log water or steps.',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              else
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
                            backgroundColor: (log.type == 'water' 
                                ? theme.colorScheme.primary 
                                : theme.colorScheme.secondary).withValues(alpha: 0.15),
                            child: FaIcon(
                              log.type == 'water' 
                                  ? FontAwesomeIcons.glassWater 
                                  : FontAwesomeIcons.personWalking,
                              color: log.type == 'water' 
                                  ? theme.colorScheme.primary 
                                  : theme.colorScheme.secondary,
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
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                Text(
                                  RelativeTimeFormatter.format(log.timestamp),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
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
          ),
        ),
      ),
    );
  }
}
