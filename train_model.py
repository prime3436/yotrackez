"""
YOTRACKEZ — Food-101 TFLite Model Trainer
==========================================
Trains a MobileNetV2 classifier on the Food-101 dataset and exports
it as a TFLite model for on-device inference in the Flutter app.

Usage:
  pip install tensorflow tensorflow-datasets Pillow
  python train_model.py

The script will:
  1. Download the Food-101 dataset (~5 GB)
  2. Fine-tune MobileNetV2 (pretrained on ImageNet)
  3. Export to assets/model/food_classifier.tflite

Estimated time:
  - GPU (Colab T4): ~15-20 minutes
  - CPU: ~3-4 hours

After training, add `tflite_flutter: ^0.11.0` to pubspec.yaml
and uncomment the interpreter lines in food_classifier_service.dart.
"""

import os
import sys
import json
import pathlib

SCRIPT_DIR = pathlib.Path(__file__).parent
ASSETS_DIR = SCRIPT_DIR / "assets"
MODEL_DIR = ASSETS_DIR / "model"
MODEL_DIR.mkdir(parents=True, exist_ok=True)

OUTPUT_TFLITE = MODEL_DIR / "food_classifier.tflite"
LABELS_FILE = MODEL_DIR / "food_labels.txt"

IMG_SIZE = 224
BATCH_SIZE = 32
EPOCHS = 10


def load_labels():
    """Read the label file to ensure our model outputs match."""
    with open(LABELS_FILE, "r") as f:
        labels = [line.strip() for line in f if line.strip()]
    print(f"[INFO] Loaded {len(labels)} labels from {LABELS_FILE}")
    return labels


def main():
    print("=" * 60)
    print("  YOTRACKEZ — Food-101 Model Trainer")
    print("=" * 60)

    try:
        import tensorflow as tf
        import tensorflow_datasets as tfds
        print(f"[OK] TensorFlow {tf.__version__}")
        print(f"[OK] GPU available: {len(tf.config.list_physical_devices('GPU')) > 0}")
    except ImportError as e:
        print(f"[ERROR] Missing dependency: {e}")
        print("  Run: pip install tensorflow tensorflow-datasets")
        sys.exit(1)

    labels = load_labels()
    num_classes = len(labels)
    print(f"[INFO] Training for {num_classes} food classes")

    print("\n[STEP 1/4] Loading Food-101 dataset...")

    ds_info = tfds.builder("food101").info
    tfds_labels = ds_info.features["label"].names

    label_map = {}
    for i, tfds_label in enumerate(tfds_labels):
        if tfds_label in labels:
            label_map[i] = labels.index(tfds_label)

    print(f"[INFO] Mapped {len(label_map)}/{len(tfds_labels)} TFDS labels to our labels")

    def preprocess(example):
        """Resize image and normalize pixels to [0, 1]."""
        image = tf.image.resize(example["image"], [IMG_SIZE, IMG_SIZE])
        image = tf.cast(image, tf.float32) / 255.0
        label = example["label"]
        return image, label

    train_ds = tfds.load("food101", split="train", as_supervised=False)
    val_ds = tfds.load("food101", split="validation", as_supervised=False)

    train_ds = (
        train_ds
        .map(preprocess, num_parallel_calls=tf.data.AUTOTUNE)
        .shuffle(1000)
        .batch(BATCH_SIZE)
        .prefetch(tf.data.AUTOTUNE)
    )

    val_ds = (
        val_ds
        .map(preprocess, num_parallel_calls=tf.data.AUTOTUNE)
        .batch(BATCH_SIZE)
        .prefetch(tf.data.AUTOTUNE)
    )

    print("\n[STEP 2/4] Building MobileNetV2 model...")

    base_model = tf.keras.applications.MobileNetV2(
        input_shape=(IMG_SIZE, IMG_SIZE, 3),
        include_top=False,
        weights="imagenet",
    )

    base_model.trainable = False

    model = tf.keras.Sequential([
        base_model,
        tf.keras.layers.GlobalAveragePooling2D(),
        tf.keras.layers.Dropout(0.3),
        tf.keras.layers.Dense(256, activation="relu"),
        tf.keras.layers.Dropout(0.2),
        tf.keras.layers.Dense(num_classes, activation="softmax"),
    ])

    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=0.001),
        loss="sparse_categorical_crossentropy",
        metrics=["accuracy"],
    )

    model.summary()

    print(f"\n[STEP 3/4] Training for {EPOCHS} epochs...")

    history = model.fit(
        train_ds,
        validation_data=val_ds,
        epochs=max(EPOCHS // 2, 3),
        callbacks=[
            tf.keras.callbacks.EarlyStopping(
                patience=3, restore_best_weights=True
            ),
        ],
    )

    print("\n[INFO] Fine-tuning base model layers...")
    base_model.trainable = True
    for layer in base_model.layers[:-30]:
        layer.trainable = False

    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=0.0001),
        loss="sparse_categorical_crossentropy",
        metrics=["accuracy"],
    )

    history = model.fit(
        train_ds,
        validation_data=val_ds,
        epochs=EPOCHS,
        initial_epoch=len(history.epoch),
        callbacks=[
            tf.keras.callbacks.EarlyStopping(
                patience=3, restore_best_weights=True
            ),
        ],
    )

    val_loss, val_acc = model.evaluate(val_ds)
    print(f"\n[RESULT] Validation accuracy: {val_acc:.1%}")

    print("\n[STEP 4/4] Converting to TFLite...")

    converter = tf.lite.TFLiteConverter.from_keras_model(model)

    converter.optimizations = [tf.lite.Optimize.DEFAULT]


    tflite_model = converter.convert()

    with open(OUTPUT_TFLITE, "wb") as f:
        f.write(tflite_model)

    size_mb = os.path.getsize(OUTPUT_TFLITE) / (1024 * 1024)
    print(f"\n{'=' * 60}")
    print(f"  ✅ Model saved to: {OUTPUT_TFLITE}")
    print(f"  📦 Model size: {size_mb:.1f} MB")
    print(f"  🎯 Validation accuracy: {val_acc:.1%}")
    print(f"{'=' * 60}")
    print()
    print("Next steps:")
    print("  1. Add to pubspec.yaml:  tflite_flutter: ^0.11.0")
    print("  2. Uncomment interpreter lines in food_classifier_service.dart")
    print("  3. Run: flutter pub get")
    print("  4. Deploy to Android/iOS for on-device inference!")


if __name__ == "__main__":
    main()
