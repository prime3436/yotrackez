import 'package:flutter/material.dart';

/// Semantic design tokens for YOTRACKEZ.
/// Pick ONE of the three action colors — never add new one-off hex values.
class AppColors {
  AppColors._();

  // ── Action colors ─────────────────────────────────────────────────────────

  /// AI / primary scan actions — filled buttons, active rings
  static const Color primaryAction = Color(0xFF8B7FFF); // periwinkle-purple

  /// Manual / gamification actions — barcode, streaks, gold highlights
  static const Color secondaryAction = Color(0xFFE8B75B); // chrome gold

  /// Body / health metrics — avatar ring, hydration, insights
  static const Color bodyMetric = Color(0xFF4FD1C5); // ghost teal

  // ── Background layers ─────────────────────────────────────────────────────
  static const Color bgDeep       = Color(0xFF0A0E1A);
  static const Color bgCard       = Color(0xFF141A2E);
  static const Color bgCardBorder = Color(0x33FFFFFF); // 20 % white

  // ── Text ─────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFF5F5FA);
  static const Color textSecondary = Color(0xFF9098B0);

  // ── Macro palette (unchanged from AppTheme for compat) ───────────────────
  static const Color protein = Color(0xFFFF2D7A); // plasma pink
  static const Color carbs   = Color(0xFF8B7FFF); // primaryAction
  static const Color fat     = Color(0xFFFFBD39); // chrome gold
  static const Color fiber   = Color(0xFF4FD1C5); // bodyMetric
  static const Color calorie = Color(0xFFFF6B35); // warm orange
}
