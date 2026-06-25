import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class GateHistologyDetector {
  Interpreter? _interpreter;

  static final GateHistologyDetector instance = GateHistologyDetector._();
  GateHistologyDetector._();

  bool get isReady => _interpreter != null;

  Future<void> init() async {
    if (_interpreter != null) return;

    final modelData = await rootBundle.load('assets/models/gate_histology.tflite');

    final options = InterpreterOptions()..threads = 4;

    _interpreter = Interpreter.fromBuffer(
      modelData.buffer.asUint8List(),
      options: options,
    );
  }

  /// Returns probability that input is histology (microscope slide).
  Future<double> predictHistologyProb(Uint8List bytes) async {
    final interpreter = _interpreter;
    if (interpreter == null) {
      throw StateError('GateHistologyDetector not initialized. Call init() first.');
    }

    // Decode image
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw Exception('Cannot decode image.');
    }

    // Resize to 224x224
    final resized = img.copyResize(decoded, width: 224, height: 224);

    // Input tensor [1,224,224,3] float32
    // MobileNetV2 preprocess: (x / 127.5) - 1.0  => [-1, 1]
    final input = List.generate(1, (_) {
      return List.generate(224, (y) {
        return List.generate(224, (x) {
          final pixel = resized.getPixel(x, y);

          // ✅ FIX: use pixel.r/g/b (new image package)
          final r = pixel.r.toDouble();
          final g = pixel.g.toDouble();
          final b = pixel.b.toDouble();

          final rr = (r / 127.5) - 1.0;
          final gg = (g / 127.5) - 1.0;
          final bb = (b / 127.5) - 1.0;

          return [rr, gg, bb];
        });
      });
    });

    // Output tensor [1,1]
    final output = List.generate(1, (_) => List.filled(1, 0.0));

    interpreter.run(input, output);

    return output[0][0];
  }

  /// True means it's a histology slide (allowed for BreakHis)
  Future<bool> isHistology(Uint8List bytes, {double threshold = 0.95}) async {
    final p = await predictHistologyProb(bytes);
    return p >= threshold;
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}