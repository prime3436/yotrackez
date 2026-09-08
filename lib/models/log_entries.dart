/// A single logged meal event.
///
/// If your existing meal/food model already has these fields (calories,
/// timestamp), you don't need this class — just make sure whatever you
/// pass into [CalorieBalanceEngine] exposes `calories` and `loggedAt`.
class MealLogEntry {
  final double calories;
  final DateTime loggedAt;

  const MealLogEntry({
    required this.calories,
    required this.loggedAt,
  });
}

/// A single logged activity/exercise event (steps synced from a wearable,
/// or a manually logged workout — anything that burns calories above BMR).
class ActivityLogEntry {
  /// Calories burned by this activity, ABOVE resting/BMR burn.
  /// If you only have step count, convert it before constructing this
  /// (see [StepsToCalories.estimate] below for a simple conversion).
  final double activeCaloriesBurned;
  final DateTime loggedAt;

  const ActivityLogEntry({
    required this.activeCaloriesBurned,
    required this.loggedAt,
  });
}

/// Basic user metrics needed for BMR calculation.
/// If your ProfileScreen already computes BMR, you can skip
/// [BmrCalculator] entirely and just feed CalorieBalanceEngine a BMR value
/// directly — this is included so the engine is self-contained/testable.
class UserMetrics {
  final double weightKg;
  final double heightCm;
  final int age;
  final Gender gender;

  const UserMetrics({
    required this.weightKg,
    required this.heightCm,
    required this.age,
    required this.gender,
  });
}

enum Gender { male, female }

/// Simple, honest step->calorie estimate. This is a rough average
/// (~0.04 kcal per step for an average adult stride/weight) — good enough
/// for a directional trend indicator, NOT precise enough to present as an
/// exact number to the user. Keep any UI copy using this vague
/// ("approx. active calories"), not falsely precise.
class StepsToCalories {
  static double estimate(int steps, {double weightKg = 70}) {
    // ~0.00057 kcal per step per kg bodyweight is a commonly used rough
    // approximation (varies with stride length/speed in reality).
    return steps * 0.00057 * weightKg;
  }
}
