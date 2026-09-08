import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../models/user_settings.dart';
import '../services/calorie_body_service.dart';
import 'cyber_blade_wings_logo.dart';
import 'yo_avatar_widget.dart';

/// Lightweight full-screen HUD scanning overlay.
/// Uses CSS-style animations only — no heavy custom painters.
class FoodScanOverlay extends StatefulWidget {
  final Uint8List? imageBytes;
  const FoodScanOverlay({super.key, this.imageBytes});

  @override
  State<FoodScanOverlay> createState() => _FoodScanOverlayState();
}

class _FoodScanOverlayState extends State<FoodScanOverlay>
    with TickerProviderStateMixin {

  static const _statusMessages = [
    'Scanning image...',
    'Detecting food item...',
    'Identifying ingredients...',
    'Querying nutrition database...',
    'Calculating macros...',
    'Almost done...',
  ];

  static const _actions = [
    ('🤔', 'Analyzing…'),
    ('👀', 'Inspecting…'),
    ('⚡', 'Processing…'),
    ('💡', 'Almost there!'),
    ('🔍', 'Cross-checking…'),
  ];

  int _statusIndex = 0;
  int _actionIndex = 0;
  Timer? _statusTimer;
  Timer? _actionTimer;

  late final AnimationController _bobCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _spinCtrl;
  late final Animation<double> _bob;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();

    _bobCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _bob = Tween<double>(begin: -8, end: 8)
        .animate(CurvedAnimation(parent: _bobCtrl, curve: Curves.easeInOut));

    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.9, end: 1.1)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _spinCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))
      ..repeat();

    _statusTimer = Timer.periodic(const Duration(milliseconds: 1600), (_) {
      if (!mounted) return;
      setState(() => _statusIndex = (_statusIndex + 1) % _statusMessages.length);
    });
    _actionTimer = Timer.periodic(const Duration(milliseconds: 2400), (_) {
      if (!mounted) return;
      setState(() => _actionIndex = (_actionIndex + 1) % _actions.length);
    });
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _actionTimer?.cancel();
    _bobCtrl.dispose();
    _pulseCtrl.dispose();
    _spinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final action = _actions[_actionIndex];

    return Container(
      color: AppTheme.background.withValues(alpha: 0.97),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            // ── Animated emoji avatar (no heavy painter) ──────────────────
            Stack(
              alignment: Alignment.center,
              children: [
                // Pulsing glow ring
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (ctx, child) => Transform.scale(
                    scale: _pulse.value,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [
                          AppTheme.primary.withValues(alpha: 0.15),
                          Colors.transparent,
                        ]),
                      ),
                    ),
                  ),
                ),

                // Spinning orbit ring
                AnimatedBuilder(
                  animation: _spinCtrl,
                  builder: (ctx, child) => CustomPaint(
                    size: const Size(220, 220),
                    painter: _RingPainter(_spinCtrl.value),
                  ),
                ),

                // Premium 3D avatar with bob
                AnimatedBuilder(
                  animation: _bob,
                  builder: (ctx, child) => Transform.translate(
                    offset: Offset(0, _bob.value),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Rive avatar — real bodyComposition from calorie engine
                        YoAvatarWidget(
                          gender: UserSettings.instance.gender,
                          size: 200,
                          isScanning: true,
                          bodyComposition:
                              CalorieBodyService.instance.bodyComposition,
                        ),

                        // Thought badge below
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 350),
                          transitionBuilder: (child, anim) => ScaleTransition(
                            scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut),
                            child: FadeTransition(opacity: anim, child: child),
                          ),
                          child: Container(
                            key: ValueKey(_actionIndex),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: AppTheme.chipRadius,
                              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.5)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(action.$1, style: const TextStyle(fontSize: 14)),
                                const SizedBox(width: 6),
                                Text(action.$2,
                                  style: const TextStyle(
                                    color: AppTheme.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // ── Scan frame ────────────────────────────────────────────────
            _buildScanFrame(),

            const SizedBox(height: 24),

            // ── Logo ──────────────────────────────────────────────────────
            const CyberBladeWingsLogo(size: 48, animateStartupScan: false)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(begin: 0.9, end: 1.1, duration: 800.ms),

            const SizedBox(height: 16),

            // ── Status text ───────────────────────────────────────────────
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                _statusMessages[_statusIndex].toUpperCase(),
                key: ValueKey(_statusIndex),
                style: const TextStyle(
                  color: AppTheme.primary,
                  letterSpacing: 2.5,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Progress shimmer ──────────────────────────────────────────
            SizedBox(
              width: 160,
              child: LinearProgressIndicator(
                backgroundColor: AppTheme.surfaceLight,
                valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
                minHeight: 2,
              ).animate(onPlay: (c) => c.repeat())
                  .shimmer(duration: 1200.ms, color: AppTheme.accent.withValues(alpha: 0.6)),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 200.ms);
  }

  Widget _buildScanFrame() {
    const sz = 150.0;
    return SizedBox(
      width: sz, height: sz,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Photo
          Container(
            width: sz, height: sz,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.glowShadow(AppTheme.primary),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: widget.imageBytes != null
                  ? Image.memory(widget.imageBytes!, fit: BoxFit.cover)
                  : Container(color: AppTheme.surface,
                      child: const Icon(Icons.restaurant_rounded, size: 40, color: AppTheme.textSecondary)),
            ),
          ),
          // Scrim
          Container(
            width: sz, height: sz,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: AppTheme.background.withValues(alpha: 0.2),
            ),
          ),
          // Laser line
          _ScanLine(frameSize: sz),
          // Corners
          ..._corners(sz),
        ],
      ),
    ).animate().scale(begin: const Offset(0.88, 0.88), curve: Curves.easeOutBack, duration: 450.ms);
  }

  List<Widget> _corners(double sz) {
    Widget c({required bool top, required bool left}) => Positioned(
      top: top ? -5 : null, bottom: top ? null : -5,
      left: left ? -5 : null, right: left ? null : -5,
      child: SizedBox(width: 20, height: 20,
        child: CustomPaint(painter: _CornerPainter(AppTheme.primary, top, left))),
    );
    return [c(top:true,left:true), c(top:true,left:false), c(top:false,left:true), c(top:false,left:false)];
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Lightweight spinning ring — only draws 1 arc + 1 dot per frame
// ═══════════════════════════════════════════════════════════════════════════

class _RingPainter extends CustomPainter {
  final double progress;
  const _RingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 4;

    // Faint circle
    canvas.drawCircle(c, r, Paint()
      ..color = AppTheme.primary.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5);

    // Moving dot
    final angle = progress * 2 * math.pi;
    final dx = c.dx + r * math.cos(angle);
    final dy = c.dy + r * math.sin(angle);
    canvas.drawCircle(Offset(dx, dy), 5, Paint()
      ..color = AppTheme.primary
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    canvas.drawCircle(Offset(dx, dy), 3, Paint()..color = AppTheme.frost);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.progress != progress;
}

// ═══════════════════════════════════════════════════════════════════════════
// Scan laser line
// ═══════════════════════════════════════════════════════════════════════════

class _ScanLine extends StatefulWidget {
  final double frameSize;
  const _ScanLine({required this.frameSize});
  @override
  State<_ScanLine> createState() => _ScanLineState();
}

class _ScanLineState extends State<_ScanLine> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  @override void initState() { super.initState(); _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true); }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (ctx, child) => Positioned(
        top: widget.frameSize * (0.08 + _ctrl.value * 0.84),
        left: 8, right: 8,
        child: Container(height: 2, decoration: BoxDecoration(
          color: AppTheme.primary,
          boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.8), blurRadius: 8, spreadRadius: 1)],
        )),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HUD corner brackets
// ═══════════════════════════════════════════════════════════════════════════

class _CornerPainter extends CustomPainter {
  final Color color; final bool top; final bool left;
  _CornerPainter(this.color, this.top, this.left);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color..strokeWidth = 3..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final vY = top ? 0.0 : size.height;
    final hX = left ? 0.0 : size.width;
    canvas.drawPath(Path()
      ..moveTo(hX, vY)..lineTo(hX, top ? size.height * 0.7 : size.height * 0.3)
      ..moveTo(hX, vY)..lineTo(left ? size.width * 0.7 : size.width * 0.3, vY), p);
  }
  @override bool shouldRepaint(_) => false;
}
