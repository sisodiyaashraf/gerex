import 'dart:math' as math;
import 'package:flutter/material.dart';

enum DeviceType {
  smallPhone,
  standardPhone,
  largePhone,
  tablet,
}

class ResponsiveHelper {
  final BuildContext context;
  late final double width;
  late final double height;
  late final double textScaleFactor;
  late final DeviceType deviceType;
  late final double paddingBottom;
  late final double paddingTop;

  ResponsiveHelper(this.context) {
    final mediaQuery = MediaQuery.of(context);
    width = mediaQuery.size.width;
    height = mediaQuery.size.height;
    // Using mediaQuery.textScaler in newer Flutter versions or fallback to textScaleFactor
    // We can handle both cleanly by trying to read textScaler or textScaleFactor
    textScaleFactor = mediaQuery.textScaler.scale(1.0);
    paddingBottom = mediaQuery.padding.bottom;
    paddingTop = mediaQuery.padding.top;

    if (width < 360) {
      deviceType = DeviceType.smallPhone;
    } else if (width < 420) {
      deviceType = DeviceType.standardPhone;
    } else if (width < 600) {
      deviceType = DeviceType.largePhone;
    } else {
      deviceType = DeviceType.tablet;
    }
  }

  // Width percentage scaling
  double w(double percent) => width * (percent / 100);

  // Height percentage scaling
  double h(double percent) => height * (percent / 100);

  // Scaled text size respecting system text scaling up to a safe clamped limit
  double sp(double size) {
    double scale = 1.0;
    switch (deviceType) {
      case DeviceType.smallPhone:
        scale = 0.85;
        break;
      case DeviceType.standardPhone:
        scale = 1.0;
        break;
      case DeviceType.largePhone:
        scale = 1.1;
        break;
      case DeviceType.tablet:
        scale = 1.25;
        break;
    }
    final systemScale = math.min(textScaleFactor, 1.4);
    return size * scale * systemScale;
  }

  // Dynamic selector helper
  T select<T>({
    required T smallPhone,
    T? standardPhone,
    T? largePhone,
    T? tablet,
  }) {
    switch (deviceType) {
      case DeviceType.smallPhone:
        return smallPhone;
      case DeviceType.standardPhone:
        return standardPhone ?? smallPhone;
      case DeviceType.largePhone:
        return largePhone ?? standardPhone ?? smallPhone;
      case DeviceType.tablet:
        return tablet ?? largePhone ?? standardPhone ?? smallPhone;
    }
  }
}

extension ResponsiveContext on BuildContext {
  ResponsiveHelper get responsive => ResponsiveHelper(this);
  
  double w(double percent) => responsive.w(percent);
  double h(double percent) => responsive.h(percent);
  double sp(double size) => responsive.sp(size);
  
  bool get isSmallPhone => responsive.deviceType == DeviceType.smallPhone;
  bool get isStandardPhone => responsive.deviceType == DeviceType.standardPhone;
  bool get isLargePhone => responsive.deviceType == DeviceType.largePhone;
  bool get isTablet => responsive.deviceType == DeviceType.tablet;
  
  double get paddingBottom => responsive.paddingBottom;
  double get paddingTop => responsive.paddingTop;
}
