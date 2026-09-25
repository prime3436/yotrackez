import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/scanned_product.dart';
import '../models/nutrition_data.dart';
import '../services/open_food_facts_service.dart';
import '../theme/app_theme.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final MobileScannerController _ctrl = MobileScannerController();
  final OpenFoodFactsService _svc = OpenFoodFactsService();

  bool _lookingUp = false;
  String? _lastCode;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_lookingUp) return;
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null || code == _lastCode) return;

    _lastCode = code;
    setState(() { _lookingUp = true; _error = null; });

    final result = await _svc.lookup(code);
    if (!mounted) return;

    switch (result) {
      case BarcodeLookupSuccess(:final product):
        await _showPortionSheet(product);
      case BarcodeLookupNotFound():
        setState(() {
          _lookingUp = false;
          _error = "Product not found in the database.\nTry manual entry instead.";
        });
      case BarcodeLookupError(:final message):
        setState(() {
          _lookingUp = false;
          _error = message;
        });
    }
  }

  Future<void> _showPortionSheet(ScannedProduct product) async {
    final defaultGrams = product.packageQuantityGrams ?? 100.0;
    final controller = TextEditingController(
      text: defaultGrams.toStringAsFixed(0),
    );

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PortionSheet(product: product, controller: controller),
    );

    if (!mounted) return;

    if (confirmed == true) {
      final grams = double.tryParse(controller.text.trim()) ?? defaultGrams;
      final data = product.forPortion(grams);

      Navigator.of(context).pop(NutritionData(
        foodName: product.brand != null
            ? '${product.brand} ${data.productName}'
            : data.productName,
        servingSize: '${grams.toStringAsFixed(0)} g',
        calories: data.calories,
        protein: NutrientInfo(name: 'Protein', amount: data.protein, unit: 'g'),
        carbs:   NutrientInfo(name: 'Carbs',   amount: data.carbs,   unit: 'g'),
        fat:     NutrientInfo(name: 'Fat',     amount: data.fat,     unit: 'g'),
        fiber:   NutrientInfo(name: 'Fiber',   amount: 0,            unit: 'g'),
        sugar:   NutrientInfo(name: 'Sugar',   amount: 0,            unit: 'g'),
        sodium:  NutrientInfo(name: 'Sodium',  amount: 0,            unit: 'mg'),
        cholesterol: NutrientInfo(name: 'Cholesterol', amount: 0,    unit: 'mg'),
        vitamins: const [],
        ingredients: const [],
        healthTip: 'Scanned from barcode — exact values from Open Food Facts.',
      ));
    } else {

      setState(() { _lookingUp = false; _lastCode = null; });
    }
  }

  void _retry() => setState(() { _lastCode = null; _error = null; });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [

          MobileScanner(controller: _ctrl, onDetect: _onDetect),

          _Vignette(),

          Center(
            child: Container(
              width: 270,
              height: 170,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.primary, width: 2.5),
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.glowShadow(AppTheme.primary),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
             .scaleXY(begin: 1.0, end: 1.02, duration: 1200.ms)
             .then()
             .scaleXY(begin: 1.02, end: 1.0, duration: 1200.ms),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded, color: AppTheme.textPrimary),
                    onPressed: () => Navigator.of(context).pop(null),
                  ),
                  const Spacer(),
                  Text('Scan Barcode',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.flash_on_rounded, color: AppTheme.accent),
                    onPressed: () => _ctrl.toggleTorch(),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            bottom: 120,
            left: 0, right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.surface.withValues(alpha: 0.8),
                  borderRadius: AppTheme.chipRadius,
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                ),
                child: const Text(
                  'Point at a product barcode',
                  style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),

          if (_lookingUp)
            Container(
              color: Colors.black.withValues(alpha: 0.65),
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const CircularProgressIndicator(color: AppTheme.primary),
                  const SizedBox(height: 16),
                  Text('Looking up product…',
                      style: TextStyle(color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600)),
                ]),
              ),
            ).animate().fadeIn(duration: 200.ms),

          if (_error != null)
            Positioned(
              bottom: 40, left: 20, right: 20,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: AppTheme.cardRadius,
                  border: Border.all(color: AppTheme.error.withValues(alpha: 0.4)),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.search_off_rounded, color: AppTheme.error, size: 32),
                  const SizedBox(height: 10),
                  Text(_error!, textAlign: TextAlign.center,
                      style: const TextStyle(color: AppTheme.textPrimary, height: 1.4)),
                  const SizedBox(height: 16),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop(null),
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: const Text('Manual entry'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textSecondary,
                        side: BorderSide(color: AppTheme.textSecondary.withValues(alpha: 0.4)),
                        shape: RoundedRectangleBorder(borderRadius: AppTheme.chipRadius),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _retry,
                      icon: const Icon(Icons.qr_code_scanner_rounded, size: 16),
                      label: const Text('Scan again'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: AppTheme.chipRadius),
                      ),
                    ),
                  ]),
                ]),
              ).animate().slideY(begin: 0.3).fadeIn(),
            ),
        ],
      ),
    );
  }
}

