import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  static const String appName = 'Gerex';

  // Paddings & Margins
  static const double p4 = 4.0;
  static const double p8 = 8.0;
  static const double p12 = 12.0;
  static const double p16 = 16.0;
  static const double p20 = 20.0;
  static const double p24 = 24.0;
  static const double p32 = 32.0;

  // BorderRadius
  static const double r8 = 8.0;
  static const double r12 = 12.0;
  static const double r16 = 16.0;

  // Common Spacing Widgets
  static const SizedBox h4 = SizedBox(height: p4);
  static const SizedBox h8 = SizedBox(height: p8);
  static const SizedBox h12 = SizedBox(height: p12);
  static const SizedBox h16 = SizedBox(height: p16);
  static const SizedBox h24 = SizedBox(height: p24);
  static const SizedBox h32 = SizedBox(height: p32);

  static const SizedBox w4 = SizedBox(width: p4);
  static const SizedBox w8 = SizedBox(width: p8);
  static const SizedBox w12 = SizedBox(width: p12);
  static const SizedBox w16 = SizedBox(width: p16);
  static const SizedBox w24 = SizedBox(width: p24);
  static const SizedBox w32 = SizedBox(width: p32);

  // Storage Keys (if any)
  static const String cachePrefix = 'gerex_cache_';
}
