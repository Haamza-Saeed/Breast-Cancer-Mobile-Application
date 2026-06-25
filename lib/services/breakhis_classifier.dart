import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class BreakHisResult {
  final String label;
  final double confidence;
  final bool isMalignant;

  final List<MapEntry<String, double>> topK;
  final String debugText;

  final List<double> rawOutput;
  final List<double> probs;
  final List<int> inputShape;
  final List<int> outputShape;

  BreakHisResult({
    required this.label,
    required this.confidence,
    required this.isMalignant,
    required this.topK,
    required this.debugText,
    required this.rawOutput,
    required this.probs,
    required this.inputShape,
    required this.outputShape,
  });
}

class BreakHisClassifierService {
  static const String _modelAsset = 'assets/models/breakhis_resnet.tflite';
  static const String _labelsAsset = 'assets/models/labels.txt';

  Interpreter? _interpreter;
  List<String> _labels = [];

  final bool debugPrints;

  BreakHisClassifierService({this.debugPrints = true});

  Future<void> init() async {
    if (_interpreter != null) return;

    _interpreter = await Interpreter.fromAsset(_modelAsset);

    final raw = await rootBundle.loadString(_labelsAsset);
    _labels = raw
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final inTensor = _interpreter!.getInputTensor(0);
    final outTensor = _interpreter!.getOutputTensor(0);
    final outLen = _outputLength(outTensor.shape);

    if (debugPrints) {
      debugPrint("✅ BreakHis model loaded");
      debugPrint("INPUT  shape=${inTensor.shape} type=${inTensor.type}");
      debugPrint("OUTPUT shape=${outTensor.shape} type=${outTensor.type}");
      debugPrint("labels.txt count=${_labels.length}");
      debugPrint("outLen=$outLen");
    }

    if (outLen != _labels.length) {
      throw Exception(
        "❌ Model output length ($outLen) != labels length (${_labels.length}). "
            "Fix labels.txt order or export correct model.",
      );
    }
  }

  Future<BreakHisResult> predict(Uint8List imageBytes, {int topK = 5}) async {
    final interpreter = _interpreter;
    if (interpreter == null) throw Exception("Call init() first.");

    final inputTensor = interpreter.getInputTensor(0);
    final outputTensor = interpreter.getOutputTensor(0);
    final inputShape = inputTensor.shape;
    final outputShape = outputTensor.shape;
    final outLen = _outputLength(outputShape);

    final log = StringBuffer();
    log.writeln("🧠 BreakHis Debug Trace");
    log.writeln("----------------------------------");
    log.writeln("Tensors:");
    log.writeln("  inputShape = $inputShape");
    log.writeln("  outputShape = $outputShape");
    log.writeln("  outLen = $outLen");
    log.writeln("----------------------------------");

    // 1) Decode
    img.Image? decoded = img.decodeImage(imageBytes);
    if (decoded == null) throw Exception("Invalid image bytes");
    log.writeln("Image decoded: ${decoded.width}x${decoded.height}");

    // 2) Fix EXIF orientation
    decoded = img.bakeOrientation(decoded);

    // ✅ 3) Resize directly (MATCH TRAINING)
    final resized = img.copyResize(
      decoded,
      width: 224,
      height: 224,
      interpolation: img.Interpolation.linear,
    );
    log.writeln("Resized: 224x224");

    // ✅ 4) ResNet preprocess_input (MATCH TRAINING)
    // training: img / 127.5 - 1
    final input = Float32List(1 * 224 * 224 * 3);
    int idx = 0;

    for (int y = 0; y < 224; y++) {
      for (int x = 0; x < 224; x++) {
        final p = resized.getPixel(x, y);

        // ResNet50 preprocess_input (caffe mode):
// 1) keep 0..255
// 2) BGR order
// 3) subtract mean
        const double meanB = 103.939;
        const double meanG = 116.779;
        const double meanR = 123.68;

        final r = p.r.toDouble();
        final g = p.g.toDouble();
        final b = p.b.toDouble();

// BGR + mean subtraction
        input[idx++] = b - meanB;
        input[idx++] = g - meanG;
        input[idx++] = r - meanR;

      }
    }

    // 5) Output buffer
    final output = List.generate(1, (_) => List.filled(outLen, 0.0));

    // 6) Run inference
    interpreter.run(input.reshape([1, 224, 224, 3]), output);

    // 7) Raw output
    final rawOut = output[0].map((e) => e.toDouble()).toList();
    log.writeln("Raw output: $rawOut");

    // 8) probs (your model already uses softmax)
    final probs = rawOut;

    // 9) label mapping check
    log.writeln("Label mapping (index -> label):");
    for (int i = 0; i < _labels.length; i++) {
      log.writeln("  [$i] ${_labels[i]}");
    }

    // 10) argmax
    int bestIdx = 0;
    double bestVal = probs[0];
    for (int k = 1; k < probs.length; k++) {
      if (probs[k] > bestVal) {
        bestVal = probs[k];
        bestIdx = k;
      }
    }

    // 11) topK
    final pairs = <MapEntry<String, double>>[];
    for (int k = 0; k < probs.length; k++) {
      pairs.add(MapEntry(_labels[k], probs[k]));
    }
    pairs.sort((a, b) => b.value.compareTo(a.value));
    final top = pairs.take(math.min(topK, pairs.length)).toList();

    final bestLabel = _labels[bestIdx];
    final isMalignant = bestLabel.startsWith("malignant_");

    log.writeln("----------------------------------");
    log.writeln("FINAL:");
    log.writeln("  bestIdx=$bestIdx");
    log.writeln("  label=$bestLabel");
    log.writeln("  confidence=${(bestVal * 100).toStringAsFixed(2)}%");
    log.writeln("  isMalignant=$isMalignant");

    if (debugPrints) debugPrint(log.toString());

    return BreakHisResult(
      label: bestLabel,
      confidence: bestVal,
      isMalignant: isMalignant,
      topK: top,
      debugText: log.toString(),
      rawOutput: rawOut,
      probs: probs,
      inputShape: inputShape,
      outputShape: outputShape,
    );
  }

  int _outputLength(List<int> shape) => shape.isEmpty ? 0 : shape.last;

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _labels = [];
  }
}

extension _ReshapeF32 on Float32List {
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
