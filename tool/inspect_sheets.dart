import 'dart:io';

void main() {
  final dir = Directory('assets/images/robot_mascot');
  final files = dir.listSync().where((f) => f.path.endsWith('.png')).toList();

  print('--- Mascot PNG Dimensions ---');
  for (final f in files) {
    final bytes = File(f.path).readAsBytesSync();
    final width = (bytes[16] << 24) | (bytes[17] << 16) | (bytes[18] << 8) | bytes[19];
    final height = (bytes[20] << 24) | (bytes[21] << 16) | (bytes[22] << 8) | bytes[23];
    final aspect = width / height;
    final name = f.path.split(Platform.pathSeparator).last;
    print('$name: ${width}x$height (Aspect ratio: ${aspect.toStringAsFixed(2)})');
  }
}
