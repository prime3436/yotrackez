class NutrientInfo {
  final String name;
  final double amount;
  final String unit;
  final double? dailyPercent;

  const NutrientInfo({
    required this.name,
    required this.amount,
    required this.unit,
    this.dailyPercent,
  });

  factory NutrientInfo.fromJson(Map<String, dynamic> json) {
    return NutrientInfo(
      name: json['name'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      unit: json['unit'] as String? ?? 'g',
      dailyPercent: (json['daily_percent'] as num?)?.toDouble(),
    );
  }

  NutrientInfo scale(double factor) => NutrientInfo(
        name: name,
        amount: amount * factor,
        unit: unit,
        dailyPercent: dailyPercent == null ? null : dailyPercent! * factor,
      );
}

/// Nutritional data for a single ingredient within a dish.
class IngredientData {
  final String name;
  final String amount;
  final double calories;
  final double carbs;
  final double protein;
  final double fat;
  final double fiber;

  const IngredientData({
    required this.name,
    required this.amount,
    required this.calories,
    required this.carbs,
    required this.protein,
    required this.fat,
    required this.fiber,
  });

  factory IngredientData.fromJson(Map<String, dynamic> json) {
    return IngredientData(
      name: json['name'] as String? ?? '',
      amount: json['amount'] as String? ?? '',
      calories: (json['calories'] as num?)?.toDouble() ?? 0,
      carbs: (json['carbs'] as num?)?.toDouble() ?? 0,
      protein: (json['protein'] as num?)?.toDouble() ?? 0,
      fat: (json['fat'] as num?)?.toDouble() ?? 0,
      fiber: (json['fiber'] as num?)?.toDouble() ?? 0,
    );
  }

  double get totalMacroGrams => carbs + protein + fat;

  IngredientData scale(double factor) => IngredientData(
        name: name,
        amount: amount,
        calories: calories * factor,
        carbs: carbs * factor,
        protein: protein * factor,
        fat: fat * factor,
        fiber: fiber * factor,
      );
}

class NutritionData {
  final String foodName;
  final String servingSize;
  final double calories;
  final NutrientInfo carbs;
  final NutrientInfo protein;
  final NutrientInfo fat;
  final NutrientInfo fiber;
  final NutrientInfo sugar;
  final NutrientInfo sodium;
  final NutrientInfo cholesterol;
  final List<NutrientInfo> vitamins;
  final List<IngredientData> ingredients;
  final String healthTip;
  final String foodCategory;
  final String portionConfidence;

  const NutritionData({
    required this.foodName,
    required this.servingSize,
    required this.calories,
    required this.carbs,
    required this.protein,
    required this.fat,
    required this.fiber,
    required this.sugar,
    required this.sodium,
    required this.cholesterol,
    required this.vitamins,
    required this.ingredients,
    required this.healthTip,
    this.foodCategory = 'mixed',
    this.portionConfidence = 'medium',
  });

  /// Whether this food has an ingredient breakdown.
  bool get hasIngredients => ingredients.isNotEmpty;

  factory NutritionData.fromJson(Map<String, dynamic> json) {
    return NutritionData(
      foodName: json['food_name'] as String? ?? 'Unknown Food',
      servingSize: json['serving_size'] as String? ?? '1 serving',
      calories: (json['calories'] as num?)?.toDouble() ?? 0,
      carbs: NutrientInfo.fromJson(
        json['carbs'] as Map<String, dynamic>? ?? {},
      ),
      protein: NutrientInfo.fromJson(
        json['protein'] as Map<String, dynamic>? ?? {},
      ),
      fat: NutrientInfo.fromJson(
        json['fat'] as Map<String, dynamic>? ?? {},
      ),
      fiber: NutrientInfo.fromJson(
        json['fiber'] as Map<String, dynamic>? ?? {},
      ),
      sugar: NutrientInfo.fromJson(
        json['sugar'] as Map<String, dynamic>? ?? {},
      ),
      sodium: NutrientInfo.fromJson(
        json['sodium'] as Map<String, dynamic>? ?? {},
      ),
      cholesterol: NutrientInfo.fromJson(
        json['cholesterol'] as Map<String, dynamic>? ?? {},
      ),
      vitamins: (json['vitamins'] as List<dynamic>?)
              ?.map(
                (v) => NutrientInfo.fromJson(v as Map<String, dynamic>),
              )
              .toList() ??
          [],
      ingredients: (json['ingredients'] as List<dynamic>?)
              ?.map(
                (i) => IngredientData.fromJson(i as Map<String, dynamic>),
              )
              .toList() ??
          [],
      healthTip: json['health_tip'] as String? ?? '',
      foodCategory: json['food_category'] as String? ?? 'mixed',
      portionConfidence: json['portion_confidence'] as String? ?? 'medium',
    );
  }

  /// Scales every nutritional value for a user-confirmed portion adjustment.
  /// The original serving description is preserved so callers can label the
  /// chosen multiplier clearly instead of guessing a new volume or weight.
  NutritionData scale(double factor) => NutritionData(
        foodName: foodName,
        servingSize: servingSize,
        calories: calories * factor,
        carbs: carbs.scale(factor),
        protein: protein.scale(factor),
        fat: fat.scale(factor),
        fiber: fiber.scale(factor),
        sugar: sugar.scale(factor),
        sodium: sodium.scale(factor),
        cholesterol: cholesterol.scale(factor),
        vitamins: vitamins.map((v) => v.scale(factor)).toList(),
        ingredients: ingredients.map((i) => i.scale(factor)).toList(),
        healthTip: healthTip,
        foodCategory: foodCategory,
        portionConfidence: portionConfidence,
      );

  /// Keeps vision-derived meal details while replacing its estimated nutrient
  /// values with a matched nutrition-database serving.
  NutritionData withNutritionFrom(NutritionData source) => NutritionData(
        foodName: foodName,
        servingSize: servingSize,
        calories: source.calories,
        carbs: source.carbs,
        protein: source.protein,
        fat: source.fat,
        fiber: source.fiber,
        sugar: source.sugar,
        sodium: source.sodium,
        cholesterol: source.cholesterol,
        vitamins: source.vitamins,
        ingredients: ingredients,
        healthTip: healthTip,
        foodCategory: foodCategory,
        portionConfidence: portionConfidence,
      );

  double get totalMacroGrams => carbs.amount + protein.amount + fat.amount;

  double get carbsPercent =>
      totalMacroGrams > 0 ? (carbs.amount / totalMacroGrams) : 0;
  double get proteinPercent =>
      totalMacroGrams > 0 ? (protein.amount / totalMacroGrams) : 0;
  double get fatPercent =>
      totalMacroGrams > 0 ? (fat.amount / totalMacroGrams) : 0;
}
