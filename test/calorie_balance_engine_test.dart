import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_snap/models/log_entries.dart';
import 'package:nutri_snap/services/calorie_balance_engine.dart';
import 'package:nutri_snap/services/bmr_calculator.dart';

void main() {
  group('BmrCalculator', () {
    test('computes Mifflin-St Jeor correctly for male', () {
      final metrics = UserMetrics(
        weightKg: 75,
        heightCm: 178,
        age: 28,
        gender: Gender.male,
      );
      final bmr = BmrCalculator.calculate(metrics);

      expect(bmr, closeTo(1727.5, 0.01));
    });

    test('computes Mifflin-St Jeor correctly for female', () {
      final metrics = UserMetrics(
        weightKg: 60,
        heightCm: 165,
        age: 25,
        gender: Gender.female,
      );
      final bmr = BmrCalculator.calculate(metrics);

      expect(bmr, closeTo(1345.25, 0.01));
    });
  });

  group('CalorieBalanceEngine', () {
    test('sustained surplus moves bodyComposition up gradually, not instantly',
        () {
      final engine = CalorieBalanceEngine(bmr: 2000);
      double value = 50.0;
      for (int i = 0; i < 10; i++) {
        value = engine.nextBodyComposition(
          currentValue: value,
          rollingAvgBalance: 500,
        );
      }
      expect(value, greaterThan(50.0));
      expect(value, lessThanOrEqualTo(65.0));
    });

    test('sustained deficit moves bodyComposition down gradually', () {
      final engine = CalorieBalanceEngine(bmr: 2000);
      double value = 50.0;
      for (int i = 0; i < 10; i++) {
        value = engine.nextBodyComposition(
          currentValue: value,
          rollingAvgBalance: -500,
        );
      }
      expect(value, lessThan(50.0));
      expect(value, greaterThanOrEqualTo(35.0));
    });

    test('extreme single-day binge is clamped to maxDailyDelta', () {
      final engine = CalorieBalanceEngine(bmr: 2000, maxDailyDelta: 1.5);
      final next = engine.nextBodyComposition(
        currentValue: 50.0,
        rollingAvgBalance: 3000,
      );
      expect(next - 50.0, closeTo(1.5, 0.001));
    });

    test('bodyComposition never exceeds 100 or drops below 0', () {
      final engine = CalorieBalanceEngine(bmr: 2000);
      final high = engine.nextBodyComposition(
        currentValue: 99.5,
        rollingAvgBalance: 5000,
      );
      expect(high, lessThanOrEqualTo(100.0));

      final low = engine.nextBodyComposition(
        currentValue: 0.5,
        rollingAvgBalance: -5000,
      );
      expect(low, greaterThanOrEqualTo(0.0));
    });

    test('dailyNetBalance sums only entries matching that calendar day', () {
      final engine = CalorieBalanceEngine(bmr: 1800);
      final targetDay = DateTime(2026, 8, 5);

      final meals = [
        MealLogEntry(calories: 600, loggedAt: DateTime(2026, 8, 5, 8)),
        MealLogEntry(calories: 700, loggedAt: DateTime(2026, 8, 5, 13)),
        MealLogEntry(calories: 900, loggedAt: DateTime(2026, 8, 4, 19)),
      ];
      final activities = [
        ActivityLogEntry(
            activeCaloriesBurned: 300, loggedAt: DateTime(2026, 8, 5, 18)),
      ];

      final balance = engine.dailyNetBalance(
        day: targetDay,
        meals: meals,
        activities: activities,
      );

      expect(balance, closeTo(-800, 0.01));
    });
  });

  group('StepsToCalories', () {
    test('produces a reasonable positive estimate for typical step counts',
        () {
      final kcal = StepsToCalories.estimate(8000, weightKg: 70);
      expect(kcal, greaterThan(0));
      expect(kcal, lessThan(600));
    });
  });
}
