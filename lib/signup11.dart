import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:project/services/supabase_service.dart';
import 'package:project/signup10.dart';
import 'package:project/signup12.dart';

const Color kPink = Color(0xffFF67CE);
const Color kBlue = Color(0xff00AEEF);

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
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}

class Signup11 extends StatefulWidget {
  final String uid;
  final String email;
  final String role;

  const Signup11({
    super.key,
    required this.uid,
    required this.email,
    required this.role,
  });

  @override
  State<Signup11> createState() => _Signup11State();
}

class _Signup11State extends State<Signup11> {
  bool _isLoading = false;

  final TextEditingController specializationController =
  TextEditingController();
  final TextEditingController qualificationController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  final List<XFile> _degreeImages = [];

  Future<void> _runWithLoading(Future<void> Function() action) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      await action();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDegreeImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1000,
      maxHeight: 1000,
    );

    if (picked != null) {
      setState(() => _degreeImages.add(picked));
    }
  }

  bool _isValidText(String value) {
    return RegExp(r'^[a-zA-Z,\s]+$').hasMatch(value);
  }

  String _fileExtension(XFile file) {
    final lower = file.path.toLowerCase();

    if (lower.endsWith(".png")) return "png";
    if (lower.endsWith(".jpg")) return "jpg";
    if (lower.endsWith(".jpeg")) return "jpg";

    return "jpg";
  }

  String _mimeType(XFile file) {
    return _fileExtension(file) == "png" ? "image/png" : "image/jpeg";
  }

  Future<String> _uploadDegree(XFile file, int index) async {
    final bytes = await file.readAsBytes();
    final ext = _fileExtension(file);

    final fileName =
        "degree_${widget.uid}_${DateTime.now().millisecondsSinceEpoch}_$index.$ext";

    return await SupabaseService.instance.uploadSignupDocumentViaEdge(
      firebaseUid: widget.uid,
      bytes: bytes,
      fileName: fileName,
      mimeType: _mimeType(file),
    );
  }

  Future<void> _next() async {
    final specialization = specializationController.text.trim();
    final qualification = qualificationController.text.trim();

    if (specialization.isEmpty) {
      showSnack(context, "Please enter your specialization.");
      return;
    }

    if (!_isValidText(specialization)) {
      showSnack(
        context,
        "Specialization can only contain alphabets, spaces and comma.",
      );
      return;
    }

    if (qualification.isEmpty) {
      showSnack(context, "Please enter your qualifications.");
      return;
    }

    if (!_isValidText(qualification)) {
      showSnack(
        context,
        "Qualifications can only contain alphabets, spaces and comma.",
      );
      return;
    }

    await _runWithLoading(() async {
      final urls = <String>[];

      try {
        for (int i = 0; i < _degreeImages.length; i++) {
          final url = await _uploadDegree(_degreeImages[i], i);
          urls.add(url);
        }

        await FirebaseFirestore.instance
            .collection("pending_signups")
            .doc(widget.uid)
            .set({
          "specialization": specialization,
          "qualification": qualification,
          "qualifications": qualification,
          "qualificationImages": urls,
          "qualificationBucket": "med_qual",
          "step": 11,
          "updatedAt": FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => Signup12(
              uid: widget.uid,
              email: widget.email,
              role: widget.role,
            ),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        showSnack(context, "Upload failed: $e");
      }
    });
  }

  void _back() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => Signup10(
          uid: widget.uid,
          email: widget.email,
          role: widget.role,
        ),
      ),
    );
  }

  Widget _imagePreview(XFile image) {
    return Container(
      width: 110,
      height: 118,
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
              width: 95,
              height: 95,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 2,
            right: 2,
            child: GestureDetector(
              onTap: () => setState(() => _degreeImages.remove(image)),
              child: const CircleAvatar(
                radius: 12,
                backgroundColor: Colors.red,
                child: Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    specializationController.dispose();
    qualificationController.dispose();
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
                      "assets/images/doctor.png",
                      width: 349,
                      height: 240,
                    ),
                  ),

                  Text(
                    "Specialization & Qualifications",
                    style: GoogleFonts.poppins(
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                      color: kPink,
                    ),
                  ),

                  const SizedBox(height: 15),

                  Text(
                    "Specialization",
                    style: GoogleFonts.poppins(
                      color: kBlue,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),

                  TextField(
                    controller: specializationController,
                    minLines: 1,
                    maxLines: 2,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z,\s]')),
                    ],
                    decoration: signupInputDecoration(
                      hint: "Example: Oncology, Cancer Specialist",
                    ),
                  ),

                  const SizedBox(height: 15),

                  Text(
                    "Professional Qualifications",
                    style: GoogleFonts.poppins(
                      color: kBlue,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),

                  TextField(
                    controller: qualificationController,
                    minLines: 3,
                    maxLines: 5,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z,\s]')),
                    ],
                    decoration: signupInputDecoration(
                      hint: "Example: MBBS, FCPS Oncology",
                    ),
                  ),

                  const SizedBox(height: 12),

                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _pickDegreeImage,
                    icon: const Icon(Icons.add_photo_alternate, color: kBlue),
                    label: Text(
                      "Add degree image",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        color: kBlue,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  if (_degreeImages.isNotEmpty)
                    Wrap(children: _degreeImages.map(_imagePreview).toList()),

                  const SizedBox(height: 45),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kBlue,
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