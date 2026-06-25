import 'dart:io';
import 'dart:typed_data';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:project/services/supabase_service.dart';
import 'package:project/signup4.dart';
import 'package:project/signup6.dart';

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
        child: Image.asset(
          "assets/images/loading.gif",
          width: 90,
          height: 90,
        ),
      ),
    ),
  );
}

class Signup5 extends StatefulWidget {
  final String email;
  final String uid;
  final String role;

  const Signup5({
    super.key,
    required this.uid,
    required this.email,
    required this.role,
  });

  @override
  State<Signup5> createState() => _Signup5State();
}

class _Signup5State extends State<Signup5> {
  bool _isLoading = false;

  File? _selectedImage;
  String _uploadedUrl = "";

  final ImagePicker _picker = ImagePicker();

  Future<void> _runWithLoading(Future<void> Function() action) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      await action();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _sweet(DialogType type, String title, String desc) {
    if (!mounted) return;

    AwesomeDialog(
      context: context,
      dialogType: type,
      animType: AnimType.scale,
      title: title,
      desc: desc,
      btnOkText: "OK",
      btnOkOnPress: () {},
    ).show();
  }

  Future<String> _uploadProfileImageViaEdge({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) async {
    return await SupabaseService.instance.uploadPatientProfileImageViaEdge(
      firebaseUid: widget.uid,
      bytes: bytes,
      fileName: fileName,
      mimeType: mimeType,
    );
  }

  Future<void> _chooseImageSource() async {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(
            "Select Profile Picture",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.blue),
                title: Text("Camera", style: GoogleFonts.poppins()),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo, color: Colors.green),
                title: Text("Gallery", style: GoogleFonts.poppins()),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    await _runWithLoading(() async {
      try {
        final picked = await _picker.pickImage(
          source: source,
          imageQuality: 55,
          maxWidth: 700,
          maxHeight: 700,
        );

        if (picked == null) {
          _sweet(
            DialogType.info,
            "No Image Selected",
            "You didn't select any image.",
          );
          return;
        }

        final file = File(picked.path);

        setState(() {
          _selectedImage = file;
        });

        final bytes = await file.readAsBytes();
        final lower = file.path.toLowerCase();

        final bool isPng = lower.endsWith(".png");
        final mimeType = isPng ? "image/png" : "image/jpeg";
        final ext = isPng ? "png" : "jpg";

        final fileName =
            "profile_${widget.uid}_${DateTime.now().millisecondsSinceEpoch}.$ext";

        final url = await _uploadProfileImageViaEdge(
          bytes: bytes,
          fileName: fileName,
          mimeType: mimeType,
        );

        await FirebaseFirestore.instance
            .collection("pending_signups")
            .doc(widget.uid)
            .set({
          "uid": widget.uid,
          "email": widget.email.trim().toLowerCase(),
          "role": widget.role,
          "profileImagePath": url,
          "profileImageBucket": "patient-images",
          "step": 5,
          "updatedAt": FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        if (!mounted) return;

        setState(() {
          _uploadedUrl = url;
        });

        _sweet(
          DialogType.success,
          "Uploaded",
          "Your profile image has been uploaded successfully.",
        );
      } catch (e) {
        if (!mounted) return;
        _sweet(
          DialogType.error,
          "Upload Failed",
          "Profile image upload failed.\n\n$e",
        );
      }
    });
  }

  Future<void> _goNext() async {
    await FirebaseFirestore.instance
        .collection("pending_signups")
        .doc(widget.uid)
        .set({
      "uid": widget.uid,
      "email": widget.email.trim().toLowerCase(),
      "role": widget.role,
      "step": 5,
      "updatedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => Signup6(
          uid: widget.uid,
          email: widget.email,
          role: widget.role,
        ),
      ),
    );
  }

  void _goBack() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => Signup4(
          uid: widget.uid,
          email: widget.email,
          role: widget.role,
        ),
      ),
    );
  }

  ImageProvider _avatarProvider() {
    if (_selectedImage != null) {
      return FileImage(_selectedImage!);
    }

    if (_uploadedUrl.trim().isNotEmpty) {
      return NetworkImage(_uploadedUrl.trim());
    }

    return const AssetImage("assets/images/profile.png");
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: signupAppBar(),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              child: Column(
                children: [
                  Image.asset(
                    "assets/images/twogirls.png",
                    width: 349,
                    height: 300,
                  ),

                  Text(
                    "Add your profile pic",
                    style: GoogleFonts.poppins(
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                      color: kPink,
                    ),
                  ),

                  const SizedBox(height: 15),

                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 65,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: _avatarProvider(),
                      ),
                      Positioned(
                        bottom: 5,
                        right: 5,
                        child: GestureDetector(
                          onTap: _isLoading ? null : _chooseImageSource,
                          child: const CircleAvatar(
                            radius: 20,
                            backgroundColor: kBlue,
                            child: Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 80),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _goNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff00EFAB),
                        disabledBackgroundColor: Colors.grey.shade300,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        "Skip",
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
                      onPressed: _isLoading ? null : _goNext,
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
                      onPressed: _isLoading ? null : _goBack,
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