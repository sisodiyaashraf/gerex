import 'dart:io';
import 'package:image/image.dart' as img;

void main() async {
  final dir = Directory('assets/images/robot_mascot');
  final files = dir.listSync().where((f) => f.path.endsWith('.png')).toList();

  print('=== HORIZONTAL FRAME STRIP ANALYSIS ===');
  for (final f in files) {
    final bytes = File(f.path).readAsBytesSync();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) continue;

    final width = decoded.width;
    final height = decoded.height;
    final filename = f.path.split(Platform.pathSeparator).last;

    print('\nFile: $filename (${width}x${height})');
    for (int cols in [1, 2, 3, 4, 5, 6]) {
      final frameW = width ~/ cols;
      if (frameW * cols != width) continue;

      List<String> frameSummaries = [];
      for (int c = 0; c < cols; c++) {
        int minX = width, maxX = -1, minY = height, maxY = -1;
        int activePixels = 0;
        for (int y = 0; y < height; y += 2) {
          for (int x = c * frameW; x < (c + 1) * frameW; x += 2) {
            final p = decoded.getPixel(x, y);
            if (p.a > 20) {
              activePixels++;
              int localX = x - c * frameW;
              if (localX < minX) minX = localX;
              if (localX > maxX) maxX = localX;
              if (y < minY) minY = y;
              if (y > maxY) maxY = y;
            }
          }
        }
        if (activePixels > 0) {
          frameSummaries.add('F$c:[box: (${minX},${minY}) to (${maxX},${maxY}), px: $activePixels]');
        } else {
          frameSummaries.add('F$c:EMPTY');
        }
      }
      print('  $cols columns (frameW=$frameW): ${frameSummaries.join(" | ")}');
    }
  }
}
