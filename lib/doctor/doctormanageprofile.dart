import 'dart:io';
import 'dart:typed_data';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:project/login.dart';

import '../services/supabase_service.dart';
import 'doctorfeedback.dart';
import 'doctorsettings.dart';
import 'manage_uploads.dart';
import 'package:project/l10n/app_localizations.dart';

class DoctorManageProfile extends StatefulWidget {
  const DoctorManageProfile({super.key});

  @override
  State<DoctorManageProfile> createState() => _DoctorManageProfileState();
}

class _DoctorManageProfileState extends State<DoctorManageProfile> {
  static const Color blue = Color(0xff00AEEF);
  static const Color pink = Color(0xffFF67CE);

  final _formKey = GlobalKey<FormState>();

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final ageController = TextEditingController();
  final emailController = TextEditingController();
  final experienceController = TextEditingController();
  final specializationController = TextEditingController();
  final qualificationController = TextEditingController();
  final descriptionController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  bool _loading = false;
  bool _logoutDialogOpen = false;

  String profileImagePath = "";
  File? pickedImage;

  String _name = "Doctor";
  String _drawerProfileUrl = "";

  List<String> qualificationImages = [];

  final RegExp _lettersOnly = RegExp(r"^[A-Za-z ]+$");
  final RegExp _lettersCommaOnly = RegExp(r"^[A-Za-z, ]+$");

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _loadDoctorProfile();
    _loadDrawerHeader();
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    ageController.dispose();
    emailController.dispose();
    experienceController.dispose();
    specializationController.dispose();
    qualificationController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  void _sweet({
    required DialogType type,
    required String title,
    required String desc,
    String okText = "OK",
    VoidCallback? onOk,
  }) {
    if (!mounted) return;

    AwesomeDialog(
      context: context,
      dialogType: type,
      animType: AnimType.scale,
      title: title,
      desc: desc,
      btnOkText: okText,
      btnOkOnPress: onOk ?? () {},
    ).show();
  }

  void _sweetConfirm({
    required String title,
    required String desc,
    required String okText,
    required String cancelText,
    required VoidCallback onOk,
  }) {
    if (!mounted) return;

    AwesomeDialog(
      context: context,
      dialogType: DialogType.question,
      animType: AnimType.scale,
      title: title,
      desc: desc,
      btnOkText: okText,
      btnCancelText: cancelText,
      btnCancelOnPress: () {},
      btnOkOnPress: onOk,
    ).show();
  }

  Future<void> _loadDrawerHeader() async {
    try {
      final uid = _uid;
      if (uid == null) return;

      final doc =
      await FirebaseFirestore.instance.collection("users").doc(uid).get();
      final data = doc.data() ?? {};

      final first = (data["firstName"] ?? "").toString().trim();
      final last = (data["lastName"] ?? "").toString().trim();
      final img = (data["profileImagePath"] ?? "").toString().trim();

      if (!mounted) return;

      setState(() {
        _name = first.isNotEmpty ? "$first $last".trim() : "Doctor";
        _drawerProfileUrl = img;
      });
    } catch (_) {}
  }

  Future<void> _loadDoctorProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      final data = doc.data() ?? {};

      firstNameController.text = (data["firstName"] ?? "").toString();
      lastNameController.text = (data["lastName"] ?? "").toString();
      ageController.text = (data["age"] ?? "").toString();
      emailController.text = (data["email"] ?? user.email ?? "").toString();

      profileImagePath = (data["profileImagePath"] ?? "").toString().trim();

      final exp = data["experienceYears"] ?? data["experience"];
      experienceController.text = exp == null ? "" : exp.toString();

      specializationController.text =
          (data["specialization"] ?? "").toString();

      qualificationController.text =
          (data["qualifications"] ?? data["qualification"] ?? "").toString();

      descriptionController.text =
          (data["doctorDescription"] ?? data["description"] ?? "").toString();

      final imgs = data["qualificationImages"];
      qualificationImages = imgs is List
          ? imgs
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList()
          : [];

