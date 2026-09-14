import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Check if single quadrant contains stacked figures', () async {
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

    // 1. Let's inspect TL quadrant: x in [0, 768], y in [0, 512]
    // Check pixel row counts for y from 0 to 512
    List<int> rowCountsTL = List.filled(512, 0);
    for (int y = 0; y < 512; y++) {
      for (int x = 0; x < 768; x++) {
        final idx = (y * width + x) * 4;
        if (buffer[idx + 3] > 30) {
          rowCountsTL[y]++;
        }
      }
    }

    // Find row segments (peaks and valleys in rowCountsTL)
    print('=== TL Quadrant (768x512) Row Profile ===');
    for (int y = 0; y < 512; y += 32) {
      final chunkSum = rowCountsTL.sublist(y, (y + 32).clamp(0, 512)).reduce((a, b) => a + b);
      print('TL y range ${y.toString().padLeft(3)}-${(y+31).toString().padLeft(3)}: $chunkSum pixels');
    }

    // 2. Let's inspect Column 0 in 4x1 layout: x in [0, 384], y in [0, 1024]
    List<int> rowCountsCol0 = List.filled(1024, 0);
    for (int y = 0; y < 1024; y++) {
      for (int x = 0; x < 384; x++) {
        final idx = (y * width + x) * 4;
        if (buffer[idx + 3] > 30) {
          rowCountsCol0[y]++;
        }
      }
    }

    print('\n=== Col 0 of 4x1 (384x1024) Row Profile ===');
    for (int y = 0; y < 1024; y += 64) {
      final chunkSum = rowCountsCol0.sublist(y, (y + 64).clamp(0, 1024)).reduce((a, b) => a + b);
      print('Col0 y range ${y.toString().padLeft(4)}-${(y+63).toString().padLeft(4)}: $chunkSum pixels');
    }
  });
}
