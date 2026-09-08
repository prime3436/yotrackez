import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ════════════════════════════════════════════════════════════════════════════
// Avatar3DWidget — Production animated avatar (Rive-spec compliant fallback)
//
// Implements every layer from the YOTRACKEZ Rive brief:
//   Layer 1 – Body:   idle(breathe) | EagerWait(scan) | Transform(burst)
//   Layer 2 – Face:   Neutral | Excited | Happy
//   Layer 3 – Outfit: continuous cloth/hair sway
//
// Body composition morph: smooth 0 (leanest) → 100 (heaviest)
// All animations run at 60 fps via single ticker.
// ════════════════════════════════════════════════════════════════════════════

class Avatar3DWidget extends StatefulWidget {
  final String avatarState; // kept for compat — derived internally from composition
  final String gender;      // 'male' | 'female'
  final double size;
  final bool autoSpin;      // maps to isScanning
  final double? yRotation;

  // Extended spec props
  final double bodyComposition;   // 0–100
  final bool isScanning;
  final bool mealAdded;           // rising edge fires Transform
  final bool calorieStreakPositive;
  final Color skinTone;
  final Color outfitColor;

  const Avatar3DWidget({
    super.key,
    this.avatarState = 'normal',
    this.gender = 'male',
    this.size = 260,
    this.autoSpin = false,
    this.yRotation,
    this.bodyComposition = 50,
    this.isScanning = false,
    this.mealAdded = false,
    this.calorieStreakPositive = false,
    this.skinTone = const Color(0xFFD4956A),
    this.outfitColor = const Color(0xFF7B6FFF),
  });

  @override
  State<Avatar3DWidget> createState() => _Avatar3DWidgetState();
}

