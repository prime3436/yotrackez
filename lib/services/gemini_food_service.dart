import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/nutrition_data.dart';
import 'image_preprocessor.dart';

class GeminiFoodService {
  static GeminiFoodService? _instance;

  GeminiFoodService._();

  static GeminiFoodService get instance {
    _instance ??= GeminiFoodService._();
    return _instance!;
  }

  bool get isAvailable => true;

  Future<NutritionData?> analyzeFood(Uint8List imageBytes) async {

    Uint8List processedBytes;
    try {
      final preprocessed = await ImagePreprocessor.process(imageBytes);
      processedBytes = preprocessed.bytes;
      debugPrint('[GeminiFood] Preprocessed: $preprocessed');
    } catch (e) {
      debugPrint('[GeminiFood] Preprocessing failed ($e), using raw bytes');
      processedBytes = imageBytes;
    }

    const bool useProxy = true;
    debugPrint('[GeminiFood] Analyzing food image (${processedBytes.length} bytes, useProxy=$useProxy)...');

    final base64Image = base64Encode(processedBytes);

    final requestBody = {
      'contents': [
        {
          'parts': [
            {
              'text': _buildPrompt(),
            },
            {
              'inline_data': {
                'mime_type': 'image/jpeg',
                'data': base64Image,
              }
            }
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.1,
        'responseMimeType': 'application/json',
      }
    };

    final http.Response response;
    const maxRetries = 3;

    http.Response? lastResponse;

    for (var attempt = 0; attempt < maxRetries; attempt++) {
      final String url = 'https://nutrisnapproxy.vercel.app/api/analyze';

      try {
        lastResponse = await http.post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestBody),
        ).timeout(const Duration(seconds: 45));
      } catch (e) {
        debugPrint('[GeminiFood] Network error/timeout on attempt $attempt: $e');
        if (attempt == maxRetries - 1) {
          throw Exception('Could not reach Gemini API backend. Please check your internet connection and try again.');
        }
        await Future.delayed(const Duration(milliseconds: 1500));
        continue;
      }

      if (lastResponse.statusCode == 429 || lastResponse.statusCode >= 500) {
        final waitSecs = (attempt + 1) * 2;
        debugPrint('[GeminiFood] Server status ${lastResponse.statusCode}. Waiting ${waitSecs}s, retrying...');
        if (attempt < maxRetries - 1) {
          await Future.delayed(Duration(seconds: waitSecs));
          continue;
        }
      }

      break;
    }

    response = lastResponse!;

    if (response.statusCode == 400) {
      final body = jsonDecode(response.body);
      final msg = body['error']?['message'] ?? 'Bad request';
      throw Exception('API error: $msg');
    } else if (response.statusCode == 403) {
      throw Exception('API key invalid or Gemini API not enabled. Check aistudio.google.com');
    } else if (response.statusCode == 429) {
      throw Exception('Rate limit still exceeded after retries. Wait 1 minute and try again.');
    } else if (response.statusCode != 200) {
      throw Exception('API returned status ${response.statusCode}');
    }

    final responseJson = jsonDecode(response.body);
    final candidates = responseJson['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      debugPrint('[GeminiFood] No candidates in response');
      return null;
    }

    final content = candidates[0]['content'];
    final parts = content['parts'] as List;
    final text = parts[0]['text'] as String;

    debugPrint('[GeminiFood] Got response: ${text.substring(0, text.length.clamp(0, 300))}...');

    try {
      final foodJson = jsonDecode(text) as Map<String, dynamic>;

      if (foodJson['error'] == true || foodJson['food_name'] == 'Not Food') {
        return null;
      }

      return NutritionData.fromJson(foodJson);
    } catch (e) {
      debugPrint('[GeminiFood] JSON parse error: $e');
      debugPrint('[GeminiFood] Raw text: $text');
      throw Exception('Failed to parse Gemini response. Please try again.');
    }
  }

  String _buildPrompt() {
    return '''You are an expert food nutritionist and computer vision system.
Analyze this food image and return a detailed JSON nutrition report.

STEP 1 — FOOD DETECTION:
- Identify all food items visible (primary dish + any sides)
- Classify the food category (e.g. grain, protein, vegetable, dairy, snack)

STEP 2 — PORTION SIZE ESTIMATION:
- Estimate the portion size using visual cues (plate diameter reference ~26cm,
  food height/depth, item count for discrete foods like pieces/slices)
- Express portion as weight in grams AND a human description (e.g. "1 cup (240ml)",
  "1 medium slice (80g)", "1 plate (350g)")
- Set serving_size to this estimate
- Scale all nutrition values to match the estimated portion (not per-100g)

STEP 3 — NUTRITION CALCULATION:
- Use standard USDA/WHO nutrition references
- For complex dishes list ALL major ingredients with per-ingredient nutrition
- For simple items (single fruit, packaged snack) omit the ingredients array

RETURN EXACTLY this JSON (no markdown, no commentary):
{
  "food_name": "Name of the food",
  "food_category": "grain | protein | vegetable | dairy | snack | beverage | mixed",
  "serving_size": "estimated portion with weight e.g. 1 plate (350g)",
  "portion_confidence": "high | medium | low",
  "calories": 0.0,
  "carbs": {"name": "Carbohydrates", "amount": 0.0, "unit": "g", "daily_percent": 0},
  "protein": {"name": "Protein", "amount": 0.0, "unit": "g", "daily_percent": 0},
  "fat": {"name": "Fat", "amount": 0.0, "unit": "g", "daily_percent": 0},
  "fiber": {"name": "Fiber", "amount": 0.0, "unit": "g", "daily_percent": 0},
  "sugar": {"name": "Sugar", "amount": 0.0, "unit": "g", "daily_percent": 0},
  "sodium": {"name": "Sodium", "amount": 0.0, "unit": "mg", "daily_percent": 0},
  "cholesterol": {"name": "Cholesterol", "amount": 0.0, "unit": "mg", "daily_percent": 0},
  "vitamins": [
    {"name": "Vitamin A", "amount": 0.0, "unit": "%DV"},
    {"name": "Vitamin C", "amount": 0.0, "unit": "%DV"}
  ],
  "ingredients": [
    {"name": "Ingredient Name", "amount": "50g", "calories": 0, "carbs": 0, "protein": 0, "fat": 0, "fiber": 0}
  ],
  "health_tip": "One actionable health tip about this specific food"
}

If the image does NOT contain food, return:
{"food_name": "Not Food", "error": true}''';
  }

  static bool isNotFood(NutritionData? data) {
    if (data == null) return true;
    return data.foodName == 'Not Food';
  }
}
