import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/meal_entry.dart';
import '../models/user_settings.dart';
import '../services/meal_db_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class MealHistoryScreen extends StatefulWidget {
  const MealHistoryScreen({super.key});

  @override
  State<MealHistoryScreen> createState() => _MealHistoryScreenState();
}

class _MealHistoryScreenState extends State<MealHistoryScreen> {
  DateTime _selectedDate = DateTime.now();
  List<MealEntry> _meals = [];
  Map<String, double> _totals = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    MealDbService.instance.mealsChangedNotifier.addListener(_load);
  }

  @override
  void dispose() {
    MealDbService.instance.mealsChangedNotifier.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final meals = await MealDbService.instance.getMealsForDay(_selectedDate);
    final totals = await MealDbService.instance.getDayTotals(_selectedDate);
    if (mounted) {
      setState(() {
        _meals = meals;
        _totals = totals;
        _loading = false;
      });
    }
  }

  void _goToPrevDay() {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
      _loading = true;
    });
    _load();
  }

  void _goToNextDay() {
    final today = DateTime.now();
    final isToday = _selectedDate.year == today.year &&
        _selectedDate.month == today.month &&
        _selectedDate.day == today.day;
    if (isToday) return;
    HapticFeedback.selectionClick();
    setState(() {
      _selectedDate = _selectedDate.add(const Duration(days: 1));
      _loading = true;
    });
    _load();
  }

  bool get _isToday {
    final today = DateTime.now();
    return _selectedDate.year == today.year &&
        _selectedDate.month == today.month &&
        _selectedDate.day == today.day;
  }

  String get _dateLabel {
    if (_isToday) return 'Today';
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    if (_selectedDate.year == yesterday.year &&
        _selectedDate.month == yesterday.month &&
        _selectedDate.day == yesterday.day) { return 'Yesterday'; }

    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${days[_selectedDate.weekday - 1]}, ${_selectedDate.day} ${months[_selectedDate.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final calGoal = UserSettings.instance.calorieLimit.toDouble();
    final calEaten = _totals['calories'] ?? 0;
    final protein = _totals['protein'] ?? 0;
    final carbs = _totals['carbs'] ?? 0;
    final fat = _totals['fat'] ?? 0;
    final calProgress = (calEaten / calGoal).clamp(0.0, 1.0);
    final remaining = (calGoal - calEaten).clamp(0.0, double.infinity);

    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
      child: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    const Text(
                      'History & Diary',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const Spacer(),

                    if (!_loading)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.primaryAction.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppColors.primaryAction.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          '${_meals.length} meals',
                          style: const TextStyle(
                            color: AppColors.primaryAction,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.bgCardBorder),
                  ),
                  child: Row(
                    children: [
                      _NavArrow(
                        icon: Icons.chevron_left_rounded,
                        onTap: _goToPrevDay,
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            _dateLabel,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      _NavArrow(
                        icon: Icons.chevron_right_rounded,
                        onTap: _isToday ? null : _goToNextDay,
                        dimmed: _isToday,
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 80.ms, duration: 400.ms),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: _CalorieSummaryCard(
                  calEaten: calEaten,
                  calGoal: calGoal,
                  calProgress: calProgress,
                  remaining: remaining,
                  protein: protein,
                  carbs: carbs,
                  fat: fat,
                ).animate().fadeIn(delay: 160.ms, duration: 500.ms).slideY(begin: 0.1),
              ),
            ),

            if (_loading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: AppColors.primaryAction)),
              )
            else if (_meals.isEmpty)
              SliverFillRemaining(child: _buildEmptyState())
            else ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Text(
                    'Meal Log',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                      child: _MealCard(
                        meal: _meals[index],
                        onDelete: () async {
                          final id = _meals[index].id;
                          if (id != null) {
                            await MealDbService.instance.deleteMeal(id);
                            _load();
                          }
                        },
                      )
                          .animate()
                          .fadeIn(delay: (220 + 60 * index).ms, duration: 400.ms)
                          .slideX(begin: 0.08),
                    );
                  },
                  childCount: _meals.length,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
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
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.bgCardBorder),
            ),
            child: const Center(
              child: Text('🍽️', style: TextStyle(fontSize: 36)),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _isToday ? 'No meals logged today' : 'Nothing logged on this day',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isToday
                ? 'Scan your food to start tracking!'
                : 'Swipe to a different day to view meals.',
            style: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.7),
              fontSize: 13,
            ),
          ),
        ],
      ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
    );
  }
}

