import 'dart:io';

void main() {
  final files = [
    'assets/images/robot_mascot/gerex_robot_idle.png',
    'assets/images/robot_mascot/gerex_robot_sweating_and_tired.png',
  ];

  for (final path in files) {
    final file = File(path);
    final bytes = file.readAsBytesSync();
    print('$path size: ${bytes.length}');
  }
}