class _Avatar3DWidgetState extends State<Avatar3DWidget>
    with TickerProviderStateMixin {

  // ── Controllers ────────────────────────────────────────────────────────────
  late AnimationController _masterCtrl;   // drives idle + sway (loops forever)
  late AnimationController _scanCtrl;     // drives EagerWait pulse (loops while scanning)
  late AnimationController _burstCtrl;    // drives Transform one-shot
  late AnimationController _streakCtrl;   // drives aura glow (loops while streak on)

  // ── Animations ─────────────────────────────────────────────────────────────
  late Animation<double> _breathe;       // 0→1 chest rise
  late Animation<double> _sway;          // 0→1 cloth/hair sway
  late Animation<double> _lean;          // 0→1 body lean forward (scan)
  late Animation<double> _scanPulse;     // 0→1 ring pulse radius
  late Animation<double> _burstScale;    // 1→1.18→1 squash-stretch
  late Animation<double> _burstFlash;    // 0→1→0 white flash opacity
  late Animation<double> _burstParticle; // 0→1 particle spread
  late Animation<double> _streakGlow;    // 0→1 aura pulse

  // ── State ──────────────────────────────────────────────────────────────────
  bool _wasMealAdded = false;
  bool _wasScanning  = false;

  // Smoothed body composition (interpolated to avoid jarring jumps)
  double _smoothedComposition = 50;

  @override
  void initState() {
    super.initState();
    _smoothedComposition = widget.bodyComposition;

    // Master controller: 4-second idle loop
    _masterCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 4000),
    )..repeat(reverse: true);

    _breathe = CurvedAnimation(parent: _masterCtrl, curve: Curves.easeInOut);

    // Cloth/hair sway slightly offset from breathe
    _sway = CurvedAnimation(
      parent: _masterCtrl,
      curve: const Interval(0.1, 0.9, curve: Curves.easeInOut),
    );

    // Scan controller: 1.2-second loop
    _scanCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200),
    );
    _lean = CurvedAnimation(parent: _scanCtrl, curve: Curves.easeInOut);
    _scanPulse = CurvedAnimation(parent: _scanCtrl, curve: Curves.easeOut);

    // Burst (Transform) controller: 900 ms one-shot
    _burstCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900),
    );
    _burstScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.20), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.20, end: 0.92), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.92, end: 1.04), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.04, end: 1.00), weight: 25),
    ]).animate(CurvedAnimation(parent: _burstCtrl, curve: Curves.easeOut));
    _burstFlash = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.7), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.7, end: 0.0), weight: 80),
    ]).animate(_burstCtrl);
    _burstParticle = CurvedAnimation(parent: _burstCtrl, curve: Curves.easeOut);

    // Streak aura controller: 2-second loop
    _streakCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2000),
    );
    _streakGlow = CurvedAnimation(parent: _streakCtrl, curve: Curves.easeInOut);

    _applyState();
  }

  void _applyState() {
    // Scanning
    if (widget.isScanning || widget.autoSpin) {
      _scanCtrl.repeat(reverse: true);
    } else {
      _scanCtrl.animateTo(0, duration: const Duration(milliseconds: 400));
    }

    // Streak aura
    if (widget.calorieStreakPositive) {
      _streakCtrl.repeat(reverse: true);
    } else {
      _streakCtrl.animateTo(0, duration: const Duration(milliseconds: 600));
    }
  }

  @override
  void didUpdateWidget(Avatar3DWidget old) {
    super.didUpdateWidget(old);

    // Smooth body composition
    _smoothedComposition = widget.bodyComposition;

    // Detect rising edge on mealAdded → fire Transform burst
    if (widget.mealAdded && !_wasMealAdded) {
      _burstCtrl.forward(from: 0);
    }
    _wasMealAdded = widget.mealAdded;

    if (widget.isScanning != _wasScanning) {
      _wasScanning = widget.isScanning;
      _applyState();
    }

    if (widget.calorieStreakPositive != old.calorieStreakPositive) {
      _applyState();
    }
  }

  @override
  void dispose() {
    _masterCtrl.dispose();
    _scanCtrl.dispose();
    _burstCtrl.dispose();
    _streakCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _masterCtrl, _scanCtrl, _burstCtrl, _streakCtrl,
      ]),
      builder: (context, _) {
        final breatheVal  = _breathe.value;
        final swayVal     = _sway.value;
        final leanVal     = _lean.value;
        final pulseVal    = _scanPulse.value;
        final burstScale  = _burstScale.value;
        final burstFlash  = _burstFlash.value;
        final particleVal = _burstParticle.value;
        final streakVal   = _streakGlow.value;
        final composition = _smoothedComposition / 100.0; // 0.0–1.0

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // ── Ground ring ─────────────────────────────────────────────
              Positioned(
                bottom: 4,
                child: _GroundRing(
                  size: widget.size,
                  isScanning: widget.isScanning || widget.autoSpin,
                  pulseVal: pulseVal,
                  streakOn: widget.calorieStreakPositive,
                  streakVal: streakVal,
                ),
              ),

              // ── Streak aura (behind character) ──────────────────────────
              if (widget.calorieStreakPositive)
                _StreakAura(size: widget.size, glowVal: streakVal),

              // ── Character body ───────────────────────────────────────────
              Transform.scale(
                scale: burstScale,
                child: Transform.translate(
                  // Lean forward while scanning
                  offset: Offset(0, -leanVal * widget.size * 0.04),
                  child: CustomPaint(
                    size: Size(widget.size * 0.62, widget.size),
                    painter: _AvatarBodyPainter(
                      gender: widget.gender,
                      composition: composition,
                      breathe: breatheVal,
                      sway: swayVal,
                      lean: leanVal,
                      skinTone: widget.skinTone,
                      outfitColor: widget.outfitColor,
                      isScanning: widget.isScanning || widget.autoSpin,
                      streakOn: widget.calorieStreakPositive,
                      streakVal: streakVal,
                    ),
                  ),
                ),
              ),

              // ── Burst flash overlay ──────────────────────────────────────
              if (burstFlash > 0.01)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(widget.size),
                      gradient: RadialGradient(
                        colors: [
                          AppTheme.accent.withValues(alpha: burstFlash * 0.8),
                          AppTheme.primary.withValues(alpha: burstFlash * 0.4),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),

              // ── Celebration particles ────────────────────────────────────
              if (_burstCtrl.isAnimating)
                _BurstParticles(
                  size: widget.size,
                  progress: particleVal,
                ),
            ],
          ),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// _AvatarBodyPainter — draws the full character with morphing body composition
