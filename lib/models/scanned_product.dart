/// A product looked up via barcode, with per-100g nutrition data.
/// Field names/structure verified directly against a real Open Food Facts
/// API response (not guessed) — see OpenFoodFactsService for the mapping.
class ScannedProduct {
  final String barcode;
  final String name;
  final String? brand;

  /// Per-100g values — Open Food Facts reports nutrition this way by
  /// default. Multiply by (gramsEaten / 100) to get the actual amount for
  /// whatever portion the user logs.
  final double caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;

  /// The package's own stated quantity (e.g. "400 g"), if available —
  /// useful as a default/suggested portion, NOT the same as per-100g data.
  final double? packageQuantityGrams;

  final String? imageUrl;

  /// Nutri-Score grade (a-e), if Open Food Facts has computed one. Purely
  /// informational — don't build any pass/fail logic around it, it's a
  /// coarse label, not a precision metric.
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

  /// Computes actual nutrition for a given portion size in grams.
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

/// Ready-to-log values for a specific portion — hand this straight to
/// whatever creates a MealLogEntry in your existing meal-logging flow.
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

/// Result wrapper distinguishing "not found" from "network/parse error"
/// so the UI can show the right message for each.
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
