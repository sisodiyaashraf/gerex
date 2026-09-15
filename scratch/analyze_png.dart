import 'dart:io';

void main() {
  final files = [
    'assets/images/robot_mascot/gerex_robot_idle.png',
    'assets/images/robot_mascot/gerex_robot_smiling.png',
    'assets/images/robot_mascot/gerex_robot_walking.png',
    'assets/images/robot_mascot/gerex_robot_sweating.png',
    'assets/images/robot_mascot/gerex_robot_sweating_and_tired.png',
    'assets/images/robot_mascot/gerex_robot_tired.png',
  ];

  for (final p in files) {
    final file = File(p);
    final bytes = file.readAsBytesSync();
    // ignore: avoid_print
    print('$p: ${bytes.length} bytes');
  }
}
