import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/nutrition_data.dart';

class NutritionDbService {
  static NutritionDbService? _instance;
  List<Map<String, dynamic>> _foods = [];
  bool _loaded = false;

  NutritionDbService._();

  static NutritionDbService get instance {
    _instance ??= NutritionDbService._();
    return _instance!;
  }

  Future<void> load() async {
    if (_loaded) return;
    final jsonStr = await rootBundle.loadString('assets/data/nutrition_db.json');
    final list = jsonDecode(jsonStr) as List<dynamic>;
    _foods = list.cast<Map<String, dynamic>>();
    _loaded = true;
    debugPrint('[NutritionDB] Loaded ${_foods.length} foods');

  }

  List<String> get allFoodNames =>
      _foods.map((f) => f['food_name'] as String).toList();

  List<FoodEntry> get allFoods => _foods
      .map((f) => FoodEntry(
            id: f['id'] as String,
            name: f['food_name'] as String,
            servingSize: f['serving_size'] as String,
            calories: (f['calories'] as num).toDouble(),
          ))
      .toList();

  NutritionData? lookupById(String id) {
    final entry = _foods.where((f) => f['id'] == id).firstOrNull;
    if (entry == null) return null;
    return NutritionData.fromJson(entry);
  }

  NutritionData? lookupByName(String name) {
    final lower = name.toLowerCase();
    final entry = _foods.where(
      (f) => (f['food_name'] as String).toLowerCase() == lower,
    ).firstOrNull;
    if (entry == null) return null;
    return NutritionData.fromJson(entry);
  }

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
