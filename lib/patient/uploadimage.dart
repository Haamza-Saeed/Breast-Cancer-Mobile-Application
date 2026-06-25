import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

import 'package:project/patient/rootpage.dart';
import 'package:project/patient/report.dart';
import 'package:project/services/ai_models.dart';
import 'package:project/l10n/app_localizations.dart';
import 'package:project/services/breakhis_classifier.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:project/services/supabase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project/services/report_generator.dart';
import 'package:uuid/uuid.dart';

import 'package:project/services/gate_histology_detector.dart';

class UploadImage extends StatefulWidget {
  const UploadImage({super.key});

  @override
  State<UploadImage> createState() => _UploadImageState();
}

class _UploadImageState extends State<UploadImage> {
  final ImagePicker _picker = ImagePicker();
  final List<Uint8List?> _selectedImages = List<Uint8List?>.filled(4, null);

  bool _isChecking = false;
  bool _modelsReady = false;

  @override
  void initState() {
    super.initState();
    _initModels();
  }

  Future<void> _initModels() async {
    try {
      await tissueDetector.init();
      await GateHistologyDetector.instance.init();
      await breakhisClassifier.init();

      if (!mounted) return;
      setState(() => _modelsReady = true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _modelsReady = false);

      final t = AppLocalizations.of(context)!;
      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        animType: AnimType.scale,
        title: t.errorTitle,
        desc: "${t.modelLoadingFailed}\n$e",
        btnOkOnPress: () {},
        btnOkText: t.ok,
      ).show();
    }
  }

  void _goBack() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const RootPage()),
          (route) => false,
    );
  }

  int get _selectedCount => _selectedImages.where((e) => e != null).length;

  int? _firstEmptySlot() {
    for (int i = 0; i < _selectedImages.length; i++) {
      if (_selectedImages[i] == null) return i;
    }
    return null;
  }

  void _removeAt(int index) {
    setState(() => _selectedImages[index] = null);
  }

  void _clearSelectedImages() {
    setState(() {
      for (int i = 0; i < _selectedImages.length; i++) {
        _selectedImages[i] = null;
      }
    });
  }

  Future<void> _showInvalidAlert({String? customDesc}) async {
    final t = AppLocalizations.of(context)!;

    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      animType: AnimType.scale,
      title: t.invalidImageTitle,
      desc: customDesc ?? t.invalidImageDesc,
      btnOkOnPress: () {},
      btnOkText: t.ok,
    ).show();
  }

  Future<void> _showLimitAlert() async {
    final t = AppLocalizations.of(context)!;

    AwesomeDialog(
      context: context,
      dialogType: DialogType.info,
      animType: AnimType.scale,
      title: t.limitReachedTitle,
      desc: t.limitReachedDesc,
      btnOkOnPress: () {},
      btnOkText: t.ok,
    ).show();
  }

  Future<void> _showMixedTypeAlert(Set<String> detectedTypes) async {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      animType: AnimType.scale,
      title: "Different Image Types Detected",
      desc:
      "Please upload images of the same type only.\n\nDetected types:\n${detectedTypes.join(", ")}",
      btnOkText: "OK",
      btnOkOnPress: () {},
    ).show();
  }

  Future<void> _showResultDialog({
    required bool isCancerous,
    required String predictedLabel,
    required double confidence,
  }) async {
    final t = AppLocalizations.of(context)!;

    final title = isCancerous ? t.resultCancerous : t.resultNotCancerous;

    final desc =
        "${t.predictionLabel}: $predictedLabel\n${t.confidenceLabel}: ${(confidence * 100).toStringAsFixed(1)}%";

    AwesomeDialog(
      context: context,
      dialogType: isCancerous ? DialogType.warning : DialogType.success,
      animType: AnimType.scale,
      title: title,
      desc: desc,
      btnCancelText: "Cancel",
      btnCancelOnPress: () {
        _clearSelectedImages();
      },
      btnOkText: "View Details",
      btnOkOnPress: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const Report()),
        );
      },
    ).show();
  }

  Future<void> _pushNotification({
    required String uid,
    required String message,
    String? reportId,
    bool isSuccess = true,
  }) async {
    await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("notifications")
        .add({
      "message": message,
      "isRead": false,
      "createdAt": FieldValue.serverTimestamp(),
      "type": "diagnosis",
      "reportId": reportId,
      "status": isSuccess ? "success" : "failed",
    });
  }

  Future<void> _validateAndAdd(Uint8List bytes) async {
    final slot = _firstEmptySlot();

    if (slot == null) {
      await _showLimitAlert();
      return;
    }

    if (!_modelsReady) {
      final t = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.modelsNotReadyYet)),
      );
      return;
    }

    setState(() => _isChecking = true);

    try {
      final okTissue = await tissueDetector.isTissue(bytes, threshold: 0.80);

      if (!mounted) return;

      if (!okTissue) {
        await _showInvalidAlert();
        return;
      }

      final okHistology =
      await GateHistologyDetector.instance.isHistology(bytes, threshold: 0.95);

      if (!mounted) return;

      if (!okHistology) {
        await _showInvalidAlert(
          customDesc:
          "Please upload microscope histology slide images only (not skin photos).",
        );
        return;
      }

      setState(() {
        _selectedImages[slot] = bytes;
      });
    } catch (e) {
      if (!mounted) return;

      final t = AppLocalizations.of(context)!;

      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        animType: AnimType.scale,
        title: t.errorTitle,
        desc: "${t.scanFailedDesc}\n$e",
        btnOkOnPress: () {},
        btnOkText: t.ok,
      ).show();
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _pickFromGallery() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 95,
    );

    if (file == null) return;

    final bytes = await file.readAsBytes();
    await _validateAndAdd(bytes);
  }

  Future<void> _pickFromCamera() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 95,
    );

    if (file == null) return;

    final bytes = await file.readAsBytes();
    await _validateAndAdd(bytes);
  }

  Future<void> _startDiagnose() async {
    final t = AppLocalizations.of(context)!;

    final images = _selectedImages.whereType<Uint8List>().toList();

    if (images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.selectAtLeastOneImage)),
      );
      return;
    }

    if (!_modelsReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.modelsNotReadyYet)),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.pleaseLoginFirst)),
      );
      return;
    }

    setState(() => _isChecking = true);

    try {
      final results = <BreakHisResult>[];

      for (final bytes in images) {
        results.add(await breakhisClassifier.predict(bytes));
      }

      final uniqueLabels = results.map((r) => r.label).toSet();

      if (uniqueLabels.length > 1) {
        if (!mounted) return;

        setState(() => _isChecking = false);

        await _showMixedTypeAlert(uniqueLabels);
        return;
      }

      final counts = <String, int>{};

      for (final r in results) {
        counts[r.label] = (counts[r.label] ?? 0) + 1;
      }

      final predictedLabel =
          counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

      final isMalignant = predictedLabel.startsWith("malignant_");

      final labelConf = results
          .where((r) => r.label == predictedLabel)
          .map((r) => r.confidence)
          .toList();

      final confidence = labelConf.isEmpty
          ? results.map((r) => r.confidence).reduce((a, b) => a + b) /
          results.length
          : labelConf.reduce((a, b) => a + b) / labelConf.length;

      if (!mounted) return;

      final reportText = ReportGenerator.generate(
        predictedLabel: predictedLabel,
        isMalignant: isMalignant,
        confidence: confidence,
      );

      final reportId = const Uuid().v4();

      await SupabaseService.instance.uploadReportImages(
        firebaseUid: user.uid,
        reportId: reportId,
        images: images,
        defaultMime: "image/jpeg",
      );

      await FirebaseFirestore.instance
          .collection("reports")
          .doc(user.uid)
          .collection("items")
          .doc(reportId)
          .set({
        "reportId": reportId,
        "firebaseUid": user.uid,
        "predictedLabel": predictedLabel,
        "isMalignant": isMalignant,
        "confidence": confidence,
        "reportText": reportText,
        "createdAt": FieldValue.serverTimestamp(),
        "imageCount": images.length,
      });

      final percent = (confidence * 100).toStringAsFixed(1);

      final notifMsg = isMalignant
          ? "Diagnosis complete: Cancerous detected ($predictedLabel) with $percent% confidence."
          : "Diagnosis complete: Not cancerous detected with $percent% confidence.";

      await _pushNotification(
        uid: user.uid,
        message: notifMsg,
        reportId: reportId,
        isSuccess: true,
      );

      if (!mounted) return;

      await _showResultDialog(
        isCancerous: isMalignant,
        predictedLabel: predictedLabel,
        confidence: confidence,
      );
    } catch (e) {
      if (!mounted) return;

      try {
        final user = FirebaseAuth.instance.currentUser;

        if (user != null) {
          await _pushNotification(
            uid: user.uid,
            message: "Diagnosis failed. Please try again.",
            isSuccess: false,
          );
        }
      } catch (_) {}

      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        animType: AnimType.scale,
        title: t.errorTitle,
        desc: "${t.scanFailedDesc}\n$e",
        btnOkOnPress: () {},
        btnOkText: t.ok,
      ).show();
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            elevation: 0,
            titleSpacing: 0,
            leading: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Image.asset("assets/images/ribon.png", width: 24),
            ),
            title: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  t.appTitle,
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: const Color(0xffFF67CE),
                  ),
                ),
              ),
            ),
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xffFF67CE),
                          width: 2,
                        ),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Color(0xffFF67CE),
                          size: 18,
                        ),
                        onPressed: _goBack,
                      ),
                    ),
                  ),

                  Image.asset(
                    "assets/images/uploadimage.png",
                    width: 373,
                    height: 249,
                  ),

                  const SizedBox(height: 10),

                  Text(
                    t.uploadImage,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 27,
                      color: const Color(0xffFF67CE),
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    "${t.selectedLabel}: $_selectedCount / 4",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: const Color(0xffFF67CE),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      t.selectYourImages,
                      style: GoogleFonts.poppins(
                        color: const Color(0xffFF67CE),
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isChecking ? null : _pickFromGallery,
                          icon: const Icon(
                            Icons.photo_library,
                            color: Colors.white,
                          ),
                          label: Text(
                            t.gallery,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xffFF67CE),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isChecking ? null : _pickFromCamera,
                          icon: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                          ),
                          label: Text(
                            t.camera,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xffFF67CE),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(4, (index) {
                      final bytes = _selectedImages[index];

                      return Stack(
                        children: [
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xffFF67CE),
                                width: 2,
                              ),
                              image: bytes == null
                                  ? null
                                  : DecorationImage(
                                image: MemoryImage(bytes),
                                fit: BoxFit.cover,
                              ),
                            ),
                            child: bytes == null
                                ? const Icon(
                              Icons.add,
                              color: Color(0xffFF67CE),
                              size: 30,
                            )
                                : null,
                          ),

                          if (bytes != null)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: GestureDetector(
                                onTap: () => _removeAt(index),
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: const BoxDecoration(
                                    color: Color(0xffFF67CE),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    }),
                  ),

                  const SizedBox(height: 18),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      t.note,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xffFF67CE),
                      ),
                    ),
                  ),

                  Text(
                    t.uploadNoteDesc,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xffFF67CE),
                    ),
                  ),

                  const SizedBox(height: 18),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isChecking ? null : _startDiagnose,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xffFF67CE),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        _modelsReady ? t.startDiagnoses : t.loadingModel,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        if (_isChecking)
          Container(
            color: Colors.black.withOpacity(0.35),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }
}