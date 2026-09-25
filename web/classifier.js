
let _mobilenetModel = null;
let _modelLoading = false;

async function loadClassifierModel() {
  if (_mobilenetModel) return true;
  if (_modelLoading) {

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

async function classifyImageBytes(uint8Array) {
  try {

    const loaded = await loadClassifierModel();
    if (!loaded) return '[]';

    const blob = new Blob([uint8Array], { type: 'image/jpeg' });
    const url = URL.createObjectURL(blob);

    const img = document.getElementById('tfjs-img');
    await new Promise((resolve, reject) => {
      img.onload = resolve;
      img.onerror = reject;
      img.src = url;
    });

    const canvas = document.getElementById('tfjs-canvas');
    canvas.width = 224;
    canvas.height = 224;
    const ctx = canvas.getContext('2d');
    ctx.drawImage(img, 0, 0, 224, 224);

    URL.revokeObjectURL(url);

    const predictions = await _mobilenetModel.classify(canvas, 10);

    console.log('[YOTRACKEZ] Predictions:', predictions);
    return JSON.stringify(predictions);
  } catch (e) {
    console.error('[YOTRACKEZ] Classification error:', e);
    return '[]';
  }
}

function isClassifierReady() {
  return _mobilenetModel !== null;
}

