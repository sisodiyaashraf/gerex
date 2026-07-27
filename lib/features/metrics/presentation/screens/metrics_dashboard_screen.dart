import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../workout/presentation/providers/workout_provider.dart';
import '../providers/metrics_provider.dart';
import '../../../ai/presentation/providers/ai_provider.dart';
import 'package:gerex/core/presentation/widgets/glass_container.dart';
import 'package:gerex/core/presentation/widgets/liquid_background.dart';
import 'package:gerex/core/validation/validators.dart';

class MetricsDashboardScreen extends StatefulWidget {
  const MetricsDashboardScreen({super.key});

  @override
  State<MetricsDashboardScreen> createState() => _MetricsDashboardScreenState();
}

class _MetricsDashboardScreenState extends State<MetricsDashboardScreen> {
  final TextEditingController _weightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData({bool forceRefresh = false}) {
    context.read<MetricsProvider>().fetchWeightLogs();
    final workouts = context.read<WorkoutProvider>();
    workouts.fetchSessions().then((_) {
      if (mounted) {
        context.read<MetricsProvider>().computeStreaks(workouts.sessions);
        context.read<AIProvider>().loadProgressSummary(
          workouts.sessions,
          forceRefresh: forceRefresh,
        );
      }
    });
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metricsProvider = Provider.of<MetricsProvider>(context);

    // Get current month info
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final startWeekday = firstDayOfMonth.weekday; // 1 = Monday, 7 = Sunday

    return Scaffold(
      body: LiquidBackground(
        child: RefreshIndicator(
          onRefresh: () async {
            _loadData(forceRefresh: true);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const SliverAppBar.large(
                title: Text('Analytics & Progress'),
                backgroundColor: Colors.transparent,
                scrolledUnderElevation: 0,
                elevation: 0,
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 100.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // AI Progress Summary Card
                    Consumer<AIProvider>(
                      builder: (context, ai, _) {
                        if (ai.isSummaryLoading) {
                          return GlassContainer(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.symmetric(
                              vertical: 24,
                              horizontal: 16,
                            ),
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  'Analyzing your logs recap...',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        if (ai.progressSummary != null) {
                          return GlassContainer(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    FaIcon(
                                      FontAwesomeIcons.chartSimple,
                                      color: theme.colorScheme.secondary,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'AI Progress Summary',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.secondary,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  ai.progressSummary!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.85),
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

                    // 1. Streaks Dashboard Panel
                    GlassContainer(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStreakIndicator(
                            context,
                            'Current Streak',
                            '${metricsProvider.currentStreak} Days',
                            FontAwesomeIcons.fire,
                            theme.colorScheme.primary,
                          ),
                          Container(
                            height: 40,
                            width: 1,
                            color: theme.colorScheme.outline.withValues(
                              alpha: 0.15,
                            ),
                          ),
                          _buildStreakIndicator(
                            context,
                            'Longest Streak',
                            '${metricsProvider.longestStreak} Days',
                            FontAwesomeIcons.trophy,
                            theme.colorScheme.secondary,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 2. Consistency Calendar Grid
                    GlassContainer(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${_getMonthName(now.month)} ${now.year} - Consistency',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              FaIcon(
                                FontAwesomeIcons.calendarCheck,
                                color: theme.colorScheme.primary,
                                size: 18,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Weekday headers
                          const Row(
                            children: [
                              _CalendarDayHeader(label: 'M'),
                              _CalendarDayHeader(label: 'T'),
                              _CalendarDayHeader(label: 'W'),
                              _CalendarDayHeader(label: 'T'),
                              _CalendarDayHeader(label: 'F'),
                              _CalendarDayHeader(label: 'S'),
                              _CalendarDayHeader(label: 'S'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 7,
                                  mainAxisSpacing: 6,
                                  crossAxisSpacing: 6,
                                ),
                            itemCount: daysInMonth + startWeekday - 1,
                            itemBuilder: (context, index) {
                              if (index < startWeekday - 1) {
                                return const SizedBox.shrink();
                              }
                              final day = index - startWeekday + 2;
                              final dateStr =
                                  '${now.year}-${now.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
                              final hasWorkout = metricsProvider.workoutDates
                                  .contains(dateStr);

                              return Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: hasWorkout
                                      ? theme.colorScheme.primary.withValues(
                                          alpha: 0.25,
                                        )
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: hasWorkout
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.outline.withValues(
                                            alpha: 0.15,
                                          ),
                                    width: 1,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    '$day',
                                    style: TextStyle(
                                      fontWeight: hasWorkout
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: hasWorkout
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 3. Weight Chart Section
                    GlassContainer(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Weight Progress Chart',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (metricsProvider.weightLogs.length < 2)
                            Container(
                              height: 180,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface.withValues(
                                  alpha: 0.05,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text(
                                    'Log at least 2 weight values to generate a progression graph.',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            )
                          else
                            Container(
                              height: 180,
                              padding: const EdgeInsets.only(
                                right: 8.0,
                                top: 8.0,
                              ),
                              child: CustomPaint(
                                painter: _LineChartPainter(
                                  theme: theme,
                                  logs: metricsProvider.weightLogs,
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: const FaIcon(
                              FontAwesomeIcons.weightScale,
                              size: 14,
                            ),
                            label: const Text('Add Weight Log'),
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) {
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      bottom: MediaQuery.of(
                                        context,
                                      ).viewInsets.bottom,
                                    ),
                                    child: GlassContainer(
                                      borderRadius: 24,
                                      padding: const EdgeInsets.all(24.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Center(
                                            child: Container(
                                              width: 40,
                                              height: 5,
                                              decoration: BoxDecoration(
                                                color: theme
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.2),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                          Text(
                                            'Log Body Weight',
                                            style: theme.textTheme.titleLarge
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 16),
                                          TextField(
                                            controller: _weightController,
                                            keyboardType:
                                                const TextInputType.numberWithOptions(
                                                  decimal: true,
                                                ),
                                            decoration: InputDecoration(
                                              labelText: 'Weight (kg)',
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              prefixIcon: const Padding(
                                                padding: EdgeInsets.all(12.0),
                                                child: FaIcon(
                                                  FontAwesomeIcons.weightScale,
                                                  size: 16,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                            ),
                                             onPressed: () async {
                                               final error = Validators.validateBodyWeightLog(
                                                 _weightController.text,
                                               );
                                               if (error != null) {
                                                 ScaffoldMessenger.of(context).showSnackBar(
                                                   SnackBar(content: Text(error)),
                                                 );
                                                 return;
                                               }
                                               final val = double.tryParse(_weightController.text)!;
                                               await metricsProvider.logWeight(val);
                                               _weightController.clear();
                                               if (context.mounted) {
                                                 Navigator.pop(context);
                                               }
                                             },
                                            child: const Text('Log Weight'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 4. Sleep Tracker Card
                    GlassContainer(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                           CircleAvatar(
                            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                            child: FaIcon(
                              FontAwesomeIcons.bed,
                              color: theme.colorScheme.primary,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Sleep Tracker',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Monitor sleep schedules & recovery goals',
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                            onPressed: () => context.push('/sleep-tracker'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 5. Meal Planner Card
                    GlassContainer(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.orangeAccent.withValues(alpha: 0.15),
                            child: const FaIcon(
                              FontAwesomeIcons.utensils,
                              color: Colors.orangeAccent,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Meal Planner',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Plan high-protein sports nutrition diets',
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                            onPressed: () => context.push('/meal-planner'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStreakIndicator(
    BuildContext context,
    String title,
    String value,
    dynamic icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Row(
      children: [
        FaIcon(icon, color: color, size: 30.0),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}

class _CalendarDayHeader extends StatelessWidget {
  final String label;
  const _CalendarDayHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final ThemeData theme;
  final List<dynamic> logs;

  _LineChartPainter({required this.theme, required this.logs});

  @override
  void paint(Canvas canvas, Size size) {
    const double paddingLeft = 32.0;
    const double paddingRight = 16.0;
    const double paddingTop = 16.0;
    const double paddingBottom = 16.0;

    final double width = size.width - paddingLeft - paddingRight;
    final double height = size.height - paddingTop - paddingBottom;

    final values = logs.map((l) => l.value as double).toList();

    double maxVal = values.reduce((curr, next) => curr > next ? curr : next);
    double minVal = values.reduce((curr, next) => curr < next ? curr : next);

    if (maxVal == minVal) {
      maxVal += 5.0;
      minVal -= 5.0;
    } else {
      final range = maxVal - minVal;
      maxVal += range * 0.15;
      minVal -= range * 0.15;
    }

    final double valRange = maxVal - minVal;

    final paintGrid = Paint()
      ..color = theme.colorScheme.outline.withValues(alpha: 0.15)
      ..strokeWidth = 1.0;

    final textStyle = TextStyle(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
      fontSize: 10,
    );

    for (int i = 0; i <= 2; i++) {
      final y = paddingTop + height * (i / 2.0);
      canvas.drawLine(
        Offset(paddingLeft, y),
        Offset(size.width - paddingRight, y),
        paintGrid,
      );

      final val = maxVal - valRange * (i / 2.0);
      final textSpan = TextSpan(text: val.toStringAsFixed(1), style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(paddingLeft - textPainter.width - 6, y - textPainter.height / 2),
      );
    }

    final points = <Offset>[];
    final double xStep = values.length > 1
        ? width / (values.length - 1)
        : width;

    for (int i = 0; i < values.length; i++) {
      final x = paddingLeft + i * xStep;
      final y = paddingTop + height * (1.0 - (values[i] - minVal) / valRange);
      points.add(Offset(x, y));
    }

    if (points.length > 1) {
      final pathArea = Path()
        ..moveTo(points.first.dx, size.height - paddingBottom);
      for (final p in points) {
        pathArea.lineTo(p.dx, p.dy);
      }
      pathArea.lineTo(points.last.dx, size.height - paddingBottom);
      pathArea.close();

      final paintArea = Paint()
        ..shader =
            LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.colorScheme.primary.withValues(alpha: 0.35),
                theme.colorScheme.primary.withValues(alpha: 0.0),
              ],
            ).createShader(
              Rect.fromLTRB(
                paddingLeft,
                paddingTop,
                size.width - paddingRight,
                size.height - paddingBottom,
              ),
            );

      canvas.drawPath(pathArea, paintArea);
    }

    final paintLine = Paint()
      ..color = theme.colorScheme.primary
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(linePath, paintLine);

    final paintDotOuter = Paint()..color = theme.colorScheme.surface;
    final paintDotInner = Paint()..color = theme.colorScheme.primary;

    for (final p in points) {
      canvas.drawCircle(p, 6.0, paintDotInner);
      canvas.drawCircle(p, 3.0, paintDotOuter);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
