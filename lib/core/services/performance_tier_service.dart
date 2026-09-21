import 'dart:io';
import 'package:flutter/foundation.dart';

enum PerformanceTier {
  high,
  medium,
  low,
}

class PerformanceTierConfig {
  final PerformanceTier tier;
  final int inferenceThrottleMs;
  final bool enableGlowBlur;
  final int maxParticleCount;
  final bool enableScanLine;
  final bool enablePulsingJoints;

  const PerformanceTierConfig({
    required this.tier,
    required this.inferenceThrottleMs,
    required this.enableGlowBlur,
    required this.maxParticleCount,
    required this.enableScanLine,
    required this.enablePulsingJoints,
  });

  factory PerformanceTierConfig.forTier(PerformanceTier tier) {
    switch (tier) {
      case PerformanceTier.high:
        return const PerformanceTierConfig(
          tier: PerformanceTier.high,
          inferenceThrottleMs: 30, // ~33 FPS
          enableGlowBlur: true,
          maxParticleCount: 16,
          enableScanLine: true,
          enablePulsingJoints: true,
        );
      case PerformanceTier.medium:
        return const PerformanceTierConfig(
          tier: PerformanceTier.medium,
          inferenceThrottleMs: 50, // ~20 FPS
          enableGlowBlur: false, // uses double stroke instead of expensive GPU MaskFilter.blur
          maxParticleCount: 8,
          enableScanLine: true,
          enablePulsingJoints: true,
        );
      case PerformanceTier.low:
        return const PerformanceTierConfig(
          tier: PerformanceTier.low,
          inferenceThrottleMs: 75, // ~13 FPS
          enableGlowBlur: false,
          maxParticleCount: 0, // particles disabled on low tier
          enableScanLine: false,
          enablePulsingJoints: false,
        );
    }
  }
}

class PerformanceTierService {
  static PerformanceTierConfig? _cachedConfig;

  /// Detect device hardware performance tier at startup
  static PerformanceTierConfig detectPerformanceTier() {
    if (_cachedConfig != null) return _cachedConfig!;

    PerformanceTier tier = PerformanceTier.medium;

    if (kIsWeb) {
      tier = PerformanceTier.medium;
    } else if (Platform.isAndroid || Platform.isIOS) {
      final processors = Platform.numberOfProcessors;
      if (processors >= 8) {
        tier = PerformanceTier.high;
      } else if (processors >= 4) {
        tier = PerformanceTier.medium;
      } else {
        tier = PerformanceTier.low;
      }
    }

    _cachedConfig = PerformanceTierConfig.forTier(tier);
    if (kDebugMode) {
      print('[PerformanceTierService] Detected tier: ${tier.name} (Processors: ${kIsWeb ? "Web" : Platform.numberOfProcessors}, Throttle: ${_cachedConfig!.inferenceThrottleMs}ms)');
    }
    return _cachedConfig!;
  }

  /// Override tier manually for testing/simulation
  static void setOverrideTier(PerformanceTier tier) {
    _cachedConfig = PerformanceTierConfig.forTier(tier);
    if (kDebugMode) {
      print('[PerformanceTierService] Manually set tier to: ${tier.name}');
    }
  }

  static void reset() {
    _cachedConfig = null;
  }
}
