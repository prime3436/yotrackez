import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Preprocessing pipeline for food images before AI analysis.
///
/// Pipeline stages:
///   1. Decode raw bytes → img.Image
///   2. Auto-orient (EXIF rotation)
///   3. Resize to max 640px on longest side (preserves aspect ratio)
///   4. Normalize brightness / contrast (basic histogram stretch)
///   5. Re-encode as JPEG at target quality
///   6. Return [PreprocessedImage] with metadata
class ImagePreprocessor {
  static const int _maxDimension = 640;
  static const int _defaultQuality = 82;

  /// Preprocess [rawBytes] for AI ingestion.
  ///
  /// Throws if the bytes cannot be decoded as an image.
  static Future<PreprocessedImage> process(Uint8List rawBytes) async {
    return compute(_processInIsolate, _ProcessArgs(rawBytes, _maxDimension, _defaultQuality));
  }

  /// Internal entry point executed in an isolate.
  static PreprocessedImage _processInIsolate(_ProcessArgs args) {
    final decoded = img.decodeImage(args.rawBytes);
    if (decoded == null) {
      throw Exception('ImagePreprocessor: could not decode image bytes.');
    }

    // 1. Auto-orient (handles EXIF rotation from camera)
    final oriented = img.bakeOrientation(decoded);

    // 2. Resize — keep aspect ratio, cap longest side at maxDimension
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

    // 3. Normalize brightness — gentle contrast enhancement
    final normalized = _normalizeContrast(resized);

    // 4. Encode as JPEG
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

  /// Gently stretch contrast by clipping the bottom 1% and top 1% of
  /// per-channel luminance values, then remapping to [0, 255].
  /// This improves recognition accuracy on under/over-exposed shots.
  static img.Image _normalizeContrast(img.Image image) {
    // Collect luminance histogram (Y = 0.299R + 0.587G + 0.114B)
    final hist = List<int>.filled(256, 0);
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final p = image.getPixel(x, y);
        final lum = (0.299 * p.r + 0.587 * p.g + 0.114 * p.b).clamp(0, 255).toInt();
        hist[lum]++;
      }
    }

    final total = image.width * image.height;
    final clip = (total * 0.01).round(); // 1% clip

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

    if (high <= low) return image; // already well-exposed

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

/// Result of image preprocessing with metadata for debugging.
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
