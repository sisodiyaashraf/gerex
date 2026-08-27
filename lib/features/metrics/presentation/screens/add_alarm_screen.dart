import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/sleep_provider.dart';
import 'package:gerex/core/presentation/widgets/glass_container.dart';
import 'package:gerex/core/presentation/widgets/gerex_scaffold.dart';
import 'package:gerex/core/widgets/slide_to_confirm_button.dart';
import 'package:gerex/core/theme/app_theme.dart';

class AddAlarmScreen extends StatefulWidget {
  const AddAlarmScreen({super.key});

  @override
  State<AddAlarmScreen> createState() => _AddAlarmScreenState();
}

class _AddAlarmScreenState extends State<AddAlarmScreen> {
  TimeOfDay _bedtime = const TimeOfDay(hour: 22, minute: 30);
  TimeOfDay _wakeTime = const TimeOfDay(hour: 6, minute: 30);
  final List<int> _repeatDays = [1, 2, 3, 4, 5];
  bool _vibrate = true;
  bool _isSmartAlarm = false;
  TimeOfDay _smartAlarmWindowStart = const TimeOfDay(hour: 6, minute: 0);

  Future<void> _selectBedtime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _bedtime,
    );
    if (picked != null && picked != _bedtime) {
      setState(() {
        _bedtime = picked;
      });
    }
  }

  Future<void> _selectWakeTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _wakeTime,
    );
    if (picked != null && picked != _wakeTime) {
      setState(() {
        _wakeTime = picked;
      });
    }
  }

  Future<void> _selectWindowStart(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _smartAlarmWindowStart,
    );
    if (picked != null && picked != _smartAlarmWindowStart) {
      setState(() {
        _smartAlarmWindowStart = picked;
      });
    }
  }

  void _toggleDay(int dayIndex) {
    setState(() {
      if (_repeatDays.contains(dayIndex)) {
        _repeatDays.remove(dayIndex);
      } else {
        _repeatDays.add(dayIndex);
      }
    });
  }

  String _formatTime(TimeOfDay time) {
    final hr = time.hour.toString().padLeft(2, '0');
    final min = time.minute.toString().padLeft(2, '0');
    return '$hr:$min';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sleepProvider = Provider.of<SleepProvider>(context, listen: false);

    final duration = sleepProvider.calculateDuration(
      _formatTime(_bedtime),
      _formatTime(_wakeTime),
    );

    return GerexScaffold(
      appBar: AppBar(
        title: Text(
          'Add Bedtime Alarm',
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
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                  // Projected sleep info banner
                  GlassContainer(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        FaIcon(FontAwesomeIcons.circleInfo, color: theme.colorScheme.primary, size: 18),
                        const SizedBox(height: 8),
                        Text(
                          'Estimated Sleep Duration: $duration hours',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          duration >= 7.0 && duration <= 9.0
                              ? 'Fits perfectly into target sleep requirements.'
                              : 'Try adjusting bedtime or wake alarms to fit 7.5 to 9.0 hours.',
                          style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Time Pickers Row
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _selectBedtime(context),
                          child: GlassContainer(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                const FaIcon(FontAwesomeIcons.bed, color: Colors.indigoAccent, size: 18),
                                const SizedBox(height: 8),
                                const Text('Bedtime', style: TextStyle(fontSize: 11)),
                                const SizedBox(height: 4),
                                Text(
                                  _bedtime.format(context),
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, fontFamily: 'Outfit'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _selectWakeTime(context),
                          child: GlassContainer(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                const FaIcon(FontAwesomeIcons.bell, color: Colors.orangeAccent, size: 18),
                                const SizedBox(height: 8),
                                const Text('Wake Alarm', style: TextStyle(fontSize: 11)),
                                const SizedBox(height: 4),
                                Text(
                                  _wakeTime.format(context),
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, fontFamily: 'Outfit'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Repeating days list
                  const Text('Repeat Days', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(7, (idx) {
                      final dayVal = idx + 1; // Mon=1, Sun=7
                      final isSelected = _repeatDays.contains(dayVal);
                      const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

                      return GestureDetector(
                        onTap: () => _toggleDay(dayVal),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.surface.withValues(alpha: 0.05),
                            border: Border.all(
                              color: isSelected ? Colors.transparent : theme.colorScheme.onSurface.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              labels[idx],
                              style: TextStyle(
                                color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),

                  // Smart Alarm Config Card
                  GlassContainer(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.sensors_rounded, size: 18, color: Colors.emerald),
                                SizedBox(width: 12),
                                Text(
                                  'Smart Alarm Mode',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                            Switch.adaptive(
                              activeColor: Colors.emerald,
                              value: _isSmartAlarm,
                              onChanged: (val) => setState(() => _isSmartAlarm = val),
                            ),
                          ],
                        ),
                        if (_isSmartAlarm) ...[
                          const SizedBox(height: 16),
                          const Divider(height: 1, color: Colors.black12),
                          const SizedBox(height: 16),
                          const Text(
                            'Wake Window Start Time',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => _selectWindowStart(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _smartAlarmWindowStart.format(context),
                                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, fontFamily: 'Outfit'),
                                  ),
                                  const Icon(Icons.edit, size: 16, color: Colors.emerald),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Wake Window: ${_smartAlarmWindowStart.format(context)} to ${_wakeTime.format(context)}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.emerald),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Smart Alarm tracking requires placing the phone on the bed, screen-side up, near your pillow. Accuracy depends on placement and case thickness.',
                            style: TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Vibrate toggle
                  GlassContainer(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.vibration_rounded, size: 18),
                            SizedBox(width: 12),
                            Text('Vibrate Device', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                        Switch.adaptive(
                          value: _vibrate,
                          onChanged: (val) => setState(() => _vibrate = val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Save button
                  SlideToConfirmButton(
                    label: 'Slide to Save Alarm',
                    knobIcon: FontAwesomeIcons.solidFloppyDisk,
                    onConfirm: () async {
                      final err = await sleepProvider.addAlarm(
                        bedtime: _formatTime(_bedtime),
                        wake: _formatTime(_wakeTime),
                        repeatDays: _repeatDays,
                        vibrate: _vibrate,
                        isSmartAlarm: _isSmartAlarm,
                        smartAlarmWindowStart: _isSmartAlarm ? _formatTime(_smartAlarmWindowStart) : null,
                      );

                      if (context.mounted) {
                        if (err != null) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                        } else {
                          context.pop();
                        }
                      }
                    },
                  ),
                ]),
              ),
            ),
          ],
        ),
    );
  }
}
