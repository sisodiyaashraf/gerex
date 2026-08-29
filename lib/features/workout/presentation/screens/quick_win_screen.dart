import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:gerex/core/presentation/widgets/gerex_scaffold.dart';
import 'package:gerex/core/presentation/widgets/glass_container.dart';
import 'package:gerex/core/presentation/widgets/pastel_gradient_card.dart';
import 'package:gerex/core/theme/app_theme.dart';
import '../../domain/entities/workout_entities.dart';
import '../providers/workout_provider.dart';

class QuickWinScreen extends StatefulWidget {
  const QuickWinScreen({super.key});

  @override
  State<QuickWinScreen> createState() => _QuickWinScreenState();
}

class _QuickWinScreenState extends State<QuickWinScreen> {
  int _secondsRemaining = 120;
  Timer? _timer;
  bool _isRunning = false;
  String _selectedRoutine = 'Bodyweight Spark';
  bool _isCompleted = false;

  final Map<String, List<String>> _routineSteps = {
    'Bodyweight Spark': [
      '0:00 - 0:45: Bodyweight Squats (controlled pace)',
      '0:45 - 1:00: Rest & deep breathing',
      '1:00 - 1:45: Wall Pushups (focus on posture)',
      '1:45 - 2:00: Relax & active shakeout',
    ],
    'Mindful Mobilisation': [
      '0:00 - 0:30: Shoulder rolls & neck circles',
      '0:30 - 1:00: Gentle torso twists',
      '1:00 - 1:30: Standing cat-cow stretch',
      '1:30 - 2:00: Slow, deep diaphragmatic breaths',
    ],
    'Core Booster': [
      '0:00 - 0:45: Standard Plank hold (active core)',
      '0:45 - 1:00: Rest on knees',
      '1:00 - 1:45: Glute Bridge hold or pulses',
      '1:45 - 2:00: Cobra stretch & child\'s pose',
    ]
  };

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    if (_isRunning) return;
    setState(() {
      _isRunning = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer?.cancel();
        _onComplete();
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = 120;
      _isRunning = false;
      _isCompleted = false;
    });
  }

  Future<void> _onComplete() async {
    setState(() {
      _isCompleted = true;
      _isRunning = false;
    });

    final provider = context.read<WorkoutProvider>();
    final loggedSets = <LoggedSet>[
      const LoggedSet(
        id: 'qw_set1',
        sessionId: '',
        exerciseId: 'ex_quick_win',
        setNumber: 1,
        reps: 1,
        weight: 0.0,
        isCompleted: true,
      )
    ];

    await provider.logCustomWorkoutSession(
      'Quick Win: $_selectedRoutine',
      120,
      loggedSets,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final minutes = _secondsRemaining ~/ 60;
    final seconds = _secondsRemaining % 60;
    final timeStr = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    final progress = (120 - _secondsRemaining) / 120.0;

    return GerexScaffold(
      appBar: AppBar(
        title: Text(
          'Quick Win Training',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textDarkHeading,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: AppColors.textDarkHeading),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Honest Psychology framing card
            PastelGradientCard(
              type: PastelCardType.mint,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.shield_rounded, color: Color(0xFF0D807B), size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Consistency > Intensity',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D807B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'When motivation is low, lowering the activation energy prevents skipping entirely. '
                    'A 2-minute focus session keeps your habit loop alive and counts fully as a streak day. Let\'s get this win!',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: const Color(0xFF14181F).withValues(alpha: 0.8),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (!_isCompleted) ...[
              // Routine presets selection
              Text(
                'Select 2-Minute Routine',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: _routineSteps.keys.map((routine) {
                  final isSelected = _selectedRoutine == routine;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (!_isRunning) {
                          setState(() => _selectedRoutine = routine);
                        }
                      },
                      child: GlassContainer(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                        borderRadius: 12,
                        color: isSelected ? const Color(0xFF10B981).withValues(alpha: 0.12) : Colors.white,
                        borderWidth: isSelected ? 1.5 : 1.0,
                        borderGradient: isSelected ? GerexGradients.primaryCTA : null,
                        child: Center(
                          child: Text(
                            routine.replaceAll(' ', '\n'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? const Color(0xFF10B981) : const Color(0xFF1E293B),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Steps visualizer
              GlassContainer(
                padding: const EdgeInsets.all(16),
                borderRadius: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$_selectedRoutine Steps:',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    ..._routineSteps[_selectedRoutine]!.map((step) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.check_circle_outline, size: 14, color: Color(0xFF10B981)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  step,
                                  style: const TextStyle(fontSize: 12, height: 1.3),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Countdown circle
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: 150,
                      width: 150,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 8,
                        color: const Color(0xFF10B981),
                        backgroundColor: Colors.grey.withValues(alpha: 0.15),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          timeStr,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.bold,
                            fontSize: 32,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'MIN REMAINING',
                          style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isRunning)
                    IconButton.filledTonal(
                      onPressed: _pauseTimer,
                      icon: const Icon(Icons.pause, size: 24),
                      style: IconButton.styleFrom(padding: const EdgeInsets.all(16)),
                    )
                  else
                    IconButton.filled(
                      onPressed: _startTimer,
                      icon: const Icon(Icons.play_arrow, size: 24),
                      style: IconButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: const Color(0xFF10B981),
                      ),
                    ),
                  const SizedBox(width: 20),
                  IconButton.outlined(
                    onPressed: _resetTimer,
                    icon: const Icon(Icons.replay, size: 24),
                    style: IconButton.styleFrom(padding: const EdgeInsets.all(16)),
                  ),
                ],
              ),
            ] else ...[
              // Completed screen
              Center(
                child: GlassContainer(
                  padding: const EdgeInsets.all(24),
                  borderRadius: 24,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 64),
                      const SizedBox(height: 20),
                      Text(
                        'Quick Win Complete!',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Consistency goal achieved. Your streak is protected!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => context.pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Back to Home'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
