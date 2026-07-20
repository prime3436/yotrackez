import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_key_service.dart';
import '../services/gemini_food_service.dart';
import '../services/nutrition_db_service.dart';
import '../theme/app_theme.dart';
import '../widgets/image_source_sheet.dart';
import 'food_search_screen.dart';
import 'result_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _analyzing = false;

  @override
  void initState() {
    super.initState();
    // Pre-load services
    NutritionDbService.instance.load();
    ApiKeyService.instance.load().then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null && mounted) {
        final bytes = await image.readAsBytes();

        // If Gemini API key is set, use Gemini for analysis
        if (GeminiFoodService.instance.isAvailable) {
          await _analyzeWithGemini(bytes);
        } else {
          // Fallback to manual food search
          _navigateToFoodSearch(bytes);
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

  /// Analyze food image using Gemini Vision API.
  Future<void> _analyzeWithGemini(Uint8List imageBytes) async {
    setState(() => _analyzing = true);

    // Show analyzing message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            SizedBox(width: 12),
            Text('Asking Gemini AI to identify your food...'),
          ],
        ),
        backgroundColor: AppTheme.primary,
        duration: const Duration(seconds: 15),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    try {
      final result = await GeminiFoodService.instance.analyzeFood(imageBytes);

      if (!mounted) return;
      setState(() => _analyzing = false);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

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

      // Go directly to result screen with Gemini's analysis
      Navigator.push(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (context, animation, _) => ResultScreen(
            imageBytes: imageBytes,
            nutritionData: result,
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
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
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
                child: Column(
                  children: [
                    // Top bar with settings
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
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
                                    : 'AI Offline',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: GeminiFoodService.instance.isAvailable
                                          ? AppTheme.fiberGreen
                                          : AppTheme.textSecondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Settings button
                        IconButton(
                          onPressed: _showApiKeyDialog,
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            child: Icon(
                              Icons.settings_rounded,
                              size: 18,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Logo
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.surface,
                        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3), width: 2),
                        boxShadow: AppTheme.glowShadow(AppTheme.primary),
                      ),
                      child: const Icon(
                        Icons.restaurant_rounded,
                        size: 48,
                        color: AppTheme.primary,
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

                    const Spacer(),

                    // Main card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
                      decoration: AppTheme.glassCard(),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.document_scanner_rounded,
                              size: 64,
                              color: AppTheme.primary,
                            ),
                          ).animate(onPlay: (c) => c.repeat(reverse: true))
                           .moveY(begin: -5, end: 5, duration: 2.seconds),
                           
                          const SizedBox(height: 24),
                          
                          Text(
                            'Scan Your Food',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 12),
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

                    const Spacer(),

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

                    // SEARCH button (new!)
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

                    const SizedBox(height: 18),

                    // Features row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _FeatureChip(icon: Icons.bolt_rounded, label: 'Instant'),
                        _FeatureChip(icon: Icons.wifi_off_rounded, label: 'Offline'),
                        _FeatureChip(icon: Icons.verified_rounded, label: 'USDA Data'),
                      ],
                    ).animate().fadeIn(delay: 1000.ms, duration: 600.ms),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
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
