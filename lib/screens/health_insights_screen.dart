import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/meal_entry.dart';
import '../models/user_settings.dart';
import '../services/meal_db_service.dart';
import '../services/recommendation_service.dart';
import '../theme/app_theme.dart';

/// Health Insights & Macro Breakdown screen.
class HealthInsightsScreen extends StatefulWidget {
  const HealthInsightsScreen({super.key});

  @override
  State<HealthInsightsScreen> createState() => _HealthInsightsScreenState();
}

class _HealthInsightsScreenState extends State<HealthInsightsScreen>
    with SingleTickerProviderStateMixin {
  List<MealEntry> _todayMeals = [];
  List<double> _weekCalories = [];
  MealRecommendation? _recommendation;
  bool _loading = true;
  late AnimationController _animCtrl;
  late Animation<double> _animValue;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _animValue =
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic);
    _load();
    MealDbService.instance.mealsChangedNotifier.addListener(_load);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    MealDbService.instance.mealsChangedNotifier.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    await UserSettings.instance.load();
    final today = DateTime.now();
    final todayMeals = await MealDbService.instance.getMealsForDay(today);
    final weekCals = <double>[];
    for (int i = 6; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      final totals = await MealDbService.instance.getDayTotals(day);
      weekCals.add(totals['calories'] ?? 0);
    }
    final rec = RecommendationService.instance.generateForDay(todayMeals);
    if (mounted) {
      setState(() {
        _todayMeals = todayMeals;
        _weekCalories = weekCals;
        _recommendation = rec;
        _loading = false;
      });
      _animCtrl.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.primary))
              : CustomScrollView(
                  slivers: [
                    _buildHeader(),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            _buildScoreBadge(),
                            const SizedBox(height: 28),
                            _buildCalorieGauge(),
                            const SizedBox(height: 28),
                            _buildMacroRings(),
                            const SizedBox(height: 28),
                            _buildMacroPie(),
                            const SizedBox(height: 28),
                            _buildWeeklyTrend(),
                            const SizedBox(height: 28),
                            _buildRecommendations(),
                            const SizedBox(height: 48),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  SliverAppBar _buildHeader() {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight.withValues(alpha: 0.6),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_rounded,
              size: 20, color: AppTheme.textPrimary),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text('Macro Dashboard',
          style: TextStyle(
              color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: AppTheme.primary),
          onPressed: _load,
          tooltip: 'Refresh',
        ),
      ],
    );
  }

  Widget _buildScoreBadge() {
    final rec = _recommendation!;
    final (bgColor, borderColor, icon) = switch (rec.overallScore) {
      HealthScore.good => (
          AppTheme.fiberGreen.withValues(alpha: 0.1),
          AppTheme.fiberGreen.withValues(alpha: 0.5),
          '🎯'
        ),
      HealthScore.fair => (
          AppTheme.accent.withValues(alpha: 0.1),
          AppTheme.accent.withValues(alpha: 0.5),
          '📈'
        ),
      HealthScore.needsAttention => (
          AppTheme.calorieOrange.withValues(alpha: 0.1),
          AppTheme.calorieOrange.withValues(alpha: 0.5),
          '⚠️'
        ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppTheme.cardRadius,
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 36)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Today\'s Score',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        )),
                const SizedBox(height: 4),
                Text(rec.scoreLabel,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w800,
                        )),
                Text(
                    '${_todayMeals.length} meals · ${rec.totalCalories.toStringAsFixed(0)} kcal logged',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        )),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildCalorieGauge() {
    final rec = _recommendation!;
    final pct = rec.calorieGoal > 0
        ? (rec.totalCalories / rec.calorieGoal).clamp(0.0, 1.0)
        : 0.0;
    final remaining =
        (rec.calorieGoal - rec.totalCalories).clamp(0, 99999);
    final over = rec.totalCalories > rec.calorieGoal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Calorie Balance',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontSize: 18))
            .animate()
            .fadeIn(delay: 80.ms),
        const SizedBox(height: 16),
        Center(
          child: AnimatedBuilder(
            animation: _animValue,
            builder: (_, __) => SizedBox(
              width: 200,
              height: 200,
              child: CustomPaint(
                painter: _GaugePainter(
                  progress: pct * _animValue.value,
                  color: over ? AppTheme.calorieOrange : AppTheme.primary,
                  trackColor: AppTheme.primary.withValues(alpha: 0.1),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        rec.totalCalories.toStringAsFixed(0),
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                      const Text('kcal eaten',
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 11)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: over
                              ? AppTheme.calorieOrange
                                  .withValues(alpha: 0.15)
                              : AppTheme.fiberGreen.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          over
                              ? '+${(rec.totalCalories - rec.calorieGoal).toStringAsFixed(0)} over'
                              : '${remaining.toStringAsFixed(0)} left',
                          style: TextStyle(
                            color: over
                                ? AppTheme.calorieOrange
                                : AppTheme.fiberGreen,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            'Goal: ${rec.calorieGoal.toStringAsFixed(0)} kcal/day',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 100.ms, duration: 400.ms);
  }

  Widget _buildMacroRings() {
    final rec = _recommendation!;
    final macros = [
      _MacroData('Protein', rec.totalProtein, rec.proteinGoalG,
          AppTheme.proteinRed, '🥩'),
      _MacroData(
          'Carbs', rec.totalCarbs, rec.carbGoalG, AppTheme.carbsBlue, '🍞'),
      _MacroData(
          'Fat', rec.totalFat, rec.fatGoalG, AppTheme.fatYellow, '🥑'),
      _MacroData('Fiber', rec.totalFiber, 30, AppTheme.fiberGreen, '🥦'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Macro Goals',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontSize: 18))
            .animate()
            .fadeIn(delay: 150.ms),
        const SizedBox(height: 16),
        AnimatedBuilder(
          animation: _animValue,
          builder: (_, __) => Row(
            children: macros
                .asMap()
                .entries
                .map((e) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                            left: e.key == 0 ? 0 : 6,
                            right: e.key == 3 ? 0 : 6),
                        child: _MacroRingCard(
                          data: e.value,
                          animProgress: _animValue.value,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 160.ms, duration: 400.ms);
  }

  Widget _buildMacroPie() {
    final rec = _recommendation!;
    final totalMacroG = rec.totalProtein + rec.totalCarbs + rec.totalFat;
    if (totalMacroG < 1) return const SizedBox.shrink();

    final proteinPct = rec.totalProtein / totalMacroG;
    final carbsPct = rec.totalCarbs / totalMacroG;
    final fatPct = rec.totalFat / totalMacroG;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Macro Ratio',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontSize: 18))
            .animate()
            .fadeIn(delay: 220.ms),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: AppTheme.glassCard(),
          child: Row(
            children: [
              AnimatedBuilder(
                animation: _animValue,
                builder: (_, __) => SizedBox(
                  width: 120,
                  height: 120,
                  child: CustomPaint(
                    painter: _PiePainter(
                      slices: [
                        _PieSlice(proteinPct, AppTheme.proteinRed),
                        _PieSlice(carbsPct, AppTheme.carbsBlue),
                        _PieSlice(fatPct, AppTheme.fatYellow),
                      ],
                      animProgress: _animValue.value,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PieLegendRow(
                        color: AppTheme.proteinRed,
                        label: 'Protein',
                        pct: proteinPct,
                        grams: rec.totalProtein),
                    const SizedBox(height: 10),
                    _PieLegendRow(
                        color: AppTheme.carbsBlue,
                        label: 'Carbs',
                        pct: carbsPct,
                        grams: rec.totalCarbs),
                    const SizedBox(height: 10),
                    _PieLegendRow(
                        color: AppTheme.fatYellow,
                        label: 'Fat',
                        pct: fatPct,
                        grams: rec.totalFat),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 240.ms, duration: 400.ms),
      ],
    );
  }

  Widget _buildWeeklyTrend() {
    final maxCal = _weekCalories.fold(0.0, (a, b) => a > b ? a : b);
    final labels = _buildDayLabels();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('7-Day Calorie Trend',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontSize: 18))
            .animate()
            .fadeIn(delay: 300.ms),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: AppTheme.glassCard(),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (i) {
              final val =
                  _weekCalories.length > i ? _weekCalories[i] : 0.0;
              final fraction = maxCal > 0 ? (val / maxCal) : 0.0;
              final isToday = i == 6;
              final barColor = isToday
                  ? AppTheme.primary
                  : AppTheme.primary.withValues(alpha: 0.4);

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(
                    children: [
                      if (isToday)
                        Text(
                          val.toStringAsFixed(0),
                          style: const TextStyle(
                              color: AppTheme.primary,
                              fontSize: 9,
                              fontWeight: FontWeight.w700),
                        ),
                      const SizedBox(height: 2),
                      AnimatedContainer(
                        duration: Duration(milliseconds: 400 + i * 60),
                        curve: Curves.easeOutCubic,
                        height: 80 * fraction.clamp(0.05, 1.0),
                        decoration: BoxDecoration(
                          color: barColor,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: isToday
                              ? AppTheme.glowShadow(
                                  AppTheme.primary.withValues(alpha: 0.6))
                              : null,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(labels[i],
                          style: TextStyle(
                            color: isToday
                                ? AppTheme.primary
                                : AppTheme.textSecondary,
                            fontSize: 10,
                            fontWeight: isToday
                                ? FontWeight.w700
                                : FontWeight.w400,
                          )),
                    ],
                  ),
                ),
              );
            }),
          ),
        ).animate().fadeIn(delay: 320.ms, duration: 400.ms),
      ],
    );
  }

  List<String> _buildDayLabels() {
    const days = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
    final today = DateTime.now();
    return List.generate(7, (i) {
      final d = today.subtract(Duration(days: 6 - i));
      return i == 6 ? 'Today' : days[d.weekday - 1];
    });
  }

  Widget _buildRecommendations() {
    final recs = _recommendation!.recommendations;
    if (recs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('AI Recommendations',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontSize: 18))
            .animate()
            .fadeIn(delay: 380.ms),
        const SizedBox(height: 14),
        ...recs.asMap().entries.map((e) {
          final delay = 400 + e.key * 60;
          return _RecommendationCard(rec: e.value)
              .animate()
              .fadeIn(delay: delay.ms, duration: 300.ms)
              .slideX(begin: 0.04);
        }),
      ],
    );
  }
}

// ─── Data classes ─────────────────────────────────────────────────────────────

class _MacroData {
  final String label;
  final double current;
  final double goal;
  final Color color;
  final String emoji;
  const _MacroData(
      this.label, this.current, this.goal, this.color, this.emoji);
}

class _PieSlice {
  final double fraction;
  final Color color;
  const _PieSlice(this.fraction, this.color);
}

// ─── Macro Ring Card ──────────────────────────────────────────────────────────

class _MacroRingCard extends StatelessWidget {
  final _MacroData data;
  final double animProgress;

  const _MacroRingCard({required this.data, required this.animProgress});

  @override
  Widget build(BuildContext context) {
    final pct =
        data.goal > 0 ? (data.current / data.goal).clamp(0.0, 1.0) : 0.0;
    final over = data.current > data.goal;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: data.color.withValues(alpha: 0.08),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: CustomPaint(
              painter: _DonutPainter(
                progress: pct * animProgress,
                color: over ? AppTheme.calorieOrange : data.color,
                trackColor: data.color.withValues(alpha: 0.12),
                strokeWidth: 7,
              ),
              child: Center(
                child: Text(data.emoji,
                    style: const TextStyle(fontSize: 18)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${data.current.toStringAsFixed(0)}g',
            style: TextStyle(
              color: over ? AppTheme.calorieOrange : data.color,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          Text(
            data.label,
            style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 2),
          Text(
            'of ${data.goal.toStringAsFixed(0)}g',
            style:
                const TextStyle(color: AppTheme.textSecondary, fontSize: 9),
          ),
        ],
      ),
    );
  }
}

// ─── Pie Legend Row ───────────────────────────────────────────────────────────

class _PieLegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final double pct;
  final double grams;

  const _PieLegendRow({
    required this.color,
    required this.label,
    required this.pct,
    required this.grams,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label,
              style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ),
        Text(
          '${(pct * 100).toStringAsFixed(0)}%',
          style: TextStyle(
              color: color, fontWeight: FontWeight.w800, fontSize: 13),
        ),
        const SizedBox(width: 6),
        Text(
          '${grams.toStringAsFixed(0)}g',
          style:
              const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
        ),
      ],
    );
  }
}

// ─── Recommendation Card ──────────────────────────────────────────────────────

class _RecommendationCard extends StatelessWidget {
  final Recommendation rec;

  const _RecommendationCard({required this.rec});

  Color get _priorityColor {
    switch (rec.priority) {
      case Priority.high:
        return AppTheme.error;
      case Priority.medium:
        return AppTheme.calorieOrange;
      case Priority.low:
        return AppTheme.primary;
      case Priority.info:
        return AppTheme.fiberGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: AppTheme.cardRadius,
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: AppTheme.cardRadius,
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.04), width: 1),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(rec.icon, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(rec.title,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                )),
                        const SizedBox(height: 4),
                        Text(rec.body,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: AppTheme.textSecondary,
                                  height: 1.5,
                                )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(width: 4, color: _priorityColor),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── CustomPainters ───────────────────────────────────────────────────────────

class _GaugePainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;

  const _GaugePainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = (size.shortestSide / 2) - 14;
    const startAngle = -math.pi / 2;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      0,
      2 * math.pi,
      false,
      Paint()
        ..color = trackColor
        ..strokeWidth = 14
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    if (progress <= 0) return;

    final sweepAngle = 2 * math.pi * progress.clamp(0, 1);
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);
    final gradient = SweepGradient(
      startAngle: startAngle,
      endAngle: startAngle + sweepAngle,
      colors: [color.withValues(alpha: 0.7), color],
      tileMode: TileMode.clamp,
    );

    canvas.drawArc(
      rect,
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..shader = gradient.createShader(rect)
        ..strokeWidth = 14
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    final tipAngle = startAngle + sweepAngle;
    final tipX = cx + radius * math.cos(tipAngle);
    final tipY = cy + radius * math.sin(tipAngle);
    canvas.drawCircle(
      Offset(tipX, tipY),
      8,
      Paint()
        ..color = color
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawCircle(Offset(tipX, tipY), 5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.progress != progress || old.color != color;
}

class _DonutPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  const _DonutPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    this.strokeWidth = 8,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = (size.shortestSide / 2) - strokeWidth / 2;
    const startAngle = -math.pi / 2;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      0,
      2 * math.pi,
      false,
      Paint()
        ..color = trackColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    if (progress <= 0) return;

    final sweepAngle = 2 * math.pi * progress.clamp(0, 1);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.progress != progress || old.color != color;
}

class _PiePainter extends CustomPainter {
  final List<_PieSlice> slices;
  final double animProgress;

  const _PiePainter({required this.slices, required this.animProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = size.shortestSide / 2 - 4;
    const gap = 0.03;

    double startAngle = -math.pi / 2;

    for (final slice in slices) {
      final sweep =
          (2 * math.pi * slice.fraction * animProgress).clamp(0.0, 2 * math.pi);
      if (sweep <= 0) continue;

      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: radius),
        startAngle + gap / 2,
        sweep - gap,
        true,
        Paint()
          ..color = slice.color
          ..style = PaintingStyle.fill,
      );

      canvas.drawCircle(
        Offset(cx, cy),
        radius * 0.52,
        Paint()
          ..color = AppTheme.card
          ..style = PaintingStyle.fill,
      );

      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(_PiePainter old) =>
      old.animProgress != animProgress;
}
