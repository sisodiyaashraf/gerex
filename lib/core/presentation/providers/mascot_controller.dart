import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

enum MascotState {
  idle,
  smiling,
  walking,
  running,
  exercise,
  sweating,
  sweatingAndTired,
  tired;

  String get assetPath {
    switch (this) {
      case MascotState.idle:
        return 'assets/images/robot_mascot/gerex_robot_idle.png';
      case MascotState.smiling:
        return 'assets/images/robot_mascot/gerex_robot_smiling.png';
      case MascotState.walking:
        return 'assets/images/robot_mascot/gerex_robot_walking.png';
      case MascotState.running:
        return 'assets/images/robot_mascot/gerex_robot_running.png';
      case MascotState.exercise:
        return 'assets/images/robot_mascot/gerex_robot_exercise.png';
      case MascotState.sweating:
        return 'assets/images/robot_mascot/gerex_robot_sweating.png';
      case MascotState.sweatingAndTired:
        return 'assets/images/robot_mascot/gerex_robot_sweating_and_tired.png';
      case MascotState.tired:
        return 'assets/images/robot_mascot/gerex_robot_tired.png';
    }
  }

  int get frameCount {
    switch (this) {
      case MascotState.idle:
      case MascotState.tired:
        return 1;
      case MascotState.smiling:
      case MascotState.sweating:
        return 4;
      case MascotState.walking:
      case MascotState.exercise:
      case MascotState.sweatingAndTired:
        return 6;
      case MascotState.running:
        return 8;
    }
  }

  int get columns {
    switch (this) {
      case MascotState.idle:
      case MascotState.tired:
        return 1;
      case MascotState.walking:
      case MascotState.exercise:
        return 3;
      case MascotState.smiling:
      case MascotState.running:
      case MascotState.sweating:
        return 4;
      case MascotState.sweatingAndTired:
        return 6;
    }
  }

  int get rows {
    switch (this) {
      case MascotState.idle:
      case MascotState.smiling:
      case MascotState.sweating:
      case MascotState.sweatingAndTired:
      case MascotState.tired:
        return 1;
      case MascotState.walking:
      case MascotState.running:
      case MascotState.exercise:
        return 2;
    }
  }

  Duration get frameDuration {
    switch (this) {
      case MascotState.idle:
        return const Duration(milliseconds: 200);
      case MascotState.smiling:
        return const Duration(milliseconds: 120);
      case MascotState.walking:
        return const Duration(milliseconds: 140);
      case MascotState.running:
        return const Duration(milliseconds: 90);
      case MascotState.exercise:
        return const Duration(milliseconds: 150);
      case MascotState.sweating:
        return const Duration(milliseconds: 130);
      case MascotState.sweatingAndTired:
        return const Duration(milliseconds: 130);
      case MascotState.tired:
        return const Duration(milliseconds: 140);
    }
  }

  MascotAnimConfig get config => MascotAnimConfig(
        assetPath: assetPath,
        frameCount: frameCount,
        frameDuration: frameDuration,
        columns: columns,
        rows: rows,
      );
}

class MascotAnimConfig {
  final String assetPath;
  final int frameWidth;
  final int frameHeight;
  final int frameCount;
  final int columns;
  final int rows;
  final Duration frameDuration;
  final bool loop;

  const MascotAnimConfig({
    required this.assetPath,
    this.frameWidth = 32,
    this.frameHeight = 32,
    this.frameCount = 1,
    this.columns = 1,
    this.rows = 1,
    this.frameDuration = const Duration(milliseconds: 150),
    this.loop = true,
  });
}

/// Centralized Mascot Controller / Behavior State Machine for Gerex.
/// Manages the robot mascot's state across the app, supporting 8 static PNG poses
/// and transform-driven movement along the navigation bar.
class MascotController extends ChangeNotifier {
  MascotState _currentState = MascotState.idle;
  Timer? _stateReturnTimer;
  Timer? _sequenceTimer;
  Timer? _randomIdleActionTimer;
  DateTime? _lastActionTime;
  final List<DateTime> _tabSwitchTimestamps = [];
  final Random _random = Random();

  int _targetTabIndex = 0;
  int _navTriggerCount = 0;

  MascotState get currentState => _currentState;
  MascotAnimConfig get activeConfig => _currentState.config;
  int get targetTabIndex => _targetTabIndex;
  int get navTriggerCount => _navTriggerCount;

  MascotController() {
    _startRandomIdleActionScheduler();
  }

