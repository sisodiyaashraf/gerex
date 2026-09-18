import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Inspect gerex_robot_sweating.png asset dimensions', () async {
    final file = File('assets/images/robot_mascot/gerex_robot_sweating.png');
    expect(file.existsSync(), isTrue);

    final bytes = file.readAsBytesSync();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    expect(image.width, equals(612));
    expect(image.height, equals(408));
  });
}
