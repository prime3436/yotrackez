import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/nutrition_data.dart';
import 'nutrition_db_service.dart';

class NutritionLookupService {
  static NutritionLookupService? _instance;
  static NutritionLookupService get instance {
    _instance ??= NutritionLookupService._();
    return _instance!;
  }
  NutritionLookupService._();

  static const Duration _timeout = Duration(seconds: 10);

  Future<NutritionData?> lookup(String foodName) async {

    final local = NutritionDbService.instance.lookupByName(foodName);
    if (local != null) {
      debugPrint('[NutritionLookup] Hit local DB for "$foodName"');
      return local;
    }

    try {
      final off = await _lookupOpenFoodFacts(foodName);
      if (off != null) {
        debugPrint('[NutritionLookup] Hit OpenFoodFacts for "$foodName"');
        return off;
      }
    } catch (e) {
      debugPrint('[NutritionLookup] OpenFoodFacts error: $e');
    }

    try {
      final usda = await _lookupUSDA(foodName);
      if (usda != null) {
        debugPrint('[NutritionLookup] Hit USDA FoodData for "$foodName"');
        return usda;
      }
    } catch (e) {
      debugPrint('[NutritionLookup] USDA error: $e');
    }

    debugPrint('[NutritionLookup] All sources missed for "$foodName"');
    return null;
  }

  Future<NutritionData?> _lookupOpenFoodFacts(String foodName) async {
    final query = Uri.encodeQueryComponent(foodName);
    final uri = Uri.parse(
        'https://world.openfoodfacts.org/cgi/search.pl'
        '?search_terms=$query&search_simple=1&action=process&json=1&page_size=1');

    final resp = await http.get(uri,
        headers: {'User-Agent': 'NutriSnap-Yotrackez/1.0'}).timeout(_timeout);

    if (resp.statusCode != 200) return null;
    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    final products = json['products'] as List?;
    if (products == null || products.isEmpty) return null;

    final p = products[0] as Map<String, dynamic>;
    final n = p['nutriments'] as Map<String, dynamic>?;
    if (n == null) return null;

    double d(String key) =>
        (n['${key}_100g'] as num?)?.toDouble() ?? 0.0;

    final cal100 = d('energy-kcal');
    final serving = (p['serving_size'] as String?) ?? '100g';

    double servingG = 100.0;
    final servingMatch = RegExp(r'(\d+\.?\d*)').firstMatch(serving);
    if (servingMatch != null) {
      servingG = double.tryParse(servingMatch.group(1)!) ?? 100.0;
    }
    final ratio = servingG / 100.0;

    NutrientInfo ni(String key, String name, String unit) => NutrientInfo(
          name: name,
          amount: d(key) * ratio,
          unit: unit,
          dailyPercent: null,
        );

    return NutritionData(
      foodName: (p['product_name'] as String?)?.isNotEmpty == true
          ? p['product_name'] as String
          : foodName,
      servingSize: serving,
      calories: cal100 * ratio,
      carbs: ni('carbohydrates', 'Carbohydrates', 'g'),
      protein: ni('proteins', 'Protein', 'g'),
      fat: ni('fat', 'Fat', 'g'),
      fiber: ni('fiber', 'Fiber', 'g'),
      sugar: ni('sugars', 'Sugar', 'g'),
      sodium: NutrientInfo(
          name: 'Sodium',
          amount: d('sodium') * ratio * 1000,
          unit: 'mg',
          dailyPercent: null),
      cholesterol: const NutrientInfo(name: 'Cholesterol', amount: 0, unit: 'mg'),
      vitamins: [],
      ingredients: [],
      healthTip: 'Data sourced from Open Food Facts (openfoodfacts.org).',
    );
  }

  Future<NutritionData?> _lookupUSDA(String foodName) async {

    const apiKey = 'DEMO_KEY';
    final query = Uri.encodeQueryComponent(foodName);
    final uri = Uri.parse(
        'https://api.nal.usda.gov/fdc/v1/foods/search'
        '?query=$query&pageSize=1&dataType=SR%20Legacy,Foundation,Survey%20(FNDDS)&api_key=$apiKey');

    final resp = await http.get(uri).timeout(_timeout);
    if (resp.statusCode != 200) return null;

    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    final foods = json['foods'] as List?;
    if (foods == null || foods.isEmpty) return null;

    final food = foods[0] as Map<String, dynamic>;
    final nutrients = food['foodNutrients'] as List? ?? [];

    double nutrient(int fdcId) {
      for (final n in nutrients) {
        final m = n as Map<String, dynamic>;
        if (m['nutrientId'] == fdcId) {
          return (m['value'] as num?)?.toDouble() ?? 0.0;
        }
      }
      return 0.0;
    }

    final cal = nutrient(1008);
    final carbs = nutrient(1005);
    final protein = nutrient(1003);
    final fat = nutrient(1004);
    final fiber = nutrient(1079);
    final sugar = nutrient(2000);
    final sodium = nutrient(1093);
    final cholesterol = nutrient(1253);
    final vitC = nutrient(1162);
    final vitA = nutrient(1104);

    NutrientInfo nInfo(String name, double amount, String unit) =>
        NutrientInfo(name: name, amount: amount, unit: unit, dailyPercent: null);

    return NutritionData(
      foodName: food['description'] as String? ?? foodName,
      servingSize: '100g',
      calories: cal,
      carbs: nInfo('Carbohydrates', carbs, 'g'),
      protein: nInfo('Protein', protein, 'g'),
      fat: nInfo('Fat', fat, 'g'),
      fiber: nInfo('Fiber', fiber, 'g'),
      sugar: nInfo('Sugar', sugar, 'g'),
      sodium: nInfo('Sodium', sodium, 'mg'),
      cholesterol: nInfo('Cholesterol', cholesterol, 'mg'),
      vitamins: [
        NutrientInfo(
            name: 'Vitamin C',
            amount: vitC,
            unit: 'mg',
            dailyPercent: vitC / 90 * 100),
        NutrientInfo(
            name: 'Vitamin A',
            amount: vitA / 9,
            unit: '%DV',
            dailyPercent: vitA / 900),
      ],
      ingredients: [],
      healthTip: 'Data sourced from USDA FoodData Central.',
    );
  }
}
