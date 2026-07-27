import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ExerciseImageWidget extends StatefulWidget {
  final String? imagePath;
  final bool removeBackground;
  final double size;

  const ExerciseImageWidget({
    super.key,
    this.imagePath,
    this.removeBackground = false,
    this.size = 50.0,
  });

  @override
  State<ExerciseImageWidget> createState() => _ExerciseImageWidgetState();
}

class _ExerciseImageWidgetState extends State<ExerciseImageWidget> {
  ui.Image? _processedImage;
  bool _isLoading = false;
  String? _loadedPath;
  bool _loadedRemoveBg = false;

  @override
  void initState() {
    super.initState();
    _processImageIfNeeded();
  }

  @override
  void didUpdateWidget(covariant ExerciseImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imagePath != widget.imagePath ||
        oldWidget.removeBackground != widget.removeBackground) {
      _processImageIfNeeded();
    }
  }

  Future<void> _processImageIfNeeded() async {
    final path = widget.imagePath;
    if (path == null || path.isEmpty) {
      setState(() {
        _processedImage = null;
      });
      return;
    }

    if (!widget.removeBackground) {
      setState(() {
        _processedImage = null;
      });
      return;
    }

    if (_loadedPath == path && _loadedRemoveBg == widget.removeBackground) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      Uint8List bytes;
      if (path.startsWith('assets/')) {
        final byteData = await rootBundle.load(path);
        bytes = byteData.buffer.asUint8List();
      } else {
        final file = File(path);
        if (await file.exists()) {
          bytes = await file.readAsBytes();
        } else {
          setState(() {
            _isLoading = false;
            _processedImage = null;
          });
          return;
        }
      }

      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final ui.Image rawImage = frame.image;

      final byteData = await rawImage.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData != null) {
        final buffer = byteData.buffer.asUint8List();
        // Remove white or near-white background pixels
        for (int i = 0; i < buffer.length; i += 4) {
          int r = buffer[i];
          int g = buffer[i + 1];
          int b = buffer[i + 2];
          // If pixel is very close to white, key it out (rgba alpha = 0)
          if (r > 240 && g > 240 && b > 240) {
            buffer[i + 3] = 0;
          }
        }

        final completer = Completer<ui.Image>();
        ui.decodeImageFromPixels(
          buffer,
          rawImage.width,
          rawImage.height,
          ui.PixelFormat.rgba8888,
          completer.complete,
        );
        final processed = await completer.future;

        if (mounted) {
          setState(() {
            _processedImage = processed;
            _loadedPath = path;
            _loadedRemoveBg = true;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _processedImage = null;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Background removal failed: $e');
      if (mounted) {
        setState(() {
          _processedImage = null;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final path = widget.imagePath;

    if (path == null || path.isEmpty) {
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.fitness_center_rounded,
          color: Colors.white70,
          size: widget.size * 0.5,
        ),
      );
    }

    if (_isLoading) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (widget.removeBackground && _processedImage != null) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: RawImage(
          image: _processedImage,
          fit: BoxFit.contain,
        ),
      );
    }

    // Default image rendering
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.size * 0.2),
        child: path.startsWith('assets/')
            ? Image.asset(path, fit: BoxFit.contain)
            : Image.file(File(path), fit: BoxFit.contain),
      ),
    );
  }
}
