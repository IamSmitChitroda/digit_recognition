import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as img;

/// Captures the drawing from the RepaintBoundary, resizes to 28x28,
/// and normalizes pixel values to produce a [1][784] float input for MNIST.
class ImageUtils {
  /// Captures the RepaintBoundary widget identified by [key],
  /// processes into a 28×28 grayscale normalized float list.
  ///
  /// Returns a `[1][784]` shaped list of lists (doubles) ready for TFLite inference.
  static Future<List<List<double>>> captureAndProcess(
    RenderRepaintBoundary boundary,
  ) async {
    // 1. Capture the boundary as a ui.Image (3x pixel ratio for quality)
    final ui.Image image = await boundary.toImage(pixelRatio: 1.0);

    // 2. Convert to byte data (RGBA format)
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) throw Exception('Failed to capture image data');

    final pixels = byteData.buffer.asUint8List();
    final width = image.width;
    final height = image.height;

    // 3. Create an image using the `image` package
    final imgLib = img.Image(width: width, height: height);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final index = (y * width + x) * 4;
        final r = pixels[index];
        final g = pixels[index + 1];
        final b = pixels[index + 2];
        final a = pixels[index + 3];
        imgLib.setPixelRgba(x, y, r, g, b, a);
      }
    }

    // 4. Resize to 28x28 using Lanczos interpolation
    final resized = img.copyResize(
      imgLib,
      width: 28,
      height: 28,
      interpolation: img.Interpolation.average,
    );

    // 5. Extract grayscale values and normalize to 0.0-1.0
    final List<double> flatPixels = [];
    for (int y = 0; y < 28; y++) {
      for (int x = 0; x < 28; x++) {
        final pixel = resized.getPixel(x, y);
        // Use luminance (grayscale) — white strokes on black bg
        final grayscale = (pixel.r * 0.299 + pixel.g * 0.587 + pixel.b * 0.114) / 255.0;
        flatPixels.add(grayscale);
      }
    }

    return [flatPixels]; // Shape: [1, 784]
  }
}
