import 'package:flutter_test/flutter_test.dart';
import 'package:gerex/core/presentation/providers/mascot_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MascotController State Machine Tests', () {
    late MascotController controller;

    setUp(() {
      controller = MascotController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('Initial state is idle', () {
      expect(controller.currentState, equals(MascotState.idle));
      expect(controller.activeConfig.columns, equals(2));
      expect(controller.activeConfig.rows, equals(2));
      expect(controller.activeConfig.frameCount, equals(4));
    });

    test('triggerWave switches state to smiling', () {
      controller.triggerWave();
      expect(controller.currentState, equals(MascotState.smiling));
      expect(controller.activeConfig.columns, equals(4));
      expect(controller.activeConfig.rows, equals(2));
      expect(controller.activeConfig.frameCount, equals(4));
    });

    test('triggerWalking switches state to walking', () {
      controller.triggerWalking();
      expect(controller.currentState, equals(MascotState.walking));
      expect(controller.activeConfig.columns, equals(4));
      expect(controller.activeConfig.rows, equals(2));
    });

    test('triggerRunning switches state to running', () {
      controller.triggerRunning();
      expect(controller.currentState, equals(MascotState.running));
      expect(controller.activeConfig.columns, equals(4));
      expect(controller.activeConfig.rows, equals(2));
    });

    test('triggerPose switches to exact specified state', () {
      controller.triggerPose(MascotState.tired);
      expect(controller.currentState, equals(MascotState.tired));

      controller.triggerPose(MascotState.sweating);
      expect(controller.currentState, equals(MascotState.sweating));

      controller.triggerPose(MascotState.sweatingAndTired);
      expect(controller.currentState, equals(MascotState.sweatingAndTired));
    });

    test('triggerWorkoutCompletion initializes exercise state', () {
      controller.triggerWorkoutCompletion();
      expect(controller.currentState, equals(MascotState.exercise));
      expect(controller.activeConfig.columns, equals(4));
      expect(controller.activeConfig.rows, equals(2));
    });

    test('resetToIdle reverts back to idle state', () {
      controller.triggerRunning();
      expect(controller.currentState, equals(MascotState.running));

      controller.resetToIdle();
      expect(controller.currentState, equals(MascotState.idle));
    });

    test('Rapid tab switches transition from walking to running', () {
      controller.triggerWalkOrRun();
      expect(controller.currentState, equals(MascotState.walking));

      controller.triggerWalkOrRun();
      controller.triggerWalkOrRun();
      expect(controller.currentState, equals(MascotState.running));
    });
  });
}
