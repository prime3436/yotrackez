import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {

  static const Color primary        = Color(0xFF7B6FFF);
  static const Color primaryDark    = Color(0xFF5548D9);
  static const Color accent         = Color(0xFF2AFFDD);
  static const Color lava           = Color(0xFFFF4D1C);
  static const Color chrome         = Color(0xFFC8D6E5);
  static const Color frost          = Color(0xFFE0F7FF);

  static const Color surface        = Color(0xFF0D0E1A);
  static const Color surfaceLight   = Color(0xFF13152A);
  static const Color card           = Color(0xFF10111F);
  static const Color background     = Color(0xFF07080F);

  static const Color textPrimary    = Color(0xFFF0F4FF);
  static const Color textSecondary  = Color(0xFF7A82A8);

  static const Color error          = Color(0xFFFF4D1C);

  static const Color calorieOrange  = Color(0xFFFF4D1C);
  static const Color carbsBlue      = Color(0xFF7B6FFF);
  static const Color proteinRed     = Color(0xFFFF2D7A);
  static const Color fatYellow      = Color(0xFFFFBD39);
  static const Color fiberGreen     = Color(0xFF2AFFDD);

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      background,
      Color(0xFF0A0B18),
      background,
    ],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, accent],
  );

  static const LinearGradient lavaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [lava, Color(0xFFFF2D7A)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF161828), Color(0xFF0D0E1A)],
  );

  static const LinearGradient chromeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [chrome, frost],
  );

  static final BorderRadius cardRadius   = BorderRadius.circular(24);
  static final BorderRadius buttonRadius = BorderRadius.circular(100);
  static final BorderRadius chipRadius   = BorderRadius.circular(100);

  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.55),
      blurRadius: 28,
      offset: const Offset(0, 14),
    ),
    BoxShadow(
      color: primary.withValues(alpha: 0.04),
      blurRadius: 60,
      spreadRadius: 2,
    ),
  ];

  static List<BoxShadow> glowShadow(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.35),
      blurRadius: 28,
      spreadRadius: 4,
    ),
    BoxShadow(
      color: color.withValues(alpha: 0.12),
      blurRadius: 56,
      spreadRadius: 14,
    ),
  ];

  static BoxDecoration glassCard({Color? color}) => BoxDecoration(
    color: (color ?? card).withValues(alpha: 0.45),
    borderRadius: cardRadius,
    border: Border.all(
      color: primary.withValues(alpha: 0.08),
      width: 1,
    ),
    boxShadow: cardShadow,
  );

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: accent,
        tertiary: lava,
        surface: surface,
        error: error,
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        ThemeData.dark().textTheme,
      ).copyWith(
        headlineLarge: GoogleFonts.outfit(
          fontSize: 36,
          fontWeight: FontWeight.w800,
          color: textPrimary,
          letterSpacing: -1,
        ),
        headlineMedium: GoogleFonts.outfit(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        headlineSmall: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
        bodySmall: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
        labelLarge: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 0.5,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: 0.5,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: background,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: buttonRadius),
          elevation: 0,
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primary.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primary.withValues(alpha: 0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.6)),
      ),
    );
  }
}
