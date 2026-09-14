import 'dart:io';
import 'dart:typed_data';

void main() {
  final dir = Directory('assets/images/robot_mascot');
  for (final file in dir.listSync().whereType<File>()) {
    if (file.path.endsWith('.png')) {
      final bytes = file.readAsBytesSync();
      if (bytes.length > 24) {
        final bd = ByteData.sublistView(bytes);
        final width = bd.getUint32(16);
        final height = bd.getUint32(20);
        print('${file.uri.pathSegments.last}: ${width}x${height}');
      }
    }
  }
}