      if (mounted) setState(() {});
    } catch (e) {
      _sweet(
        type: DialogType.error,
        title: "Load Failed",
        desc: "Could not load profile.\n$e",
      );
    }
  }

  ImageProvider _drawerAvatarProvider() {
    if (_drawerProfileUrl.trim().isNotEmpty) {
      return NetworkImage(_drawerProfileUrl);
    }
    return const AssetImage("assets/images/profileblue.png");
  }

  ImageProvider _profileProvider() {
    if (pickedImage != null) return FileImage(pickedImage!);
    if (profileImagePath.trim().isNotEmpty) {
      return NetworkImage(profileImagePath);
    }
    return const AssetImage("assets/images/profileblue.png");
  }

  void _goTo(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  void _logoutConfirm(AppLocalizations? t) {
    if (_logoutDialogOpen) return;
    _logoutDialogOpen = true;

    _sweetConfirm(
      title: t?.logout ?? "Logout",
      desc: t?.logoutConfirm ?? "Are you sure you want to logout?",
      okText: t?.yes ?? "Yes",
      cancelText: t?.no ?? "No",
      onOk: () async {
        try {
          await FirebaseAuth.instance.signOut();

          if (!mounted) return;

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const Login()),
                (route) => false,
          );
        } finally {
          _logoutDialogOpen = false;
        }
      },
    );

    Future.delayed(const Duration(milliseconds: 600), () {
      _logoutDialogOpen = false;
    });
  }

  bool _isProfileComplete() {
    final exp = int.tryParse(experienceController.text.trim()) ?? -1;

    return firstNameController.text.trim().isNotEmpty &&
        lastNameController.text.trim().isNotEmpty &&
        ageController.text.trim().isNotEmpty &&
        exp >= 0 &&
        specializationController.text.trim().isNotEmpty &&
        qualificationController.text.trim().isNotEmpty &&
        descriptionController.text.trim().isNotEmpty;
  }

  Future<void> _pickProfileImage(AppLocalizations? t) async {
    try {
      final xfile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (xfile == null) return;

      setState(() => pickedImage = File(xfile.path));
    } catch (e) {
      _sweet(
        type: DialogType.error,
        title: t?.imageError ?? "Image Error",
        desc: "${t?.couldNotPickImage ?? "Could not pick image."}\n$e",
      );
    }
  }

  Future<String?> _uploadProfileImageIfNeeded(
      AppLocalizations? t,
      String uid,
      ) async {
    try {
      if (pickedImage == null) return null;

      final Uint8List bytes = await pickedImage!.readAsBytes();
      final lower = pickedImage!.path.toLowerCase();

      final mime = lower.endsWith(".png") ? "image/png" : "image/jpeg";
      final fileName = lower.endsWith(".png") ? "profile.png" : "profile.jpg";

      final url = await SupabaseService.instance.uploadDoctorProfileImageViaEdge(
        firebaseUid: uid,
        bytes: bytes,
        fileName: fileName,
        mimeType: mime,
      );

      return url.trim().isEmpty ? null : url.trim();
    } catch (e) {
      _sweet(
        type: DialogType.error,
        title: t?.uploadFailed ?? "Upload Failed",
        desc:
        "${t?.profileImageUploadFailed ?? "Profile image upload failed."}\n\n$e",
      );
      return null;
    }
  }

  Future<void> _pickAndUploadQualificationImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _loading = true);

    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 1000,
        maxHeight: 1000,
      );

      if (picked == null) {
        setState(() => _loading = false);
        return;
      }

      final file = File(picked.path);
      final bytes = await file.readAsBytes();
      final lower = file.path.toLowerCase();

      final isPng = lower.endsWith(".png");
      final mimeType = isPng ? "image/png" : "image/jpeg";
      final ext = isPng ? "png" : "jpg";

      final fileName =
          "degree_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.$ext";

      final url = await SupabaseService.instance.uploadSignupDocumentViaEdge(
        firebaseUid: user.uid,
        bytes: bytes,
        fileName: fileName,
        mimeType: mimeType,
      );

      if (url.trim().isEmpty) {
        throw Exception("Uploaded image URL is empty.");
      }

      qualificationImages.add(url.trim());

      await FirebaseFirestore.instance.collection("users").doc(user.uid).set({
        "qualificationImages": qualificationImages,
        "qualificationBucket": "med_qual",
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      setState(() {});

      _sweet(
        type: DialogType.success,
        title: "Image Added",
        desc: "Qualification / Degree image added successfully.",
      );
    } catch (e) {
      _sweet(
        type: DialogType.error,
        title: "Upload Failed",
        desc: "$e",
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _removeQualificationImage(int index) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (index < 0 || index >= qualificationImages.length) return;

    setState(() {
      qualificationImages.removeAt(index);
    });

    await FirebaseFirestore.instance.collection("users").doc(user.uid).set({
      "qualificationImages": qualificationImages,
      "qualificationBucket": "med_qual",
      "updatedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  String? _validateLettersOnly(String? value, {required String fieldName}) {
    final v = (value ?? "").trim();

    if (v.isEmpty) return "$fieldName is required";

    if (!_lettersOnly.hasMatch(v)) {
      return "$fieldName must contain only letters and spaces";
    }

    return null;
  }

  String? _validateLettersCommaOnly(String? value, {required String fieldName}) {
    final v = (value ?? "").trim();

    if (v.isEmpty) return "$fieldName is required";

    if (!_lettersCommaOnly.hasMatch(v)) {
      return "$fieldName must contain only alphabets, spaces and comma";
    }

    return null;
  }

  String? _validateAge(String? value) {
    final v = (value ?? "").trim();

    if (v.isEmpty) return "Age is required";

    final n = int.tryParse(v);

    if (n == null) return "Enter a valid age";
    if (n < 18 || n > 90) return "Age must be between 18 and 90";

    return null;
  }

  String? _validateExperience(String? value) {
    final v = (value ?? "").trim();

    if (v.isEmpty) return "Experience is required";

    final n = int.tryParse(v);

    if (n == null) return "Enter valid experience";
    if (n < 0 || n > 60) return "Experience must be between 0 and 60";

    return null;
  }

  String? _validateDescription(String? value) {
    final v = (value ?? "").trim();

    if (v.isEmpty) return "Description is required";
    if (v.length < 10) return "Description must be at least 10 characters";
    if (v.length > 500) return "Description can't exceed 500 characters";

    return null;
  }

  Future<void> _saveProfile(AppLocalizations? t) async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      _sweet(
        type: DialogType.warning,
        title: t?.validation ?? "Validation",
        desc: t?.fixHighlightedFields ?? "Please fix the highlighted fields.",
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final uploadedUrl = await _uploadProfileImageIfNeeded(t, user.uid);
      final completeNow = _isProfileComplete();

      final updateData = {
        "uid": user.uid,
        "role": "doctor",
        "firstName": firstNameController.text.trim(),
        "lastName": lastNameController.text.trim(),
        "age": int.parse(ageController.text.trim()),
        "email": emailController.text.trim(),
        "experienceYears": int.parse(experienceController.text.trim()),
        "experience": int.parse(experienceController.text.trim()),
        "specialization": specializationController.text.trim(),
        "qualifications": qualificationController.text.trim(),
        "qualification": qualificationController.text.trim(),
        "doctorDescription": descriptionController.text.trim(),
        "description": descriptionController.text.trim(),
        "qualificationImages": qualificationImages,
        "qualificationBucket": "med_qual",
        "profileComplete": completeNow,
        "updatedAt": FieldValue.serverTimestamp(),
      };

      if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
        updateData["profileImagePath"] = uploadedUrl;
      }

      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .set(updateData, SetOptions(merge: true));

      if (!mounted) return;

      setState(() {
        if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
          profileImagePath = uploadedUrl;
          pickedImage = null;
        }
      });

      await _loadDrawerHeader();

      _sweet(
        type: DialogType.success,
        title: completeNow ? "Profile Completed ✅" : "Profile Saved ✅",
        desc: completeNow
            ? "Your doctor profile is completed successfully."
            : "Profile saved, but some fields are still incomplete.",
      );
    } catch (e) {
      _sweet(type: DialogType.error, title: "Save Failed", desc: "$e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  InputDecoration _decoration({String? hint, Widget? prefixIcon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: prefixIcon,
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

  Widget _label(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: blue,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
    );
  }

  Widget _sectionCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: blue.withValues(alpha: 0.25), width: 1.5),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _qualificationImageCard(String url, int index) {
    return Container(
      width: 115,
      height: 125,
      margin: const EdgeInsets.only(right: 10, bottom: 10),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        border: Border.all(color: pink, width: 2),
        borderRadius: BorderRadius.circular(14),
        color: Colors.white,
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              url,
              width: 100,
              height: 105,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return Container(
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                );
              },
            ),
          ),
          Positioned(
            top: 2,
            right: 2,
            child: GestureDetector(
              onTap: _loading ? null : () => _removeQualificationImage(index),
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

  Widget _qualificationImagesSection() {
    if (qualificationImages.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          "No qualification images added.",
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.black54),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        children: List.generate(
          qualificationImages.length,
              (index) => _qualificationImageCard(qualificationImages[index], index),
        ),
      ),
    );
  }

  Widget _drawerButton({
    required Widget icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: blue,
          padding: const EdgeInsets.symmetric(vertical: 17),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 15),
            Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final uid = _uid;

    if (uid == null) {
      return Scaffold(
        body: Center(
          child: Text(
            "Doctor not logged in",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () => _logoutConfirm(t),
            icon: const Icon(Icons.logout, size: 30, color: Colors.black),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const SizedBox(height: 20),
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _drawerAvatarProvider(),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                _name,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 27,
                  color: blue,
                ),
              ),
            ),
            const SizedBox(height: 15),
            _drawerButton(
              icon: const Icon(Icons.settings, color: Colors.white, size: 20),
              text: t?.settings ?? "Settings",
              onTap: () => _goTo(const DoctorSettings()),
            ),
            _drawerButton(
              icon: Image.asset("assets/images/smileface.png", width: 24),
              text: t?.feedbackTitle ?? "Feedback",
              onTap: () => _goTo(const DoctorFeedBack()),
            ),
            _drawerButton(
              icon: const Icon(Icons.folder_open, color: Colors.white, size: 20),
              text: t?.manageUploads ?? "Manage Uploads",
              onTap: () => _goTo(const ManageUploads()),
            ),
            _drawerButton(
              icon: const Icon(Icons.logout, color: Colors.white, size: 20),
              text: t?.logout ?? "Logout",
              onTap: () => _logoutConfirm(t),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Image.asset(
                  "assets/images/manageprofile.png",
                  width: 373,
                  height: 249,
                ),

                Text(
                  "Manage Doctor Profile",
                  style: GoogleFonts.poppins(
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                    color: blue,
                  ),
                ),

                const SizedBox(height: 15),

                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 65,
                      backgroundImage: _profileProvider(),
                    ),
                    InkWell(
                      onTap: _loading ? null : () => _pickProfileImage(t),
                      child: const CircleAvatar(
                        radius: 18,
                        backgroundColor: blue,
                        child: Icon(Icons.edit, color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                _sectionCard(
                  children: [
                    _label("First Name"),
                    TextFormField(
                      controller: firstNameController,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r"[A-Za-z ]")),
                      ],
                      validator: (v) =>
                          _validateLettersOnly(v, fieldName: "First Name"),
                      decoration: _decoration(hint: "Enter first name"),
                    ),
                    const SizedBox(height: 15),
                    _label("Last Name"),
                    TextFormField(
                      controller: lastNameController,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r"[A-Za-z ]")),
                      ],
                      validator: (v) =>
                          _validateLettersOnly(v, fieldName: "Last Name"),
                      decoration: _decoration(hint: "Enter last name"),
                    ),
                    const SizedBox(height: 15),
                    _label("Age"),
                    TextFormField(
                      controller: ageController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(2),
                      ],
                      validator: _validateAge,
                      decoration: _decoration(hint: "Enter age"),
                    ),
                    const SizedBox(height: 15),
                    _label("Email (Read-only)"),
                    TextFormField(
                      controller: emailController,
                      readOnly: true,
                      decoration: _decoration(
                        prefixIcon: const Icon(Icons.email_outlined),
                      ),
                    ),
                  ],
                ),

                _sectionCard(
                  children: [
                    _label("Experience (Years)"),
                    TextFormField(
                      controller: experienceController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(2),
                      ],
                      validator: _validateExperience,
                      decoration:
                      _decoration(hint: "Enter years of experience"),
                    ),
                    const SizedBox(height: 15),
                    _label("Specialization"),
                    TextFormField(
                      controller: specializationController,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r"[A-Za-z, ]"),
                        ),
                      ],
                      validator: (v) => _validateLettersCommaOnly(
                        v,
                        fieldName: "Specialization",
                      ),
                      decoration: _decoration(
                        hint: "e.g. Oncology, Cancer Specialist",
                      ),
                    ),
                    const SizedBox(height: 15),
                    _label("Qualifications"),
                    TextFormField(
                      controller: qualificationController,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r"[A-Za-z, ]"),
                        ),
                      ],
                      validator: (v) => _validateLettersCommaOnly(
                        v,
                        fieldName: "Qualifications",
                      ),
                      decoration: _decoration(hint: "e.g. MBBS, FCPS"),
                    ),
                    const SizedBox(height: 15),
                    _label("Description"),
                    TextFormField(
                      controller: descriptionController,
                      maxLines: 5,
                      validator: _validateDescription,
                      decoration: _decoration(hint: "Write about yourself"),
                    ),
                  ],
                ),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Qualification / Degree Images",
                    style: GoogleFonts.poppins(
                      color: blue,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed:
                    _loading ? null : _pickAndUploadQualificationImage,
                    icon: const Icon(Icons.add_photo_alternate, color: blue),
                    label: Text(
                      "Add More Degree Images",
                      style: GoogleFonts.poppins(
                        color: blue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                _qualificationImagesSection(),

                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : () => _saveProfile(t),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: blue,
                      disabledBackgroundColor: Colors.grey.shade300,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : Text(
                      "Save",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 25),
              ],
            ),
          ),
        ),
      ),
    );
  }
}