/// Maps ImageNet/MobileNet class names to our Food-101 database IDs.
///
/// MobileNet outputs ImageNet class names like "pizza, pizza pie" or "cheeseburger".
/// This mapping converts those to our food IDs like "pizza" or "hamburger".
///
/// Only DIRECT food-to-food mappings are kept. Nonsensical mappings
/// (e.g. banana → pancakes, plate → fried_rice) have been removed.
class ImageNetFoodMapper {
  /// Minimum confidence threshold — below this, don't suggest.
  static const double minConfidence = 0.10;

  /// Maps lowercase ImageNet class substrings to our food database IDs.
  /// Only direct, sensible food-to-food mappings.
  static const Map<String, String> _mapping = {
    // Direct food matches
    'pizza': 'pizza',
    'cheeseburger': 'hamburger',
    'hotdog': 'hot_dog',
    'hot dog': 'hot_dog',
    'ice cream': 'ice_cream',
    'ice lolly': 'frozen_yogurt',
    'burrito': 'breakfast_burrito',
    'guacamole': 'guacamole',
    'carbonara': 'spaghetti_carbonara',
    'meat loaf': 'steak',
    'french fries': 'french_fries',
    'taco': 'tacos',

    // Seafood
    'lobster': 'lobster_bisque',
    'crab': 'crab_cakes',
    'sushi': 'sushi',

    // Baked goods & desserts
    'chocolate sauce': 'chocolate_cake',
    'pretzel': 'churros',
    'bagel': 'donuts',

    // Asian food
    'noodle': 'ramen',
    'ramen': 'ramen',
    'dumpling': 'dumplings',

    // Indian food
    'curry': 'chicken_curry',

    // Standalone items (new entries in DB)
    'banana': 'banana',
    'orange': 'apple',
    'strawberry': 'strawberry_shortcake',
    'broccoli': 'edamame',
  };

  /// Try to map an ImageNet class name to one of our food IDs.
  /// Returns null if no match found.
  static String? mapToFoodId(String imageNetClass) {
    final lower = imageNetClass.toLowerCase();

    // Try exact substring matches
    for (final entry in _mapping.entries) {
      if (lower.contains(entry.key)) {
        return entry.value;
      }
    }

    return null;
  }

  /// Map multiple predictions and return unique food IDs with best confidence.
  /// Returns a list of (foodId, confidence) tuples, deduplicated.
  /// Filters out predictions below [minConfidence].
  static List<MappedPrediction> mapPredictions(
    List<MapEntry<String, double>> predictions,
  ) {
    final seen = <String>{};
    final results = <MappedPrediction>[];

    for (final pred in predictions) {
      // Skip low-confidence predictions
      if (pred.value < minConfidence) continue;

      final foodId = mapToFoodId(pred.key);
      if (foodId != null && !seen.contains(foodId)) {
        seen.add(foodId);
        results.add(MappedPrediction(
          foodId: foodId,
          confidence: pred.value,
          originalClass: pred.key,
        ));
      }
    }

    return results;
  }
}

class MappedPrediction {
  final String foodId;
  final double confidence;
  final String originalClass;

  const MappedPrediction({
    required this.foodId,
    required this.confidence,
    required this.originalClass,
  });
}