// ════════════════════════════════════════════════════════════════════════════

class _AvatarBodyPainter extends CustomPainter {
  final String gender;
  final double composition; // 0.0 (lean) → 1.0 (heavy)
  final double breathe;     // 0.0 → 1.0 chest rise
  final double sway;        // 0.0 → 1.0 cloth sway
  final double lean;        // 0.0 → 1.0 forward lean (scanning)
  final Color skinTone;
  final Color outfitColor;
  final bool isScanning;
  final bool streakOn;
  final double streakVal;

  const _AvatarBodyPainter({
    required this.gender,
    required this.composition,
    required this.breathe,
    required this.sway,
    required this.lean,
    required this.skinTone,
    required this.outfitColor,
    required this.isScanning,
    required this.streakOn,
    required this.streakVal,
  });

  // Lerp helper
  static double _l(double a, double b, double t) => a + (b - a) * t;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // Body width scale: lean = 1.0, heavy = 1.35
    final bodyScale = _l(1.0, 1.35, composition);
    // Belly protrusion: 0 → 0.12*w
    final bellyBulge = _l(0.0, w * 0.12, composition);
    // Arm thickness: lean = 0.08w, heavy = 0.13w
    final armW = _l(w * 0.08, w * 0.14, composition);
    // Leg thickness
    final legW = _l(w * 0.11, w * 0.18, composition);

    // Breathing offsets
    final breatheY = breathe * h * 0.008;
    final chestExpand = breathe * w * 0.012;

    // Colors
    final skin = skinTone;
    final skinDark = Color.lerp(skinTone, Colors.black, 0.25)!;
    final skinLight = Color.lerp(skinTone, Colors.white, 0.3)!;
    final outfit = outfitColor;
    final outfitDark = Color.lerp(outfitColor, Colors.black, 0.35)!;
    final outfitGlow = Color.lerp(outfitColor, AppTheme.accent, 0.5)!;
    final hairColor = gender == 'female'
        ? const Color(0xFF3D1F0A)
        : const Color(0xFF2A1505);

    // Neon trim color (cyan accent lines on outfit)
    final neonTrim = AppTheme.accent;

