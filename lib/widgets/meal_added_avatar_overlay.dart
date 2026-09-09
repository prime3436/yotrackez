import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/user_settings.dart';
import '../services/meal_db_service.dart';
import '../services/sound_service.dart';
import '../services/step_counter_service.dart';
import '../services/calorie_body_service.dart';
import '../theme/app_theme.dart';
import 'particle_system.dart';
import 'super_saiyan_aura.dart';
import 'yo_avatar_widget.dart';

/// Cinematic full-screen overlay shown every time a meal is stored.
/// Features:
///  - Screen-space particle explosion
///  - 3D spinning/tumbling avatar reveal
///  - Super Saiyan aura blast
///  - Weight-level morph with before/after 3D character switch
///  - Calorie burst HUD
///  - Ring-pulse shockwave
class MealAddedAvatarOverlay extends StatefulWidget {
  final String foodName;
  final double calories;
  final VoidCallback? onDismissed;

  const MealAddedAvatarOverlay({
    super.key,
    required this.foodName,
    required this.calories,
    this.onDismissed,
  });

  /// Static helper to trigger the pop-up overlay anywhere.
  static Future<void> show(
    BuildContext context, {
    required String foodName,
    required double calories,
  }) async {
    await showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.88),
      barrierDismissible: true,
      builder: (ctx) => MealAddedAvatarOverlay(
        foodName: foodName,
        calories: calories,
      ),
    );
  }

  @override
  State<MealAddedAvatarOverlay> createState() => _MealAddedAvatarOverlayState();
}

