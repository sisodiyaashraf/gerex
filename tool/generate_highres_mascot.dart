import 'dart:io';
import 'dart:typed_data';

void main() async {
  final dir = Directory('assets/images/robot_mascot');
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }

  stdout.writeln('Generating ultra high-resolution robot mascot assets...');

  // 1. gerex_robot_sweating.png (1024 x 1024, 2x2 grid = 4 frames of 512x512)
  final sweatingBytes = generateSweatingSheet();
  File('${dir.path}/gerex_robot_sweating.png').writeAsBytesSync(sweatingBytes);
  stdout.writeln(
    'Generated gerex_robot_sweating.png (${sweatingBytes.length} bytes)',
  );

  // 2. gerex_robot_sweating_and_tired.png (1536 x 1024, 3x2 grid = 6 frames of 512x512)
  final sweatingTiredBytes = generateSweatingAndTiredSheet();
  File(
    '${dir.path}/gerex_robot_sweating_and_tired.png',
  ).writeAsBytesSync(sweatingTiredBytes);
  stdout.writeln(
    'Generated gerex_robot_sweating_and_tired.png (${sweatingTiredBytes.length} bytes)',
  );

  // 3. gerex_robot_tired.png (1024 x 1024, 1x1 grid = 1 frame of 1024x1024)
  final tiredBytes = generateTiredSheet();
  File('${dir.path}/gerex_robot_tired.png').writeAsBytesSync(tiredBytes);
  stdout.writeln(
    'Generated gerex_robot_tired.png (${tiredBytes.length} bytes)',
  );

  stdout.writeln('Successfully generated high-resolution mascot PNG assets!');
}

List<int> generateSweatingSheet() {
  const width = 1024;
  const height = 1024;
  const cols = 2;
  const rows = 2;

  final scanlines = BytesBuilder();

  for (int y = 0; y < height; y++) {
    scanlines.addByte(0); // PNG Filter type None
    final rIdx = y ~/ 512;
    final localY = y % 512;

    for (int x = 0; x < width; x++) {
      final cIdx = x ~/ 512;
      final localX = x % 512;
      final frameIndex = rIdx * cols + cIdx;

      final color = drawMascotFrame(
        frameIndex: frameIndex,
        totalFrames: 4,
        localX: localX,
        localY: localY,
        frameSize: 512,
        isTired: false,
        isSweating: true,
      );
      scanlines.add(color);
    }
  }

  return encodePng(width, height, scanlines.takeBytes());
}

List<int> generateSweatingAndTiredSheet() {
  const width = 1536;
  const height = 1024;
  const cols = 3;
  const rows = 2;

  final scanlines = BytesBuilder();

  for (int y = 0; y < height; y++) {
    scanlines.addByte(0);
    final rIdx = y ~/ 512;
    final localY = y % 512;

    for (int x = 0; x < width; x++) {
      final cIdx = x ~/ 512;
      final localX = x % 512;
      final frameIndex = rIdx * cols + cIdx;

      final color = drawMascotFrame(
        frameIndex: frameIndex,
        totalFrames: 6,
        localX: localX,
        localY: localY,
        frameSize: 512,
        isTired: true,
        isSweating: true,
      );
      scanlines.add(color);
    }
  }

  return encodePng(width, height, scanlines.takeBytes());
}

List<int> generateTiredSheet() {
  const width = 1024;
  const height = 1024;

  final scanlines = BytesBuilder();

  for (int y = 0; y < height; y++) {
    scanlines.addByte(0);
    for (int x = 0; x < width; x++) {
      final color = drawMascotFrame(
        frameIndex: 0,
        totalFrames: 1,
        localX: x,
        localY: y,
        frameSize: 1024,
        isTired: true,
        isSweating: false,
      );
      scanlines.add(color);
    }
  }

  return encodePng(width, height, scanlines.takeBytes());
}