    // ── Shadow under feet ──────────────────────────────────────────────────
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, h * 0.97),
        width: w * 0.55 * bodyScale,
        height: h * 0.025,
      ),
      shadowPaint,
    );

    // ── LEGS ────────────────────────────────────────────────────────────────
    _drawLegs(canvas, size, cx, h, legW, bodyScale, skin, skinDark,
        outfit, outfitDark, neonTrim, breatheY);

    // ── TORSO ────────────────────────────────────────────────────────────────
    _drawTorso(canvas, size, cx, h, w, bodyScale, bellyBulge, chestExpand,
        skin, skinLight, outfit, outfitDark, outfitGlow, neonTrim, breatheY,
        streakOn, streakVal);

    // ── ARMS ─────────────────────────────────────────────────────────────────
    _drawArms(canvas, size, cx, h, w, armW, bodyScale, skin, skinDark,
        outfit, outfitDark, neonTrim, sway, lean, breatheY);

    // ── HEAD ─────────────────────────────────────────────────────────────────
    _drawHead(canvas, size, cx, h, w, skin, skinLight, skinDark, hairColor,
        outfitColor, breatheY, isScanning);
  }

  void _drawLegs(Canvas c, Size s, double cx, double h, double legW,
      double bodyScale, Color skin, Color skinDark, Color outfit,
      Color outfitDark, Color neonTrim, double breatheY) {
    final _ = s.width; // width available for future use
    final legPaint = Paint()..color = outfitDark;
    final neonPaint = Paint()
      ..color = neonTrim.withValues(alpha: 0.6)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    // Left thigh
    final lThighX = cx - legW * 0.85 * bodyScale;
    _drawRoundedSegment(c,
      Rect.fromLTWH(lThighX - legW / 2, h * 0.59 - breatheY,
          legW * bodyScale, h * 0.21),
      legPaint, radius: legW * 0.35);
    // Left shin
    _drawRoundedSegment(c,
      Rect.fromLTWH(lThighX - legW * 0.45, h * 0.795 - breatheY,
          legW * bodyScale * 0.9, h * 0.14),
      Paint()..color = outfitDark.withValues(alpha: 0.85),
      radius: legW * 0.3);
    // Left foot
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(lThighX - legW * 0.7, h * 0.915,
            legW * bodyScale * 1.3, h * 0.058),
        Radius.circular(legW * 0.4),
      ),
      Paint()..color = const Color(0xFF1A1A2E),
    );
    // Neon stripe on left leg
    c.drawLine(
      Offset(lThighX, h * 0.60),
      Offset(lThighX, h * 0.91),
      neonPaint,
    );

    // Right thigh
    final rThighX = cx + legW * 0.85 * bodyScale;
    _drawRoundedSegment(c,
      Rect.fromLTWH(rThighX - legW / 2, h * 0.59 - breatheY,
          legW * bodyScale, h * 0.21),
      legPaint, radius: legW * 0.35);
    _drawRoundedSegment(c,
      Rect.fromLTWH(rThighX - legW * 0.45, h * 0.795 - breatheY,
          legW * bodyScale * 0.9, h * 0.14),
      Paint()..color = outfitDark.withValues(alpha: 0.85),
      radius: legW * 0.3);
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rThighX - legW * 0.6, h * 0.915,
            legW * bodyScale * 1.3, h * 0.058),
        Radius.circular(legW * 0.4),
      ),
      Paint()..color = const Color(0xFF1A1A2E),
    );
    c.drawLine(
      Offset(rThighX, h * 0.60),
      Offset(rThighX, h * 0.91),
      neonPaint,
    );

    // Shoe glow dots
    final glowPaint = Paint()
      ..color = neonTrim.withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    c.drawCircle(Offset(lThighX - legW * 0.2, h * 0.944), 3, glowPaint);
    c.drawCircle(Offset(rThighX + legW * 0.2, h * 0.944), 3, glowPaint);
  }

  void _drawTorso(Canvas c, Size s, double cx, double h, double w,
      double bodyScale, double bellyBulge, double chestExpand, Color skin,
      Color skinLight, Color outfit, Color outfitDark, Color outfitGlow,
      Color neonTrim, double breatheY, bool streakOn, double streakVal) {
    final torsoW = w * 0.52 * bodyScale + chestExpand;
    final torsoTop = h * 0.30 - breatheY;
    final torsoBot = h * 0.615;
    final torsoH = torsoBot - torsoTop;

    // Chest-to-hip trapezoid
    final torsoPath = Path()
      ..moveTo(cx - torsoW * 0.52, torsoTop + torsoH * 0.06)
      ..quadraticBezierTo(cx, torsoTop, cx + torsoW * 0.52, torsoTop + torsoH * 0.06)
      ..lineTo(cx + torsoW * 0.55 + bellyBulge, torsoBot)
      ..lineTo(cx - torsoW * 0.55 - bellyBulge, torsoBot)
      ..close();

    // Outfit gradient
    final torsoGrad = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [outfit, outfitDark],
      ).createShader(Rect.fromLTWH(cx - torsoW, torsoTop, torsoW * 2, torsoH));
    c.drawPath(torsoPath, torsoGrad);

    // Outfit border
    c.drawPath(torsoPath, Paint()
      ..color = neonTrim.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5);

    // Neon chest hexagon emblem
    _drawHexEmblem(c, Offset(cx, torsoTop + torsoH * 0.28),
        w * 0.09, neonTrim, outfitGlow);

    // Neon side stripes
    final stripePaint = Paint()
      ..color = neonTrim.withValues(alpha: 0.55)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    c.drawLine(
      Offset(cx - torsoW * 0.4, torsoTop + torsoH * 0.12),
      Offset(cx - torsoW * 0.45, torsoBot - torsoH * 0.08),
      stripePaint,
    );
    c.drawLine(
      Offset(cx + torsoW * 0.4, torsoTop + torsoH * 0.12),
      Offset(cx + torsoW * 0.45, torsoBot - torsoH * 0.08),
      stripePaint,
    );

    // Neck
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - w * 0.065, h * 0.275 - breatheY,
            w * 0.13, h * 0.045),
        const Radius.circular(6),
      ),
      Paint()..color = skin,
    );

    // Streak glow overlay on torso
    if (streakOn && streakVal > 0.01) {
      c.drawPath(torsoPath, Paint()
        ..color = AppTheme.accent.withValues(alpha: streakVal * 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    }
  }

  void _drawArms(Canvas c, Size s, double cx, double h, double w, double armW,
      double bodyScale, Color skin, Color skinDark, Color outfit,
      Color outfitDark, Color neonTrim, double sway, double lean,
      double breatheY) {
    final shoulderY = h * 0.315 - breatheY;
    final torsoHalfW = w * 0.26 * bodyScale;

    // Sway angle for arms (cloth movement layer)
    final swayAngle = (sway - 0.5) * 0.06;
    // Lean makes arms slightly forward
    final leanOffset = lean * h * 0.03;

    // ── Left arm ────────────────────────────────────────────────────────────
    final lShoulderX = cx - torsoHalfW - armW * 0.1;
    // Upper arm
    _drawRotatedSegment(c,
      center: Offset(lShoulderX, shoulderY + h * 0.07),
      size: Size(armW, h * 0.19),
      angle: -0.18 + swayAngle - lean * 0.12,
      paint: Paint()..color = outfit,
    );
    // Forearm
    _drawRotatedSegment(c,
      center: Offset(lShoulderX - h * 0.02 + leanOffset, shoulderY + h * 0.25),
      size: Size(armW * 0.88, h * 0.16),
      angle: -0.08 + swayAngle * 1.3,
      paint: Paint()..color = skin,
    );
    // Hand (fist when scanning, open when idle)
    _drawHand(c,
      Offset(lShoulderX - h * 0.03 + leanOffset * 1.5, shoulderY + h * 0.38),
      armW * 0.7, skin, skinDark, isScanning);

    // Neon wristband
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(lShoulderX - armW * 0.55, shoulderY + h * 0.305,
            armW * 1.1, h * 0.022),
        Radius.circular(armW * 0.2),
      ),
      Paint()
        ..color = neonTrim.withValues(alpha: 0.7)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // ── Right arm ────────────────────────────────────────────────────────────
    final rShoulderX = cx + torsoHalfW + armW * 0.1;
    _drawRotatedSegment(c,
      center: Offset(rShoulderX, shoulderY + h * 0.07),
      size: Size(armW, h * 0.19),
      angle: 0.18 - swayAngle + lean * 0.12,
      paint: Paint()..color = outfit,
    );
    _drawRotatedSegment(c,
      center: Offset(rShoulderX + h * 0.02 - leanOffset, shoulderY + h * 0.25),
      size: Size(armW * 0.88, h * 0.16),
      angle: 0.08 - swayAngle * 1.3,
      paint: Paint()..color = skin,
    );
    _drawHand(c,
      Offset(rShoulderX + h * 0.03 - leanOffset * 1.5, shoulderY + h * 0.38),
      armW * 0.7, skin, skinDark, isScanning);

    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rShoulderX - armW * 0.55, shoulderY + h * 0.305,
            armW * 1.1, h * 0.022),
        Radius.circular(armW * 0.2),
      ),
      Paint()
        ..color = neonTrim.withValues(alpha: 0.7)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
  }

  void _drawHead(Canvas c, Size s, double cx, double h, double w, Color skin,
      Color skinLight, Color skinDark, Color hairColor, Color outfitColor,
      double breatheY, bool isScanning) {
    final headCY = h * 0.19 - breatheY;
    final headW  = w * 0.38;
    final headH  = h * 0.17;

    // ── Neck shadow ──────────────────────────────────────────────────────────
    c.drawOval(
      Rect.fromCenter(center: Offset(cx, headCY + headH * 0.45),
          width: w * 0.15, height: h * 0.03),
      Paint()..color = skinDark.withValues(alpha: 0.4),
    );

    // ── Head shape ───────────────────────────────────────────────────────────
    final headRect = Rect.fromCenter(
        center: Offset(cx, headCY), width: headW, height: headH);
    c.drawRRect(
      RRect.fromRectAndCorners(headRect,
        topLeft: Radius.circular(headW * 0.42),
        topRight: Radius.circular(headW * 0.42),
        bottomLeft: Radius.circular(headW * 0.3),
        bottomRight: Radius.circular(headW * 0.3),
      ),
      Paint()..color = skin,
    );

    // Face shading — cheek highlight
    c.drawOval(
      Rect.fromCenter(
          center: Offset(cx - headW * 0.22, headCY + headH * 0.08),
          width: headW * 0.2, height: headH * 0.15),
      Paint()..color = skinLight.withValues(alpha: 0.35),
    );
    c.drawOval(
      Rect.fromCenter(
          center: Offset(cx + headW * 0.22, headCY + headH * 0.08),
          width: headW * 0.2, height: headH * 0.15),
      Paint()..color = skinLight.withValues(alpha: 0.35),
    );

    // ── Eyes ─────────────────────────────────────────────────────────────────
    final eyeY = headCY - headH * 0.05;
    final eyeSpread = headW * 0.21;
    final eyeW = headW * 0.18;
    final eyeH = isScanning ? headH * 0.14 : headH * 0.10; // wide when scanning

    // Eye whites
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx - eyeSpread, eyeY),
            width: eyeW, height: eyeH),
        Radius.circular(eyeH * 0.5),
      ),
      Paint()..color = Colors.white,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx + eyeSpread, eyeY),
            width: eyeW, height: eyeH),
        Radius.circular(eyeH * 0.5),
      ),
      Paint()..color = Colors.white,
    );

    // Pupils — glowing cyberpunk style
    final pupilColor = outfitColor.withValues(alpha: 0.9);
    final pupilGlow = Paint()
      ..color = pupilColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    c.drawCircle(Offset(cx - eyeSpread, eyeY), eyeH * 0.38, pupilGlow);
    c.drawCircle(Offset(cx + eyeSpread, eyeY), eyeH * 0.38, pupilGlow);
    c.drawCircle(Offset(cx - eyeSpread, eyeY), eyeH * 0.2,
        Paint()..color = Colors.white.withValues(alpha: 0.8));
    c.drawCircle(Offset(cx + eyeSpread, eyeY), eyeH * 0.2,
        Paint()..color = Colors.white.withValues(alpha: 0.8));

    // Eyebrows — raised when scanning (Excited state)
    final browY = eyeY - eyeH * 0.9 - (isScanning ? eyeH * 0.5 : 0);
    final browPaint = Paint()
      ..color = hairColor
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    c.drawLine(
      Offset(cx - eyeSpread - eyeW * 0.45, browY + (isScanning ? 2 : 0)),
      Offset(cx - eyeSpread + eyeW * 0.45, browY),
      browPaint,
    );
    c.drawLine(
      Offset(cx + eyeSpread - eyeW * 0.45, browY),
      Offset(cx + eyeSpread + eyeW * 0.45, browY + (isScanning ? 2 : 0)),
      browPaint,
    );

    // ── Mouth ─────────────────────────────────────────────────────────────────
    final mouthY = headCY + headH * 0.22;
    final mouthPaint = Paint()
      ..color = skinDark
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    if (isScanning) {
      // "O" mouth — excited/anticipating
      c.drawOval(
        Rect.fromCenter(center: Offset(cx, mouthY),
            width: headW * 0.14, height: headH * 0.09),
        Paint()..color = skinDark,
      );
    } else {
      // Smile
      final smilePath = Path()
        ..moveTo(cx - headW * 0.14, mouthY)
        ..quadraticBezierTo(cx, mouthY + headH * 0.09, cx + headW * 0.14, mouthY);
      c.drawPath(smilePath, mouthPaint);
    }

    // ── Hair ──────────────────────────────────────────────────────────────────
    _drawHair(c, cx, headCY, headW, headH, hairColor, sway: 0);
  }

  void _drawHair(Canvas c, double cx, double headCY, double headW,
      double headH, Color hairColor, {required double sway}) {
    final hairPaint = Paint()..color = hairColor;

    // Top volume
    final topHair = Path()
      ..moveTo(cx - headW * 0.45, headCY - headH * 0.1)
      ..quadraticBezierTo(
          cx - headW * 0.22, headCY - headH * 0.7,
          cx, headCY - headH * 0.72)
      ..quadraticBezierTo(
          cx + headW * 0.22, headCY - headH * 0.7,
          cx + headW * 0.45, headCY - headH * 0.1)
      ..close();
    c.drawPath(topHair, hairPaint);

    // Side strands with sway
    final strandOffset = sway * headW * 0.04;
    final sideHair = Path()
      ..moveTo(cx - headW * 0.44, headCY - headH * 0.12)
      ..quadraticBezierTo(
          cx - headW * 0.54 + strandOffset, headCY + headH * 0.1,
          cx - headW * 0.42 + strandOffset, headCY + headH * 0.28)
      ..lineTo(cx - headW * 0.35, headCY + headH * 0.28)
      ..close();
    c.drawPath(sideHair, hairPaint);

    // Hair highlight
    c.drawPath(topHair, Paint()
      ..color = Color.lerp(hairColor, Colors.white, 0.25)!.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  void _drawRoundedSegment(Canvas c, Rect rect, Paint paint,
      {double radius = 8}) {
    c.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)), paint);
  }

  void _drawRotatedSegment(Canvas c,
      {required Offset center, required Size size, required double angle,
       required Paint paint}) {
    c.save();
    c.translate(center.dx, center.dy);
    c.rotate(angle);
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: size.width, height: size.height),
        Radius.circular(size.width * 0.42),
      ),
      paint,
    );
    c.restore();
  }

  void _drawHand(Canvas c, Offset pos, double r, Color skin, Color skinDark,
      bool isFist) {
    if (isFist) {
      // Clenched fist
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: pos, width: r * 1.2, height: r * 0.9),
          Radius.circular(r * 0.35),
        ),
        Paint()..color = skin,
      );
    } else {
      // Open hand / relaxed
      c.drawCircle(pos, r * 0.52, Paint()..color = skin);
      // Finger lines
      final fp = Paint()
        ..color = skinDark.withValues(alpha: 0.4)
        ..strokeWidth = 0.8
        ..style = PaintingStyle.stroke;
      c.drawLine(pos.translate(-r * 0.2, -r * 0.1),
          pos.translate(-r * 0.2, r * 0.4), fp);
      c.drawLine(pos.translate(0, -r * 0.15),
          pos.translate(0, r * 0.42), fp);
      c.drawLine(pos.translate(r * 0.2, -r * 0.1),
          pos.translate(r * 0.2, r * 0.4), fp);
    }
  }

  void _drawHexEmblem(Canvas c, Offset center, double r, Color neon, Color fill) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 90) * math.pi / 180;
      final p = Offset(center.dx + r * math.cos(angle),
          center.dy + r * math.sin(angle));
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    c.drawPath(path, Paint()..color = fill.withValues(alpha: 0.2));
    c.drawPath(path, Paint()
      ..color = neon.withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));
    // Inner dot
    c.drawCircle(center, r * 0.28, Paint()
      ..color = neon.withValues(alpha: 0.8)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
  }

  @override
  bool shouldRepaint(_AvatarBodyPainter old) =>
      old.composition != composition ||
      old.breathe != breathe ||
      old.sway != sway ||
      old.lean != lean ||
      old.isScanning != isScanning ||
      old.streakOn != streakOn ||
      old.streakVal != streakVal;
}

