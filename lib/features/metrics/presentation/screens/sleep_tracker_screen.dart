import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/sleep_provider.dart';
import 'package:gerex/features/metrics/domain/entities/sleep_entities.dart';
import 'package:gerex/core/presentation/widgets/glass_container.dart';
import 'package:gerex/core/presentation/widgets/liquid_background.dart';

class SleepTrackerScreen extends StatelessWidget {
  const SleepTrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sleepProvider = Provider.of<SleepProvider>(context);

    // Calculate last sleep log
    final lastLog = sleepProvider.sleepLogs.isNotEmpty ? sleepProvider.sleepLogs.last : null;
    final averageSleep = sleepProvider.sleepLogs.isNotEmpty
        ? (sleepProvider.sleepLogs.map((l) => l.hours).reduce((a, b) => a + b) / sleepProvider.sleepLogs.length)
        : 0.0;

    return Scaffold(
      body: LiquidBackground(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 120.0,
              floating: false,
              pinned: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Sleep Tracker',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                centerTitle: true,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Summary card
                  GlassContainer(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Last Night Sleep',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lastLog != null ? '${lastLog.hours} hrs' : '-- hrs',
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    fontFamily: 'Outfit',
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                Text(
                                  lastLog != null ? 'Sleep Quality: ${lastLog.quality.toInt()}%' : 'No logs recorded',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: (lastLog != null && lastLog.hours >= sleepProvider.sleepGoalHours)
                                    ? Colors.greenAccent.withValues(alpha: 0.15)
                                    : Colors.orangeAccent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                (lastLog != null && lastLog.hours >= sleepProvider.sleepGoalHours)
                                    ? 'Goal Reached'
                                    : 'Goal: ${sleepProvider.sleepGoalHours}h',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: (lastLog != null && lastLog.hours >= sleepProvider.sleepGoalHours)
                                      ? Colors.greenAccent
                                      : Colors.orangeAccent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Chart
                  Text(
                    'Sleep Analytics (Last 7 Days)',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  GlassContainer(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 160,
                          width: double.infinity,
                          child: sleepProvider.sleepLogs.isEmpty
                              ? const Center(child: Text('No sleep data available.'))
                              : CustomPaint(
                                  painter: _SleepChartPainter(
                                    theme: theme,
                                    logs: sleepProvider.sleepLogs,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Average Sleep Duration',
                              style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                            ),
                            Text(
                              '${averageSleep.toStringAsFixed(1)} hrs/day',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
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
                          child: GlassContainer(
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
                                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
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

class _SleepChartPainter extends CustomPainter {
  final ThemeData theme;
  final List<SleepLog> logs;

  _SleepChartPainter({required this.theme, required this.logs});

  @override
  void paint(Canvas canvas, Size size) {
    const double paddingLeft = 32.0;
    const double paddingRight = 16.0;
    const double paddingTop = 16.0;
    const double paddingBottom = 20.0;

    final double width = size.width - paddingLeft - paddingRight;
    final double height = size.height - paddingTop - paddingBottom;

    if (logs.isEmpty) return;

    double maxVal = 10.0;
    double minVal = 4.0;

    final double valRange = maxVal - minVal;

    final paintGrid = Paint()
      ..color = theme.colorScheme.outline.withValues(alpha: 0.1)
      ..strokeWidth = 1.0;

    final textStyle = TextStyle(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
      fontSize: 9,
    );

    // Draw horizontal grid lines
    for (int i = 0; i <= 2; i++) {
      final y = paddingTop + height * (i / 2.0);
      canvas.drawLine(
        Offset(paddingLeft, y),
        Offset(size.width - paddingRight, y),
        paintGrid,
      );

      final val = maxVal - valRange * (i / 2.0);
      final textSpan = TextSpan(text: '${val.toStringAsFixed(0)}h', style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(paddingLeft - textPainter.width - 6, y - textPainter.height / 2),
      );
    }

    // Plot data coordinates
    final points = <Offset>[];
    for (int i = 0; i < logs.length; i++) {
      final x = paddingLeft + width * (i / (logs.length - 1));
      final double normalizedVal = (logs[i].hours - minVal) / valRange;
      final y = paddingTop + height * (1.0 - normalizedVal.clamp(0.0, 1.0));
      points.add(Offset(x, y));
    }

    // Draw gradient area below curve
    final path = Path()
      ..moveTo(points.first.dx, size.height - paddingBottom);
    for (final p in points) {
      path.lineTo(p.dx, p.dy);
    }
    path.lineTo(points.last.dx, size.height - paddingBottom);
    path.close();

    final paintArea = Paint()
      ..shader = LinearGradient(
        colors: [theme.colorScheme.primary.withValues(alpha: 0.35), Colors.transparent],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(paddingLeft, paddingTop, width, height));
    canvas.drawPath(path, paintArea);

    // Draw line curve
    final paintLine = Paint()
      ..color = theme.colorScheme.primary
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(linePath, paintLine);

    // Draw circles on point coordinates
    final paintCircle = Paint()
      ..color = theme.colorScheme.primary
      ..style = PaintingStyle.fill;
    final paintCircleStroke = Paint()
      ..color = theme.colorScheme.surface
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (final p in points) {
      canvas.drawCircle(p, 5.0, paintCircle);
      canvas.drawCircle(p, 5.0, paintCircleStroke);
    }

    // Draw weekdays at bottom
    final weekdayNames = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    for (int i = 0; i < logs.length; i++) {
      final x = paddingLeft + width * (i / (logs.length - 1));
      final name = weekdayNames[(logs[i].date.weekday - 1) % 7];
      final textSpan = TextSpan(text: name, style: textStyle.copyWith(fontWeight: FontWeight.bold));
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, size.height - paddingBottom + 6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
