// lib/services/ai_models.dart

import 'package:project/services/tissue_detector_service.dart';
import 'package:project/services/breakhis_classifier.dart';



/// ✅ AI MODELS MANAGER FILE
///
/// This file keeps all your TFLite models initialized globally.
/// So you can access them anywhere in the app without loading again.

/// ✅ Tissue Detector Model (Step-1)
final TissueDetectorService tissueDetector = TissueDetectorService();
final breakhisClassifier = BreakHisClassifierService(
  debugPrints: false,
);





/// ------------------------------------------------------------
/// Future Models Can Be Added Here Later
/// Example:
///
/// final CancerClassifierService cancerClassifier =
///     CancerClassifierService();
///
/// final BenignMalignantService benignMalignantModel =
///     BenignMalignantService();
/// ------------------------------------------------------------
