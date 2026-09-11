import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/meal_entry.dart';
import '../models/nutrition_data.dart';
import '../models/user_settings.dart';
import '../services/calorie_body_service.dart';
import '../services/meal_db_service.dart';
import '../services/streak_service.dart';
import '../services/water_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/diary_meal_card.dart';
import '../widgets/macro_ring_widget.dart';
import '../widgets/yo_avatar_widget.dart';
import 'profile_screen.dart';
import 'result_screen.dart';
import 'unified_scan_screen.dart';

class DashboardHomeScreen extends StatefulWidget {
  const DashboardHomeScreen({super.key});

  @override
  State<DashboardHomeScreen> createState() => _DashboardHomeScreenState();
}

class _DashboardHomeScreenState extends State<DashboardHomeScreen> {
  List<MealEntry> _todayMeals = [];
  Map<String, double> _totals = {};

  @override
  void initState() {
    super.initState();
    _loadToday();
    MealDbService.instance.mealsChangedNotifier.addListener(_loadToday);
    WaterService.instance.load();
    StreakService.instance.load();
    CalorieBodyService.instance.loadCached().then((_) {
      CalorieBodyService.instance.runIfNeeded();
    });
  }

  @override
  void dispose() {
    MealDbService.instance.mealsChangedNotifier.removeListener(_loadToday);
    super.dispose();
  }

  Future<void> _loadToday() async {
    final meals = await MealDbService.instance.getMealsForDay(DateTime.now());
    final totals = await MealDbService.instance.getDayTotals(DateTime.now());
    if (mounted) setState(() { _todayMeals = meals; _totals = totals; });
  }

  List<MealEntry> _mealsFor(String type) =>
      _todayMeals.where((m) => m.mealType == type).toList();

