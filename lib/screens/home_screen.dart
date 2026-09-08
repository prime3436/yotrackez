import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '../models/nutrition_data.dart';
import '../services/api_key_service.dart';
import '../services/calorie_body_service.dart';
import '../services/gemini_food_service.dart';
import '../services/nutrition_db_service.dart';
import '../services/nutrition_lookup_service.dart';
import '../theme/app_theme.dart';
import '../widgets/image_source_sheet.dart';
import '../widgets/cyber_blade_wings_logo.dart';
import '../widgets/food_scan_overlay.dart';
import '../services/streak_service.dart';
import '../services/water_service.dart';
import '../widgets/water_tracker_widget.dart';
import 'food_search_screen.dart';
import 'health_insights_screen.dart';
import 'profile_screen.dart';
import 'result_screen.dart';
import 'barcode_scanner_screen.dart';




class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _analyzing = false;
  Uint8List? _analyzingImageBytes;

  @override
  void initState() {
    super.initState();
    // Pre-load services
    NutritionDbService.instance.load();
    ApiKeyService.instance.load().then((_) {
      if (mounted) setState(() {});
    });
    // Run calorie engine once per day — drives the Rive avatar bodyComposition
    CalorieBodyService.instance.loadCached().then((_) {
      CalorieBodyService.instance.runIfNeeded();
    });
    // Load water + streak trackers
    WaterService.instance.load();
    StreakService.instance.load();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      // Pick the image at full quality — ImagePreprocessor will resize
      // and normalise it before sending to the AI (avoids double-compression).
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null && mounted) {
        final bytes = await image.readAsBytes();

        // If Gemini API key is set, use Gemini for analysis
        if (GeminiFoodService.instance.isAvailable) {
          await _analyzeWithGemini(bytes);
        } else {
          _promptApiKeyOrFallback(bytes);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _promptApiKeyOrFallback(Uint8List imageBytes) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: AppTheme.cardRadius),
        title: Row(
          children: [
            Icon(Icons.auto_awesome_rounded, color: AppTheme.primary, size: 24),
            const SizedBox(width: 12),
            const Text('Gemini AI Key Required'),
          ],
        ),
        content: Text(
          'To use instant AI food recognition, enter your free Gemini API key (get it at aistudio.google.com). Or continue with manual food search.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _navigateToFoodSearch(imageBytes);
            },
            child: const Text('Use Search'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showApiKeyDialog();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: AppTheme.background,
            ),
            child: const Text('Enter Key'),
          ),
        ],
      ),
    );
  }

  /// Analyze food image using Gemini Vision API.
  Future<void> _analyzeWithGemini(Uint8List imageBytes) async {
    setState(() {
      _analyzing = true;
      _analyzingImageBytes = imageBytes;
    });

    try {
      final result = await GeminiFoodService.instance.analyzeFood(imageBytes);

      if (!mounted) return;
      setState(() => _analyzing = false);

      if (result == null || GeminiFoodService.isNotFood(result)) {
        // Gemini couldn't identify — fall back to manual search
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

      // Go directly to the review screen with Gemini's detection and a
      // database-backed nutrient profile whenever both servings use grams.
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
        setState(() => _analyzing = false);

        final isInvalidKey = e.toString().contains('API key invalid') || e.toString().contains('403');
        if (isInvalidKey) {
          await ApiKeyService.instance.clearApiKey();
          if (!mounted) return;
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Gemini API error. Please check backend proxy or connection.'),
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
              duration: const Duration(seconds: 6),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
          _navigateToFoodSearch(imageBytes);
        }
      }
    }
  }

  /// Cross-check a detected food against the local/Open Food Facts/USDA chain.
  /// A replacement is only used when both servings state a gram weight, so a
  /// "slice" or "cup" is never silently treated as an equivalent portion.
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
    } catch (_) {
      // Vision nutrition remains a safe fallback if a network source is down.
    }
    return vision;
  }

  double? _gramsInServing(String serving) {
    final match = RegExp(r'(\d+(?:\.\d+)?)\s*g\b', caseSensitive: false)
        .firstMatch(serving);
    return match == null ? null : double.tryParse(match.group(1)!);
  }

  /// Show dialog to enter/update Gemini API key.
  void _showApiKeyDialog() {
    final controller = TextEditingController(
      text: ApiKeyService.instance.apiKey ?? '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: AppTheme.cardRadius),
        title: Row(
          children: [
            Icon(Icons.key_rounded, color: AppTheme.primary, size: 24),
            const SizedBox(width: 12),
            const Text('Gemini API Key'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your Gemini API key for AI-powered food recognition. Get a free key at aistudio.google.com',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'AIzaSy...',
                hintStyle: TextStyle(
                  color: AppTheme.textSecondary.withValues(alpha: 0.4),
                ),
                filled: true,
                fillColor: AppTheme.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (ApiKeyService.instance.hasApiKey)
            TextButton(
              onPressed: () async {
                await ApiKeyService.instance.clearApiKey();
                if (mounted) setState(() {});
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text('Remove',
                  style: TextStyle(color: AppTheme.error)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final key = controller.text.trim();
              if (key.isNotEmpty) {
                await ApiKeyService.instance.saveApiKey(key);
                if (mounted) setState(() {});
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: AppTheme.background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _navigateToFoodSearch(Uint8List imageBytes) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) =>
            FoodSearchScreen(imageBytes: imageBytes),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
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
  }

  void _navigateToSearch() {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, animation, _) =>
            const FoodSearchScreen(),
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
  }

  void _navigateToInsights() {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, animation, _) => const HealthInsightsScreen(),
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
  }

  Future<void> _navigateToBarcodeScan() async {
    final result = await Navigator.push<NutritionData>(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, animation, _) => const BarcodeScannerScreen(),
        transitionsBuilder: (context, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );

    if (!mounted || result == null) return;

    // Feed directly into ResultScreen — same flow as AI photo scan
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ResultScreen(nutritionData: result)),
    );
  }


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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: Stack(
          children: [
            // Animated Glowing Background Orb
            Positioned(
              top: MediaQuery.of(context).size.height * 0.25,
              left: -80,
              right: -80,
              child: Container(
                height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accent.withValues(alpha: 0.15),
                      blurRadius: 100,
                      spreadRadius: 50,
                    ),
                  ],
                ),
              ).animate(onPlay: (controller) => controller.repeat(reverse: true))
               .scaleXY(begin: 0.95, end: 1.05, duration: 3.seconds)
               .fadeIn(duration: 1.seconds),
            ),
            
            // Foreground Content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: Column(
                        children: [
                              // Top bar with settings
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Profile button
                                  GestureDetector(
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppTheme.surfaceLight.withValues(alpha: 0.5),
                                        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                                      ),
                                      child: const Icon(
                                        Icons.person_rounded,
                                        size: 18,
                                        color: AppTheme.primary,
                                      ),
                                    ),
                                  ),
                                  // AI status badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: GeminiFoodService.instance.isAvailable
                                          ? AppTheme.fiberGreen.withValues(alpha: 0.1)
                                          : AppTheme.surfaceLight.withValues(alpha: 0.5),
                                      borderRadius: AppTheme.chipRadius,
                                      border: Border.all(
                                        color: GeminiFoodService.instance.isAvailable
                                            ? AppTheme.fiberGreen.withValues(alpha: 0.3)
                                            : Colors.white.withValues(alpha: 0.06),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          GeminiFoodService.instance.isAvailable
                                              ? Icons.auto_awesome_rounded
                                              : Icons.auto_awesome_outlined,
                                          size: 14,
                                          color: GeminiFoodService.instance.isAvailable
                                              ? AppTheme.fiberGreen
                                              : AppTheme.textSecondary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          GeminiFoodService.instance.isAvailable
                                              ? 'AI Connected'
                                              : 'AI Ready',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: GeminiFoodService.instance.isAvailable
                                                    ? AppTheme.fiberGreen
                                                    : AppTheme.primary,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // Logo - Cyber Blade Wings Emblem (Static on main UI dashboard)
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.surface,
                                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3), width: 2),
                                  boxShadow: AppTheme.glowShadow(AppTheme.primary),
                                ),
                                child: const CyberBladeWingsLogo(
                                  size: 64,
                                  animateStartupScan: false, // Fully static on main UI dashboard (NO ROTATION)
                                ),
                              )
                                  .animate()
                                  .fadeIn(duration: 600.ms)
                                  .scale(begin: const Offset(0.5, 0.5)),

                              const SizedBox(height: 28),

                              // App Name
                              Text(
                                'YOTRACKEZ',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineLarge
                                    ?.copyWith(
                                      fontSize: 44,
                                      foreground: Paint()
                                        ..shader = AppTheme.primaryGradient.createShader(
                                            const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
                                    ),
                              ).animate().fadeIn(delay: 200.ms, duration: 600.ms),

                              const SizedBox(height: 8),

                              Text(
                                'Snap. Analyze. Eat Smart.',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: AppTheme.textSecondary,
                                      letterSpacing: 2.0,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ).animate().fadeIn(delay: 400.ms, duration: 600.ms),

                              const SizedBox(height: 24),

                              // Main card
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                                decoration: AppTheme.glassCard(),
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.document_scanner_rounded,
                                        size: 48,
                                        color: AppTheme.primary,
                                      ),
                                    ).animate(onPlay: (c) => c.repeat(reverse: true))
                                     .moveY(begin: -5, end: 5, duration: 2.seconds),
                                     
                                    const SizedBox(height: 16),
                                    
                                    Text(
                                      'Scan Your Food',
                                      style: Theme.of(context).textTheme.headlineMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Take a photo of your meal and get\ninstant nutritional breakdown',
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
                                    ),
                                  ],
                                ),
                              )
                                  .animate()
                                  .fadeIn(delay: 600.ms, duration: 600.ms)
                                  .slideY(begin: 0.2),

                              const SizedBox(height: 24),

                    // SCAN button (or analyzing state)
                    Container(
                      width: double.infinity,
                      height: 64,
                      decoration: BoxDecoration(
                        borderRadius: AppTheme.buttonRadius,
                        boxShadow: _analyzing
                            ? []
                            : AppTheme.glowShadow(AppTheme.primary),
                      ),
                      child: ElevatedButton(
                        onPressed: _analyzing ? null : _showImageSourceSheet,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _analyzing
                              ? AppTheme.surfaceLight
                              : AppTheme.primary,
                          foregroundColor: AppTheme.background,
                          disabledBackgroundColor: AppTheme.surfaceLight,
                          disabledForegroundColor: AppTheme.textSecondary,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppTheme.buttonRadius,
                          ),
                        ),
                        child: _analyzing
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Text(
                                    'ANALYZING...',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.5,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                ],
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.qr_code_scanner_rounded, size: 26),
                                  SizedBox(width: 12),
                                  Text(
                                    'SCAN MEAL',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 800.ms, duration: 600.ms)
                        .slideY(begin: 0.3),

                    const SizedBox(height: 14),

                    // SEARCH button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: _navigateToSearch,
                        icon: const Icon(Icons.search_rounded, size: 22),
                        label: const Text(
                          'SEARCH FOOD',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primary,
                          side: BorderSide(
                            color: AppTheme.primary.withValues(alpha: 0.4),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppTheme.buttonRadius,
                          ),
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 900.ms, duration: 600.ms)
                        .slideY(begin: 0.3),

                    const SizedBox(height: 10),

                    // SCAN BARCODE button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: _navigateToBarcodeScan,
                        icon: const Icon(Icons.qr_code_scanner_rounded, size: 22),
                        label: const Text(
                          'SCAN BARCODE',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.fatYellow,
                          side: BorderSide(
                            color: AppTheme.fatYellow.withValues(alpha: 0.4),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppTheme.buttonRadius,
                          ),
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 920.ms, duration: 600.ms)
                        .slideY(begin: 0.3),

                    const SizedBox(height: 10),

                    // HEALTH INSIGHTS button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: _navigateToInsights,
                        icon: const Icon(Icons.insights_rounded, size: 22),
                        label: const Text(
                          'HEALTH INSIGHTS',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.accent,
                          side: BorderSide(
                            color: AppTheme.accent.withValues(alpha: 0.4),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppTheme.buttonRadius,
                          ),
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 950.ms, duration: 600.ms)
                        .slideY(begin: 0.3),

                    const SizedBox(height: 18),

                    // Features row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _FeatureChip(icon: Icons.bolt_rounded, label: 'Instant'),
                        _FeatureChip(icon: Icons.auto_awesome_rounded, label: 'Smart AI'),
                        _FeatureChip(icon: Icons.verified_rounded, label: 'USDA Data'),
                      ],
                    ).animate().fadeIn(delay: 1000.ms, duration: 600.ms),

                    const SizedBox(height: 24),

                    // ── Water Tracker ──────────────────────────────────
                    const WaterTrackerWidget()
                        .animate()
                        .fadeIn(delay: 1100.ms, duration: 600.ms)
                        .slideY(begin: 0.3),

                    const SizedBox(height: 14),

                    // ── Streak Card ────────────────────────────────────
                    _StreakCard()
                        .animate()
                        .fadeIn(delay: 1200.ms, duration: 600.ms)
                        .slideY(begin: 0.3),

                    const SizedBox(height: 32),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            // Full-screen scanning animation while Gemini analyzes the photo
            if (_analyzing)
              Positioned.fill(
                child: FoodScanOverlay(imageBytes: _analyzingImageBytes),
              ),
          ],
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.card.withValues(alpha: 0.4),
        borderRadius: AppTheme.chipRadius,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                ),
          ),
        ],
      ),
    );
  }
}

