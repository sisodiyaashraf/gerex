import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../providers/mascot_controller.dart';

/// Asset-agnostic generic Sprite Animator widget for 8-bit Gerex robot graphics.
/// Loads grid-based PNG sprite sheets from assets, caches them synchronously in memory,
/// and cycles through frames using an [AnimationController].
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

  static final Map<String, ui.Image> _imageCache = {};

  /// Preload all Gerex robot PNG assets into memory for zero-latency frame switching.
  static Future<void> preloadAllAssets() async {
    for (final state in MascotState.values) {
      if (!_imageCache.containsKey(state.assetPath)) {
        try {
          final ByteData data = await rootBundle.load(state.assetPath);
          final Uint8List bytes = data.buffer.asUint8List();
          final ui.Codec codec = await ui.instantiateImageCodec(bytes);
          final ui.FrameInfo frameInfo = await codec.getNextFrame();
          _imageCache[state.assetPath] = frameInfo.image;
        } catch (_) {}
      }
    }
  }

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

  void _loadSpriteSheet() {
    if (SpriteAnimator._imageCache.containsKey(widget.assetPath)) {
      setState(() {
        _spriteImage = SpriteAnimator._imageCache[widget.assetPath];
        _isLoadingImage = false;
        _hasImageError = false;
      });
      return;
    }

    setState(() {
      _isLoadingImage = true;
      _hasImageError = false;
    });

    rootBundle.load(widget.assetPath).then((data) {
      final Uint8List bytes = data.buffer.asUint8List();
      return ui.instantiateImageCodec(bytes);
    }).then((codec) {
      return codec.getNextFrame();
    }).then((frameInfo) {
      SpriteAnimator._imageCache[widget.assetPath] = frameInfo.image;
      if (mounted) {
        setState(() {
          _spriteImage = frameInfo.image;
          _isLoadingImage = false;
          _hasImageError = false;
        });
      }
    }).catchError((e) {
      if (mounted) {
        setState(() {
          _spriteImage = null;
          _isLoadingImage = false;
          _hasImageError = true;
        });
      }
    });
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
              rows: widget.rows,
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
  final int rows;
  final int frameCount;
  final String stateName;
  final bool hasError;

  _SpriteFramePainter({
    required this.image,
    required this.currentFrame,
    required this.frameWidth,
    required this.frameHeight,
    required this.columns,
    required this.rows,
    required this.frameCount,
    required this.stateName,
    required this.hasError,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (image != null && !hasError && frameCount > 0) {
      final int numCols = columns > 0 ? columns : 1;
      final int numRows = rows > 0 ? rows : 1;

      final double singleFrameWidth = image!.width / numCols;
      final double singleFrameHeight = image!.height / numRows;

      final int frameIndex = currentFrame.clamp(0, frameCount - 1);
      final int col = frameIndex % numCols;
      final int row = frameIndex ~/ numCols;

      final Rect srcRect = Rect.fromLTWH(
        col * singleFrameWidth,
        row * singleFrameHeight,
        singleFrameWidth,
        singleFrameHeight,
      );

      final double srcAspect =
          singleFrameWidth / (singleFrameHeight > 0 ? singleFrameHeight : 1);
      final double dstAspect =
          size.width / (size.height > 0 ? size.height : 1);

      Rect dstRect;
      if ((srcAspect - dstAspect).abs() < 0.001) {
        dstRect = Rect.fromLTWH(0, 0, size.width, size.height);
      } else if (srcAspect > dstAspect) {
        final double drawHeight = size.width / srcAspect;
        final double top = (size.height - drawHeight) / 2.0;
        dstRect = Rect.fromLTWH(0, top, size.width, drawHeight);
      } else {
        final double drawWidth = size.height * srcAspect;
        final double left = (size.width - drawWidth) / 2.0;
        dstRect = Rect.fromLTWH(left, 0, drawWidth, size.height);
      }

      final Paint paint = Paint()..filterQuality = FilterQuality.high;

      canvas.drawImageRect(image!, srcRect, dstRect, paint);
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
