import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/nutrition_data.dart';
import '../theme/app_theme.dart';
import '../widgets/nutrient_card.dart';

class ResultScreen extends StatelessWidget {
  final Uint8List? imageBytes;
  final NutritionData nutritionData;

  const ResultScreen({
    super.key,
    this.imageBytes,
    required this.nutritionData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: CustomScrollView(
          slivers: [
            // Hero image app bar (only if we have an image)
            SliverAppBar(
              expandedHeight: imageBytes != null ? 280 : 80,
              pinned: true,
              backgroundColor: AppTheme.surface,
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back_rounded, size: 20),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              flexibleSpace: imageBytes != null
                  ? FlexibleSpaceBar(
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.memory(
                            imageBytes!,
                            fit: BoxFit.cover,
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  AppTheme.background.withValues(alpha: 0.8),
                                  AppTheme.background,
                                ],
                                stops: const [0.3, 0.7, 1.0],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : null,
            ),

            // Content
            SliverToBoxAdapter(
              child: _buildResultContent(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultContent(BuildContext context) {
    final data = nutritionData;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Food name & serving
          Center(
            child: Column(
              children: [
                Text(
                  data.foodName,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: AppTheme.chipRadius,
                  ),
                  child: Text(
                    data.servingSize,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.primary,
                        ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms),

          const SizedBox(height: 24),

          // Calorie badge
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight.withValues(alpha: 0.3),
                borderRadius: AppTheme.buttonRadius,
                border: Border.all(
                  color: AppTheme.calorieOrange.withValues(alpha: 0.5),
                  width: 1.5,
                ),
                boxShadow: AppTheme.glowShadow(
                    AppTheme.calorieOrange.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.local_fire_department_rounded,
                      color: AppTheme.calorieOrange, size: 32),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${data.calories.toStringAsFixed(0)} kcal',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                            ),
                      ),
                      if (data.hasIngredients)
                        Text(
                          'Total for all ingredients',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary,
                                fontSize: 10,
                              ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          )
              .animate()
              .fadeIn(delay: 200.ms, duration: 400.ms)
              .scale(begin: const Offset(0.9, 0.9)),

          const SizedBox(height: 28),

          // Macros
          Text(
            'Macronutrients',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 18),
          ).animate().fadeIn(delay: 300.ms),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: NutrientCard(
                  name: 'Carbs', amount: data.carbs.amount,
                  unit: data.carbs.unit, percent: data.carbsPercent,
                  color: AppTheme.carbsBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: NutrientCard(
                  name: 'Protein', amount: data.protein.amount,
                  unit: data.protein.unit, percent: data.proteinPercent,
                  color: AppTheme.proteinRed,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: NutrientCard(
                  name: 'Fat', amount: data.fat.amount,
                  unit: data.fat.unit, percent: data.fatPercent,
                  color: AppTheme.fatYellow,
                ),
              ),
            ],
          ).animate().fadeIn(delay: 400.ms, duration: 500.ms),

          const SizedBox(height: 28),

          // ═══════════════════════════════════════════
          // INGREDIENT BREAKDOWN (new!)
          // ═══════════════════════════════════════════
          if (data.hasIngredients) ...[
            _buildIngredientBreakdown(context, data),
            const SizedBox(height: 28),
          ],

          // Details
          Text(
            'Other Nutrients',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 18),
          ).animate().fadeIn(delay: 500.ms),

          const SizedBox(height: 12),

          ...[
            _DetailRow(label: data.fiber.name, value: '${data.fiber.amount}${data.fiber.unit}', icon: Icons.grass_rounded, color: AppTheme.fiberGreen),
            _DetailRow(label: data.sugar.name, value: '${data.sugar.amount}${data.sugar.unit}', icon: Icons.cookie_rounded, color: Colors.pinkAccent),
            _DetailRow(label: data.sodium.name, value: '${data.sodium.amount}${data.sodium.unit}', icon: Icons.water_drop_rounded, color: Colors.lightBlueAccent),
            _DetailRow(label: data.cholesterol.name, value: '${data.cholesterol.amount}${data.cholesterol.unit}', icon: Icons.favorite_rounded, color: Colors.redAccent),
          ]
              .asMap()
              .entries
              .map((e) => e.value.animate().fadeIn(
                  delay: (600 + e.key * 100).ms, duration: 400.ms)),

          if (data.vitamins.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Vitamins & Minerals',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 18),
            ).animate().fadeIn(delay: 800.ms),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: data.vitamins
                  .map((v) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.08),
                          borderRadius: AppTheme.chipRadius,
                          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          '${v.name}: ${v.amount}${v.unit}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.primary, fontWeight: FontWeight.w500,
                              ),
                        ),
                      ))
                  .toList(),
            ).animate().fadeIn(delay: 900.ms, duration: 400.ms),
          ],

