import 'dart:io';

void main() {
  final dir = Directory('assets/images/robot_mascot');
  for (var file in dir.listSync()) {
    if (file is File && file.path.endsWith('.png')) {
      final bytes = file.readAsBytesSync();
      if (bytes.length > 24 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
        final width = (bytes[16] << 24) | (bytes[17] << 16) | (bytes[18] << 8) | bytes[19];
        final height = (bytes[20] << 24) | (bytes[21] << 16) | (bytes[22] << 8) | bytes[23];
        // ignore: avoid_print
        print('${file.path}: ${width}x$height px (file size: ${bytes.length} bytes)');
      }
    }
  }
}
