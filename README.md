# Digit Recognition

A beautifully designed Flutter application that leverages an on-device TensorFlow Lite model to recognize handwritten digits.

## Overview & Workflow

The app provides an interactive canvas where users can draw a single digit (0-9). The workflow operates entirely on-device:

1. **Drawing Canvas**: The user draws on a custom white-on-black canvas that accurately tracks strokes (following the MNIST dataset format).
2. **Image Processing**:
   - The drawing is captured from the UI.
   - It is resized to 28×28 pixels.
   - The image is converted to grayscale, and pixel values are normalized to floats between `0.0` and `1.0`.
   - The final processed matrix reshapes to a continuous `[1][784]` array.
3. **Inference**:
   - The normalized array is passed into the pre-trained `.tflite` model.
   - The model computes the probabilities for each digit (0-9).
4. **Displaying Results**: The app animates and displays the predicted digit along with a confidence bar chart for all 10 possible classes.

---

## Python Directory & Model Creation

The `Python/` directory contains the pipeline utilized to train and export the underlying Artificial Neural Network (ANN) used in this Flutter app.

### How the Model is Built (`Python/main.py`)

1. **Data Loading**: The model uses the standard MNIST dataset provided by `keras.datasets`.
2. **Preprocessing**: 
   - Pixel values are normalized by dividing by 255.0.
   - Labels are One-Hot Encoded.
3. **Architecture**: 
   - A Sequential model with an `Input(shape=(28, 28))` layer.
   - `Flatten()` layer.
   - Two hidden `Dense` layers with 128 and 64 units, and `relu` activation.
   - An output `Dense` layer with 10 units (for digits 0-9) and `sigmoid` activation.
4. **Training**: The model is compiled using `adam` optimizer and `categorical_crossentropy` loss, and trained for 5 epochs.
5. **TFLite Conversion**: 
   - Once trained, the saved Keras model is loaded into `lite.TFLiteConverter`.
   - Default optimizations (`[lite.Optimize.DEFAULT]`) are applied to reduce the size and improve latency specifically for mobile devices.
   - The resulting optimized `.tflite` model is exported and placed into the Flutter app's `assets/model/` folder.

## Getting Started

1. Clone this repository.
2. Ensure you have Flutter installed.
3. Run `flutter pub get` to install dependencies (including `tflite_flutter` and `image`).
4. Run `flutter run` to test the app on your preferred emulator or physical device.
