import 'dart:io';

void main() {
  final specs = [
    {'name': 'idle', 'path': 'assets/images/robot_mascot/gerex_robot_idle.png', 'cols': 1, 'rows': 1},
    {'name': 'smiling', 'path': 'assets/images/robot_mascot/gerex_robot_smiling.png', 'cols': 4, 'rows': 1},
    {'name': 'walking', 'path': 'assets/images/robot_mascot/gerex_robot_walking.png', 'cols': 3, 'rows': 2},
    {'name': 'running', 'path': 'assets/images/robot_mascot/gerex_robot_running.png', 'cols': 4, 'rows': 2},
    {'name': 'exercise', 'path': 'assets/images/robot_mascot/gerex_robot_exercise.png', 'cols': 3, 'rows': 2},
    {'name': 'sweating', 'path': 'assets/images/robot_mascot/gerex_robot_sweating.png', 'cols': 4, 'rows': 1},
    {'name': 'sweating_and_tired', 'path': 'assets/images/robot_mascot/gerex_robot_sweating_and_tired.png', 'cols': 6, 'rows': 1},
    {'name': 'tired', 'path': 'assets/images/robot_mascot/gerex_robot_tired.png', 'cols': 1, 'rows': 1},
  ];

  for (final s in specs) {
    final file = File(s['path'] as String);
    if (!file.existsSync()) continue;
    final bytes = file.readAsBytesSync();
    final width = (bytes[16] << 24) | (bytes[17] << 16) | (bytes[18] << 8) | bytes[19];
    final height = (bytes[20] << 24) | (bytes[21] << 16) | (bytes[22] << 8) | bytes[23];
    final cols = s['cols'] as int;
    final rows = s['rows'] as int;
    final frameW = width / cols;
    final frameH = height / rows;
    final aspect = frameW / frameH;
    print('${s['name']}: total ${width}x${height}, grid ${cols}x${rows} => frame ${frameW.toStringAsFixed(1)}x${frameH.toStringAsFixed(1)} (aspect: ${aspect.toStringAsFixed(3)})');
  }
}
