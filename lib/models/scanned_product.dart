
class ScannedProduct {
  final String barcode;
  final String name;
  final String? brand;

  final double caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;

  final double? packageQuantityGrams;

  final String? imageUrl;

  final String? nutriScoreGrade;

  const ScannedProduct({
    required this.barcode,
    required this.name,
    this.brand,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
    this.packageQuantityGrams,
    this.imageUrl,
    this.nutriScoreGrade,
  });

  MealLogEntryData forPortion(double grams) {
    final ratio = grams / 100.0;
    return MealLogEntryData(
      productName: name,
      grams: grams,
      calories: caloriesPer100g * ratio,
      protein: proteinPer100g * ratio,
      carbs: carbsPer100g * ratio,
      fat: fatPer100g * ratio,
    );
  }
}

class MealLogEntryData {
  final String productName;
  final double grams;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  const MealLogEntryData({
    required this.productName,
    required this.grams,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });
}

sealed class BarcodeLookupResult {}

class BarcodeLookupSuccess extends BarcodeLookupResult {
  final ScannedProduct product;
  BarcodeLookupSuccess(this.product);
}

class BarcodeLookupNotFound extends BarcodeLookupResult {
  final String barcode;
  BarcodeLookupNotFound(this.barcode);
}

class BarcodeLookupError extends BarcodeLookupResult {
  final String message;
  BarcodeLookupError(this.message);
}
