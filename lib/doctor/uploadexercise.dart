import 'dart:io';
import 'dart:typed_data';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project/doctor/doctorrootpage.dart';
import 'package:project/services/supabase_service.dart';
import 'package:uuid/uuid.dart';

// ✅ Localization
import 'package:project/l10n/app_localizations.dart';

class UploadExercise extends StatefulWidget {
  const UploadExercise({super.key});

  @override
  State<UploadExercise> createState() => _UploadExerciseState();
}

class _UploadExerciseState extends State<UploadExercise> {
  static const Color blue = Color(0xff00AEEF);

  // Keep in sync with SupabaseService.maxUploadBytes if you want
  static const int maxUploadBytes = 15 * 1024 * 1024; // 15MB

  final TextEditingController _title = TextEditingController();
  final TextEditingController _desc = TextEditingController();

  bool _uploading = false;

  // picked media
  File? _pickedFile;
  String _pickedName = "";
  String _pickedType = ""; // image | video

  String get _doctorId => FirebaseAuth.instance.currentUser?.uid ?? "";

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  // ---------------- DIALOG HELPERS (localized) ----------------
  void _successDialog(AppLocalizations? t, String msg) {
    if (!mounted) return;
    AwesomeDialog(
      context: context,
      dialogType: DialogType.success,
      animType: AnimType.scale,
      title: t?.success ?? "Success",
      desc: msg,
      btnOkText: t?.ok ?? "OK",
      btnOkOnPress: () {},
    ).show();
  }

