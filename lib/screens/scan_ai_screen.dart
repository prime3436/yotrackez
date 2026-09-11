import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/nutrition_data.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'food_search_screen.dart';
import 'health_insights_screen.dart';
import 'result_screen.dart';
import 'unified_scan_screen.dart';

/// Fast-utility Scan & AI tab.
/// Three entry points: Scan (unified camera), Search Food, Health Insights.
/// All Gemini + barcode logic lives in UnifiedScanScreen.
class ScanAiScreen extends StatelessWidget {
  const ScanAiScreen({super.key});

  Future<void> _openUnifiedScan(BuildContext context) async {
    // UnifiedScanScreen pops with NutritionData when barcode is confirmed.
    // For the food-photo path it pushes ResultScreen directly and then pops
    // scan screen itself, so we only need to handle the barcode return here.
    final result = await Navigator.push<NutritionData>(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (ctx, anim, sa) => const UnifiedScanScreen(),
        transitionsBuilder: (ctx, anim, sa, child) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: child,
        ),
      ),
    );

    if (!context.mounted || result == null) return;

    // Barcode path returned NutritionData — push ResultScreen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ResultScreen(nutritionData: result)),
    );
  }

  void _openSearch(BuildContext context) =>
      Navigator.push(context, PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (ctx, anim, sa) => const FoodSearchScreen(),
        transitionsBuilder: (ctx, anim, sa, child) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
                .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
            child: child,
          ),
        ),
      ));

  void _openInsights(BuildContext context) =>
      Navigator.push(context, PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (ctx, anim, sa) => const HealthInsightsScreen(),
        transitionsBuilder: (ctx, anim, sa, child) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
                .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
            child: child,
          ),
        ),
      ));

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // ── Header ──────────────────────────────────────────────────
              Row(
                children: [
                  const Text(
                    'Scan & AI',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  // Capability badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.bodyMetric.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.bodyMetric.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.camera_alt_rounded,
                            size: 12, color: AppColors.bodyMetric),
                        const SizedBox(width: 4),
                        const Text(
                          'AI + Barcode',
                          style: TextStyle(
                            color: AppColors.bodyMetric,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms),

              const SizedBox(height: 32),

              // ── PRIMARY: Scan Meal (opens UnifiedScanScreen) ────────────
              _ScanMealButton(
                onTap: () => _openUnifiedScan(context),
              ).animate().fadeIn(delay: 100.ms, duration: 500.ms).slideY(begin: 0.1),

              const SizedBox(height: 16),

              // ── SECONDARY: Search Food (full-width) ─────────────────────
              _OutlineActionButton(
                icon: Icons.search_rounded,
                label: 'Search Food',
                subtitle: 'Browse USDA + Open Food database',
                color: AppColors.primaryAction,
                onTap: () => _openSearch(context),
              ).animate().fadeIn(delay: 200.ms, duration: 500.ms).slideY(begin: 0.1),

              const SizedBox(height: 12),

              // ── TERTIARY: Health Insights (full-width, teal) ────────────
              _OutlineActionButton(
                icon: Icons.insights_rounded,
                label: 'Health Insights',
                subtitle: 'Trends, targets & AI recommendations',
                color: AppColors.bodyMetric,
                onTap: () => _openInsights(context),
              ).animate().fadeIn(delay: 280.ms, duration: 500.ms).slideY(begin: 0.1),

              const SizedBox(height: 28),

              // ── Trust badge strip ────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _TrustBadge(icon: Icons.bolt_rounded, label: 'Instant'),
                  const SizedBox(width: 16),
                  _TrustBadge(icon: Icons.qr_code_rounded, label: 'Auto Barcode'),
                  const SizedBox(width: 16),
                  _TrustBadge(icon: Icons.verified_rounded, label: 'USDA Data'),
                ],
              ).animate().fadeIn(delay: 360.ms, duration: 500.ms),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── SCAN MEAL hero button ─────────────────────────────────────────────────────
class _ScanMealButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _ScanMealButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 130,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primaryAction, Color(0xFF6B5CE7)],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryAction.withValues(alpha: 0.42),
              blurRadius: 32,
              offset: const Offset(0, 10),
              spreadRadius: 2,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Subtle corner decoration
            Positioned(
              right: -20, top: -20,
              child: Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              right: 20, bottom: -30,
              child: Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ),
            // Content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.camera_alt_rounded, size: 36, color: Colors.white),
                  const SizedBox(height: 6),
                  const Text(
                    'SCAN MEAL',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Food photo  ·  Barcode auto-detected',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Outline action buttons ───────────────────────────────────────────────────
class _OutlineActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  const _OutlineActionButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.32)),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(
                  color: color, fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w400)),
              ],
            ),
            const Spacer(),
            Icon(Icons.chevron_right_rounded, color: color.withValues(alpha: 0.6), size: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Trust badge ───────────────────────────────────────────────────────────────
class _TrustBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _TrustBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(
          color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