class _PortionSheet extends StatelessWidget {
  final ScannedProduct product;
  final TextEditingController controller;

  const _PortionSheet({required this.product, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [

          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppTheme.textSecondary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),

          if (product.brand != null)
            Text(product.brand!, style: TextStyle(color: AppTheme.primary, fontSize: 11,
                fontWeight: FontWeight.w700, letterSpacing: 1)),
          Text(product.name, style: const TextStyle(color: AppTheme.textPrimary,
              fontSize: 18, fontWeight: FontWeight.w800)),
          if (product.nutriScoreGrade != null) ...[
            const SizedBox(height: 6),
            _NutriScoreBadge(product.nutriScoreGrade!),
          ],

          const SizedBox(height: 16),

          _MacroRow(product: product),

          const SizedBox(height: 20),
          const Text('How many grams are you eating?',
              style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),

          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 18),
            decoration: InputDecoration(
              suffixText: 'g',
              suffixStyle: TextStyle(color: AppTheme.textSecondary),
              filled: true,
              fillColor: AppTheme.surfaceLight.withValues(alpha: 0.4),
              border: OutlineInputBorder(borderRadius: AppTheme.cardRadius,
                  borderSide: BorderSide(color: AppTheme.primary.withValues(alpha: 0.2))),
              focusedBorder: OutlineInputBorder(borderRadius: AppTheme.cardRadius,
                  borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
            ),
          ),

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.add_circle_rounded, size: 20),
              label: const Text('LOG THIS MEAL'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: AppTheme.buttonRadius),
                textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _MacroRow extends StatelessWidget {
  final ScannedProduct product;
  const _MacroRow({required this.product});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      _Macro('Cal', product.caloriesPer100g.toStringAsFixed(0), AppTheme.calorieOrange),
      _Macro('Protein', '${product.proteinPer100g.toStringAsFixed(1)}g', AppTheme.proteinRed),
      _Macro('Carbs', '${product.carbsPer100g.toStringAsFixed(1)}g', AppTheme.carbsBlue),
      _Macro('Fat', '${product.fatPer100g.toStringAsFixed(1)}g', AppTheme.fatYellow),
    ]);
  }
}

class _Macro extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Macro(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w800)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11,
          fontWeight: FontWeight.w600)),
    ]);
  }
}

class _NutriScoreBadge extends StatelessWidget {
  final String grade;
  const _NutriScoreBadge(this.grade);

  Color get _color {
    switch (grade.toLowerCase()) {
      case 'a': return const Color(0xFF1E8449);
      case 'b': return const Color(0xFF85C341);
      case 'c': return const Color(0xFFE8C02A);
      case 'd': return const Color(0xFFE87D2A);
      default:  return const Color(0xFFE03A2A);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: _color, borderRadius: BorderRadius.circular(6)),
      child: Text('Nutri-Score ${grade.toUpperCase()}',
          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
    );
  }
}

class _Vignette extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.2,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.65)],
        ),
      ),
      child: const SizedBox.expand(),
    );
  }
}
