import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_snap/models/nutrition_data.dart';

NutritionData _nutrition() => const NutritionData(
      foodName: 'Rice Bowl',
      servingSize: '1 bowl (200g)',
      calories: 400,
      carbs: NutrientInfo(name: 'Carbohydrates', amount: 80, unit: 'g'),
      protein: NutrientInfo(name: 'Protein', amount: 10, unit: 'g'),
      fat: NutrientInfo(name: 'Fat', amount: 8, unit: 'g'),
      fiber: NutrientInfo(name: 'Fiber', amount: 4, unit: 'g'),
      sugar: NutrientInfo(name: 'Sugar', amount: 2, unit: 'g'),
      sodium: NutrientInfo(name: 'Sodium', amount: 300, unit: 'mg'),
      cholesterol: NutrientInfo(name: 'Cholesterol', amount: 0, unit: 'mg'),
      vitamins: [],
      ingredients: [],
      healthTip: '',
    );

void main() {
  test('portion scaling updates calories and every macro consistently', () {
    final half = _nutrition().scale(0.5);

    expect(half.calories, 200);
    expect(half.carbs.amount, 40);
    expect(half.protein.amount, 5);
    expect(half.fat.amount, 4);
    expect(half.fiber.amount, 2);
    expect(half.sodium.amount, 150);
  });
}