  /// Trigger navigation to a target bottom nav bar tab.
  /// Robot walks/runs to the target tab icon, stands for 1s, then disappears.
  void navigateToTab(int tabIndex) {
    _cancelReturnTimers();
    final now = DateTime.now();
    _tabSwitchTimestamps.add(now);
    _tabSwitchTimestamps.removeWhere((t) => now.difference(t).inMilliseconds > 2000);

    final bool isRapidSwitch = _tabSwitchTimestamps.length >= 3;
    _targetTabIndex = tabIndex;
    _currentState = isRapidSwitch ? MascotState.running : MascotState.walking;
    _navTriggerCount++;
    _lastActionTime = now;
    notifyListeners();
  }

  /// Trigger a friendly smiling greeting (e.g. when app starts or tab focuses).
  void triggerWave() {
    _cancelReturnTimers();
    _currentState = MascotState.smiling;
    _lastActionTime = DateTime.now();
    notifyListeners();

    _stateReturnTimer = Timer(const Duration(milliseconds: 2600), () {
      resetToIdle();
    });
  }

  /// Trigger a tab switch walk or run animation.
  /// Detects rapid tab switching to switch from walk to run state.
  void triggerWalkOrRun() {
    navigateToTab(_targetTabIndex);
  }

  /// Explicitly trigger walking pose.
  void triggerWalking() {
    _cancelReturnTimers();
    _currentState = MascotState.walking;
    _lastActionTime = DateTime.now();
    notifyListeners();

    _stateReturnTimer = Timer(const Duration(milliseconds: 2800), () {
      resetToIdle();
    });
  }

  /// Explicitly trigger running pose.
  void triggerRunning() {
    _cancelReturnTimers();
    _currentState = MascotState.running;
    _lastActionTime = DateTime.now();
    notifyListeners();

    _stateReturnTimer = Timer(const Duration(milliseconds: 2200), () {
      resetToIdle();
    });
  }

  /// Trigger exercise/flex pose celebration.
  void triggerFlexAnimation() {
    triggerWorkoutCompletion();
  }

  /// Trigger workout completion sequence: exercise (flex pose) -> recovery pose (sweating/tired) -> idle.
  void triggerWorkoutCompletion() {
    _cancelReturnTimers();
    _currentState = MascotState.exercise;
    _lastActionTime = DateTime.now();
    notifyListeners();

    // Step 1: Hold exercise/flex pose for 2.8s
    _sequenceTimer = Timer(const Duration(milliseconds: 2800), () {
      if (_currentState == MascotState.exercise) {
        // Choose recovery state: sweating, tired, or sweatingAndTired
        final recoveryOptions = [
          MascotState.sweating,
          MascotState.sweatingAndTired,
          MascotState.tired,
        ];
        _currentState = recoveryOptions[_random.nextInt(recoveryOptions.length)];
        notifyListeners();

        // Step 2: Hold recovery pose for 2.5s before returning to idle
        _stateReturnTimer = Timer(const Duration(milliseconds: 2500), () {
          resetToIdle();
        });
      }
    });
  }

  /// Trigger specific momentary pose (exercise, sweating, tired, sweatingAndTired, smiling).
  void triggerPose(MascotState state, {Duration duration = const Duration(milliseconds: 2800)}) {
    _cancelReturnTimers();
    _currentState = state;
    _lastActionTime = DateTime.now();
    notifyListeners();

    _stateReturnTimer = Timer(duration, () {
      resetToIdle();
    });
  }

  /// Revert back to continuous default idle pose.
  void resetToIdle() {
    _cancelReturnTimers();
    if (_currentState != MascotState.idle) {
      _currentState = MascotState.idle;
      notifyListeners();
    }
  }

  /// Frequent subtle random action scheduler during quiet app usage so the robot feels alive.
  void _startRandomIdleActionScheduler() {
    _randomIdleActionTimer?.cancel();
    _randomIdleActionTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (_currentState == MascotState.idle) {
        final now = DateTime.now();
        if (_lastActionTime == null || now.difference(_lastActionTime!).inSeconds > 5) {
          final roll = _random.nextDouble();
          if (roll < 0.30) {
            // Waving smile greeting
            triggerPose(MascotState.smiling, duration: const Duration(milliseconds: 3000));
          } else if (roll < 0.55) {
            // Marching walk animation
            triggerWalking();
          } else if (roll < 0.75) {
            // Workout flex celebration
            triggerWorkoutCompletion();
          } else if (roll < 0.90) {
            // Energetic run burst
            triggerRunning();
          } else {
            // Tired recovery pose
            triggerPose(MascotState.tired, duration: const Duration(milliseconds: 2800));
          }
        }
      }
    });
  }

  void _cancelReturnTimers() {
    _stateReturnTimer?.cancel();
    _stateReturnTimer = null;
    _sequenceTimer?.cancel();
    _sequenceTimer = null;
  }

  @override
  void dispose() {
    _cancelReturnTimers();
    _randomIdleActionTimer?.cancel();
    super.dispose();
  }
}

