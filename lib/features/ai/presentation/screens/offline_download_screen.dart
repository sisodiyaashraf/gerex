import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gerex/core/presentation/widgets/glass_container.dart';
import 'package:gerex/core/presentation/widgets/liquid_background.dart';
import 'package:gerex/core/widgets/slide_to_confirm_button.dart';
import '../providers/ai_provider.dart';

class OfflineDownloadScreen extends StatefulWidget {
  const OfflineDownloadScreen({super.key});

  @override
  State<OfflineDownloadScreen> createState() => _OfflineDownloadScreenState();
}

class _OfflineDownloadScreenState extends State<OfflineDownloadScreen> {
  bool _isChecking = true;
  bool _hasChecked = false;
  bool _isDownloading = false;
  double _progress = 0.0;
  String _statusText = 'Checking system specifications...';
  
  // Specs metrics
  final double _availableStorage = 18.4; // GB
  final double _requiredStorage = 1.2; // GB
  final double _deviceRam = 8.0; // GB
  bool _isRamSufficient = true;
  bool _isStorageSufficient = true;

  @override
  void initState() {
    super.initState();
    _runSystemChecks();
  }

  void _runSystemChecks() {
    Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _isChecking = false;
          _hasChecked = true;
          _isStorageSufficient = _availableStorage >= _requiredStorage;
          _isRamSufficient = _deviceRam >= 4.0;
          _statusText = 'Ready to download on-device AI model.';
        });
      }
    });
  }

  void _startDownload() {
    setState(() {
      _isDownloading = true;
      _statusText = 'Downloading Gemma 1B-IT (1.2 GB)...';
    });

    // Simulate 1.2 GB download with progress ticks
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _progress += 0.02;
        if (_progress >= 1.0) {
          _progress = 1.0;
          _statusText = 'Installing and indexing local model...';
          timer.cancel();
          _finalizeInstallation();
        } else {
          final percentage = (_progress * 100).toInt();
          _statusText = 'Downloading: $percentage% completed...';
        }
      });
    });
  }

  void _finalizeInstallation() {
    Timer(const Duration(seconds: 1), () async {
      if (mounted) {
        final aiProvider = Provider.of<AIProvider>(context, listen: false);
        await aiProvider.setOfflineModelDownloaded(true);
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gerex Offline AI installed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: LiquidBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Back button row
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        color: theme.colorScheme.onSurface,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Spacer(),

                  // Header Section
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(alpha: 0.3),
                          width: 2.0,
                        ),
                      ),
                      child: Icon(
                        Icons.download_for_offline_rounded,
                        size: 56,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Setup On-Device AI',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Download a small 1.2 GB quantized Gemma LLM to answer gym, meal, and routine questions fully offline with zero token costs.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Status and specs card
                  GlassContainer(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _statusText,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        
                        if (_isChecking)
                          const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2.5),
                            ),
                          ),

                        if (_hasChecked && !_isDownloading) ...[
                          const Divider(),
                          const SizedBox(height: 8),
                          _buildSpecRow(
                            label: 'Available Disk Storage',
                            value: '${_availableStorage.toStringAsFixed(1)} GB',
                            isPass: _isStorageSufficient,
                          ),
                          const SizedBox(height: 10),
                          _buildSpecRow(
                            label: 'System Memory (RAM)',
                            value: '${_deviceRam.toStringAsFixed(0)} GB',
                            isPass: _isRamSufficient,
                          ),
                        ],

                        if (_isDownloading) ...[
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: _progress,
                              minHeight: 8,
                              backgroundColor: Colors.white10,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Actions block
                  if (_hasChecked && !_isDownloading)
                    (_isStorageSufficient && _isRamSufficient)
                        ? SlideToConfirmButton(
                            label: 'Slide to Download & Install',
                            onConfirm: _startDownload,
                          )
                        : const Text(
                            'Your system does not meet the minimum requirements (1.2 GB storage, 4 GB RAM) for local models. Gemini Cloud Fallback is recommended.',
                            style: TextStyle(color: Colors.redAccent, fontSize: 13, height: 1.4),
                            textAlign: TextAlign.center,
                          ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      );
    }

  Widget _buildSpecRow({required String label, required String value, required bool isPass}) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        Row(
          children: [
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(width: 6),
            Icon(
              isPass ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: isPass ? Colors.green : Colors.red,
              size: 16,
            ),
          ],
        ),
      ],
    );
  }
}
