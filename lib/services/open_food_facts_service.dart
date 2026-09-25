import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/scanned_product.dart';

class OpenFoodFactsService {
  final http.Client _client;

  OpenFoodFactsService({http.Client? client}) : _client = client ?? http.Client();

  static const _userAgent = 'YOTRACKEZ/1.0 (nutri-snap; contact: yotrackez@example.com)';
  static const _baseUrl = 'https://world.openfoodfacts.org/api/v2/product';

  static const _fields = 'product_name,brands,nutriments,product_quantity,'
      'product_quantity_unit,image_url,image_front_url,nutriscore_grade,'
      'status,status_verbose,code';

  Future<BarcodeLookupResult> lookup(String barcode) async {
    final uri = Uri.parse('$_baseUrl/$barcode.json?fields=$_fields');

    try {
      final response = await _client
          .get(uri, headers: {'User-Agent': _userAgent})
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        return BarcodeLookupError(
            'Server returned status ${response.statusCode}');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      final status = json['status'];
      if (status != 1) {
        return BarcodeLookupNotFound(barcode);
      }

      final product = json['product'] as Map<String, dynamic>?;
      if (product == null) {
        return BarcodeLookupNotFound(barcode);
      }

      final nutriments = product['nutriments'] as Map<String, dynamic>?;
      if (nutriments == null) {
        return BarcodeLookupError(
            'Product found but has no nutrition data (common for '
            'incomplete database entries — consider offering manual entry '
            'as a fallback here)');
      }

      final name = (product['product_name'] as String?)?.trim();
      if (name == null || name.isEmpty) {
        return BarcodeLookupError('Product found but has no name recorded');
      }

      final calories = _asDouble(nutriments['energy-kcal_100g']);
      final protein = _asDouble(nutriments['proteins_100g']);
      final carbs = _asDouble(nutriments['carbohydrates_100g']);
      final fat = _asDouble(nutriments['fat_100g']);

      if (calories == null) {
        return BarcodeLookupError(
            'Product found but has no calorie data recorded');
      }

      final brands = product['brands'] as String?;
      final firstBrand =
          (brands != null && brands.isNotEmpty) ? brands.split(',').first.trim() : null;

      return BarcodeLookupSuccess(ScannedProduct(
        barcode: barcode,
        name: name,
        brand: firstBrand,
        caloriesPer100g: calories,
        proteinPer100g: protein ?? 0,
        carbsPer100g: carbs ?? 0,
        fatPer100g: fat ?? 0,
        packageQuantityGrams: _asDouble(product['product_quantity']),
        imageUrl: (product['image_front_url'] ?? product['image_url'])
            as String?,
        nutriScoreGrade: product['nutriscore_grade'] as String?,
      ));
    } on FormatException {
      return BarcodeLookupError('Could not parse the server response');
    } catch (e) {
      return BarcodeLookupError('Network error: $e');
    }
  }

  double? _asDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
