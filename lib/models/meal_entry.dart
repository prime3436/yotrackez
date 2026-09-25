
class MealEntry {
  final int? id;
  final String foodName;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final String mealType;
  final DateTime timestamp;
  final String? imagePath;

  MealEntry({
    this.id,
    required this.foodName,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.mealType,
    required this.timestamp,
    this.imagePath,
  });

  MealEntry copyWith({
    int? id,
    String? foodName,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    double? fiber,
    String? mealType,
    DateTime? timestamp,
    String? imagePath,
  }) {
    return MealEntry(
      id: id ?? this.id,
      foodName: foodName ?? this.foodName,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      fiber: fiber ?? this.fiber,
      mealType: mealType ?? this.mealType,
      timestamp: timestamp ?? this.timestamp,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  static String getMealType(DateTime time) {
    final hour = time.hour;
    if (hour >= 6 && hour < 11) return 'breakfast';
    if (hour >= 11 && hour < 15) return 'lunch';
    if (hour >= 15 && hour < 18) return 'snack';
    return 'dinner';
  }

  static String getMealEmoji(String type) {
    switch (type) {
      case 'breakfast': return '🌅';
      case 'lunch': return '☀️';
      case 'snack': return '🍪';
      case 'dinner': return '🌙';
      default: return '🍽️';
    }
  }

  static String getMealLabel(String type) {
    switch (type) {
      case 'breakfast': return 'Breakfast';
      case 'lunch': return 'Lunch';
      case 'snack': return 'Snack';
      case 'dinner': return 'Dinner';
      default: return 'Meal';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'foodName': foodName,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'mealType': mealType,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'imagePath': imagePath,
    };
  }

  factory MealEntry.fromMap(Map<String, dynamic> map) {
    return MealEntry(
      id: map['id'] as int?,
      foodName: map['foodName'] as String,
      calories: (map['calories'] as num).toDouble(),
      protein: (map['protein'] as num).toDouble(),
      carbs: (map['carbs'] as num).toDouble(),
      fat: (map['fat'] as num).toDouble(),
      fiber: (map['fiber'] as num).toDouble(),
      mealType: map['mealType'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      imagePath: map['imagePath'] as String?,
    );
  }
}
