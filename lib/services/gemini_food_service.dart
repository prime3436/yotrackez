import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/nutrition_data.dart';
import 'api_key_service.dart';

/// Gemini Vision-based food recognition service.
///
/// Sends a food image to the Gemini API and gets back:
/// - Food identification
/// - Full ingredient breakdown with per-ingredient nutrition
/// - Total nutrition facts
///
/// This is a SEPARATE service from the MobileNet classifier.
/// It requires a Gemini API key to function.
class GeminiFoodService {
  static GeminiFoodService? _instance;

  GeminiFoodService._();

  static GeminiFoodService get instance {
    _instance ??= GeminiFoodService._();
    return _instance!;
  }

  /// Whether the service is available (API key is set).
  bool get isAvailable => ApiKeyService.instance.hasApiKey;

  /// Analyze a food image using Gemini Vision.
  /// Returns a NutritionData object with full ingredient breakdown.
  /// Throws on error so the caller can display the message.
  Future<NutritionData?> analyzeFood(Uint8List imageBytes) async {
    final apiKey = ApiKeyService.instance.apiKey;
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('No API key configured. Tap ⚙️ to add one.');
    }

    debugPrint('[GeminiFood] Analyzing food image (${imageBytes.length} bytes)...');

    // Convert image to base64
    final base64Image = base64Encode(imageBytes);

    // Build the request
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

    // Make the API call
    final http.Response response;
    // Make the API call with retry for rate limits
    const maxRetries = 3;
    final models = [
      'gemini-2.5-flash',
      'gemini-2.0-flash',
      'gemini-2.0-flash-lite',
    ];
    
    http.Response? lastResponse;
    
    for (var attempt = 0; attempt < maxRetries; attempt++) {
      final model = models[attempt.clamp(0, models.length - 1)];
      final url = 'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey';
      
      try {
        lastResponse = await http.post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestBody),
        );
      } catch (e) {
        throw Exception('Network error: Could not reach Gemini API. Check your internet connection.');
      }

      if (lastResponse.statusCode == 429) {
        // Rate limited — wait and retry with next model
        final waitSecs = (attempt + 1) * 3; // 3s, 6s, 9s
        debugPrint('[GeminiFood] Rate limited. Waiting ${waitSecs}s, trying $model...');
        await Future.delayed(Duration(seconds: waitSecs));
        continue;
      }
      
      // Not rate limited — break out
      break;
    }
    
    response = lastResponse!;

    // Check for API errors
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

    // Parse the Gemini response
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

    // Parse the JSON from Gemini's response
    try {
      final foodJson = jsonDecode(text) as Map<String, dynamic>;

      // Check for "not food" response
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

  /// Build the prompt that tells Gemini what to return.
  String _buildPrompt() {
    return '''Analyze this food image and identify the food item(s). Return a JSON object with detailed nutrition information.

RULES:
- Identify the PRIMARY food item in the image
- If it's a complex dish (curry, biryani, etc.), list ALL ingredients with individual nutrition
- If it's a simple item (banana, apple, bread), don't include ingredients array
- Use realistic nutrition values based on standard serving sizes
- All nutrition values should be per serving

Return EXACTLY this JSON structure (no markdown, no explanation):
{
  "food_name": "Name of the food",
  "serving_size": "1 serving description with weight",
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
  "health_tip": "One-line health tip about this food"
}

If the image does NOT contain food, return:
{"food_name": "Not Food", "error": true}''';
  }

  /// Check if a Gemini response indicates "not food".
  static bool isNotFood(NutritionData? data) {
    if (data == null) return true;
    return data.foodName == 'Not Food';
  }
}
