import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/nutrition_data.dart';
import '../models/scanned_product.dart';
import '../services/api_key_service.dart';
import '../services/gemini_food_service.dart';
import '../services/nutrition_db_service.dart';
import '../services/nutrition_lookup_service.dart';
import '../services/open_food_facts_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/food_scan_overlay.dart';
import 'food_search_screen.dart';
import 'result_screen.dart';

enum _ScanState {
  scanning,
  barcodeDetected,
  barcodeLoading,
  photoCapturing,
}

class UnifiedScanScreen extends StatefulWidget {
  const UnifiedScanScreen({super.key});

  @override
  State<UnifiedScanScreen> createState() => _UnifiedScanScreenState();
}

class _UnifiedScanScreenState extends State<UnifiedScanScreen> {
  final MobileScannerController _ctrl = MobileScannerController();
  final OpenFoodFactsService _offSvc = OpenFoodFactsService();
  final ImagePicker _picker = ImagePicker();

  _ScanState _state = _ScanState.scanning;
  String? _lastCode;
  String? _error;
  Uint8List? _capturingBytes;

  bool get _isIdle => _state == _ScanState.scanning;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (_state != _ScanState.scanning) return;
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null || code == _lastCode) return;

    _lastCode = code;
    setState(() { _state = _ScanState.barcodeDetected; _error = null; });
    HapticFeedback.mediumImpact();

    Future.delayed(const Duration(milliseconds: 550), () {
      if (mounted) {
        setState(() => _state = _ScanState.barcodeLoading);
        _lookupBarcode(code);
      }
    });
  }

  Future<void> _lookupBarcode(String code) async {
    final result = await _offSvc.lookup(code);
    if (!mounted) return;

    switch (result) {
      case BarcodeLookupSuccess(:final product):
        await _showPortionSheet(product);
      case BarcodeLookupNotFound():
        setState(() {
          _state = _ScanState.scanning;
          _error = 'Product not found in the database.\nTry manual entry instead.';
        });
      case BarcodeLookupError(:final message):
        setState(() {
          _state = _ScanState.scanning;
          _error = message;
        });
    }
  }

  Future<void> _showPortionSheet(ScannedProduct product) async {
    final defaultGrams = product.packageQuantityGrams ?? 100.0;
    final controller = TextEditingController(text: defaultGrams.toStringAsFixed(0));

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PortionSheet(product: product, controller: controller),
    );

    if (!mounted) return;

    if (confirmed == true) {
      final grams = double.tryParse(controller.text.trim()) ?? defaultGrams;
      final data  = product.forPortion(grams);

      Navigator.of(context).pop(NutritionData(
        foodName:    product.brand != null ? '${product.brand} ${data.productName}' : data.productName,
        servingSize: '${grams.toStringAsFixed(0)} g',
        calories:    data.calories,
        protein:     NutrientInfo(name: 'Protein',     amount: data.protein, unit: 'g'),
        carbs:       NutrientInfo(name: 'Carbs',       amount: data.carbs,   unit: 'g'),
        fat:         NutrientInfo(name: 'Fat',         amount: data.fat,     unit: 'g'),
        fiber:       NutrientInfo(name: 'Fiber',       amount: 0,            unit: 'g'),
        sugar:       NutrientInfo(name: 'Sugar',       amount: 0,            unit: 'g'),
        sodium:      NutrientInfo(name: 'Sodium',      amount: 0,            unit: 'mg'),
        cholesterol: NutrientInfo(name: 'Cholesterol', amount: 0,            unit: 'mg'),
        vitamins:     const [],
        ingredients:  const [],
        healthTip:   'Scanned from barcode — exact values from Open Food Facts.',
      ));
    } else {

      setState(() { _state = _ScanState.scanning; _lastCode = null; });
    }
  }

  Future<void> _onShutterTapped() async {
    if (!_isIdle) return;

    await _ctrl.stop();

    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image == null) {
        await _ctrl.start();
        return;
      }
      final bytes = await image.readAsBytes();
      setState(() { _state = _ScanState.photoCapturing; _capturingBytes = bytes; });

      await _analyzeWithGemini(bytes);
    } catch (e) {
      if (mounted) {
        setState(() => _state = _ScanState.scanning);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Camera error: $e'),
          backgroundColor: AppTheme.error,
        ));
        await _ctrl.start();
      }
    }
  }

  Future<void> _analyzeWithGemini(Uint8List bytes) async {

    await ApiKeyService.instance.load();

    if (!GeminiFoodService.instance.isAvailable) {
      if (!mounted) return;
      setState(() { _state = _ScanState.scanning; _capturingBytes = null; });
      await _ctrl.start();
      _showApiKeyPrompt(bytes);
      return;
    }

    try {
      final result = await GeminiFoodService.instance.analyzeFood(bytes);
      if (!mounted) return;

      if (result == null || GeminiFoodService.isNotFood(result)) {
        setState(() { _state = _ScanState.scanning; _capturingBytes = null; });
        await _ctrl.start();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('AI could not identify the food. Try again or search manually.'),
          backgroundColor: Color(0xFFFF6B35),
        ));
        return;
      }

      final nutrition = await _enrich(result);
      if (!mounted) return;

      final nav = Navigator.of(context);
      nav.pop();
      nav.push(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (ctx, anim, sa) => ResultScreen(imageBytes: bytes, nutritionData: nutrition),
          transitionsBuilder: (ctx, anim, sa, child) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
                  .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
              child: child,
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() { _state = _ScanState.scanning; _capturingBytes = null; });
      await _ctrl.start();
      if (!mounted) return;
      final isKeyError = e.toString().contains('403') || e.toString().contains('API key');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isKeyError ? 'Invalid API key — please update in Scan & AI settings.' : 'AI error: $e'),
        backgroundColor: AppTheme.error,
      ));
    }
  }

  Future<NutritionData> _enrich(NutritionData vision) async {
    try {
      await NutritionDbService.instance.load();
      final db = await NutritionLookupService.instance.lookup(vision.foodName);
      final dg = _grams(vision.servingSize);
      final dbg = db == null ? null : _grams(db.servingSize);
      if (db != null && dg != null && dbg != null) {
        return vision.withNutritionFrom(db.scale(dg / dbg));
      }
    } catch (_) {}
    return vision;
  }

  double? _grams(String s) {
    final m = RegExp(r'(\d+(?:\.\d+)?)\s*g\b', caseSensitive: false).firstMatch(s);
    return m == null ? null : double.tryParse(m.group(1)!);
  }

  void _showApiKeyPrompt(Uint8List bytes) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: AppTheme.cardRadius),
        title: const Text('Gemini API Key Required'),
        content: const Text(
          'Enter your free Gemini API key (aistudio.google.com) to enable AI food recognition.',
        ),
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => const FoodSearchScreen())); },
            child: const Text('Search Food'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _showApiKeyDialog();
              if (GeminiFoodService.instance.isAvailable) await _analyzeWithGemini(bytes);
            },
            child: const Text('Enter Key'),
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
        title: const Text('Gemini API Key'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'AIza…'), obscureText: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
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

  void _manualBarcodeEntry() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: AppTheme.cardRadius),
        title: const Text('Enter Barcode'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: '0123456789…'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              final code = ctrl.text.trim();
              if (code.isNotEmpty) {
                _lastCode = code;
                setState(() { _state = _ScanState.barcodeLoading; _error = null; });
                _lookupBarcode(code);
              }
            },
            child: const Text('Look up'),
          ),
        ],
      ),
    );
  }

  void _retry() => setState(() { _lastCode = null; _error = null; _state = _ScanState.scanning; });

  @override
  Widget build(BuildContext context) {
    final isProcessing = _state == _ScanState.photoCapturing;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [

          MobileScanner(
            controller: _ctrl,
            onDetect: _onBarcodeDetected,
            fit: BoxFit.cover,
          ),

          const _Vignette(),

          if (!isProcessing)
            Center(
              child: _ViewfinderBrackets(
                size: MediaQuery.of(context).size.width * 0.65,
                color: _state == _ScanState.barcodeDetected
                    ? AppColors.bodyMetric
                    : AppColors.primaryAction.withValues(alpha: 0.8),
              ),
            ),

          if (_state == _ScanState.barcodeDetected)
            const _DetectionPulse(),

          if (!isProcessing)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    _TopIconButton(
                      icon: Icons.arrow_back_ios_rounded,
                      onTap: () => Navigator.of(context).pop(null),
                    ),
                    const Spacer(),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Scan',
                          style: TextStyle(color: Colors.white, fontSize: 18,
                              fontWeight: FontWeight.w800),
                        ),
                        Text(
                          'barcode auto-detected · tap to capture food',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 10, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const Spacer(),
                    _TopIconButton(
                      icon: Icons.flash_on_rounded,
                      onTap: _ctrl.toggleTorch,
                      color: AppColors.secondaryAction,
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms),
            ),

          if (!isProcessing)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: AppTheme.cardRadius,
                            border: Border.all(color: AppTheme.error.withValues(alpha: 0.4)),
                          ),
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.search_off_rounded, color: AppTheme.error, size: 28),
                            const SizedBox(height: 8),
                            Text(_error!, textAlign: TextAlign.center,
                                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, height: 1.4)),
                            const SizedBox(height: 12),
                            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              OutlinedButton.icon(
                                onPressed: _manualBarcodeEntry,
                                icon: const Icon(Icons.edit_rounded, size: 14),
                                label: const Text('Type it'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.textSecondary,
                                  side: BorderSide(color: AppTheme.textSecondary.withValues(alpha: 0.4)),
                                  shape: RoundedRectangleBorder(borderRadius: AppTheme.chipRadius),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton.icon(
                                onPressed: _retry,
                                icon: const Icon(Icons.refresh_rounded, size: 14),
                                label: const Text('Try again'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primary,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(borderRadius: AppTheme.chipRadius),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ]),
                          ]),
                        ).animate().slideY(begin: 0.3).fadeIn(),
                      ),

                    if (_error == null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.qr_code_rounded, size: 13,
                                color: AppColors.bodyMetric),
                            const SizedBox(width: 6),
                            Text('Point at barcode to auto-detect',
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.65),
                                    fontSize: 11, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(40, 0, 40, 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [

                          GestureDetector(
                            onTap: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) => const FoodSearchScreen())),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                    color: AppColors.primaryAction.withValues(alpha: 0.3)),
                              ),
                              child: const Icon(Icons.search_rounded,
                                  color: AppColors.primaryAction, size: 22),
                            ),
                          ),

                          _ShutterButton(
                            onTap: _onShutterTapped,
                            isLoading: _state == _ScanState.barcodeLoading,
                          ),

                          GestureDetector(
                            onTap: _manualBarcodeEntry,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                    color: AppColors.secondaryAction.withValues(alpha: 0.3)),
                              ),
                              child: const Icon(Icons.edit_rounded,
                                  color: AppColors.secondaryAction, size: 22),
                            ),
                          ),
                        ],
                      ),
                    ),

                    GestureDetector(
                      onTap: _manualBarcodeEntry,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Type barcode instead',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.35),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (isProcessing)
            Positioned.fill(
              child: FoodScanOverlay(imageBytes: _capturingBytes),
            ),

          if (_state == _ScanState.barcodeLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.7),
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const CircularProgressIndicator(color: AppColors.bodyMetric),
                  const SizedBox(height: 16),
                  Text('Looking up product…',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w600)),
                ]),
              ),
            ).animate().fadeIn(duration: 150.ms),
        ],
      ),
    );
  }
}

