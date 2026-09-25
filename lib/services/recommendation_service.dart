import 'package:flutter/foundation.dart';
import '../models/meal_entry.dart';
import '../models/user_settings.dart';

class RecommendationService {
  static RecommendationService? _instance;
  static RecommendationService get instance {
    _instance ??= RecommendationService._();
    return _instance!;
  }
  RecommendationService._();

  MealRecommendation generateForDay(List<MealEntry> meals) {
    final settings = UserSettings.instance;
    final calorieGoal = settings.calorieLimit.toDouble();

    final proteinGoalG = calorieGoal * 0.30 / 4;
    final carbGoalG = calorieGoal * 0.40 / 4;
    final fatGoalG = calorieGoal * 0.30 / 9;

    double totalCal = 0, totalPro = 0, totalCarb = 0, totalFat = 0, totalFiber = 0;
    final mealTypes = <String>{};

    for (final m in meals) {
      totalCal += m.calories;
      totalPro += m.protein;
      totalCarb += m.carbs;
      totalFat += m.fat;
      totalFiber += m.fiber;
      mealTypes.add(m.mealType);
    }

    final calPct = calorieGoal > 0 ? totalCal / calorieGoal : 0.0;
    final proPct = proteinGoalG > 0 ? totalPro / proteinGoalG : 0.0;
    final carbPct = carbGoalG > 0 ? totalCarb / carbGoalG : 0.0;
    final fatPct = fatGoalG > 0 ? totalFat / fatGoalG : 0.0;

    final tips = <Recommendation>[];
    var overallScore = HealthScore.good;

    if (calPct > 1.15) {
      overallScore = HealthScore.needsAttention;
      tips.add(Recommendation(
        icon: '🔥',
        title: 'Over Calorie Goal',
        body: 'You\'ve consumed ${(totalCal - calorieGoal).toStringAsFixed(0)} kcal '
            'above your daily target. Consider a lighter dinner and a 20-min walk.',
        priority: Priority.high,
      ));
    } else if (calPct > 0.9) {
      tips.add(Recommendation(
        icon: '✅',
        title: 'Calorie Goal On Track',
        body: 'You\'re at ${(calPct * 100).toStringAsFixed(0)}% of your calorie goal. '
            'Keep going — you\'ve got this!',
        priority: Priority.info,
      ));
    } else if (meals.isNotEmpty && calPct < 0.5) {
      tips.add(Recommendation(
        icon: '⚡',
        title: 'Low Energy Intake',
        body: 'You\'ve only had ${totalCal.toStringAsFixed(0)} kcal today. '
            'Under-eating can slow metabolism — have a balanced meal soon.',
        priority: Priority.medium,
      ));
    }

    if (proPct < 0.6 && meals.isNotEmpty) {
      overallScore = overallScore == HealthScore.good ? HealthScore.fair : overallScore;
      tips.add(Recommendation(
        icon: '💪',
        title: 'Low Protein',
        body: 'Your protein intake is ${totalPro.toStringAsFixed(0)}g — '
            'aim for ${proteinGoalG.toStringAsFixed(0)}g. '
            'Try adding eggs, legumes, or a protein shake.',
        priority: Priority.medium,
      ));
    } else if (proPct >= 0.9) {
      tips.add(Recommendation(
        icon: '🥩',
        title: 'Great Protein Intake',
        body: 'Excellent! ${totalPro.toStringAsFixed(0)}g protein today supports '
            'muscle maintenance and keeps you feeling full.',
        priority: Priority.info,
      ));
    }

    if (totalFiber < 15 && meals.isNotEmpty) {
      tips.add(Recommendation(
        icon: '🥦',
        title: 'Boost Your Fiber',
        body: 'Only ${totalFiber.toStringAsFixed(1)}g fiber logged. '
            'Add vegetables, whole grains, or fruits to reach the 25–38g daily goal.',
        priority: Priority.medium,
      ));
    }

    if (fatPct > 1.2) {
      overallScore = HealthScore.needsAttention;
      tips.add(Recommendation(
        icon: '🫀',
        title: 'High Fat Intake',
        body: 'Fat intake at ${totalFat.toStringAsFixed(0)}g exceeds the target of '
            '${fatGoalG.toStringAsFixed(0)}g. Choose grilled over fried and reduce '
            'added oils.',
        priority: Priority.high,
      ));
    }

    if (meals.length >= 3 && mealTypes.length < 2) {
      tips.add(Recommendation(
        icon: '🕐',
        title: 'Spread Your Meals',
        body: 'All meals logged at the same time of day. Regular meal intervals '
            '(every 3–5 hours) help stabilise blood sugar.',
        priority: Priority.low,
      ));
    }

    if (meals.isEmpty) {
      tips.add(Recommendation(
        icon: '📸',
        title: 'Start Tracking!',
        body: 'No meals logged yet today. Snap a photo of your next meal to begin '
            'your nutrition journey.',
        priority: Priority.info,
      ));
    }

    final hour = DateTime.now().hour;
    if (hour >= 14 && hour < 18) {
      tips.add(Recommendation(
        icon: '💧',
        title: 'Hydration Check',
        body: 'Afternoon slump? Drink a glass of water — dehydration often mimics '
            'hunger and reduces concentration.',
        priority: Priority.low,
      ));
    }

    tips.sort((a, b) => a.priority.index.compareTo(b.priority.index));

    debugPrint('[Recommendations] Generated ${tips.length} tips, score=$overallScore');

    return MealRecommendation(
      calorieGoal: calorieGoal,
      proteinGoalG: proteinGoalG,
      carbGoalG: carbGoalG,
      fatGoalG: fatGoalG,
      totalCalories: totalCal,
      totalProtein: totalPro,
      totalCarbs: totalCarb,
      totalFat: totalFat,
      totalFiber: totalFiber,
      caloriePct: calPct,
      proteinPct: proPct,
      carbPct: carbPct,
      fatPct: fatPct,
      overallScore: overallScore,
      recommendations: tips,
    );
  }
}

enum HealthScore { good, fair, needsAttention }

enum Priority { high, medium, low, info }

class Recommendation {
  final String icon;
  final String title;
  final String body;
  final Priority priority;

  const Recommendation({
    required this.icon,
    required this.title,
    required this.body,
    required this.priority,
  });
}

class MealRecommendation {
  final double calorieGoal;
  final double proteinGoalG;
  final double carbGoalG;
  final double fatGoalG;
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final double totalFiber;
  final double caloriePct;
  final double proteinPct;
  final double carbPct;
  final double fatPct;
  final HealthScore overallScore;
  final List<Recommendation> recommendations;

  const MealRecommendation({
    required this.calorieGoal,
    required this.proteinGoalG,
    required this.carbGoalG,
    required this.fatGoalG,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.totalFiber,
    required this.caloriePct,
    required this.proteinPct,
    required this.carbPct,
    required this.fatPct,
    required this.overallScore,
    required this.recommendations,
  });

  String get scoreLabel {
    switch (overallScore) {
      case HealthScore.good: return 'On Track 🎯';
      case HealthScore.fair: return 'Could Improve 📈';
      case HealthScore.needsAttention: return 'Needs Attention ⚠️';
    }
  }
}
