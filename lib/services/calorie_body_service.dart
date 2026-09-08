import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/log_entries.dart';
import '../models/user_settings.dart';
import '../services/calorie_balance_engine.dart';
import '../services/meal_db_service.dart';
import '../services/step_counter_service.dart';

/// Runs the CalorieBalanceEngine once per calendar day and exposes the
/// resulting `bodyComposition` value (0–100) for the Rive avatar.
///
/// Call [runIfNeeded] on every app open (e.g. HomeScreen.initState).
/// The value is persisted to SharedPreferences so it survives restarts
/// and only nudges once per day as intended.
class CalorieBodyService {
  static CalorieBodyService? _instance;
  static CalorieBodyService get instance {
    _instance ??= CalorieBodyService._();
    return _instance!;
  }
  CalorieBodyService._();

  static const _compositionKey = 'yotrackez_body_composition';
  static const _lastRunDateKey = 'yotrackez_body_last_run';

  /// Current avatar body composition value (0 = leanest, 100 = heaviest).
  /// Starts at 50 (mid-point) for new users.
  double _bodyComposition = 50.0;
  double get bodyComposition => _bodyComposition;

  /// Notifier so widgets can rebuild when the value changes.
  final ValueNotifier<double> compositionNotifier = ValueNotifier(50.0);

  /// Load the persisted value without running the engine.
  /// Call this early in startup (before runIfNeeded) so the avatar
  /// shows the correct value immediately while meals are being fetched.
  Future<void> loadCached() async {
    final prefs = await SharedPreferences.getInstance();
    _bodyComposition = prefs.getDouble(_compositionKey) ?? 50.0;
    compositionNotifier.value = _bodyComposition;
  }

  /// Run the engine if it hasn't run today yet (once-per-day gate).
  /// Safe to call every time the app opens.
  Future<void> runIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();

    // Load cached value first so UI is correct while engine runs
    _bodyComposition = prefs.getDouble(_compositionKey) ?? 50.0;
    compositionNotifier.value = _bodyComposition;

    // Check once-per-day gate
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

      // Fetch the last 7 days of meals from MealDbService
      final now = DateTime.now();
      final List<MealLogEntry> mealLog = [];
      for (int i = 0; i < 7; i++) {
        final day = now.subtract(Duration(days: i));
        final meals = await MealDbService.instance.getMealsForDay(day);
        for (final m in meals) {
          mealLog.add(MealLogEntry(calories: m.calories, loggedAt: m.timestamp));
        }
      }

      // Convert today's step count to activity calories
      final steps = StepCounterService.instance.todaySteps;
      final activeCalories = StepsToCalories.estimate(steps, weightKg: settings.weightKg);
      final List<ActivityLogEntry> activityLog = [
        if (activeCalories > 0)
          ActivityLogEntry(
            activeCaloriesBurned: activeCalories,
            loggedAt: now,
          ),
      ];

      // Run the engine
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

      // Persist result and gate flag
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