class _MealAddedAvatarOverlayState extends State<MealAddedAvatarOverlay>
    with TickerProviderStateMixin {

  // ─── Shared state ─────────────────────────────────────────────────────────
  double _caloriesEaten = 0;
  String _previousState = 'normal';
  String _currentState = 'normal';

  // ─── Animation phases ──────────────────────────────────────────────────────
  bool _showParticles = false;
  bool _showCard = false;
  bool _showAura = false;
  bool _morphed = false;
  bool _flash = false;
  bool _showShockwave = false;

  // ─── 3D spin controller ────────────────────────────────────────────────────
  late AnimationController _spinController;
  late AnimationController _shockwaveController;
  late AnimationController _cardEntryController;
  late Animation<double> _cardSlide;
  late Animation<double> _cardFade;

  @override
  void initState() {
    super.initState();

    // 3D hero spin: 0→2π in 1.2 s, then settles into slow drift
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Shockwave ring expands from centre
    _shockwaveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    // Card slide-up from bottom
    _cardEntryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _cardSlide = Tween<double>(begin: 80, end: 0).animate(
      CurvedAnimation(parent: _cardEntryController, curve: Curves.easeOutBack),
    );
    _cardFade = CurvedAnimation(parent: _cardEntryController, curve: Curves.easeOut);

    _startSequence();
  }

  @override
  void dispose() {
    _spinController.dispose();
    _shockwaveController.dispose();
    _cardEntryController.dispose();
    super.dispose();
  }

  Future<void> _startSequence() async {
    // Load data first
    final totals = await MealDbService.instance.getDayTotals(DateTime.now());
    final burned = StepCounterService.instance.caloriesBurned;
    final eaten = totals['calories'] ?? 0.0;
    final net = eaten - burned;
    final prevNet = (eaten - widget.calories) - burned;
    final prevState = UserSettings.instance.getAvatarState(prevNet);
    final currState = UserSettings.instance.getAvatarState(net);

    if (!mounted) return;
    setState(() {
      _caloriesEaten = eaten;
      _previousState = prevState;
      _currentState = currState;
    });

    // ── PHASE 1: Sound + Particles burst (t=0) ─────────────────────────────
    SoundService.instance.playMealLogged();
    setState(() {
      _showParticles = true;
      _showShockwave = true;
    });
    _shockwaveController.forward();

    await Future.delayed(const Duration(milliseconds: 150));

    // ── PHASE 2: Screen flash (t=150ms) ────────────────────────────────────
    if (!mounted) return;
    setState(() => _flash = true);
    await Future.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;
    setState(() => _flash = false);

    // ── PHASE 3: 3D Avatar spins into view (t=270ms) ───────────────────────
    if (!mounted) return;
    setState(() => _showAura = true);
    _spinController.forward();

    await Future.delayed(const Duration(milliseconds: 300));

    // ── PHASE 4: Card slides up (t=570ms) ──────────────────────────────────
    if (!mounted) return;
    setState(() => _showCard = true);
    _cardEntryController.forward();

    await Future.delayed(const Duration(milliseconds: 700));

    // ── PHASE 5: Avatar morphs to new state (t=1270ms) ─────────────────────
    if (!mounted) return;
    setState(() => _morphed = true);
    if (prevState != currState) {
      SoundService.instance.playPowerUp();
    }

    // ── PHASE 6: Avatar drifts in slow spin indefinitely ──────────────────
    _spinController
      ..stop()
      ..duration = const Duration(seconds: 4)
      ..repeat();

    // ── PHASE 7: Auto-dismiss after 5s (safety net) ────────────────────────
    await Future.delayed(const Duration(seconds: 5));
    if (mounted) {
      Navigator.of(context).pop();
      widget.onDismissed?.call();
    }
  }

  Color get _moodColor {
    final s = _morphed ? _currentState : _previousState;
    switch (s) {
      case 'very_fit':   return AppTheme.fiberGreen;
      case 'fit':        return AppTheme.primary;
      case 'normal':     return AppTheme.accent;
      case 'chubby':     return AppTheme.calorieOrange;
      case 'overweight': return AppTheme.error;
      default:           return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final _ = UserSettings.instance.gender; // reserved for gender-specific avatar art
    final activeState = _morphed ? _currentState : _previousState;
    final stateChanged = _previousState != _currentState && _morphed;
    final label = UserSettings.instance.getAvatarLabel(activeState);

    return Stack(
      children: [

        // ── Particle Explosion ──────────────────────────────────────────────
        if (_showParticles)
          Center(
            child: ParticleSystem(
              baseColor: _moodColor,
              count: 48,
              size: MediaQuery.of(context).size.width,
            ),
          ),

        // ── Shockwave ring ──────────────────────────────────────────────────
        if (_showShockwave)
          Center(
            child: AnimatedBuilder(
              animation: _shockwaveController,
              builder: (ctx, child) {
                final t = Curves.easeOut.transform(_shockwaveController.value);
                final radius = t * MediaQuery.of(context).size.width * 0.8;
                final opacity = (1 - t).clamp(0.0, 1.0);
                return CustomPaint(
                  size: const Size(double.infinity, double.infinity),
                  painter: _ShockwavePainter(
                    radius: radius,
                    color: _moodColor.withValues(alpha: opacity * 0.7),
                  ),
                );
              },
            ),
          ),

        // ── Full-screen white flash ─────────────────────────────────────────
        if (_flash)
          Positioned.fill(
            child: Container(color: Colors.white.withValues(alpha: 0.82))
                .animate()
                .fadeOut(duration: 200.ms),
          ),

        // ── Main content ────────────────────────────────────────────────────
        Center(
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  // ── 3D Avatar hero area ───────────────────────────────────
                  SizedBox(
                    width: 300,
                    height: 300,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Super Saiyan aura backdrop
                        SuperSaiyanAura(
                          size: 300,
                          color: stateChanged ? AppTheme.calorieOrange : _moodColor,
                          isActive: _showAura,
                        ),

                        // Rive avatar — fires mealAdded trigger, uses real bodyComposition
                        YoAvatarWidget(
                          gender: UserSettings.instance.gender,
                          size: 220,
                          bodyComposition:
                              CalorieBodyService.instance.bodyComposition,
                          mealAdded: _showAura,
                        ),

                        // Food projectile flies into avatar's chest
                        _FoodProjectile(
                          calories: widget.calories,
                          moodColor: _moodColor,
                        ),

                        // Floating kcal badge
                        Positioned(
                          top: 8,
                          right: 8,
                          child: _CalorieBadge(calories: widget.calories),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ── Info card slides up ───────────────────────────────────
                  if (_showCard)
                    AnimatedBuilder(
                      animation: _cardEntryController,
                      builder: (_, child) {
                        return Transform.translate(
                          offset: Offset(0, _cardSlide.value),
                          child: Opacity(opacity: _cardFade.value, child: child),
                        );
                      },
                      child: _InfoCard(
                        foodName: widget.foodName,
                        calories: widget.calories,
                        caloriesEaten: _caloriesEaten,
                        label: label,
                        moodColor: _moodColor,
                        stateChanged: stateChanged,
                        previousLabel: UserSettings.instance.getAvatarLabel(_previousState),
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Sub-widgets
// ════════════════════════════════════════════════════════════════════════════

class _FoodProjectile extends StatefulWidget {
  final double calories;
  final Color moodColor;
  const _FoodProjectile({required this.calories, required this.moodColor});
  @override
  State<_FoodProjectile> createState() => _FoodProjectileState();
}

class _FoodProjectileState extends State<_FoodProjectile>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _y;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))
      ..forward();
    _y = Tween<double>(begin: -100, end: 30).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInBack),
    );
    _opacity = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.7, 1.0)),
    );
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  String get _foodEmoji {
    if (widget.calories < 100) return '🥗';
    if (widget.calories < 300) return '🥪';
    if (widget.calories < 600) return '🍔';
    if (widget.calories < 900) return '🍕';
    return '🎂';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (ctx, child) => Transform.translate(
        offset: Offset(0, _y.value),
        child: Opacity(
          opacity: _opacity.value,
          child: Text(_foodEmoji, style: const TextStyle(fontSize: 38)),
        ),
      ),
    );
  }
}

class _CalorieBadge extends StatelessWidget {
  final double calories;
  const _CalorieBadge({required this.calories});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.calorieOrange,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppTheme.glowShadow(AppTheme.calorieOrange),
      ),
      child: Text(
        '+${calories.toStringAsFixed(0)} kcal 🍖',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 12,
          letterSpacing: 0.5,
        ),
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(begin: -4, end: 4, duration: 1.seconds)
        .fadeIn(delay: 300.ms);
  }
}

