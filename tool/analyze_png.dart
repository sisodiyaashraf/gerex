import 'dart:io';
import 'dart:typed_data';

void main() {
  final file = File('assets/images/robot_mascot/gerex_robot_running.png');
  final bytes = file.readAsBytesSync();
  print('gerex_robot_running.png size: ${bytes.length} bytes');

  final fileWalk = File('assets/images/robot_mascot/gerex_robot_walking.png');
  print('gerex_robot_walking.png size: ${fileWalk.readAsBytesSync().length} bytes');
}
