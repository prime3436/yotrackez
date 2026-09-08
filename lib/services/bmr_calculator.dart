import '../models/log_entries.dart';

/// Mifflin-St Jeor BMR calculation.
///
/// NOTE: your ProfileScreen already implements this per your project notes.
/// This copy exists so CalorieBalanceEngine has zero dependency on your
/// existing screens/widgets and can be unit-tested in isolation. Feel free
/// to delete this file and pass your existing BMR value straight into
/// CalorieBalanceEngine instead — the engine only needs a `double bmr`.
class BmrCalculator {
  static double calculate(UserMetrics metrics) {
    final base = (10 * metrics.weightKg) +
        (6.25 * metrics.heightCm) -
        (5 * metrics.age);

    switch (metrics.gender) {
      case Gender.male:
        return base + 5;
      case Gender.female:
        return base - 161;
    }
  }
}
