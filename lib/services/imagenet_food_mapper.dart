
class ImageNetFoodMapper {

  static const double minConfidence = 0.10;

  static const Map<String, String> _mapping = {

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

    'lobster': 'lobster_bisque',
    'crab': 'crab_cakes',
    'sushi': 'sushi',

    'chocolate sauce': 'chocolate_cake',
    'pretzel': 'churros',
    'bagel': 'donuts',

    'noodle': 'ramen',
    'ramen': 'ramen',
    'dumpling': 'dumplings',

    'curry': 'chicken_curry',

    'banana': 'banana',
    'orange': 'apple',
    'strawberry': 'strawberry_shortcake',
    'broccoli': 'edamame',
  };

  static String? mapToFoodId(String imageNetClass) {
    final lower = imageNetClass.toLowerCase();

    for (final entry in _mapping.entries) {
      if (lower.contains(entry.key)) {
        return entry.value;
      }
    }

    return null;
  }

  static List<MappedPrediction> mapPredictions(
    List<MapEntry<String, double>> predictions,
  ) {
    final seen = <String>{};
    final results = <MappedPrediction>[];

    for (final pred in predictions) {

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

