import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/nutrition_data.dart';

/// Loads and queries the bundled nutrition database.
/// No API needed — all data is embedded in the app.
class NutritionDbService {
  static NutritionDbService? _instance;
  List<Map<String, dynamic>> _foods = [];
  bool _loaded = false;

  NutritionDbService._();

  static NutritionDbService get instance {
    _instance ??= NutritionDbService._();
    return _instance!;
  }

  /// Load the nutrition database from assets.
  Future<void> load() async {
    if (_loaded) return;
    final jsonStr = await rootBundle.loadString('assets/data/nutrition_db.json');
    final list = jsonDecode(jsonStr) as List<dynamic>;
    _foods = list.cast<Map<String, dynamic>>();
    _loaded = true;
    debugPrint('[NutritionDB] Loaded ${_foods.length} foods');

  }

  /// Get all food names for search.
  List<String> get allFoodNames =>
      _foods.map((f) => f['food_name'] as String).toList();

  /// Get all food entries (id + display name).
  List<FoodEntry> get allFoods => _foods
      .map((f) => FoodEntry(
            id: f['id'] as String,
            name: f['food_name'] as String,
            servingSize: f['serving_size'] as String,
            calories: (f['calories'] as num).toDouble(),
          ))
      .toList();

  /// Look up nutrition data by food ID (e.g., 'chicken_curry').
  NutritionData? lookupById(String id) {
    final entry = _foods.where((f) => f['id'] == id).firstOrNull;
    if (entry == null) return null;
    return NutritionData.fromJson(entry);
  }

  /// Look up nutrition data by display name (e.g., 'Chicken Curry').
  NutritionData? lookupByName(String name) {
    final lower = name.toLowerCase();
    final entry = _foods.where(
      (f) => (f['food_name'] as String).toLowerCase() == lower,
    ).firstOrNull;
    if (entry == null) return null;
    return NutritionData.fromJson(entry);
  }

  /// Search foods by query (fuzzy match on name).
  List<FoodEntry> search(String query) {
    if (query.isEmpty) return allFoods;
    final lower = query.toLowerCase();
    return _foods
        .where((f) {
          final name = (f['food_name'] as String).toLowerCase();
          final id = (f['id'] as String).toLowerCase();
          return name.contains(lower) || id.contains(lower);
        })
        .map((f) => FoodEntry(
              id: f['id'] as String,
              name: f['food_name'] as String,
              servingSize: f['serving_size'] as String,
              calories: (f['calories'] as num).toDouble(),
            ))
        .toList();
  }
}

/// Lightweight food entry for lists and search results.
class FoodEntry {
  final String id;
  final String name;
  final String servingSize;
  final double calories;

  const FoodEntry({
    required this.id,
    required this.name,
    required this.servingSize,
    required this.calories,
  });
}
