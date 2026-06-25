import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:project/services/supabase_service.dart';
import 'package:project/signup7.dart';
import 'package:project/signup9.dart';

const Color kPink = Color(0xffFF67CE);
const Color kBlue = Color(0xff00AEEF);
const String kMedicationBucket = "med_qual";

InputDecoration signupInputDecoration({Widget? suffixIcon, String? hint}) {
  return InputDecoration(
    hintText: hint,
    suffixIcon: suffixIcon,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Colors.blue, width: 2),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Colors.blue, width: 2),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
    ),
  );
}

PreferredSizeWidget signupAppBar() {
  return AppBar(
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
          "AI-Based Breast Cancer Detection App",
          maxLines: 1,
          overflow: TextOverflow.visible,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: kPink,
          ),
        ),
      ),
    ),
  );
}

Widget loadingOverlay(bool isLoading) {
  if (!isLoading) return const SizedBox.shrink();

  return Positioned.fill(
    child: Container(
      color: Colors.black.withValues(alpha: 0.35),
      child: Center(
        child: Image.asset("assets/images/loading.gif", width: 90, height: 90),
      ),
    ),
  );
}

void showSnack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg)),
  );
}

class Signup8 extends StatefulWidget {
  final String uid;
  final String email;
  final String role;

  const Signup8({
    super.key,
    required this.uid,
    required this.email,
    required this.role,
  });

  @override
  State<Signup8> createState() => _Signup8State();
}

class _Signup8State extends State<Signup8> {
  bool _isLoading = false;
  bool anyMedication = false;

  final TextEditingController medicationController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _images = [];

  Future<void> _runWithLoading(Future<void> Function() action) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      await action();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _fileExt(XFile file) {
    final lower = file.path.toLowerCase();
    if (lower.endsWith(".png")) return "png";
    if (lower.endsWith(".jpg")) return "jpg";
    if (lower.endsWith(".jpeg")) return "jpg";
    return "jpg";
  }

  String _mimeType(XFile file) {
    return _fileExt(file) == "png" ? "image/png" : "image/jpeg";
  }

  Future<String> _uploadMedicationImage(XFile file, int index) async {
    final bytes = await file.readAsBytes();
    final ext = _fileExt(file);

    final fileName =
        "medication_${widget.uid}_${DateTime.now().millisecondsSinceEpoch}_$index.$ext";

    final url = await SupabaseService.instance.uploadFileViaEdgeToBucket(
      firebaseUid: widget.uid,
      folderId: "medications/${widget.uid}",
      bytes: bytes,
      fileName: fileName,
      mimeType: _mimeType(file),
      targetBucket: kMedicationBucket,
    );

    if (url.trim().isEmpty) {
      throw Exception("Uploaded image URL is empty.");
    }

    return url.trim();
  }

  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 65,
        maxWidth: 900,
        maxHeight: 900,
      );

      if (picked != null) {
        setState(() => _images.add(picked));
      }
    } catch (e) {
      showSnack(context, "Image selection failed: $e");
    }
  }

  Future<void> _next() async {
    if (anyMedication && medicationController.text.trim().isEmpty) {
      showSnack(context, "Please describe your medication.");
      return;
    }

    await _runWithLoading(() async {
      final urls = <String>[];

      if (anyMedication) {
        for (int i = 0; i < _images.length; i++) {
          final url = await _uploadMedicationImage(_images[i], i);
          urls.add(url);
        }
      }

      await FirebaseFirestore.instance
          .collection("pending_signups")
          .doc(widget.uid)
          .set({
        "anyMedication": anyMedication ? "Yes" : "No",
        "medicationDetails":
        anyMedication ? medicationController.text.trim() : "",
        "medicationImages": urls,
        "medicationBucket": kMedicationBucket,
        "step": 8,
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => Signup9(
            uid: widget.uid,
            email: widget.email,
            role: widget.role,
          ),
        ),
      );
    });
  }

  void _back() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => Signup7(
          uid: widget.uid,
          email: widget.email,
          role: widget.role,
        ),
      ),
    );
  }

  Widget _imagePreview(XFile image, int index) {
    return Container(
      width: 112,
      height: 122,
      margin: const EdgeInsets.only(right: 10, bottom: 10),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: kPink, width: 2),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              File(image.path),
              width: 98,
              height: 108,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 2,
            right: 2,
            child: GestureDetector(
              onTap: _isLoading
                  ? null
                  : () {
                setState(() => _images.removeAt(index));
              },
              child: const CircleAvatar(
                radius: 12,
                backgroundColor: Colors.red,
                child: Icon(Icons.close, color: Colors.white, size: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    medicationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: signupAppBar(),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Image.asset(
                      "assets/images/womens.png",
                      width: 349,
                      height: 250,
                    ),
                  ),
                  Text(
                    "Any Medication?",
                    style: GoogleFonts.poppins(
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                      color: kPink,
                    ),
                  ),
                  SwitchListTile(
                    activeColor: kPink,
                    title: Text(
                      anyMedication ? "Yes" : "No",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        color: kBlue,
                      ),
                    ),
                    value: anyMedication,
                    onChanged: _isLoading
                        ? null
                        : (v) {
                      setState(() {
                        anyMedication = v;
                        if (!v) {
                          medicationController.clear();
                          _images.clear();
                        }
                      });
                    },
                  ),
                  if (anyMedication) ...[
                    Text(
                      "Tell us about your medication",
                      style: GoogleFonts.poppins(
                        color: kBlue,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    TextField(
                      controller: medicationController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: signupInputDecoration(
                        hint: "Enter medication details",
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : _pickImage,
                      icon: const Icon(
                        Icons.add_photo_alternate,
                        color: kBlue,
                      ),
                      label: Text(
                        "Add medication image/report",
                        style: GoogleFonts.poppins(
                          color: kBlue,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_images.isNotEmpty)
                      Wrap(
                        children: List.generate(
                          _images.length,
                              (index) => _imagePreview(_images[index], index),
                        ),
                      ),
                  ],
                  const SizedBox(height: 50),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kBlue,
                        disabledBackgroundColor: Colors.grey.shade300,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        "Next",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _back,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPink,
                        disabledBackgroundColor: Colors.grey.shade300,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        "Back",
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
        ),
        loadingOverlay(_isLoading),
      ],
    );
  }
}