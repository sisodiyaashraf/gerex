import 'dart:io';

void main() {
  final idleFile = File('assets/images/robot_mascot/gerex_robot_idle.png');
  final bytes = idleFile.readAsBytesSync();
  print('Idle file bytes: ${bytes.length}');
  
  // PNG IHDR inspect
  final width = (bytes[16] << 24) | (bytes[17] << 16) | (bytes[18] << 8) | bytes[19];
  final height = (bytes[20] << 24) | (bytes[21] << 16) | (bytes[22] << 8) | bytes[23];
  final bitDepth = bytes[24];
  final colorType = bytes[25];
  print('Idle PNG: ${width}x${height}, depth: $bitDepth, colorType: $colorType');
}