class _StreakCard extends StatefulWidget {
  @override
  State<_StreakCard> createState() => _StreakCardState();
}

class _StreakCardState extends State<_StreakCard> {
  @override
  void initState() {
    super.initState();
    StreakService.instance.addListener(_rebuild);
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    StreakService.instance.removeListener(_rebuild);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final svc = StreakService.instance;
    final streak = svc.streak;
    final longest = svc.longestStreak;
    final loggedToday = svc.loggedToday;

    // Build fire emojis (up to 7)
    final fires = streak == 0
        ? ''
        : List.filled(streak.clamp(0, 7), '🔥').join();

    final message = streak == 0
        ? 'Snap a meal to start your streak!'
        : loggedToday
            ? 'Logged today — keep it up!'
            : 'Log a meal to keep the streak alive!';

    final accentColor = streak >= 7
        ? const Color(0xFFFFB800)
        : streak >= 3
        ? AppTheme.accent
            : AppTheme.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0D1B3E),
            accentColor.withValues(alpha: 0.1),
          ],
        ),
        border: Border.all(
          color: streak > 0
              ? accentColor.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: streak >= 3 ? AppTheme.glowShadow(accentColor) : null,
      ),
      child: Row(
        children: [
          // Streak number circle
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor.withValues(alpha: 0.15),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Center(
              child: streak == 0
                  ? Icon(Icons.local_fire_department_outlined,
                      color: accentColor.withValues(alpha: 0.5), size: 26)
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$streak',
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                        Text(
                          streak == 1 ? 'day' : 'days',
                          style: TextStyle(
                            color: accentColor.withValues(alpha: 0.7),
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      streak == 0 ? 'Start Your Streak' : 'Daily Streak',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (streak > 0) ...[
                      const SizedBox(width: 6),
                      Text(fires, style: const TextStyle(fontSize: 13)),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11,
                  ),
                ),
                if (longest > 0 && longest > streak) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Best: $longest days',
                    style: TextStyle(
                      color: accentColor.withValues(alpha: 0.6),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (loggedToday)
            Icon(Icons.check_circle_rounded, color: accentColor, size: 22),
        ],
      ),
    );
  }
}