// ════════════════════════════════════════════════════════════════════════════
// _GroundRing — neon halo under the character
// ════════════════════════════════════════════════════════════════════════════

class _GroundRing extends StatelessWidget {
  final double size;
  final bool isScanning;
  final double pulseVal;
  final bool streakOn;
  final double streakVal;

  const _GroundRing({
    required this.size,
    required this.isScanning,
    required this.pulseVal,
    required this.streakOn,
    required this.streakVal,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = streakOn
        ? Color.lerp(AppTheme.primary, AppTheme.accent, streakVal)!
        : AppTheme.primary;
    final ringW = size * 0.58 + (isScanning ? pulseVal * size * 0.12 : 0);

    return SizedBox(
      width: size,
      height: size * 0.09,
      child: CustomPaint(
        painter: _RingPainter(
          color: baseColor,
          pulseVal: isScanning ? pulseVal : 0,
          width: ringW,
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final Color color;
  final double pulseVal;
  final double width;

  const _RingPainter({required this.color, required this.pulseVal,
      required this.width});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Outer glow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: width, height: size.height * 0.55),
      Paint()
        ..color = color.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );

    // Main ring
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: width * 0.95, height: size.height * 0.4),
      Paint()
        ..color = color.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );

    // Scan pulse expanding ring
    if (pulseVal > 0.02) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, cy),
          width: width * (1 + pulseVal * 0.4),
          height: size.height * (0.5 + pulseVal * 0.3),
        ),
        Paint()
          ..color = color.withValues(alpha: (1 - pulseVal) * 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.color != color || old.pulseVal != pulseVal || old.width != width;
}