List<int> drawMascotFrame({
  required int frameIndex,
  required int totalFrames,
  required int localX,
  required int localY,
  required int frameSize,
  required bool isTired,
  required bool isSweating,
}) {
  // Normalize coordinates to 0.0 .. 1.0
  final nx = localX / frameSize;
  final ny = localY / frameSize;

  // Animation offsets per frame
  final double breathY = isTired
      ? ((frameIndex % 2 == 0) ? 0.02 : -0.01)
      : ((frameIndex % 2 == 0) ? 0.01 : -0.01);

  final double headOffset = isTired ? 0.05 : 0.0;

  // Center points (scaled relative to normalized grid)
  final cx = 0.5;
  final cy = 0.48 + headOffset + breathY;

  // Head bounds (rounded metallic face)
  final headW = 0.52;
  final headH = 0.44;
  final dx = (nx - cx).abs();
  final dy = (ny - cy).abs();

  // Outer border / contour
  final inHeadOuter =
      (dx * dx) / ((headW / 2) * (headW / 2)) +
          (dy * dy) / ((headH / 2) * (headH / 2)) <=
      1.0;
  final inHeadInner =
      (dx * dx) / ((headW / 2 - 0.02) * (headW / 2 - 0.02)) +
          (dy * dy) / ((headH / 2 - 0.02) * (headH / 2 - 0.02)) <=
      1.0;

  // Screen Face Glass
  final screenW = 0.40;
  final screenH = 0.28;
  final inScreen =
      (dx * dx) / ((screenW / 2) * (screenW / 2)) +
          ((ny - cy - 0.01).abs() * (ny - cy - 0.01).abs()) /
              ((screenH / 2) * (screenH / 2)) <=
      1.0;

  // Eyes (Cyan glowing digital eyes)
  final eyeY = cy - 0.02;
  final eyeLeftX = cx - 0.11;
  final eyeRightX = cx + 0.11;
  final distLeftEye =
      ((nx - eyeLeftX) * (nx - eyeLeftX)) + ((ny - eyeY) * (ny - eyeY));
  final distRightEye =
      ((nx - eyeRightX) * (nx - eyeRightX)) + ((ny - eyeY) * (ny - eyeY));

  final isLeftEye = distLeftEye <= 0.0022;
  final isRightEye = distRightEye <= 0.0022;

  // Tired half-lids
  final isEyeLid =
      isTired && (ny < eyeY - 0.01 + (frameIndex % 2 == 0 ? 0.008 : 0.0));

  // Chest Core Light (Amber / Cyan pulse)
  final chestY = cy + 0.28;
  final distChest = ((nx - cx) * (nx - cx)) + ((ny - chestY) * (ny - chestY));
  final isChestCore = distChest <= 0.0035;
  final isChestRing = distChest <= 0.0055 && !isChestCore;

  // Sweat Droplet (Glistening cyan animated water drops)
  bool isSweatDrop = false;
  if (isSweating) {
    final dropCycle = frameIndex % 3;
    final dropX = cx + 0.18 + (dropCycle == 1 ? 0.03 : 0.0);
    final dropY = cy - 0.12 + (dropCycle * 0.06);
    final dropDist =
        ((nx - dropX) * (nx - dropX)) / 0.0006 +
        ((ny - dropY) * (ny - dropY)) / 0.0012;
    if (dropDist <= 1.0) {
      isSweatDrop = true;
    }

    // Secondary sweat drop on forehead/ear
    final drop2X = cx - 0.20;
    final drop2Y = cy - 0.08 + ((frameIndex * 0.03) % 0.08);
    final drop2Dist =
        ((nx - drop2X) * (nx - drop2X)) / 0.0005 +
        ((ny - drop2Y) * (ny - drop2Y)) / 0.0009;
    if (drop2Dist <= 1.0) {
      isSweatDrop = true;
    }
  }

  // Wiping arm / hand in sweating poses
  bool isWipingArm = false;
  if (isSweating && (frameIndex == 1 || frameIndex == 2 || frameIndex == 4)) {
    final armX = cx + 0.14 - (frameIndex == 2 ? 0.04 : 0.0);
    final armY = cy - 0.08;
    final armDist =
        ((nx - armX) * (nx - armX)) / 0.004 +
        ((ny - armY) * (ny - armY)) / 0.008;
    if (armDist <= 1.0) {
      isWipingArm = true;
    }
  }

  // Color Palette Definitions (RGBA)
  // Transparent background
  if (!inHeadOuter &&
      !isChestCore &&
      !isChestRing &&
      !isSweatDrop &&
      !isWipingArm) {
    return [0, 0, 0, 0];
  }

  if (isSweatDrop) {
    // Vibrant glowing cyan sweat droplet with white highlight
    return [56, 189, 248, 255]; // Sky cyan
  }

  if (isWipingArm) {
    return [99, 102, 241, 255]; // Indigo robot arm
  }

  if (inHeadOuter && !inHeadInner) {
    // Dark sleek contour / bevel ring
    return [15, 23, 42, 255]; // Slate 900
  }

  if (isChestCore) {
    // Glowing warning / exhausted core
    if (isTired) {
      return [245, 158, 11, 255]; // Amber glow
    } else {
      return [16, 185, 129, 255]; // Emerald glow
    }
  }

  if (isChestRing) {
    return [30, 41, 59, 255]; // Slate 800
  }

  if (inScreen) {
    if ((isLeftEye || isRightEye) && !isEyeLid) {
      // Cyan glowing digital eyes
      return [6, 182, 212, 255]; // Cyan 500
    }
    // Screen glass background (Deep glossy navy)
    return [15, 23, 42, 255];
  }

  if (inHeadInner) {
    // Body metallic gradient / shading (Indigo / Slate theme)
    final double lightGrad = (1.0 - ny).clamp(0.0, 1.0);
    final int r = (63 + lightGrad * 30).toInt().clamp(0, 255);
    final int g = (70 + lightGrad * 32).toInt().clamp(0, 255);
    final int b = (220 + lightGrad * 35).toInt().clamp(0, 255);
    return [r, g, b, 255];
  }

  return [0, 0, 0, 0];
}

