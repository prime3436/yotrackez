import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─── Colors ───────────────────────────────────────────
  static const Color primary = Color(0xFF00FFA3); // Neon Mint
  static const Color primaryDark = Color(0xFF00D185);
  static const Color accent = Color(0xFF00F0FF); // Electric Teal
  static const Color surface = Color(0xFF18181B); // Zinc 900
  static const Color surfaceLight = Color(0xFF27272A); // Zinc 800
  static const Color card = Color(0xFF121214); // Darker card
  static const Color background = Color(0xFF09090B); // OLED Black
  static const Color textPrimary = Color(0xFFFAFAFA);
  static const Color textSecondary = Color(0xFFA1A1AA); // Zinc 400
  static const Color error = Color(0xFFFF3366); // Neon Pink/Red

  // Macronutrient Colors (Neon variants)
  static const Color calorieOrange = Color(0xFFFF5D00);
  static const Color carbsBlue = Color(0xFF00E5FF);
  static const Color proteinRed = Color(0xFFFF3366);
  static const Color fatYellow = Color(0xFFFFD600);
  static const Color fiberGreen = Color(0xFF00FFA3);

  // ─── Gradients ────────────────────────────────────────
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [background, Color(0xFF101014), Color(0xFF09090B)],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, accent],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E1E24), Color(0xFF18181B)],
  );

  // ─── Border Radius ───────────────────────────────────
  static final BorderRadius cardRadius = BorderRadius.circular(24);
  static final BorderRadius buttonRadius = BorderRadius.circular(100); // Fully rounded pills
  static final BorderRadius chipRadius = BorderRadius.circular(100);

  // ─── Box Shadows ──────────────────────────────────────
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.5),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
  ];

  static List<BoxShadow> glowShadow(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.3),
      blurRadius: 24,
      spreadRadius: 4,
    ),
    BoxShadow(
      color: color.withValues(alpha: 0.1),
      blurRadius: 48,
      spreadRadius: 12,
    ),
  ];

  // ─── Glassmorphism Decoration ─────────────────────────
  static BoxDecoration glassCard({Color? color}) => BoxDecoration(
    color: (color ?? card).withValues(alpha: 0.4),
    borderRadius: cardRadius,
    border: Border.all(
      color: Colors.white.withValues(alpha: 0.05),
      width: 1,
    ),
    boxShadow: cardShadow,
  );

  // ─── Theme Data ───────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: accent,
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
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: background, // Black text on neon button
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: buttonRadius),
          elevation: 0, // Removing default elevation for custom drop shadows when needed
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
