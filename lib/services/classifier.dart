import 'package:tflite_flutter/tflite_flutter.dart';

/// Service that loads the MNIST TFLite model and runs digit classification.
class DigitClassifier {
  Interpreter? _interpreter;
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  /// Loads the TFLite model from assets.
  Future<void> loadModel() async {
    try {
      // _interpreter = await Interpreter.fromAsset('model/mnist_model.tflite');
      _interpreter = await Interpreter.fromAsset('assets/model/mnist_model.tflite');
      _isLoaded = true;
    } catch (e) {
      _isLoaded = false;
      rethrow;
    }
  }

  /// Classifies the input image data.
  ///
  /// [input] should be shaped [1][784] — a flattened 28×28 grayscale image
  /// with values normalized to 0.0–1.0.
  ///
  /// Returns a [ClassificationResult] with the predicted digit and confidences.
  ClassificationResult classify(List<List<double>> input) {
    if (_interpreter == null) {
      throw Exception('Model not loaded. Call loadModel() first.');
    }

    // Output shape: [1][10] — one probability per digit (0-9)
    final output = List.filled(10, 0.0).reshape([1, 10]);

    _interpreter!.run(input, output);

    final probabilities = (output[0] as List<double>);

    // Find the digit with highest confidence
    int predictedDigit = 0;
    double maxConfidence = probabilities[0];
    for (int i = 1; i < probabilities.length; i++) {
      if (probabilities[i] > maxConfidence) {
        maxConfidence = probabilities[i];
        predictedDigit = i;
      }
    }

    return ClassificationResult(
      predictedDigit: predictedDigit,
      confidences: List<double>.from(probabilities),
    );
  }

  /// Releases model resources.
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isLoaded = false;
  }
}

/// Result of a digit classification.
class ClassificationResult {
  final int predictedDigit;
  final List<double> confidences;

  const ClassificationResult({
    required this.predictedDigit,
    required this.confidences,
  });

  double get confidence => confidences[predictedDigit];
}