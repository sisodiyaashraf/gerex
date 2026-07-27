import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GerexGradients {
  GerexGradients._();

  static const LinearGradient darkBaseBackground = LinearGradient(
    colors: [Color(0xFF131416), Color(0xFF0B0B0C)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient lightBaseBackground = LinearGradient(
    colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient primaryCTA = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF14B8A6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static final LinearGradient darkGlassCard = LinearGradient(
    colors: [
      Colors.white.withValues(alpha: 0.07),
      Colors.white.withValues(alpha: 0.01),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static final LinearGradient lightGlassCard = LinearGradient(
    colors: [
      Colors.black.withValues(alpha: 0.03),
      Colors.black.withValues(alpha: 0.005),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentBorder = LinearGradient(
    colors: [Color(0xFF34D399), Color(0xFF2DD4BF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryCard = LinearGradient(
    colors: [Color(0xFF3B2E5C), Color(0xFF261D3E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient destructive = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFF43F5E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  AppTheme._();

  // Dark Palette (Dark Charcoal & Emerald Green/Teal)
  static const Color darkBackground = Color(0xFF0B0B0C);
  static const Color darkSurface = Color(0xFF131416);
  static const Color darkPrimary = Color(0xFF10B981);
  static const Color darkAccent = Color(0xFF14B8A6);
  static const Color darkOnBackground = Color(0xFFF8FAFC);
  static const Color darkOnSurface = Color(0xFFE2E8F0);
  static const Color darkMuted = Color(0xFF64748B);

  // Light Palette (Soft Slate & Teal)
  static const Color lightBackground = Color(0xFFF8FAFC); // Slate 50
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightPrimary = Color(0xFF0891B2); // Cyan 600
  static const Color lightAccent = Color(0xFFEA580C); // Orange 600
  static const Color lightOnBackground = Color(0xFF0F172A); // Slate 900
  static const Color lightOnSurface = Color(0xFF334155); // Slate 700
  static const Color lightMuted = Color(0xFF94A3B8); // Slate 400

  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: const ColorScheme.light(
        surface: lightBackground,
        primary: lightPrimary,
        secondary: lightAccent,
        onSurface: lightOnSurface,
      ),
      scaffoldBackgroundColor: lightBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: lightOnBackground,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: lightOnBackground,
        ),
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        headlineLarge: GoogleFonts.outfit(
          color: lightOnBackground,
          fontSize: 32,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
        ),
        titleLarge: GoogleFonts.outfit(
          color: lightOnBackground,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: GoogleFonts.inter(color: lightOnSurface, fontSize: 16),
        bodyMedium: GoogleFonts.inter(color: lightOnSurface, fontSize: 14),
      ),
      cardTheme: CardThemeData(
        color: lightSurface.withValues(alpha: 0.7),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      colorScheme: const ColorScheme.dark(
        surface: darkBackground,
        primary: darkPrimary,
        secondary: darkAccent,
        onSurface: darkOnSurface,
      ),
      scaffoldBackgroundColor: darkBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: darkOnBackground,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: darkOnBackground,
        ),
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        headlineLarge: GoogleFonts.outfit(
          color: darkOnBackground,
          fontSize: 32,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
        ),
        titleLarge: GoogleFonts.outfit(
          color: darkOnBackground,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: GoogleFonts.inter(color: darkOnSurface, fontSize: 16),
        bodyMedium: GoogleFonts.inter(color: darkOnSurface, fontSize: 14),
      ),
      cardTheme: CardThemeData(
        color: darkSurface.withValues(alpha: 0.7),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
    );
  }
}
