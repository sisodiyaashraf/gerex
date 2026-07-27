import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  // Phase 15R Exact Color Tokens
  static const Color bgDarkPrimary = Color(0xFF12132A);
  static const Color bgDarkSecondary = Color(0xFF151729);
  static const Color cardDarkGlass = Color(0xFF30377B);
  static const Color cardDarkGlassAlt = Color(0xFF31367B);
  static const Color accentEmeraldDeep = Color(0xFF178C6D);
  static const Color accentEmeraldLight = Color(0xFF50C19D);

  static const Color badgeTealText = Color(0xFF0D807B);
  static const Color badgeGoldAccent = Color(0xFFFFDA61);
  static const Color badgeDarkNavy = Color(0xFF042537);

  // Typography & Content Colors
  static const Color textDarkHeading = Color(0xFFFFFFFF);
  static const Color textDarkBody = Color(0xFFF1F5F9);
  static const Color textDarkMuted = Color(0x99F1F5F9);

  static const Color textLightHeading = Color(0xFF0B1220);
  static const Color textLightBody = Color(0xFF1E293B);

  // Destructive / Error
  static const Color destructiveRed = Color(0xFFE5484D);

  // Translucent Chip Backgrounds
  static const Color chipTealBg = Color(0x260D807B);
  static const Color chipGreenBg = Color(0x2650C19D);
  static const Color chipAmberBg = Color(0x26F59E0B);
  static const Color chipRedBg = Color(0x26E5484D);
}

class GerexGradients {
  GerexGradients._();

  static const LinearGradient scaffoldBackground = LinearGradient(
    colors: [AppColors.bgDarkPrimary, AppColors.bgDarkSecondary],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient heroMintLight = LinearGradient(
    colors: [
      Color(0xFF89C8CA),
      Color(0xFFB5E9EA),
      Color(0xFFCBFBFA),
      Color(0xFFFFFFFF),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient primaryCTA = LinearGradient(
    colors: [AppColors.accentEmeraldDeep, AppColors.accentEmeraldLight],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static final LinearGradient darkGlassCard = LinearGradient(
    colors: [
      AppColors.cardDarkGlass.withValues(alpha: 0.88),
      AppColors.cardDarkGlassAlt.withValues(alpha: 0.82),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static final LinearGradient darkGlassCardAlt = LinearGradient(
    colors: [
      AppColors.cardDarkGlassAlt.withValues(alpha: 0.88),
      AppColors.cardDarkGlass.withValues(alpha: 0.82),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentBorder = LinearGradient(
    colors: [AppColors.accentEmeraldLight, AppColors.accentEmeraldDeep],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryCard = LinearGradient(
    colors: [AppColors.cardDarkGlass, AppColors.cardDarkGlassAlt],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient destructive = LinearGradient(
    colors: [Color(0xFFE5484D), Color(0xFFC7363B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  AppTheme._();

  // Legacy accessor mappings bound directly to Phase 15R tokens
  static const Color darkBackground = AppColors.bgDarkPrimary;
  static const Color darkSurface = AppColors.bgDarkSecondary;
  static const Color darkPrimary = AppColors.accentEmeraldDeep;
  static const Color darkAccent = AppColors.accentEmeraldLight;
  static const Color darkOnBackground = AppColors.textDarkHeading;
  static const Color darkOnSurface = AppColors.textDarkBody;
  static const Color darkMuted = AppColors.textDarkMuted;

  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightPrimary = AppColors.accentEmeraldDeep;
  static const Color lightAccent = AppColors.accentEmeraldLight;
  static const Color lightOnBackground = AppColors.textLightHeading;
  static const Color lightOnSurface = AppColors.textLightBody;
  static const Color lightMuted = Color(0xFF64748B);

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
        surface: AppColors.bgDarkSecondary,
        primary: AppColors.accentEmeraldDeep,
        secondary: AppColors.accentEmeraldLight,
        onSurface: AppColors.textDarkBody,
      ),
      scaffoldBackgroundColor: AppColors.bgDarkPrimary,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textDarkHeading,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.textDarkHeading,
        ),
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        headlineLarge: GoogleFonts.outfit(
          color: AppColors.textDarkHeading,
          fontSize: 32,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
        ),
        titleLarge: GoogleFonts.outfit(
          color: AppColors.textDarkHeading,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: GoogleFonts.inter(color: AppColors.textDarkBody, fontSize: 16),
        bodyMedium: GoogleFonts.inter(color: AppColors.textDarkBody, fontSize: 14),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardDarkGlass.withValues(alpha: 0.88),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.cardDarkGlass.withValues(alpha: 0.5)),
        ),
      ),
    );
  }
}