  /// Opens the unified camera/barcode screen.
  /// Handles the barcode return (NutritionData) and pushes ResultScreen.
  Future<void> _navigateToSearch() async {
    final result = await Navigator.push<NutritionData>(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (ctx, anim, sa) => const UnifiedScanScreen(),
        transitionsBuilder: (ctx, anim, sa, child) =>
            FadeTransition(opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut), child: child),
      ),
    );
    if (!mounted || result == null) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => ResultScreen(nutritionData: result)));
  }

  @override
  Widget build(BuildContext context) {
    final settings   = UserSettings.instance;
    final calGoal    = settings.calorieLimit.toDouble();
    final protGoal   = (calGoal * 0.30 / 4).roundToDouble();  // 30% from protein
    final carbGoal   = (calGoal * 0.45 / 4).roundToDouble();  // 45% from carbs
    final fatGoal    = (calGoal * 0.25 / 9).roundToDouble();  // 25% from fat

    final calEaten   = _totals['calories'] ?? 0;
    final protEaten  = _totals['protein']  ?? 0;
    final carbEaten  = _totals['carbs']    ?? 0;
    final fatEaten   = _totals['fat']      ?? 0;

    final bodyComp   = CalorieBodyService.instance.bodyComposition;
    final gender     = settings.gender == 'female' ? 'female' : 'male';

    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
      child: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Top bar ───────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const ProfileScreen())),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.bgCard,
                          border: Border.all(color: AppColors.bgCardBorder),
                        ),
                        child: const Icon(Icons.person_rounded, size: 20,
                            color: AppColors.primaryAction),
                      ),
                    ),
                    const Spacer(),
                    ShaderMask(
                      shaderCallback: (r) => const LinearGradient(
                        colors: [AppColors.primaryAction, AppColors.bodyMetric],
                      ).createShader(r),
                      child: const Text(
                        'YOTRACKEZ',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Date badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.bgCardBorder),
                      ),
                      child: Text(
                        _todayLabel(),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms),
            ),

            // ── Avatar + Calorie ring hero ─────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: _AvatarCalorieHero(
                  gender: gender,
                  bodyComposition: bodyComp,
                  caloriesEaten: calEaten,
                  caloriesGoal: calGoal,
                ).animate().fadeIn(delay: 100.ms, duration: 500.ms).scaleXY(
                    begin: 0.95, end: 1.0),
              ),
            ),

            // ── Macros row ────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.bgCardBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: MacroRingWidget(
                        label: 'Protein', value: protEaten, goal: protGoal,
                        color: AppColors.protein)),
                      Expanded(child: MacroRingWidget(
                        label: 'Carbs', value: carbEaten, goal: carbGoal,
                        color: AppColors.carbs)),
                      Expanded(child: MacroRingWidget(
                        label: 'Fat', value: fatEaten, goal: fatGoal,
                        color: AppColors.fat)),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 500.ms).slideY(begin: 0.15),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ── Today's diary ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            size: 16, color: AppColors.bodyMetric),
                        const SizedBox(width: 8),
                        const Text(
                          "TODAY'S DIARY",
                          style: TextStyle(
                            color: AppColors.bodyMetric,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: _navigateToSearch,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryAction.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: AppColors.primaryAction.withValues(alpha: 0.3)),
                            ),
                            child: const Text(
                              '+ Add',
                              style: TextStyle(
                                color: AppColors.primaryAction,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...(['breakfast', 'lunch', 'snack', 'dinner']
                        .asMap()
                        .entries
                        .map((e) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: DiaryMealCard(
                                mealType: e.value,
                                meals: _mealsFor(e.value),
                                onAddTap: _navigateToSearch,
                              ).animate().fadeIn(
                                    delay: Duration(milliseconds: 250 + e.key * 60),
                                    duration: 400.ms,
                                  ).slideX(begin: 0.05),
                            ))),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ── Water + Streak row ────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(child: _CompactWaterCard()),
                    const SizedBox(width: 12),
                    Expanded(child: _CompactStreakCard()),
                  ],
                ),
              ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  String _todayLabel() {
    final now = DateTime.now();
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${months[now.month - 1]} ${now.day}';
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Avatar + Calorie Arc Hero
// ════════════════════════════════════════════════════════════════════════════
class _AvatarCalorieHero extends StatelessWidget {
  final String gender;
  final double bodyComposition;
  final double caloriesEaten;
  final double caloriesGoal;

  const _AvatarCalorieHero({
    required this.gender,
    required this.bodyComposition,
    required this.caloriesEaten,
    required this.caloriesGoal,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final ringSize = screenWidth * 0.72;
    final avatarSize = ringSize * 0.72;
    final pct = caloriesGoal > 0
        ? (caloriesEaten / caloriesGoal).clamp(0.0, 1.0)
        : 0.0;

    return Center(
      child: Column(
        children: [
          SizedBox(
            width: ringSize,
            height: ringSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Subtle radial glow behind avatar
                Container(
                  width: ringSize * 0.85,
                  height: ringSize * 0.85,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.bodyMetric.withValues(alpha: 0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                // Calorie ring (CustomPainter)
                CustomPaint(
                  size: Size(ringSize, ringSize),
                  painter: _CalorieRingPainter(progress: pct),
                ),
                // Avatar centered
                YoAvatarWidget(
                  gender: gender,
                  size: avatarSize,
                  bodyComposition: bodyComposition,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Calorie label
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                caloriesEaten.toStringAsFixed(0),
                style: const TextStyle(
                  color: AppColors.bodyMetric,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              Text(
                ' / ${caloriesGoal.toStringAsFixed(0)} kcal',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _statusMessage(pct),
            style: TextStyle(
              color: _statusColor(pct),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  String _statusMessage(double pct) {
    if (pct == 0) return 'Nothing logged yet today';
    if (pct < 0.5) return 'Keep going — great start!';
    if (pct < 0.85) return 'On track for your goal';
    if (pct < 1.0) return 'Almost at your daily limit';
    return 'Daily goal reached! 🎉';
  }

  Color _statusColor(double pct) {
    if (pct < 0.85) return AppColors.bodyMetric;
    if (pct < 1.0) return AppColors.secondaryAction;
    return AppColors.secondaryAction;
  }
}

class _CalorieRingPainter extends CustomPainter {
  final double progress;
  const _CalorieRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const stroke = 7.0;
    const startAngle = -math.pi / 2;

    // Track
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0, 2 * math.pi, false,
      Paint()
        ..color = AppColors.bodyMetric.withValues(alpha: 0.10)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );

    if (progress <= 0) return;

    // Glow
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle, 2 * math.pi * progress, false,
      Paint()
        ..color = AppColors.bodyMetric.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke * 3
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle, 2 * math.pi * progress, false,
      Paint()
        ..color = progress >= 1.0 ? AppColors.secondaryAction : AppColors.bodyMetric
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_CalorieRingPainter old) => old.progress != progress;
}

// ════════════════════════════════════════════════════════════════════════════
// Compact Water card (condensed vs. old WaterTrackerWidget hero)
// ════════════════════════════════════════════════════════════════════════════
class _CompactWaterCard extends StatefulWidget {
  @override
  State<_CompactWaterCard> createState() => _CompactWaterCardState();
}

class _CompactWaterCardState extends State<_CompactWaterCard> {
  @override
  void initState() {
    super.initState();
    WaterService.instance.addListener(_rebuild);
  }

  void _rebuild() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    WaterService.instance.removeListener(_rebuild);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final svc = WaterService.instance;
    final current = svc.glasses;
    const goal    = 8; // WaterService._goal
    final pct     = (current / goal).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: svc.addGlass,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.bodyMetric.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.water_drop_rounded,
                    color: AppColors.bodyMetric, size: 18),
                const SizedBox(width: 6),
                const Text('Hydration',
                    style: TextStyle(color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 6,
                backgroundColor: AppColors.bodyMetric.withValues(alpha: 0.12),
                valueColor: const AlwaysStoppedAnimation(AppColors.bodyMetric),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$current / $goal glasses',
              style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Compact Streak card
// ════════════════════════════════════════════════════════════════════════════
class _CompactStreakCard extends StatefulWidget {
  @override
  State<_CompactStreakCard> createState() => _CompactStreakCardState();
}

class _CompactStreakCardState extends State<_CompactStreakCard> {
  @override
  void initState() {
    super.initState();
    StreakService.instance.addListener(_rebuild);
  }

  void _rebuild() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    StreakService.instance.removeListener(_rebuild);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final svc    = StreakService.instance;
    final streak = svc.streak;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.secondaryAction.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              const Text('Streak',
                  style: TextStyle(color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            streak == 0 ? '—' : '$streak',
            style: TextStyle(
              color: streak > 0 ? AppColors.secondaryAction : AppColors.textSecondary,
              fontSize: streak == 0 ? 20 : 28,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            streak == 0 ? 'Log a meal to start' : streak == 1 ? 'day — keep it up!' : 'days — on fire!',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
