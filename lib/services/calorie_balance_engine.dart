import '../models/log_entries.dart';

/// Computes a user's rolling calorie balance and converts it into the
/// smooth 0-100 `bodyComposition` value the Rive avatar rig consumes
/// (0 = leanest, 100 = heaviest — see the Rive avatar brief).
///
/// Design intent (why it works this way, not just what it does):
/// - Uses a 7-day rolling average, not single-day balance, so the avatar
///   doesn't jitter after one big meal or one lazy day.
/// - Nudges the current value by a CLAMPED daily delta rather than jumping
///   straight to a "correct" value, so changes always look like gradual,
///   continuous animation in Rive, never a snap/pop.
/// - All tuning constants are named and commented so you can adjust the
///   pacing without touching the logic.
class CalorieBalanceEngine {
  /// User's Basal Metabolic Rate (resting calorie burn/day).
  /// Get this from BmrCalculator, or from your existing ProfileScreen calc.
  final double bmr;

  /// Kcal of rolling daily surplus/deficit that corresponds to a full
  /// 1.0-unit shift in bodyComposition. Tune this to control how
  /// "sensitive" the avatar is. Larger = avatar changes more slowly.
  final double kcalPerCompositionUnit;

  /// Hard cap on how much bodyComposition can move in a single day,
  /// regardless of how extreme the calorie balance was. This is what
  /// guarantees smooth animation instead of the avatar "teleporting".
  final double maxDailyDelta;

  CalorieBalanceEngine({
    required this.bmr,
    this.kcalPerCompositionUnit = 150,
    this.maxDailyDelta = 1.5,
  });

  /// Net calorie balance for a single calendar day.
  /// Positive = surplus (ate more than burned), negative = deficit.
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

  /// Rolling average net balance over [windowDays] ending on [asOf]
  /// (inclusive of asOf's day).
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

  /// Given the avatar's current bodyComposition value (0-100) and the
  /// current rolling average balance, returns the NEXT value to send to
  /// Rive — nudged gradually, clamped to [0, 100].
  ///
  /// Call this once per day (e.g. on app open, or via a daily background
  /// job) — not on every meal log — so the avatar moves in calm, readable
  /// daily steps rather than reacting to every single food entry.
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