class _InfoCard extends StatelessWidget {
  final String foodName;
  final double calories;
  final double caloriesEaten;
  final String label;
  final Color moodColor;
  final bool stateChanged;
  final String previousLabel;
  final VoidCallback onTap;

  const _InfoCard({
    required this.foodName,
    required this.calories,
    required this.caloriesEaten,
    required this.label,
    required this.moodColor,
    required this.stateChanged,
    required this.previousLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: moodColor.withValues(alpha: 0.6), width: 2),
        boxShadow: [
          ...AppTheme.glowShadow(moodColor),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── MEAL LOGGED! title ─────────────────────────────────────────
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [moodColor, Colors.white],
            ).createShader(bounds),
            child: const Text(
              'MEAL LOGGED!',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
                fontSize: 24,
              ),
            ),
          ).animate().fadeIn().scale(begin: const Offset(0.7, 0.7)),

          const SizedBox(height: 6),

          Text(
            '$foodName · +${calories.toStringAsFixed(0)} cal',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textPrimary.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ).animate().fadeIn(delay: 100.ms),

          const SizedBox(height: 14),

          // ── Progress bar ────────────────────────────────────────────────
          _CalorieMeter(
            eaten: caloriesEaten,
            limit: UserSettings.instance.calorieLimit.toDouble(),
            color: moodColor,
          ),

          const SizedBox(height: 14),

          // ── Avatar state change tag ─────────────────────────────────────
          if (stateChanged)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.calorieOrange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.calorieOrange),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.trending_up_rounded, color: AppTheme.calorieOrange, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Avatar: $previousLabel ➔ $label',
                    style: const TextStyle(
                      color: AppTheme.calorieOrange,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().scale(),

          // ── AWESOME button ──────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: moodColor,
                foregroundColor: AppTheme.background,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 8,
                shadowColor: moodColor.withValues(alpha: 0.5),
              ),
              child: const Text(
                'AWESOME! 💪',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  fontSize: 15,
                ),
              ),
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),
        ],
      ),
    );
  }
}

class _CalorieMeter extends StatelessWidget {
  final double eaten;
  final double limit;
  final Color color;
  const _CalorieMeter({required this.eaten, required this.limit, required this.color});

  @override
  Widget build(BuildContext context) {
    final pct = limit > 0 ? (eaten / limit).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Today: ${eaten.toStringAsFixed(0)} kcal',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            Text(
              'Goal: ${limit.toStringAsFixed(0)} kcal',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 8,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(
              pct > 0.9 ? AppTheme.error : color,
            ),
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Shockwave ring painter
// ════════════════════════════════════════════════════════════════════════════

class _ShockwavePainter extends CustomPainter {
  final double radius;
  final Color color;
  const _ShockwavePainter({required this.radius, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _ShockwavePainter old) =>
      old.radius != radius || old.color != color;
}
