import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '../models/nutrition_data.dart';
import '../services/api_key_service.dart';
import '../services/gemini_food_service.dart';
import '../services/nutrition_db_service.dart';
import '../services/nutrition_lookup_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/food_scan_overlay.dart';
import '../widgets/image_source_sheet.dart';
import 'barcode_scanner_screen.dart';
import 'food_search_screen.dart';
import 'health_insights_screen.dart';
import 'result_screen.dart';

/// Fast-utility Scan & AI tab.
/// Goal: get user to a logged meal in the fewest taps.
class ScanAiScreen extends StatefulWidget {
  const ScanAiScreen({super.key});

  @override
  State<ScanAiScreen> createState() => _ScanAiScreenState();
}

class _ScanAiScreenState extends State<ScanAiScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _analyzing = false;
  Uint8List? _analyzingImageBytes;

  @override
  void initState() {
    super.initState();
    NutritionDbService.instance.load();
    ApiKeyService.instance.load().then((_) {
      if (mounted) setState(() {});
    });
  }

  // ── Image pick / analyze ──────────────────────────────────────────────────

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ImageSourceSheet(
        onCamera: () => _pickImage(ImageSource.camera),
        onGallery: () => _pickImage(ImageSource.gallery),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null && mounted) {
        final bytes = await image.readAsBytes();
        if (GeminiFoodService.instance.isAvailable) {
          await _analyzeWithGemini(bytes);
        } else {
          _promptApiKeyOrFallback(bytes);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e'),
              backgroundColor: AppTheme.error),
        );
      }
    }
  }

  Future<void> _analyzeWithGemini(Uint8List imageBytes) async {
    setState(() { _analyzing = true; _analyzingImageBytes = imageBytes; });
    try {
      final result = await GeminiFoodService.instance.analyzeFood(imageBytes);
      if (!mounted) return;
      setState(() => _analyzing = false);

      if (result == null || GeminiFoodService.isNotFood(result)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('AI could not identify the food. Search manually below.'),
            backgroundColor: AppTheme.calorieOrange,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        _navigateToFoodSearch(imageBytes);
        return;
      }

      final nutrition = await _enrichVisionNutrition(result);
      if (!mounted) return;

      Navigator.push(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (context, animation, _) => ResultScreen(
            imageBytes: imageBytes,
            nutritionData: nutrition,
          ),
          transitionsBuilder: (context, animation, _, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              ),
            );
          },
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() { _analyzing = false; _analyzingImageBytes = null; });
        final isInvalidKey = e.toString().contains('API key invalid') || e.toString().contains('403');
        if (isInvalidKey) {
          await ApiKeyService.instance.clearApiKey();
          if (!mounted) return;
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Gemini API error. Please check your API key.'),
              backgroundColor: AppTheme.error,
              duration: const Duration(seconds: 5),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gemini AI error: $e'),
              backgroundColor: AppTheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
          _navigateToFoodSearch(imageBytes);
        }
      }
    }
  }

  Future<NutritionData> _enrichVisionNutrition(NutritionData vision) async {
    try {
      await NutritionDbService.instance.load();
      final database = await NutritionLookupService.instance.lookup(vision.foodName);
      final detectedGrams = _gramsInServing(vision.servingSize);
      final databaseGrams = database == null ? null : _gramsInServing(database.servingSize);
      if (database != null && detectedGrams != null && databaseGrams != null) {
        final factor = detectedGrams / databaseGrams;
        return vision.withNutritionFrom(database.scale(factor));
      }
    } catch (_) {}
    return vision;
  }

  double? _gramsInServing(String serving) {
    final match = RegExp(r'(\d+(?:\.\d+)?)\s*g\b', caseSensitive: false)
        .firstMatch(serving);
    return match == null ? null : double.tryParse(match.group(1)!);
  }

  void _promptApiKeyOrFallback(Uint8List imageBytes) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: AppTheme.cardRadius),
        title: Row(children: [
          Icon(Icons.auto_awesome_rounded, color: AppColors.primaryAction, size: 24),
          const SizedBox(width: 12),
          const Text('Gemini AI Key Required'),
        ]),
        content: Text(
          'To use instant AI food recognition, enter your free Gemini API key '
          '(get it at aistudio.google.com). Or continue with manual food search.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(ctx); _navigateToFoodSearch(imageBytes); },
            child: const Text('Search Food'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _showApiKeyDialog();
              if (GeminiFoodService.instance.isAvailable) {
                await _analyzeWithGemini(imageBytes);
              }
            },
            child: const Text('Enter API Key'),
          ),
        ],
      ),
    );
  }

  Future<void> _showApiKeyDialog() async {
    final ctrl = TextEditingController(text: ApiKeyService.instance.apiKey ?? '');
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: AppTheme.cardRadius),
        title: const Text('Enter Gemini API Key'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'AIza...'),
          obscureText: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isNotEmpty) {
                await ApiKeyService.instance.saveApiKey(ctrl.text.trim());
                if (mounted) setState(() {});
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _navigateToFoodSearch(Uint8List imageBytes) {
    Navigator.push(context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (context, animation, _) => FoodSearchScreen(imageBytes: imageBytes),
          transitionsBuilder: (context, animation, _, child) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.1), end: Offset.zero,
              ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
              child: child,
            ),
          ),
        ));
  }

  void _navigateToSearch() => Navigator.push(context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, animation, _) => const FoodSearchScreen(),
        transitionsBuilder: (context, animation, _, child) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
                .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          ),
        ),
      ));

  Future<void> _navigateToBarcodeScan() async {
    final result = await Navigator.push<NutritionData>(context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (context, animation, _) => const BarcodeScannerScreen(),
          transitionsBuilder: (context, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
        ));
    if (!mounted || result == null) return;
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => ResultScreen(nutritionData: result)));
  }

  void _navigateToInsights() => Navigator.push(context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, animation, _) => const HealthInsightsScreen(),
        transitionsBuilder: (context, animation, _, child) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
                .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          ),
        ),
      ));

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final aiConnected = GeminiFoodService.instance.isAvailable;

    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // ── Header ──────────────────────────────────────────────
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
                      // AI status chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: aiConnected
                              ? AppColors.bodyMetric.withValues(alpha: 0.12)
                              : AppColors.bgCard,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: aiConnected
                                ? AppColors.bodyMetric.withValues(alpha: 0.35)
                                : AppColors.bgCardBorder,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              aiConnected
                                  ? Icons.auto_awesome_rounded
                                  : Icons.auto_awesome_outlined,
                              size: 13,
                              color: aiConnected ? AppColors.bodyMetric : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              aiConnected ? 'AI Connected' : 'AI Ready',
                              style: TextStyle(
                                color: aiConnected ? AppColors.bodyMetric : AppColors.textSecondary,
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

                  // ── Primary: SCAN MEAL ────────────────────────────────
                  _ScanMealButton(
                    analyzing: _analyzing,
                    onTap: _analyzing ? null : _showImageSourceSheet,
                  ).animate().fadeIn(delay: 100.ms, duration: 500.ms)
                      .slideY(begin: 0.1),

                  const SizedBox(height: 16),

                  // ── Secondary: Search + Barcode (2-up row) ───────────
                  Row(
                    children: [
                      Expanded(
                        child: _OutlineActionButton(
                          icon: Icons.search_rounded,
                          label: 'Search Food',
                          color: AppColors.primaryAction,
                          onTap: _navigateToSearch,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _OutlineActionButton(
                          icon: Icons.qr_code_scanner_rounded,
                          label: 'Barcode',
                          color: AppColors.secondaryAction,
                          onTap: _navigateToBarcodeScan,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 200.ms, duration: 500.ms)
                      .slideY(begin: 0.1),

                  const SizedBox(height: 12),

                  // ── Tertiary: Health Insights (full width, teal) ──────
                  _OutlineActionButton(
                    icon: Icons.insights_rounded,
                    label: 'Health Insights',
                    color: AppColors.bodyMetric,
                    onTap: _navigateToInsights,
                    fullWidth: true,
                  ).animate().fadeIn(delay: 280.ms, duration: 500.ms)
                      .slideY(begin: 0.1),

                  const SizedBox(height: 28),

                  // ── Trust badge strip ─────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _TrustBadge(icon: Icons.bolt_rounded, label: 'Instant'),
                      const SizedBox(width: 16),
                      _TrustBadge(icon: Icons.auto_awesome_rounded, label: 'Smart AI'),
                      const SizedBox(width: 16),
                      _TrustBadge(icon: Icons.verified_rounded, label: 'USDA Data'),
                    ],
                  ).animate().fadeIn(delay: 360.ms, duration: 500.ms),
                ],
              ),
            ),
          ),
        ),

        // Full-screen scan overlay while Gemini processes
        if (_analyzing)
          Positioned.fill(
            child: FoodScanOverlay(imageBytes: _analyzingImageBytes),
          ),
      ],
    );
  }
}

// ─── SCAN MEAL button ────────────────────────────────────────────────────────
class _ScanMealButton extends StatelessWidget {
  final bool analyzing;
  final VoidCallback? onTap;

  const _ScanMealButton({required this.analyzing, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: analyzing
              ? null
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primaryAction, Color(0xFF6B5CE7)],
                ),
          color: analyzing ? AppColors.bgCard : null,
          border: Border.all(
            color: analyzing
                ? AppColors.primaryAction.withValues(alpha: 0.3)
                : Colors.transparent,
          ),
          boxShadow: analyzing
              ? null
              : [
                  BoxShadow(
                    color: AppColors.primaryAction.withValues(alpha: 0.40),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                    spreadRadius: 2,
                  ),
                ],
        ),
        child: analyzing
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.primaryAction,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'ANALYZING…',
                    style: TextStyle(
                      color: AppColors.primaryAction,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.camera_alt_rounded, size: 34, color: Colors.white),
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
                  const SizedBox(height: 2),
                  Text(
                    'AI-powered instant nutrition analysis',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ─── Outline action button ────────────────────────────────────────────────────
class _OutlineActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool fullWidth;

  const _OutlineActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Trust badge strip ────────────────────────────────────────────────────────
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
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