class _CalorieSummaryCard extends StatelessWidget {
  final double calEaten, calGoal, calProgress, remaining;
  final double protein, carbs, fat;

  const _CalorieSummaryCard({
    required this.calEaten,
    required this.calGoal,
    required this.calProgress,
    required this.remaining,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  @override
  Widget build(BuildContext context) {
    final isOver = calEaten > calGoal;
    final barColor = isOver ? AppTheme.lava : AppColors.primaryAction;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryAction.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    calEaten.toStringAsFixed(0),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  const Text(
                    'kcal eaten',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    isOver
                        ? '+${(calEaten - calGoal).toStringAsFixed(0)}'
                        : remaining.toStringAsFixed(0),
                    style: TextStyle(
                      color: isOver ? AppTheme.lava : AppColors.bodyMetric,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    isOver ? 'over goal' : 'remaining',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: calProgress,
              minHeight: 8,
              backgroundColor: AppColors.bgCardBorder,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0', style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
              Text(
                'Goal: ${calGoal.toStringAsFixed(0)} kcal',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
              ),
            ],
          ),

          const SizedBox(height: 18),
          const Divider(color: AppColors.bgCardBorder, height: 1),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MacroChip(label: 'Protein', value: '${protein.toStringAsFixed(0)}g',
                  color: AppColors.protein),
              _MacroChip(label: 'Carbs', value: '${carbs.toStringAsFixed(0)}g',
                  color: AppColors.carbs),
              _MacroChip(label: 'Fat', value: '${fat.toStringAsFixed(0)}g',
                  color: AppColors.fat),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String label, value;
  final Color color;
  const _MacroChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: color, fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _MealCard extends StatelessWidget {
  final MealEntry meal;
  final VoidCallback onDelete;
  const _MealCard({required this.meal, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final timeStr =
        '${meal.timestamp.hour.toString().padLeft(2, '0')}:${meal.timestamp.minute.toString().padLeft(2, '0')}';

    return Dismissible(
      key: Key('meal_${meal.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.lava.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_rounded, color: AppTheme.lava),
            const SizedBox(height: 4),
            Text('Delete', style: TextStyle(color: AppTheme.lava, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.bgCardBorder),
        ),
        child: Row(
          children: [

            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primaryAction.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      MealEntry.getMealEmoji(meal.mealType),
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(timeStr,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal.foodName,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      _MiniMacro(label: 'P', value: '${meal.protein.toStringAsFixed(0)}g',
                          color: AppColors.protein),
                      const SizedBox(width: 6),
                      _MiniMacro(label: 'C', value: '${meal.carbs.toStringAsFixed(0)}g',
                          color: AppColors.carbs),
                      const SizedBox(width: 6),
                      _MiniMacro(label: 'F', value: '${meal.fat.toStringAsFixed(0)}g',
                          color: AppColors.fat),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryAction.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          MealEntry.getMealLabel(meal.mealType),
                          style: const TextStyle(
                              color: AppColors.primaryAction,
                              fontSize: 10,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  meal.calories.toStringAsFixed(0),
                  style: const TextStyle(
                    color: AppColors.primaryAction,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Text('kcal',
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniMacro extends StatelessWidget {
  final String label, value;
  final Color color;
  const _MiniMacro({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      '$label: $value',
      style: TextStyle(
        color: color.withValues(alpha: 0.85),
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _NavArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool dimmed;

  const _NavArrow({required this.icon, this.onTap, this.dimmed = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: dimmed
              ? AppColors.bgCardBorder.withValues(alpha: 0.3)
              : AppColors.primaryAction.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: dimmed
              ? AppColors.textSecondary.withValues(alpha: 0.3)
              : AppColors.primaryAction,
          size: 22,
        ),
      ),
    );
  }
}
