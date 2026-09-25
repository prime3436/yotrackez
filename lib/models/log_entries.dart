
class MealLogEntry {
  final double calories;
  final DateTime loggedAt;

  const MealLogEntry({
    required this.calories,
    required this.loggedAt,
  });
}

class ActivityLogEntry {

  final double activeCaloriesBurned;
  final DateTime loggedAt;

  const ActivityLogEntry({
    required this.activeCaloriesBurned,
    required this.loggedAt,
  });
}

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

class StepsToCalories {
  static double estimate(int steps, {double weightKg = 70}) {

    return steps * 0.00057 * weightKg;
  }
}
