/**
 * YOTRACKEZ — In-Browser Food Classifier
 * Uses TensorFlow.js MobileNet to classify food images.
 * Called from Dart via JS interop.
 */

// Global model reference (loaded once, reused)
let _mobilenetModel = null;
let _modelLoading = false;

/**
 * Load MobileNet model (lazy, cached after first call).
 * Returns true when ready.
 */
async function loadClassifierModel() {
  if (_mobilenetModel) return true;
  if (_modelLoading) {
    // Wait for ongoing load
    while (_modelLoading) {
      await new Promise(r => setTimeout(r, 100));
    }
    return _mobilenetModel !== null;
  }

  _modelLoading = true;
  try {
    console.log('[YOTRACKEZ] Loading MobileNet model...');
    _mobilenetModel = await mobilenet.load({ version: 2, alpha: 1.0 });
    console.log('[YOTRACKEZ] MobileNet model loaded!');
    _modelLoading = false;
    return true;
  } catch (e) {
    console.error('[YOTRACKEZ] Failed to load model:', e);
    _modelLoading = false;
    return false;
  }
}

/**
 * Classify an image from raw bytes (Uint8Array).
 * Returns a JSON string of predictions:
 * [{"className": "pizza", "probability": 0.92}, ...]
 */
async function classifyImageBytes(uint8Array) {
  try {
    // Ensure model is loaded
    const loaded = await loadClassifierModel();
    if (!loaded) return '[]';

    // Convert bytes to image via canvas
    const blob = new Blob([uint8Array], { type: 'image/jpeg' });
    const url = URL.createObjectURL(blob);

    const img = document.getElementById('tfjs-img');
    await new Promise((resolve, reject) => {
      img.onload = resolve;
      img.onerror = reject;
      img.src = url;
    });

    // Draw to canvas (MobileNet needs an HTMLImageElement or canvas)
    const canvas = document.getElementById('tfjs-canvas');
    canvas.width = 224;
    canvas.height = 224;
    const ctx = canvas.getContext('2d');
    ctx.drawImage(img, 0, 0, 224, 224);

    // Clean up blob URL
    URL.revokeObjectURL(url);

    // Run classification
    const predictions = await _mobilenetModel.classify(canvas, 10);

    console.log('[YOTRACKEZ] Predictions:', predictions);
    return JSON.stringify(predictions);
  } catch (e) {
    console.error('[YOTRACKEZ] Classification error:', e);
    return '[]';
  }
}

/**
 * Check if the model is loaded and ready.
 */
function isClassifierReady() {
  return _mobilenetModel !== null;
}
