import 'dart:io';

void main() {
  final files = [
    'assets/images/robot_mascot/gerex_robot_idle.png',
    'assets/images/robot_mascot/gerex_robot_smiling.png',
    'assets/images/robot_mascot/gerex_robot_walking.png',
    'assets/images/robot_mascot/gerex_robot_running.png',
    'assets/images/robot_mascot/gerex_robot_exercise.png',
    'assets/images/robot_mascot/gerex_robot_sweating.png',
    'assets/images/robot_mascot/gerex_robot_sweating_and_tired.png',
    'assets/images/robot_mascot/gerex_robot_tired.png',
  ];

  for (final path in files) {
    final file = File(path);
    if (file.existsSync()) {
      // ignore: avoid_print
      print('$path: ${file.lengthSync()} bytes');
    } else {
      // ignore: avoid_print
      print('$path: MISSING');
    }
  }
}