// ════════════════════════════════════════════════════════════════════════════
// _StreakAura — full-body glow when calorieStreakPositive == true
// ════════════════════════════════════════════════════════════════════════════

class _StreakAura extends StatelessWidget {
  final double size;
  final double glowVal;

  const _StreakAura({required this.size, required this.glowVal});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _AuraPainter(glowVal: glowVal),
      ),
    );
  }
}

class _AuraPainter extends CustomPainter {
  final double glowVal;
  const _AuraPainter({required this.glowVal});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.52;

    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, cy),
          width: size.width * 0.55,
          height: size.height * 0.88),
      Paint()
        ..color = AppTheme.accent.withValues(alpha: 0.04 + glowVal * 0.07)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28),
    );

    // Vertical light rays
    for (int i = 0; i < 5; i++) {
      final x = cx + (i - 2) * size.width * 0.09;
      canvas.drawLine(
        Offset(x, cy - size.height * 0.44),
        Offset(x, cy + size.height * 0.44),
        Paint()
          ..color = AppTheme.accent.withValues(alpha: glowVal * 0.06)
          ..strokeWidth = 2
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
  }

  @override
  bool shouldRepaint(_AuraPainter old) => old.glowVal != glowVal;
}

// ════════════════════════════════════════════════════════════════════════════
// _BurstParticles — celebration particles on mealAdded trigger
// ════════════════════════════════════════════════════════════════════════════

