import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/scanned_product.dart';

/// Looks up product nutrition data by barcode via the Open Food Facts API.
/// Free, no API key required, no rate limiting for reasonable use.
///
/// IMPORTANT: send a real User-Agent identifying your app — the API docs
/// specifically ask for this, and generic/missing User-Agents are more
/// likely to get deprioritized. Update the constant below with your real
/// app name/version/contact before shipping.
class OpenFoodFactsService {
  final http.Client _client;

  /// Inject a client for testing (see the test file for an example using
  /// http's MockClient). Defaults to a real client in production.
  OpenFoodFactsService({http.Client? client}) : _client = client ?? http.Client();

  static const _userAgent = 'YOTRACKEZ/1.0 (nutri-snap; contact: yotrackez@example.com)';
  static const _baseUrl = 'https://world.openfoodfacts.org/api/v2/product';

  // Only request the fields we actually use — shrinks the response
  // significantly (the full product object is huge, see the raw API
  // response if you're curious just how huge).
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

      // status == 1 means found, status == 0 means not found — verified
      // against a real API response, not assumed.
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
