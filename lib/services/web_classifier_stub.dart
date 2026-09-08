import 'dart:typed_data';

/// A prediction from TF.js MobileNet.
class WebPrediction {
  final String className;
  final double probability;

  const WebPrediction({
    required this.className,
    required this.probability,
  });

  @override
  String toString() => '$className (${(probability * 100).toStringAsFixed(1)}%)';
}

/// Stub implementation for non-web platforms.
class WebClassifierService {
  bool get isReady => false;

  Future<bool> load() async => false;

  Future<List<WebPrediction>> classify(Uint8List imageBytes) async => [];
}