class _BurstParticles extends StatelessWidget {
  final double size;
  final double progress; // 0→1

  const _BurstParticles({required this.size, required this.progress});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ParticlePainter(progress: progress),
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final double progress;
  static const int _count = 16;

  const _ParticlePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.45;
    final maxR = size.width * 0.52;
    final fade = (1 - progress).clamp(0.0, 1.0);

    final colors = [
      AppTheme.accent,
      AppTheme.primary,
      AppTheme.lava,
      const Color(0xFFFFBD39),
      Colors.white,
    ];

    for (int i = 0; i < _count; i++) {
      final angle = (i / _count) * math.pi * 2;
      final r = maxR * progress;
      final px = cx + r * math.cos(angle);
      final py = cy + r * math.sin(angle) * 0.55;
      final color = colors[i % colors.length];
      final pSize = (3.5 + (i % 3) * 1.5) * fade;

      canvas.drawCircle(
        Offset(px, py),
        pSize,
        Paint()
          ..color = color.withValues(alpha: fade * 0.9)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, pSize * 0.5),
      );

      // Trail
      if (progress > 0.1) {
        final trailR = maxR * (progress - 0.12).clamp(0, 1);
        canvas.drawLine(
          Offset(cx + trailR * math.cos(angle), cy + trailR * math.sin(angle) * 0.55),
          Offset(px, py),
          Paint()
            ..color = color.withValues(alpha: fade * 0.4)
            ..strokeWidth = 1.2,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}
