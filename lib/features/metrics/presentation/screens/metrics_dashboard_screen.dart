import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../workout/presentation/providers/workout_provider.dart';
import '../providers/metrics_provider.dart';
import 'package:gerex/core/presentation/widgets/glass_container.dart';
import 'package:gerex/core/presentation/widgets/liquid_background.dart';

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

  void _loadData() {
    context.read<MetricsProvider>().fetchWeightLogs();
    final workouts = context.read<WorkoutProvider>();
    workouts.fetchSessions().then((_) {
      if (mounted) {
        context.read<MetricsProvider>().computeStreaks(workouts.sessions);
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
      appBar: AppBar(
        title: const Text('Analytics & Progress'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: LiquidBackground(
        child: RefreshIndicator(
        onRefresh: () async {
          _loadData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                        Icons.local_fire_department_rounded,
                        theme.colorScheme.primary,
                      ),
                      VerticalDivider(
                        color: theme.colorScheme.outline.withValues(alpha: 0.3),
                        thickness: 1,
                        width: 24,
                      ),
                      _buildStreakIndicator(
                        context,
                        'Longest Streak',
                        '${metricsProvider.longestStreak} Days',
                        Icons.emoji_events_rounded,
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
                      Text(
                        'Workout Consistency — ${_getMonthName(now.month)} ${now.year}',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      // Weekday labels
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
                      // Calendar grid
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                        ),
                        itemCount: daysInMonth + (startWeekday - 1),
                        itemBuilder: (context, index) {
                          // Before first day of month
                          if (index < startWeekday - 1) {
                            return const SizedBox.shrink();
                          }

                          final day = index - (startWeekday - 2);
                          final dateStr =
                              '${now.year}-${now.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
                          final completed =
                              metricsProvider.workoutDates.contains(dateStr);

                          return Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: completed
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.4),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: completed
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.outline.withValues(
                                        alpha: 0.1,
                                      ),
                              ),
                            ),
                            child: Text(
                              '$day',
                              style: TextStyle(
                                color: completed
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.onSurface,
                                fontWeight: completed
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
              ),
              const SizedBox(height: 16),

              // 3. Weight Tracking Chart Card
              GlassContainer(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Weight Progress Chart',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 24),
                      if (metricsProvider.weightLogs.length < 2)
                        Container(
                          height: 180,
                          alignment: Alignment.center,
                          child: Text(
                            'Log at least 2 weight values to generate a progression graph.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.5,
                              ),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      else
                        SizedBox(
                          height: 180,
                          child: CustomPaint(
                            painter: _LineChartPainter(
                              theme: theme,
                              logs: metricsProvider.weightLogs,
                            ),
                          ),
                        ),
                    ],
                  ),
              ),
              const SizedBox(height: 16),

              // 4. Body Metrics Weight Logs Logger
              GlassContainer(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Body Weight Log',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _weightController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Log Weight (kg)',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            onPressed: metricsProvider.isLoading
                                ? null
                                : () async {
                                    final val = double.tryParse(
                                      _weightController.text,
                                    );
                                    if (val != null && val > 0) {
                                      final done =
                                          await metricsProvider.logWeight(val);
                                      if (done && context.mounted) {
                                        _weightController.clear();
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text('Weight logged!'),
                                          ),
                                        );
                                      }
                                    }
                                  },
                            child: const Text('Save'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // History List
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: metricsProvider.weightLogs.length > 5
                            ? 5
                            : metricsProvider.weightLogs.length,
                        itemBuilder: (context, idx) {
                          // Show in descending order
                          final log = metricsProvider.weightLogs[
                              metricsProvider.weightLogs.length - 1 - idx];
                          return ListTile(
                            dense: true,
                            leading: Icon(
                              Icons.monitor_weight_outlined,
                              color: theme.colorScheme.primary,
                            ),
                            title: Text(
                              '${log.value} kg',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            trailing: Text(
                              '${log.loggedAt.day}/${log.loggedAt.month}/${log.loggedAt.year}',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildStreakIndicator(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: color, size: 36),
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

    // Min and Max weight
    double maxVal = values.reduce((curr, next) => curr > next ? curr : next);
    double minVal = values.reduce((curr, next) => curr < next ? curr : next);

    // Padding values range slightly to draw correctly
    if (maxVal == minVal) {
      maxVal += 5.0;
      minVal -= 5.0;
    } else {
      final range = maxVal - minVal;
      maxVal += range * 0.15;
      minVal -= range * 0.15;
    }

    final double valRange = maxVal - minVal;

    // Draw grid lines and labels
    final paintGrid = Paint()
      ..color = theme.colorScheme.outline.withValues(alpha: 0.15)
      ..strokeWidth = 1.0;

    final textStyle = TextStyle(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
      fontSize: 10,
    );

    // Horizontal grid lines (3 divisions)
    for (int i = 0; i <= 2; i++) {
      final y = paddingTop + height * (i / 2.0);
      canvas.drawLine(
        Offset(paddingLeft, y),
        Offset(size.width - paddingRight, y),
        paintGrid,
      );

      final val = maxVal - valRange * (i / 2.0);
      final textSpan = TextSpan(
        text: val.toStringAsFixed(1),
        style: textStyle,
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(paddingLeft - textPainter.width - 6, y - textPainter.height / 2),
      );
    }

    // Points logic
    final points = <Offset>[];
    final double xStep = values.length > 1 ? width / (values.length - 1) : width;

    for (int i = 0; i < values.length; i++) {
      final x = paddingLeft + i * xStep;
      final y = paddingTop + height * (1.0 - (values[i] - minVal) / valRange);
      points.add(Offset(x, y));
    }

    // Paint Area Fill Gradient
    if (points.length > 1) {
      final pathArea = Path()..moveTo(points.first.dx, size.height - paddingBottom);
      for (final p in points) {
        pathArea.lineTo(p.dx, p.dy);
      }
      pathArea.lineTo(points.last.dx, size.height - paddingBottom);
      pathArea.close();

      final paintArea = Paint()
        ..shader = LinearGradient(
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

    // Paint Neon Connection Line
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

    // Paint Dots on values
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
