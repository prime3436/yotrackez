import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/log_entries.dart';
import '../models/user_settings.dart';
import '../services/calorie_balance_engine.dart';
import '../services/meal_db_service.dart';
import '../services/step_counter_service.dart';

class CalorieBodyService {
  static CalorieBodyService? _instance;
  static CalorieBodyService get instance {
    _instance ??= CalorieBodyService._();
    return _instance!;
  }
  CalorieBodyService._();

  static const _compositionKey = 'yotrackez_body_composition';
  static const _lastRunDateKey = 'yotrackez_body_last_run';

  double _bodyComposition = 50.0;
  double get bodyComposition => _bodyComposition;

  final ValueNotifier<double> compositionNotifier = ValueNotifier(50.0);

  Future<void> loadCached() async {
    final prefs = await SharedPreferences.getInstance();
    _bodyComposition = prefs.getDouble(_compositionKey) ?? 50.0;
    compositionNotifier.value = _bodyComposition;
  }

  Future<void> runIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();

    _bodyComposition = prefs.getDouble(_compositionKey) ?? 50.0;
    compositionNotifier.value = _bodyComposition;

    final lastRunStr = prefs.getString(_lastRunDateKey) ?? '';
    final today = _dateKey(DateTime.now());
    if (lastRunStr == today) {
      debugPrint('[CalorieBody] Already ran today — skipping engine.');
      return;
    }

    await _runEngine(prefs, today);
  }

  Future<void> _runEngine(SharedPreferences prefs, String today) async {
    try {
      final settings = UserSettings.instance;
      final bmr = settings.bmr;

      final now = DateTime.now();
      final List<MealLogEntry> mealLog = [];
      for (int i = 0; i < 7; i++) {
        final day = now.subtract(Duration(days: i));
        final meals = await MealDbService.instance.getMealsForDay(day);
        for (final m in meals) {
          mealLog.add(MealLogEntry(calories: m.calories, loggedAt: m.timestamp));
        }
      }

      final steps = StepCounterService.instance.todaySteps;
      final activeCalories = StepsToCalories.estimate(steps, weightKg: settings.weightKg);
      final List<ActivityLogEntry> activityLog = [
        if (activeCalories > 0)
          ActivityLogEntry(
            activeCaloriesBurned: activeCalories,
            loggedAt: now,
          ),
      ];

      final engine = CalorieBalanceEngine(bmr: bmr);
      final rollingAvg = engine.rollingAverageBalance(
        asOf: now,
        meals: mealLog,
        activities: activityLog,
      );
      final nextValue = engine.nextBodyComposition(
        currentValue: _bodyComposition,
        rollingAvgBalance: rollingAvg,
      );

      _bodyComposition = nextValue;
      compositionNotifier.value = nextValue;
      await prefs.setDouble(_compositionKey, nextValue);
      await prefs.setString(_lastRunDateKey, today);

      debugPrint(
        '[CalorieBody] rollingAvg=${rollingAvg.toStringAsFixed(1)} kcal/day '
        '→ bodyComposition=${nextValue.toStringAsFixed(2)}',
      );
    } catch (e, st) {
      debugPrint('[CalorieBody] Engine error: $e\n$st');
    }
  }

  String _dateKey(DateTime d) => '${d.year}-${d.month}-${d.day}';
}
