import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Asset-agnostic generic Sprite Animator widget for 8-bit pixel graphics.
/// Loads any grid-based PNG sprite sheet (e.g., 4 frames x 1 row) from assets
/// and cycles through frames using an [AnimationController].
///
/// If the PNG image is loading or unavailable, falls back gracefully to a crisp
/// pixel-art custom canvas rendering so the mascot is 100% visibly testable.
class SpriteAnimator extends StatefulWidget {
  final String assetPath;
  final int frameWidth;
  final int frameHeight;
  final int frameCount;
  final int columns;
  final int rows;
  final Duration frameDuration;
  final bool loop;
  final VoidCallback? onComplete;
  final double width;
  final double height;
  final String mascotStateName;

  const SpriteAnimator({
    super.key,
    required this.assetPath,
    this.frameWidth = 32,
    this.frameHeight = 32,
    this.frameCount = 4,
    this.columns = 4,
    this.rows = 1,
    this.frameDuration = const Duration(milliseconds: 150),
    this.loop = true,
    this.onComplete,
    this.width = 48.0,
    this.height = 48.0,
    this.mascotStateName = 'idle',
  });

  @override
  State<SpriteAnimator> createState() => _SpriteAnimatorState();
}

class _SpriteAnimatorState extends State<SpriteAnimator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  ui.Image? _spriteImage;
  bool _isLoadingImage = false;
  bool _hasImageError = false;

  @override
  void initState() {
    super.initState();
    _initAnimationController();
    _loadSpriteSheet();
  }

  void _initAnimationController() {
    final totalDuration = widget.frameDuration * widget.frameCount;
    _controller = AnimationController(vsync: this, duration: totalDuration);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (widget.loop) {
          _controller.repeat();
        } else {
          widget.onComplete?.call();
        }
      }
    });

    if (widget.loop) {
      _controller.repeat();
    } else {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void didUpdateWidget(covariant SpriteAnimator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetPath != widget.assetPath) {
      _loadSpriteSheet();
    }
    if (oldWidget.frameCount != widget.frameCount ||
        oldWidget.frameDuration != widget.frameDuration ||
        oldWidget.loop != widget.loop) {
      _controller.duration = widget.frameDuration * widget.frameCount;
      if (widget.loop) {
        _controller.repeat();
      } else {
        _controller.forward(from: 0.0);
      }
    }
  }

  Future<void> _loadSpriteSheet() async {
    setState(() {
      _isLoadingImage = true;
      _hasImageError = false;
    });

    try {
      final ByteData data = await rootBundle.load(widget.assetPath);
      final Uint8List bytes = data.buffer.asUint8List();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();

      if (mounted) {
        setState(() {
          _spriteImage = frameInfo.image;
          _isLoadingImage = false;
          _hasImageError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _spriteImage = null;
          _isLoadingImage = false;
          _hasImageError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double progress = _controller.value.clamp(0.0, 0.999);
        final int currentFrame = (progress * widget.frameCount).floor();

        return SizedBox(
          width: widget.width,
          height: widget.height,
          child: CustomPaint(
            painter: _SpriteFramePainter(
              image: _spriteImage,
              currentFrame: currentFrame,
              frameWidth: widget.frameWidth,
              frameHeight: widget.frameHeight,
              columns: widget.columns,
              frameCount: widget.frameCount,
              stateName: widget.mascotStateName,
              hasError: _hasImageError || _isLoadingImage,
            ),
          ),
        );
      },
    );
  }
}

class _SpriteFramePainter extends CustomPainter {
  final ui.Image? image;
  final int currentFrame;
  final int frameWidth;
  final int frameHeight;
  final int columns;
  final int frameCount;
  final String stateName;
  final bool hasError;

  _SpriteFramePainter({
    required this.image,
    required this.currentFrame,
    required this.frameWidth,
    required this.frameHeight,
    required this.columns,
    required this.frameCount,
    required this.stateName,
    required this.hasError,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (image != null && !hasError && frameCount > 0) {
      final double singleFrameWidth = image!.width / frameCount;
      final double singleFrameHeight = image!.height.toDouble();

      final int frameIndex = currentFrame.clamp(0, frameCount - 1);

      final Rect srcRect = Rect.fromLTWH(
        frameIndex * singleFrameWidth,
        0,
        singleFrameWidth,
        singleFrameHeight,
      );

      final Rect dstRect = Rect.fromLTWH(0, 0, size.width, size.height);

      final Paint paint = Paint()..filterQuality = FilterQuality.none;

      canvas.drawImageRect(image!, srcRect, dstRect, paint);
    } else {
      _drawPixelFallback(canvas, size);
    }
  }

  void _drawPixelFallback(Canvas canvas, Size size) {
    final double pixelSize = size.width / 16.0;

    // Pick state tint
    Color bodyColor = const Color(0xFF6366F1); // Indigo default (idle)
    if (stateName == 'walk') bodyColor = const Color(0xFF10B981); // Emerald
    if (stateName == 'run') bodyColor = const Color(0xFFF59E0B); // Amber
    if (stateName == 'wave') bodyColor = const Color(0xFFEC4899); // Pink
    if (stateName == 'flex') bodyColor = const Color(0xFF8B5CF6); // Purple

    final Paint bodyPaint = Paint()..color = bodyColor;
    final Paint eyePaint = Paint()..color = const Color(0xFF06B6D4); // Cyan
    final Paint chestPaint = Paint()..color = const Color(0xFFFDE047); // Yellow
    final Paint outlinePaint = Paint()
      ..color = const Color(0xFF0F172A); // Dark slate

    // Animation frame variations
    final int bobOffset = (stateName == 'idle' && currentFrame % 2 == 1)
        ? 1
        : 0;
    final int waveOffset = (stateName == 'wave' && currentFrame % 2 == 1)
        ? 2
        : 0;

    void drawPixel(int x, int y, Paint p) {
      final Rect r = Rect.fromLTWH(
        x * pixelSize,
        (y + bobOffset) * pixelSize,
        pixelSize,
        pixelSize,
      );
      canvas.drawRect(r, p);
    }

    // Outer dark box / head
    for (int y = 2; y <= 12; y++) {
      for (int x = 3; x <= 12; x++) {
        if (x == 3 || x == 12 || y == 2 || y == 12) {
          drawPixel(x, y, outlinePaint);
        } else {
          drawPixel(x, y, bodyPaint);
        }
      }
    }

    // Antenna
    drawPixel(7, 0, outlinePaint);
    drawPixel(8, 0, outlinePaint);
    drawPixel(7, 1, chestPaint);
    drawPixel(8, 1, chestPaint);

    // Pixel Eyes
    if (stateName == 'idle' && currentFrame == 2) {
      // Blinking closed eye line
      drawPixel(5, 6, outlinePaint);
      drawPixel(6, 6, outlinePaint);
      drawPixel(9, 6, outlinePaint);
      drawPixel(10, 6, outlinePaint);
    } else {
      drawPixel(5, 5, eyePaint);
      drawPixel(6, 5, eyePaint);
      drawPixel(5, 6, eyePaint);
      drawPixel(6, 6, eyePaint);

      drawPixel(9, 5, eyePaint);
      drawPixel(10, 5, eyePaint);
      drawPixel(9, 6, eyePaint);
      drawPixel(10, 6, eyePaint);
    }

    // Chest core
    drawPixel(7, 8, chestPaint);
    drawPixel(8, 8, chestPaint);
    drawPixel(7, 9, chestPaint);
    drawPixel(8, 9, chestPaint);

    // Waving hand
    if (stateName == 'wave' || stateName == 'flex') {
      drawPixel(13, 3 + waveOffset, bodyPaint);
      drawPixel(14, 3 + waveOffset, chestPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SpriteFramePainter oldDelegate) {
    return oldDelegate.currentFrame != currentFrame ||
        oldDelegate.image != image ||
        oldDelegate.stateName != stateName ||
        oldDelegate.hasError != hasError;
  }
}