List<int> encodePng(int width, int height, Uint8List rawScanlines) {
  final header = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];

  final ihdrData = ByteData(13);
  ihdrData.setUint32(0, width);
  ihdrData.setUint32(4, height);
  ihdrData.setUint8(8, 8); // bit depth 8
  ihdrData.setUint8(9, 6); // RGBA
  ihdrData.setUint8(10, 0); // compression
  ihdrData.setUint8(11, 0); // filter
  ihdrData.setUint8(12, 0); // interlace

  final ihdrChunk = makeChunk('IHDR', ihdrData.buffer.asUint8List());

  final idatCompressed = zlib.encode(rawScanlines);
  final idatChunk = makeChunk('IDAT', idatCompressed);

  final iendChunk = makeChunk('IEND', []);

  final builder = BytesBuilder();
  builder.add(header);
  builder.add(ihdrChunk);
  builder.add(idatChunk);
  builder.add(iendChunk);
  return builder.takeBytes();
}

List<int> makeChunk(String type, List<int> data) {
  final builder = BytesBuilder();
  final len = ByteData(4)..setUint32(0, data.length);
  builder.add(len.buffer.asUint8List());

  final typeBytes = type.codeUnits;
  builder.add(typeBytes);
  builder.add(data);

  final crc = calculateCrc32([...typeBytes, ...data]);
  final crcData = ByteData(4)..setUint32(0, crc);
  builder.add(crcData.buffer.asUint8List());

  return builder.takeBytes();
}

int calculateCrc32(List<int> bytes) {
  int crc = 0xFFFFFFFF;
  for (int b in bytes) {
    crc ^= b;
    for (int i = 0; i < 8; i++) {
      if ((crc & 1) != 0) {
        crc = (crc >> 1) ^ 0xEDB88320;
      } else {
        crc >>= 1;
      }
    }
  }
  return crc ^ 0xFFFFFFFF;
}
