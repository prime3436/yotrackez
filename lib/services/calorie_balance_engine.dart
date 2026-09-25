import '../models/log_entries.dart';

class CalorieBalanceEngine {

  final double bmr;

  final double kcalPerCompositionUnit;

  final double maxDailyDelta;

  CalorieBalanceEngine({
    required this.bmr,
    this.kcalPerCompositionUnit = 150,
    this.maxDailyDelta = 1.5,
  });

  double dailyNetBalance({
    required DateTime day,
    required List<MealLogEntry> meals,
    required List<ActivityLogEntry> activities,
  }) {
    final consumed = _sumForDay(day, meals, (m) => m.calories, (m) => m.loggedAt);
    final activeBurn = _sumForDay(
        day, activities, (a) => a.activeCaloriesBurned, (a) => a.loggedAt);

    final totalBurn = bmr + activeBurn;
    return consumed - totalBurn;
  }

  double rollingAverageBalance({
    required DateTime asOf,
    required List<MealLogEntry> meals,
    required List<ActivityLogEntry> activities,
    int windowDays = 7,
  }) {
    double total = 0;
    for (int i = 0; i < windowDays; i++) {
      final day = asOf.subtract(Duration(days: i));
      total += dailyNetBalance(day: day, meals: meals, activities: activities);
    }
    return total / windowDays;
  }

  double nextBodyComposition({
    required double currentValue,
    required double rollingAvgBalance,
  }) {
    final rawDelta = rollingAvgBalance / kcalPerCompositionUnit;
    final clampedDelta = rawDelta.clamp(-maxDailyDelta, maxDailyDelta);
    final next = currentValue + clampedDelta;
    return next.clamp(0.0, 100.0);
  }

  double _sumForDay<T>(
    DateTime day,
    List<T> entries,
    double Function(T) valueOf,
    DateTime Function(T) dateOf,
  ) {
    return entries
        .where((e) => _isSameDay(dateOf(e), day))
        .fold(0.0, (sum, e) => sum + valueOf(e));
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