class _DetectionPulse extends StatefulWidget {
  const _DetectionPulse();

  @override
  State<_DetectionPulse> createState() => _DetectionPulseState();
}

class _DetectionPulseState extends State<_DetectionPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _punchScale;
  late final Animation<double> _checkScale;
  late final Animation<double> _fadeOut;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    )..forward();

    _punchScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.1), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 20),
    ]).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.27, curve: Curves.easeOut),
    ));

    _checkScale = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.18, 0.64, curve: Curves.elasticOut),
      ),
    );

    _fadeOut = Tween(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.64, 1.0, curve: Curves.easeIn),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bracketSize = MediaQuery.of(context).size.width * 0.65;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (ctx, sa) => Opacity(
        opacity: _fadeOut.value,
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [

              Transform.scale(
                scale: _punchScale.value,
                child: _ViewfinderBrackets(
                  size: bracketSize,
                  color: AppColors.bodyMetric,
                  strokeWidth: 4,
                ),
              ),

              Transform.scale(
                scale: _checkScale.value,
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: AppColors.bodyMetric,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.bodyMetric.withValues(alpha: 0.55),
                        blurRadius: 28,
                        spreadRadius: 6,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 38),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ViewfinderBrackets extends StatelessWidget {
  final double size;
  final Color color;
  final double strokeWidth;

  const _ViewfinderBrackets({
    required this.size,
    required this.color,
    this.strokeWidth = 3.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _BracketsPainter(
        color: color,
        strokeWidth: strokeWidth,
      ),
    );
  }
}

class _BracketsPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  const _BracketsPainter({
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const armFraction = 0.22;
    final arm = size.width * armFraction;
    final r = size.width * 0.06;
    final w = size.width;
    final h = size.height;

    _drawBracket(canvas, paint, Offset(0, 0), arm, r, BracketCorner.topLeft, w, h);

    _drawBracket(canvas, paint, Offset(w, 0), arm, r, BracketCorner.topRight, w, h);

    _drawBracket(canvas, paint, Offset(0, h), arm, r, BracketCorner.bottomLeft, w, h);

    _drawBracket(canvas, paint, Offset(w, h), arm, r, BracketCorner.bottomRight, w, h);
  }

  void _drawBracket(Canvas canvas, Paint paint, Offset corner, double arm, double r,
      BracketCorner type, double w, double h) {
    final path = Path();
    switch (type) {
      case BracketCorner.topLeft:
        path.moveTo(corner.dx, corner.dy + arm);
        path.arcToPoint(Offset(corner.dx + r, corner.dy + r),
            radius: Radius.circular(r), clockwise: false);
        path.lineTo(corner.dx + arm, corner.dy);
      case BracketCorner.topRight:
        path.moveTo(corner.dx, corner.dy + arm);
        path.arcToPoint(Offset(corner.dx - r, corner.dy + r),
            radius: Radius.circular(r), clockwise: true);
        path.lineTo(corner.dx - arm, corner.dy);
      case BracketCorner.bottomLeft:
        path.moveTo(corner.dx, corner.dy - arm);
        path.arcToPoint(Offset(corner.dx + r, corner.dy - r),
            radius: Radius.circular(r), clockwise: true);
        path.lineTo(corner.dx + arm, corner.dy);
      case BracketCorner.bottomRight:
        path.moveTo(corner.dx, corner.dy - arm);
        path.arcToPoint(Offset(corner.dx - r, corner.dy - r),
            radius: Radius.circular(r), clockwise: false);
        path.lineTo(corner.dx - arm, corner.dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_BracketsPainter old) =>
      old.color != color || old.strokeWidth != strokeWidth;
}

enum BracketCorner { topLeft, topRight, bottomLeft, bottomRight }

class _ShutterButton extends StatelessWidget {
  final VoidCallback? onTap;
  final bool isLoading;

  const _ShutterButton({this.onTap, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: isLoading ? 0.3 : 0.9),
          border: Border.all(
            color: AppColors.primaryAction.withValues(alpha: isLoading ? 0.3 : 0.8),
            width: 3,
          ),
          boxShadow: isLoading
              ? null
              : [
                  BoxShadow(
                    color: AppColors.primaryAction.withValues(alpha: 0.45),
                    blurRadius: 20,
                    spreadRadius: 3,
                  ),
                ],
        ),
        child: isLoading
            ? const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primaryAction,
                  ),
                ),
              )
            : const Icon(Icons.camera_alt_rounded,
                color: AppColors.primaryAction, size: 32),
      ),
    );
  }
}

class _TopIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;

  const _TopIconButton({required this.icon, this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Icon(icon, color: color ?? Colors.white, size: 20),
      ),
    );
  }
}

class _Vignette extends StatelessWidget {
  const _Vignette();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.15,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.70)],
        ),
      ),
      child: const SizedBox.expand(),
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
            Text(product.brand!,
                style: const TextStyle(color: AppTheme.primary, fontSize: 11,
                    fontWeight: FontWeight.w700, letterSpacing: 1)),
          Text(product.name,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
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
              suffixStyle: const TextStyle(color: AppTheme.textSecondary),
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
            width: double.infinity, height: 52,
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
      _Macro('Cal',     product.caloriesPer100g.toStringAsFixed(0),          AppTheme.calorieOrange),
      _Macro('Protein', '${product.proteinPer100g.toStringAsFixed(1)}g',     AppTheme.proteinRed),
      _Macro('Carbs',   '${product.carbsPer100g.toStringAsFixed(1)}g',       AppTheme.carbsBlue),
      _Macro('Fat',     '${product.fatPer100g.toStringAsFixed(1)}g',         AppTheme.fatYellow),
    ]);
  }
}

class _Macro extends StatelessWidget {
  final String label, value;
  final Color color;
  const _Macro(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w800)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
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
