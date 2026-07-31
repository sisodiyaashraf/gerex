import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:gerex/core/theme/app_theme.dart';
import 'package:gerex/core/utils/logger.dart';

class MealBarcodeScannerScreen extends StatefulWidget {
  const MealBarcodeScannerScreen({super.key});

  @override
  State<MealBarcodeScannerScreen> createState() => _MealBarcodeScannerScreenState();
}

class _MealBarcodeScannerScreenState extends State<MealBarcodeScannerScreen> {
  CameraController? _cameraController;
  final BarcodeScanner _barcodeScanner = BarcodeScanner();
  bool _isCameraInitialized = false;
  bool _isScanning = false;
  bool _hasFoundBarcode = false;
  String _statusMessage = 'Align barcode inside the frame';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _barcodeScanner.close();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _statusMessage = 'No cameras found';
        });
        return;
      }

      final backCam = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        backCam,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (!mounted) return;

      setState(() {
        _isCameraInitialized = true;
      });

      _startScanStream();
    } catch (e) {
      SecureLogger.logError('BarcodeScanner: Camera initialization failed', e);
      setState(() {
        _statusMessage = 'Failed to open camera';
      });
    }
  }

  void _startScanStream() {
    if (_cameraController == null || !_isCameraInitialized) return;

    _cameraController!.startImageStream((CameraImage image) async {
      if (_isScanning || _hasFoundBarcode || !mounted) return;
      _isScanning = true;

      try {
        final WriteBuffer allBytes = WriteBuffer();
        for (final Plane plane in image.planes) {
          allBytes.putUint8List(plane.bytes);
        }
        final bytes = allBytes.done().buffer.asUint8List();

        final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());
        const InputImageRotation imageRotation = InputImageRotation.rotation90deg;
        const InputImageFormat inputImageFormat = InputImageFormat.nv21;

        final inputImageMetadata = InputImageMetadata(
          size: imageSize,
          rotation: imageRotation,
          format: inputImageFormat,
          bytesPerRow: image.planes[0].bytesPerRow,
        );

        final inputImage = InputImage.fromBytes(
          bytes: bytes,
          metadata: inputImageMetadata,
        );

        final List<Barcode> barcodes = await _barcodeScanner.processImage(inputImage);
        if (barcodes.isNotEmpty && !_hasFoundBarcode && mounted) {
          final barcodeVal = barcodes.first.rawValue;
          if (barcodeVal != null && barcodeVal.isNotEmpty) {
            _hasFoundBarcode = true;
            _cameraController?.stopImageStream();
            Navigator.pop(context, barcodeVal);
            return;
          }
        }
      } catch (e) {
        SecureLogger.logError('BarcodeScanner: Scan error', e);
      } finally {
        _isScanning = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan Product Barcode', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          if (_isCameraInitialized && _cameraController != null)
            Positioned.fill(
              child: AspectRatio(
                aspectRatio: _cameraController!.value.aspectRatio,
                child: CameraPreview(_cameraController!),
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: AppColors.accentEmeraldLight),
            ),
          
          // Guide overlay
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 280,
                      height: 160,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.accentEmeraldLight, width: 2),
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.transparent,
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Container(
                              width: 260,
                              height: 2,
                              color: AppColors.accentEmeraldLight.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _statusMessage,
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