  void _errorDialog(AppLocalizations? t, String msg) {
    if (!mounted) return;
    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      animType: AnimType.scale,
      title: t?.error ?? "Error",
      desc: msg,
      btnOkText: t?.ok ?? "OK",
      btnOkOnPress: () {},
    ).show();
  }

  bool _isImageFile(String fileName) {
    final lower = fileName.toLowerCase();
    return lower.endsWith(".jpg") ||
        lower.endsWith(".jpeg") ||
        lower.endsWith(".png") ||
        lower.endsWith(".webp");
  }

  bool _isVideoFile(String fileName) {
    final lower = fileName.toLowerCase();
    return lower.endsWith(".mp4") ||
        lower.endsWith(".mov") ||
        lower.endsWith(".mkv") ||
        lower.endsWith(".avi") ||
        lower.endsWith(".webm");
  }

  Future<void> _pickMedia(AppLocalizations? t) async {
    if (_uploading) return;

    try {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowMultiple: false,
        allowedExtensions: const [
          // images
          "jpg", "jpeg", "png", "webp",
          // videos
          "mp4", "mov", "mkv", "avi", "webm",
        ],
        withData: false,
      );

      if (res == null || res.files.isEmpty) return;

      final f = res.files.first;
      final path = f.path;
      if (path == null) {
        _errorDialog(t, t?.couldNotReadFilePath ?? "Could not read file path. Try again.");
        return;
      }

      final name = f.name;

      final isImage = _isImageFile(name);
      final isVideo = _isVideoFile(name);

      if (!isImage && !isVideo) {
        _errorDialog(t, t?.onlyImagesAndVideosAllowed ?? "Only images and videos are allowed.");
        return;
      }

      // Best-effort file size check
      final file = File(path);
      int size = 0;
      try {
        size = await file.length();
      } catch (_) {}

      if (size > maxUploadBytes) {
        final fileMb = (size / (1024 * 1024)).toStringAsFixed(2);
        final maxMb = (maxUploadBytes / (1024 * 1024)).toStringAsFixed(0);
        _errorDialog(
          t,
          "${t?.fileTooLarge ?? "File too large"} ($fileMb MB). "
              "${t?.maxAllowed ?? "Max allowed"}: $maxMb MB.",
        );
        return;
      }

      setState(() {
        _pickedFile = file;
        _pickedName = name;
        _pickedType = isImage ? "image" : "video";
      });
    } catch (e) {
      _errorDialog(t, "${t?.pickFailed ?? "Pick failed"}: $e");
    }
  }

  String _guessMime(String fileName, String pickedType) {
    final lower = fileName.toLowerCase();
    if (pickedType == "image") {
      if (lower.endsWith(".png")) return "image/png";
      if (lower.endsWith(".webp")) return "image/webp";
      return "image/jpeg";
    }
    // video
    if (lower.endsWith(".mov")) return "video/quicktime";
    if (lower.endsWith(".webm")) return "video/webm";
    if (lower.endsWith(".mkv")) return "video/x-matroska";
    if (lower.endsWith(".avi")) return "video/x-msvideo";
    return "video/mp4";
  }

  void _resetForm() {
    setState(() {
      _pickedFile = null;
      _pickedName = "";
      _pickedType = "";
    });
    _title.clear();
    _desc.clear();
  }

  Future<Uint8List> _readBytes(AppLocalizations? t, File f) async {
    final bytes = await f.readAsBytes();
    if (bytes.isEmpty) throw Exception(t?.selectedFileEmpty ?? "Selected file is empty.");
    if (bytes.length > maxUploadBytes) {
      throw Exception(
        "${t?.fileTooLargeBytes ?? "File too large"} (${bytes.length} bytes). "
            "${t?.maxAllowedBytes ?? "Max allowed"}: $maxUploadBytes bytes.",
      );
    }
    return bytes;
  }

  Future<void> _upload(AppLocalizations? t) async {
    final title = _title.text.trim();
    final desc = _desc.text.trim();

    if (_doctorId.isEmpty) {
      _errorDialog(t, t?.doctorNotLoggedIn ?? "Doctor not logged in.");
      return;
    }

    if (title.isEmpty) {
      _errorDialog(t, t?.pleaseEnterTitle ?? "Please enter title.");
      return;
    }
    if (desc.isEmpty) {
      _errorDialog(t, t?.pleaseEnterDescription ?? "Please enter description.");
      return;
    }
    if (_pickedFile == null) {
      _errorDialog(t, t?.pleaseSelectMediaFirst ?? "Please select an image or video first.");
      return;
    }
    if (_pickedType.isEmpty || _pickedName.isEmpty) {
      _errorDialog(t, t?.pleaseRepickFile ?? "Please re-pick the file.");
      return;
    }
    if (_uploading) return;

    setState(() => _uploading = true);

    try {
      final Uint8List bytes = await _readBytes(t, _pickedFile!);
      final mimeType = _guessMime(_pickedName, _pickedType);

      // Generate exerciseId before upload (stable folder)
      final exerciseId = const Uuid().v4();

      // Upload via Edge (service role)
      final uploaded = await SupabaseService.instance.uploadDoctorExerciseViaEdge(
        doctorId: _doctorId,
        exerciseId: exerciseId,
        bytes: bytes,
        fileName: _pickedName,
        mimeType: mimeType,
      );

      final fileUrl = uploaded.url.trim();
      final filePath = uploaded.path.trim();
      final savedFileName = uploaded.fileName;

      if (fileUrl.isEmpty || filePath.isEmpty) {
        throw Exception(t?.uploadReturnedEmptyUrl ?? "Upload succeeded but server returned empty url/path.");
      }

      // Save record to Firestore
      await FirebaseFirestore.instance.collection("doctorUploads").add({
        "doctorId": _doctorId,
        "exerciseId": exerciseId,
        "title": title,
        "description": desc,
        "type": _pickedType, // image | video
        "mimeType": mimeType,
        "fileUrl": fileUrl,
        "filePath": filePath,
        "fileName": savedFileName,
        "size": bytes.length,
        "createdAt": FieldValue.serverTimestamp(),
      });

      _successDialog(t, t?.exerciseUploadedSuccessfully ?? "Exercise uploaded successfully!");
      _resetForm();
    } catch (e) {
      _errorDialog(t, "${t?.uploadFailed ?? "Upload failed"}: $e");
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  InputDecoration _decoration() {
    return InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: blue, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: blue, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: blue, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
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
              t?.appTitle ?? "AI-Based Breast Cancer Detection App",
              maxLines: 1,
              overflow: TextOverflow.visible,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: blue,
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
                    border: Border.all(color: blue, width: 2),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: blue, size: 18),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const DoctorRootPage()),
                      );
                    },
                  ),
                ),
              ),

              Image.asset("assets/images/uploadexercise.png", width: 373, height: 249),
              const SizedBox(height: 10),

              Text(
                t?.uploadExerciseTitle ?? "Upload Exercise",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 27,
                  color: blue,
                ),
              ),
              const SizedBox(height: 15),

              // Title
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  t?.titleLabel ?? "Title",
                  style: GoogleFonts.poppins(
                    color: blue,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              TextField(
                controller: _title,
                decoration: _decoration(),
              ),

              const SizedBox(height: 20),

              // Description
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  t?.descriptionLabel ?? "Description",
                  style: GoogleFonts.poppins(
                    color: blue,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
              TextField(
                controller: _desc,
                maxLines: 2,
                decoration: _decoration().copyWith(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                ),
              ),

              const SizedBox(height: 15),

              // Media
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  t?.selectMediaLabel ?? "Select Media (Image / Video)",
                  style: GoogleFonts.poppins(
                    color: blue,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              InkWell(
                onTap: _uploading ? null : () => _pickMedia(t),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: blue, width: 2),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.upload_file_rounded, size: 34, color: blue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _pickedName.isEmpty
                              ? (t?.tapToPickMedia ?? "Tap to pick image/video")
                              : _pickedName,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      if (_pickedType.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: blue.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: blue.withOpacity(0.35)),
                          ),
                          child: Text(
                            _pickedType.toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                              color: blue,
                            ),
                          ),
                        )
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _uploading ? null : () => _upload(t),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: blue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _uploading
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : Text(
                    t?.upload ?? "Upload",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
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
    );
  }
}