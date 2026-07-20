import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

/// On-device food classification service.
///
/// Supports two modes:
/// 1. **TFLite mode** (Android/iOS/desktop): Uses a bundled .tflite model
///    for real inference. Requires `tflite_flutter` package + trained model.
/// 2. **Fallback mode** (web or no model): Returns empty predictions,
///    letting the UI fall back to manual food search.
class FoodClassifierService {
  static const String _modelAssetPath = 'assets/model/food_classifier.tflite';
  static const String _labelsPath = 'assets/model/food_labels.txt';
  static const int inputSize = 224;

  List<String> _labels = [];
  bool _modelLoaded = false;
  dynamic _interpreter; // Will be tflite_flutter Interpreter when available

  /// Whether the classifier has a loaded model and can classify.
  bool get isAvailable => _modelLoaded;

  /// All loaded labels.
  List<String> get labels => _labels;

  /// Load labels and attempt to load the TFLite model.
  Future<void> load() async {
    try {
      // Load labels (always works — labels are a plain text asset)
      final labelsStr = await rootBundle.loadString(_labelsPath);
      _labels = labelsStr
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();
      debugPrint('[FoodClassifier] Loaded ${_labels.length} labels');

      // Skip TFLite on web — dart:ffi is not available
      if (kIsWeb) {
        debugPrint('[FoodClassifier] Web platform — using search fallback');
        _modelLoaded = false;
        return;
      }

      // Try to load the TFLite model from assets
      try {
        final modelData = await rootBundle.load(_modelAssetPath);
        if (modelData.lengthInBytes > 0) {
          // Model file exists — attempt to create interpreter
          // NOTE: Uncomment these lines after adding tflite_flutter to pubspec:
          // import 'package:tflite_flutter/tflite_flutter.dart';
          // _interpreter = await Interpreter.fromAsset(_modelAssetPath);
          // _modelLoaded = true;
          debugPrint('[FoodClassifier] Model file found (${modelData.lengthInBytes} bytes)');
          debugPrint('[FoodClassifier] To enable inference, add tflite_flutter to pubspec.yaml');
          _modelLoaded = false; // Set to true once tflite_flutter is added
        }
      } catch (e) {
        debugPrint('[FoodClassifier] No model file bundled — using search fallback');
        _modelLoaded = false;
      }
    } catch (e) {
      debugPrint('[FoodClassifier] Failed to load labels: $e');
      _modelLoaded = false;
    }
  }

  /// Preprocess an image for model input: decode, resize to 224×224, normalize.
  /// Returns a [Float32List] of shape [1, 224, 224, 3] ready for inference.
  Float32List? preprocessImage(Uint8List imageBytes) {
    try {
      // Decode image
      final image = img.decodeImage(imageBytes);
      if (image == null) return null;

      // Resize to model input size
      final resized = img.copyResize(image, width: inputSize, height: inputSize);

      // Convert to float32 array normalized to [0, 1]
      final input = Float32List(1 * inputSize * inputSize * 3);
      int idx = 0;
      for (int y = 0; y < inputSize; y++) {
        for (int x = 0; x < inputSize; x++) {
          final pixel = resized.getPixel(x, y);
          input[idx++] = pixel.r / 255.0;
          input[idx++] = pixel.g / 255.0;
          input[idx++] = pixel.b / 255.0;
        }
      }

      return input;
    } catch (e) {
      debugPrint('[FoodClassifier] Image preprocessing failed: $e');
      return null;
    }
  }

  /// Classify a food image. Returns top-N predictions sorted by confidence.
  /// Returns empty list if model is not loaded or inference fails.
  Future<List<FoodPrediction>> classify(Uint8List imageBytes, {int topN = 5}) async {
    if (!_modelLoaded || _labels.isEmpty || _interpreter == null) {
      return [];
    }

    final input = preprocessImage(imageBytes);
    if (input == null) return [];

    try {
      // Prepare output buffer: [1][numClasses] probabilities
      final outputBuffer = List<List<double>>.generate(
        1,
        (_) => List<double>.filled(_labels.length, 0.0),
      );

      // Run inference
      // NOTE: Uncomment after adding tflite_flutter to pubspec.yaml:
      // _interpreter.run(input.buffer, outputBuffer);

      // Parse results
      final probabilities = outputBuffer[0];
      final predictions = <FoodPrediction>[];

      for (int i = 0; i < probabilities.length && i < _labels.length; i++) {
        predictions.add(FoodPrediction(
          label: _labels[i],
          displayName: labelToDisplayName(_labels[i]),
          confidence: probabilities[i],
        ));
      }

      // Sort by confidence descending, return top N
      predictions.sort((a, b) => b.confidence.compareTo(a.confidence));
      return predictions.take(topN).toList();
    } catch (e) {
      debugPrint('[FoodClassifier] Inference failed: $e');
      return [];
    }
  }


  /// Convert a label like 'chicken_curry' to 'Chicken Curry'.
  String labelToDisplayName(String label) {
    return label
        .split('_')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }

  void dispose() {
    _interpreter?.close();
  }
}

/// A single food prediction with confidence score.
class FoodPrediction {
  final String label;
  final String displayName;
  final double confidence;

  const FoodPrediction({
    required this.label,
    required this.displayName,
    required this.confidence,
  });
}
