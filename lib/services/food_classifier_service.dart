import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

class FoodClassifierService {
  static const String _modelAssetPath = 'assets/model/food_classifier.tflite';
  static const String _labelsPath = 'assets/model/food_labels.txt';
  static const int inputSize = 224;

  List<String> _labels = [];
  bool _modelLoaded = false;
  dynamic _interpreter;

  bool get isAvailable => _modelLoaded;

  List<String> get labels => _labels;

  Future<void> load() async {
    try {

      final labelsStr = await rootBundle.loadString(_labelsPath);
      _labels = labelsStr
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();
      debugPrint('[FoodClassifier] Loaded ${_labels.length} labels');

      if (kIsWeb) {
        debugPrint('[FoodClassifier] Web platform — using search fallback');
        _modelLoaded = false;
        return;
      }

      try {
        final modelData = await rootBundle.load(_modelAssetPath);
        if (modelData.lengthInBytes > 0) {

          debugPrint('[FoodClassifier] Model file found (${modelData.lengthInBytes} bytes)');
          debugPrint('[FoodClassifier] To enable inference, add tflite_flutter to pubspec.yaml');
          _modelLoaded = false;
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

  Float32List? preprocessImage(Uint8List imageBytes) {
    try {

      final image = img.decodeImage(imageBytes);
      if (image == null) return null;

      final resized = img.copyResize(image, width: inputSize, height: inputSize);

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

  Future<List<FoodPrediction>> classify(Uint8List imageBytes, {int topN = 5}) async {
    if (!_modelLoaded || _labels.isEmpty || _interpreter == null) {
      return [];
    }

    final input = preprocessImage(imageBytes);
    if (input == null) return [];

    try {

      final outputBuffer = List<List<double>>.generate(
        1,
        (_) => List<double>.filled(_labels.length, 0.0),
      );

      final probabilities = outputBuffer[0];
      final predictions = <FoodPrediction>[];

      for (int i = 0; i < probabilities.length && i < _labels.length; i++) {
        predictions.add(FoodPrediction(
          label: _labels[i],
          displayName: labelToDisplayName(_labels[i]),
          confidence: probabilities[i],
        ));
      }

      predictions.sort((a, b) => b.confidence.compareTo(a.confidence));
      return predictions.take(topN).toList();
    } catch (e) {
      debugPrint('[FoodClassifier] Inference failed: $e');
      return [];
    }
  }

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
