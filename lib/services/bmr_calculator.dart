import '../models/log_entries.dart';

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
