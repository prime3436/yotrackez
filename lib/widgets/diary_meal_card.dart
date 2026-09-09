import 'package:flutter/material.dart';
import '../models/meal_entry.dart';
import '../theme/app_colors.dart';

/// A single collapsible diary card for one meal-type slot (Breakfast, Lunch, etc.)
class DiaryMealCard extends StatefulWidget {
  final String mealType;        // 'breakfast' | 'lunch' | 'snack' | 'dinner'
  final List<MealEntry> meals;  // entries already filtered to this type
  final VoidCallback? onAddTap; // opens the appropriate add-meal flow

  const DiaryMealCard({
    super.key,
    required this.mealType,
    required this.meals,
    this.onAddTap,
  });

  @override
  State<DiaryMealCard> createState() => _DiaryMealCardState();
}

class _DiaryMealCardState extends State<DiaryMealCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _ctrl;
  late final Animation<double> _expand;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 260));
    _expand = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _ctrl.forward() : _ctrl.reverse();
  }

  // ── Metadata ────────────────────────────────────────────────────────────

  static const _meta = {
    'breakfast': (icon: '🌅', label: 'Breakfast', color: Color(0xFFFFB347)),
    'lunch':     (icon: '🌞', label: 'Lunch',     color: Color(0xFF8B7FFF)),
    'snack':     (icon: '🍎', label: 'Snack',     color: Color(0xFF4FD1C5)),
    'dinner':    (icon: '🌙', label: 'Dinner',    color: Color(0xFF6C8EFF)),
  };

  @override
  Widget build(BuildContext context) {
    final info = _meta[widget.mealType] ??
        (icon: '🍽️', label: 'Meal', color: AppColors.textSecondary);
    final totalCal = widget.meals.fold(0.0, (s, m) => s + m.calories);
    final hasMeals = widget.meals.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.bgCardBorder, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _toggle,
          child: Column(
            children: [
              // ── Header row ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    // Emoji + color dot
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: info.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: info.color.withValues(alpha: 0.25)),
                      ),
                      child: Center(
                        child: Text(info.icon, style: const TextStyle(fontSize: 20)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Label + calorie count
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            info.label,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            hasMeals
                                ? '${totalCal.toStringAsFixed(0)} kcal · ${widget.meals.length} item${widget.meals.length == 1 ? '' : 's'}'
                                : 'Nothing logged yet',
                            style: TextStyle(
                              color: hasMeals ? info.color : AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Add button + chevron
                    GestureDetector(
                      onTap: widget.onAddTap,
                      child: Container(
                        width: 32,
                        height: 32,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryAction.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primaryAction.withValues(alpha: 0.3)),
                        ),
                        child: const Icon(Icons.add_rounded, size: 18, color: AppColors.primaryAction),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _expanded ? 0.25 : 0,
                      duration: const Duration(milliseconds: 260),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: _expanded ? info.color : AppColors.textSecondary,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
              // ── Expanded items list ─────────────────────────────────────
              SizeTransition(
                sizeFactor: _expand,
                child: hasMeals
                    ? Column(
                        children: [
                          Divider(
                            color: AppColors.bgCardBorder,
                            height: 1,
                            indent: 16,
                            endIndent: 16,
                          ),
                          ...widget.meals.map((m) => _MealItemRow(meal: m)),
                          const SizedBox(height: 4),
                        ],
                      )
                    : Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                        child: Row(
                          children: [
                            Icon(Icons.add_circle_outline_rounded,
                                color: AppColors.primaryAction.withValues(alpha: 0.6), size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Tap + to log a meal',
                              style: TextStyle(
                                color: AppColors.textSecondary.withValues(alpha: 0.7),
                                fontSize: 12,
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
    );
  }
}

class _MealItemRow extends StatelessWidget {
  final MealEntry meal;
  const _MealItemRow({required this.meal});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              meal.foodName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.bodyMetric.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${meal.calories.toStringAsFixed(0)} kcal',
              style: const TextStyle(
                color: AppColors.bodyMetric,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
