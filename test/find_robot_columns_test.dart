import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Find exact robot positions in running sprite sheet', () async {
    final file = File('assets/images/robot_mascot/gerex_robot_running.png');
    final bytes = file.readAsBytesSync();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final width = image.width; // 1536
    final height = image.height; // 1024

    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) return;
    final buffer = byteData.buffer.asUint8List();

    // Check X column density in top half y in [0, 512] across 1536 width
    List<int> topRowX = List.filled(1536, 0);
    List<int> botRowX = List.filled(1536, 0);

    for (int y = 0; y < 512; y++) {
      for (int x = 0; x < 1536; x++) {
        final idx = (y * width + x) * 4;
        if (buffer[idx + 3] > 30) topRowX[x]++;
      }
    }
    for (int y = 512; y < 1024; y++) {
      for (int x = 0; x < 1536; x++) {
        final idx = (y * width + x) * 4;
        if (buffer[idx + 3] > 30) botRowX[x]++;
      }
    }

    print('=== TOP ROW (y: 0..512) Horizontal Profile across 1536px ===');
    for (int x = 0; x < 1536; x += 96) {
      final sum = topRowX.sublist(x, (x + 96).clamp(0, 1536)).reduce((a, b) => a + b);
      print('Top y, x ${x.toString().padLeft(4)}-${(x+95).toString().padLeft(4)}: $sum');
    }

    print('\n=== BOTTOM ROW (y: 512..1024) Horizontal Profile across 1536px ===');
    for (int x = 0; x < 1536; x += 96) {
      final sum = botRowX.sublist(x, (x + 96).clamp(0, 1536)).reduce((a, b) => a + b);
      print('Bot y, x ${x.toString().padLeft(4)}-${(x+95).toString().padLeft(4)}: $sum');
    }
  });
}
