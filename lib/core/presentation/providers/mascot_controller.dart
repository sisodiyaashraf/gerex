import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

enum MascotState {
  idle,
  walk,
  run,
  wave,
  flex,
}

class MascotAnimConfig {
  final String assetPath;
  final int frameWidth;
  final int frameHeight;
  final int frameCount;
  final int columns;
  final Duration frameDuration;
  final bool loop;

  const MascotAnimConfig({
    required this.assetPath,
    this.frameWidth = 32,
    this.frameHeight = 32,
    this.frameCount = 4,
    this.columns = 4,
    this.frameDuration = const Duration(milliseconds: 150),
    this.loop = true,
  });
}

/// Centralized Mascot Controller / Behavior State Machine for Gerex.
/// Manages the robot mascot's animation state across the app, ensuring
/// consistent triggers (greeting wave, walking on tab switch, flex pose on workout completed).
class MascotController extends ChangeNotifier {
  MascotState _currentState = MascotState.idle;
  Timer? _stateReturnTimer;
  Timer? _randomIdleActionTimer;
  DateTime? _lastActionTime;
  final Random _random = Random();

  MascotState get currentState => _currentState;

  MascotController() {
    _startRandomIdleActionScheduler();
  }

  /// Get the configuration for the active sprite sheet state slot.
  MascotAnimConfig get activeConfig {
    switch (_currentState) {
      case MascotState.walk:
        return const MascotAnimConfig(
          assetPath: 'assets/images/robot_mascot/robot_walk.png',
          frameWidth: 32,
          frameHeight: 32,
          frameCount: 4,
          columns: 4,
          frameDuration: Duration(milliseconds: 140),
          loop: true,
        );
      case MascotState.run:
        return const MascotAnimConfig(
          assetPath: 'assets/images/robot_mascot/robot_run.png',
          frameWidth: 32,
          frameHeight: 32,
          frameCount: 4,
          columns: 4,
          frameDuration: Duration(milliseconds: 100),
          loop: true,
        );
      case MascotState.wave:
        return const MascotAnimConfig(
          assetPath: 'assets/images/robot_mascot/robot_wave.png',
          frameWidth: 32,
          frameHeight: 32,
          frameCount: 4,
          columns: 4,
          frameDuration: Duration(milliseconds: 160),
          loop: false,
        );
      case MascotState.flex:
        return const MascotAnimConfig(
          assetPath: 'assets/images/robot_mascot/robot_flex.png',
          frameWidth: 32,
          frameHeight: 32,
          frameCount: 4,
          columns: 4,
          frameDuration: Duration(milliseconds: 180),
          loop: false,
        );
      case MascotState.idle:
      default:
        return const MascotAnimConfig(
          assetPath: 'assets/images/robot_mascot/robot_idle.png',
          frameWidth: 32,
          frameHeight: 32,
          frameCount: 4,
          columns: 4,
          frameDuration: Duration(milliseconds: 180),
          loop: true,
        );
    }
  }

  /// Trigger a friendly greeting wave (e.g. when app starts or home tab focuses).
  void triggerWave() {
    _cancelReturnTimer();
    _currentState = MascotState.wave;
    _lastActionTime = DateTime.now();
    notifyListeners();

    _stateReturnTimer = Timer(const Duration(milliseconds: 2400), () {
      resetToIdle();
    });
  }

  /// Trigger a short walk or run animation (e.g. switching tabs).
  void triggerWalkOrRun() {
    _cancelReturnTimer();
    final bool useRun = _random.nextBool();
    _currentState = useRun ? MascotState.run : MascotState.walk;
    _lastActionTime = DateTime.now();
    notifyListeners();

    _stateReturnTimer = Timer(const Duration(milliseconds: 2200), () {
      resetToIdle();
    });
  }

  /// Trigger a celebratory gym-pose / flex animation when a workout is finished or streak hit.
  void triggerFlexAnimation() {
    _cancelReturnTimer();
    _currentState = MascotState.flex;
    _lastActionTime = DateTime.now();
    notifyListeners();

    _stateReturnTimer = Timer(const Duration(milliseconds: 3600), () {
      resetToIdle();
    });
  }

  /// Revert back to the continuous default idle animation state.
  void resetToIdle() {
    _cancelReturnTimer();
    if (_currentState != MascotState.idle) {
      _currentState = MascotState.idle;
      notifyListeners();
    }
  }

  /// Low-frequency subtle random action scheduler during quiet idle browsing.
  void _startRandomIdleActionScheduler() {
    _randomIdleActionTimer?.cancel();
    _randomIdleActionTimer = Timer.periodic(const Duration(seconds: 25), (timer) {
      if (_currentState == MascotState.idle) {
        final now = DateTime.now();
        if (_lastActionTime == null || now.difference(_lastActionTime!).inSeconds > 20) {
          // 30% chance to do a quick walk or wave
          if (_random.nextDouble() < 0.3) {
            triggerWalkOrRun();
          }
        }
      }
    });
  }

  void _cancelReturnTimer() {
    _stateReturnTimer?.cancel();
    _stateReturnTimer = null;
  }

  @override
  void dispose() {
    _cancelReturnTimer();
    _randomIdleActionTimer?.cancel();
    super.dispose();
  }
}
