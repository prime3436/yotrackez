import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/meal_entry.dart';
import '../services/meal_db_service.dart';
import '../theme/app_theme.dart';

/// Daily meal timeline screen — shows all meals for today with a summary card.
class MealHistoryScreen extends StatefulWidget {
  const MealHistoryScreen({super.key});

  @override
  State<MealHistoryScreen> createState() => _MealHistoryScreenState();
}

class _MealHistoryScreenState extends State<MealHistoryScreen> {
  List<MealEntry> _meals = [];
  Map<String, double> _totals = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadToday();
    MealDbService.instance.mealsChangedNotifier.addListener(_loadToday);
  }

  @override
  void dispose() {
    MealDbService.instance.mealsChangedNotifier.removeListener(_loadToday);
    super.dispose();
  }

  Future<void> _loadToday() async {
    final today = DateTime.now();
    final meals = await MealDbService.instance.getMealsForDay(today);
    final totals = await MealDbService.instance.getDayTotals(today);
    if (mounted) {
      setState(() {
        _meals = meals;
        _totals = totals;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_rounded, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Today\'s Meals',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
              ),

              // Daily summary card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildSummaryCard(),
              ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1),

              const SizedBox(height: 20),

              // Meal timeline
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                    : _meals.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _meals.length,
                            itemBuilder: (context, index) {
                              return _buildMealCard(_meals[index], index)
                                  .animate()
                                  .fadeIn(delay: (100 * index).ms, duration: 400.ms)
                                  .slideX(begin: 0.1);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final cal = _totals['calories'] ?? 0;
    final pro = _totals['protein'] ?? 0;
    final carbs = _totals['carbs'] ?? 0;
    final fat = _totals['fat'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${cal.toStringAsFixed(0)} cal',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_meals.length} meals',
                  style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _macroChip('Protein', '${pro.toStringAsFixed(0)}g', AppTheme.proteinRed),
              _macroChip('Carbs', '${carbs.toStringAsFixed(0)}g', AppTheme.accent),
              _macroChip('Fat', '${fat.toStringAsFixed(0)}g', AppTheme.calorieOrange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _macroChip(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
      ],
    );
  }

  Widget _buildMealCard(MealEntry meal, int index) {
    final timeStr = '${meal.timestamp.hour.toString().padLeft(2, '0')}:${meal.timestamp.minute.toString().padLeft(2, '0')}';

    return Dismissible(
      key: Key('meal_${meal.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_rounded, color: Colors.red),
      ),
      onDismissed: (_) async {
        if (meal.id != null) {
          await MealDbService.instance.deleteMeal(meal.id!);
          _loadToday();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            // Meal type emoji & time
            Column(
              children: [
                Text(MealEntry.getMealEmoji(meal.mealType), style: const TextStyle(fontSize: 24)),
                const SizedBox(height: 4),
                Text(timeStr, style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              ],
            ),
            const SizedBox(width: 16),
            // Food info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal.foodName,
                    style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${MealEntry.getMealLabel(meal.mealType)} • P:${meal.protein.toStringAsFixed(0)}g C:${meal.carbs.toStringAsFixed(0)}g F:${meal.fat.toStringAsFixed(0)}g',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
            // Calories
            Text(
              meal.calories.toStringAsFixed(0),
              style: TextStyle(color: AppTheme.primary, fontSize: 20, fontWeight: FontWeight.w900),
            ),
            Text(' cal', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🍽️', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            'No meals logged today',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Scan your food to start tracking!',
            style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.6), fontSize: 13),
          ),
        ],
      ),
    );
  }
}
