import 'dart:convert';
import 'dart:js_interop';
import 'package:flutter/foundation.dart';

/// Bridges Dart ↔ TensorFlow.js MobileNet running in the browser.
/// Only available on Flutter Web.
class WebClassifierService {
  bool _ready = false;

  /// Whether the TF.js model is loaded and ready.
  bool get isReady => _ready;

  /// Load the MobileNet model (downloads ~16MB on first use, cached after).
  Future<bool> load() async {
    if (!kIsWeb) return false;

    try {
      final result = await _loadModel().toDart;
      _ready = result.toDart;
      debugPrint('[WebClassifier] Model loaded: $_ready');
      return _ready;
    } catch (e) {
      debugPrint('[WebClassifier] Failed to load: $e');
      return false;
    }
  }

  /// Classify image bytes. Returns list of {className, probability}.
  Future<List<WebPrediction>> classify(Uint8List imageBytes) async {
    if (!kIsWeb || !_ready) return [];

    try {
      final jsBytes = imageBytes.toJS;
      final resultJson = await _classifyBytes(jsBytes).toDart;
      final jsonStr = resultJson.toDart;

      if (jsonStr.isEmpty || jsonStr == '[]') return [];

      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((item) {
        return WebPrediction(
          className: item['className'] as String,
          probability: (item['probability'] as num).toDouble(),
        );
      }).toList();
    } catch (e) {
      debugPrint('[WebClassifier] Classification error: $e');
      return [];
    }
  }
}

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

// ─── JS Interop bindings ────────────────────────────────────

@JS('loadClassifierModel')
external JSPromise<JSBoolean> _loadModel();

@JS('classifyImageBytes')
external JSPromise<JSString> _classifyBytes(JSUint8Array bytes);