          if (data.healthTip.isNotEmpty) ...[
            const SizedBox(height: 28),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.06),
                borderRadius: AppTheme.cardRadius,
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_rounded,
                      color: AppTheme.primary.withValues(alpha: 0.7), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      data.healthTip,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary, height: 1.5,
                          ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 1000.ms, duration: 400.ms),
          ],

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity, height: 56,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.qr_code_scanner_rounded),
              label: const Text('Scan Another Food'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primary,
                side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(borderRadius: AppTheme.buttonRadius),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ).animate().fadeIn(delay: 1100.ms, duration: 400.ms),
        ],
      ),
    );
  }

  /// Builds the ingredient breakdown section for complex dishes.
  Widget _buildIngredientBreakdown(BuildContext context, NutritionData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.receipt_long_rounded,
                  color: AppTheme.accent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ingredient Breakdown',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontSize: 18,
                        ),
                  ),
                  Text(
                    '${data.ingredients.length} ingredients',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ).animate().fadeIn(delay: 450.ms),

        const SizedBox(height: 16),

        // Ingredient cards
        ...data.ingredients.asMap().entries.map((entry) {
          final index = entry.key;
          final ingredient = entry.value;
          return _IngredientCard(
            ingredient: ingredient,
            index: index,
          ).animate().fadeIn(
                delay: (500 + index * 80).ms,
                duration: 400.ms,
              ).slideX(begin: 0.05);
        }),
      ],
    );
  }
}

/// Card showing a single ingredient's nutrition.
class _IngredientCard extends StatefulWidget {
  final IngredientData ingredient;
  final int index;

  const _IngredientCard({
    required this.ingredient,
    required this.index,
  });

  @override
  State<_IngredientCard> createState() => _IngredientCardState();
}

class _IngredientCardState extends State<_IngredientCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final ing = widget.ingredient;
    final maxMacro = [ing.carbs, ing.protein, ing.fat, ing.fiber]
        .reduce((a, b) => a > b ? a : b)
        .clamp(1.0, double.infinity);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.card.withValues(alpha: 0.5),
        borderRadius: AppTheme.cardRadius,
        border: Border.all(
          color: AppTheme.accent.withValues(alpha: 0.08),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppTheme.cardRadius,
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Header row
                Row(
                  children: [
                    // Index badge
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${widget.index + 1}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.accent,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Name + amount
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ing.name,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          Text(
                            ing.amount,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textSecondary,
                                  fontSize: 11,
                                ),
                          ),
                        ],
                      ),
                    ),
                    // Calorie chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.calorieOrange.withValues(alpha: 0.12),
                        borderRadius: AppTheme.chipRadius,
                      ),
                      child: Text(
                        '${ing.calories.toStringAsFixed(0)} cal',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.calorieOrange,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Expand icon
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppTheme.textSecondary.withValues(alpha: 0.5),
                        size: 20,
                      ),
                    ),
                  ],
                ),

                // Expanded nutrition bars
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Column(
                      children: [
                        _NutrientBar(
                          label: 'Carbs',
                          value: ing.carbs,
                          maxValue: maxMacro,
                          color: AppTheme.carbsBlue,
                        ),
                        const SizedBox(height: 8),
                        _NutrientBar(
                          label: 'Protein',
                          value: ing.protein,
                          maxValue: maxMacro,
                          color: AppTheme.proteinRed,
                        ),
                        const SizedBox(height: 8),
                        _NutrientBar(
                          label: 'Fat',
                          value: ing.fat,
                          maxValue: maxMacro,
                          color: AppTheme.fatYellow,
                        ),
                        const SizedBox(height: 8),
                        _NutrientBar(
                          label: 'Fiber',
                          value: ing.fiber,
                          maxValue: maxMacro,
                          color: AppTheme.fiberGreen,
                        ),
                      ],
                    ),
                  ),
                  crossFadeState: _expanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 250),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A horizontal bar showing a nutrient value with color fill.
class _NutrientBar extends StatelessWidget {
  final String label;
  final double value;
  final double maxValue;
  final Color color;

  const _NutrientBar({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = (value / maxValue).clamp(0.0, 1.0);

    return Row(
      children: [
        SizedBox(
          width: 52,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                ),
          ),
        ),
        Expanded(
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: fraction,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 36,
          child: Text(
            '${value.toStringAsFixed(1)}g',
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _DetailRow({
    required this.label, required this.value,
    required this.icon, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: AppTheme.glassCard().copyWith(
        border: Border(
          left: BorderSide(color: color, width: 4),
          top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
          right: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textPrimary, fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: color, fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}
