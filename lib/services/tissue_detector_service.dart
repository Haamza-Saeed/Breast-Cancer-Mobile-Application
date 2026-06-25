import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class TissueDetectorService {
  static const String _assetKey = 'assets/models/tissue_detector.tflite';
  Interpreter? _interpreter;

  Future<void> init() async {
    _interpreter ??= await Interpreter.fromAsset(_assetKey);
  }

  Future<double> predictTissueProbability(Uint8List imageBytes) async {
    final interpreter = _interpreter;
    if (interpreter == null) {
      throw Exception("Interpreter is null. Call init() first.");
    }

    img.Image? decoded = img.decodeImage(imageBytes);
    if (decoded == null) throw Exception("Invalid image bytes");

    // ✅ 1) Fix camera rotation (EXIF)
    decoded = img.bakeOrientation(decoded);

    // ✅ 2) Center-crop to square to reduce background
    // This helps a LOT for camera photos where tissue is in the middle.
    final int side = decoded.width < decoded.height ? decoded.width : decoded.height;
    final int x0 = (decoded.width - side) ~/ 2;
    final int y0 = (decoded.height - side) ~/ 2;
    final cropped = img.copyCrop(decoded, x: x0, y: y0, width: side, height: side);

    // ✅ 3) Resize to model input
    final resized = img.copyResize(cropped, width: 224, height: 224, interpolation: img.Interpolation.linear);

    // ✅ 4) Build Float32 input [1,224,224,3] normalized (0..1)
    final input = Float32List(1 * 224 * 224 * 3);
    int i = 0;

    for (int y = 0; y < 224; y++) {
      for (int x = 0; x < 224; x++) {
        final p = resized.getPixel(x, y);
        input[i++] = p.r / 255.0;
        input[i++] = p.g / 255.0;
        input[i++] = p.b / 255.0;
      }
    }

    final output = List.generate(1, (_) => List.filled(1, 0.0));
    interpreter.run(input.reshape([1, 224, 224, 3]), output);
    return output[0][0];
  }

  Future<bool> isTissue(Uint8List bytes, {double threshold = 0.80}) async {
    final p = await predictTissueProbability(bytes);
    return p >= threshold;
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}

extension _Reshape on Float32List {
  List reshape(List<int> shape) {
    final b = shape[0], h = shape[1], w = shape[2], c = shape[3];
    int idx = 0;
    return List.generate(b, (_) {
      return List.generate(h, (_) {
        return List.generate(w, (_) {
          return List.generate(c, (_) => this[idx++]);
        });
      });
    });
  }
}
