import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class ImagePreprocessor {
  static const int _maxDimension = 640;
  static const int _defaultQuality = 82;

  static Future<PreprocessedImage> process(Uint8List rawBytes) async {
    return compute(_processInIsolate, _ProcessArgs(rawBytes, _maxDimension, _defaultQuality));
  }

  static PreprocessedImage _processInIsolate(_ProcessArgs args) {
    final decoded = img.decodeImage(args.rawBytes);
    if (decoded == null) {
      throw Exception('ImagePreprocessor: could not decode image bytes.');
    }

    final oriented = img.bakeOrientation(decoded);

    img.Image resized;
    final w = oriented.width;
    final h = oriented.height;
    if (w > h) {
      final targetW = w > args.maxDimension ? args.maxDimension : w;
      final targetH = (h * targetW / w).round();
      resized = img.copyResize(oriented, width: targetW, height: targetH,
          interpolation: img.Interpolation.linear);
    } else {
      final targetH = h > args.maxDimension ? args.maxDimension : h;
      final targetW = (w * targetH / h).round();
      resized = img.copyResize(oriented, width: targetW, height: targetH,
          interpolation: img.Interpolation.linear);
    }

    final normalized = _normalizeContrast(resized);

    final outputBytes = img.encodeJpg(normalized, quality: args.quality);

    return PreprocessedImage(
      bytes: Uint8List.fromList(outputBytes),
      originalWidth: w,
      originalHeight: h,
      processedWidth: normalized.width,
      processedHeight: normalized.height,
      originalSizeBytes: args.rawBytes.length,
      processedSizeBytes: outputBytes.length,
    );
  }

  static img.Image _normalizeContrast(img.Image image) {

    final hist = List<int>.filled(256, 0);
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final p = image.getPixel(x, y);
        final lum = (0.299 * p.r + 0.587 * p.g + 0.114 * p.b).clamp(0, 255).toInt();
        hist[lum]++;
      }
    }

    final total = image.width * image.height;
    final clip = (total * 0.01).round();

    int low = 0, high = 255;
    int cumL = 0, cumH = 0;
    for (int i = 0; i < 256; i++) {
      cumL += hist[i];
      if (cumL >= clip) { low = i; break; }
    }
    for (int i = 255; i >= 0; i--) {
      cumH += hist[i];
      if (cumH >= clip) { high = i; break; }
    }

    if (high <= low) return image;

    final range = (high - low).toDouble();

    final out = img.Image(width: image.width, height: image.height);
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final p = image.getPixel(x, y);
        final nr = ((p.r - low) / range * 255).clamp(0, 255).toInt();
        final ng = ((p.g - low) / range * 255).clamp(0, 255).toInt();
        final nb = ((p.b - low) / range * 255).clamp(0, 255).toInt();
        out.setPixelRgb(x, y, nr, ng, nb);
      }
    }
    return out;
  }
}

class _ProcessArgs {
  final Uint8List rawBytes;
  final int maxDimension;
  final int quality;
  const _ProcessArgs(this.rawBytes, this.maxDimension, this.quality);
}

class PreprocessedImage {
  final Uint8List bytes;
  final int originalWidth;
  final int originalHeight;
  final int processedWidth;
  final int processedHeight;
  final int originalSizeBytes;
  final int processedSizeBytes;

  const PreprocessedImage({
    required this.bytes,
    required this.originalWidth,
    required this.originalHeight,
    required this.processedWidth,
    required this.processedHeight,
    required this.originalSizeBytes,
    required this.processedSizeBytes,
  });

  double get compressionRatio =>
      originalSizeBytes > 0 ? processedSizeBytes / originalSizeBytes : 1.0;

  @override
  String toString() =>
      'PreprocessedImage(${originalWidth}x$originalHeight → ${processedWidth}x$processedHeight, '
      '${(originalSizeBytes / 1024).toStringAsFixed(1)}KB → ${(processedSizeBytes / 1024).toStringAsFixed(1)}KB, '
      'ratio=${compressionRatio.toStringAsFixed(2)})';
}
