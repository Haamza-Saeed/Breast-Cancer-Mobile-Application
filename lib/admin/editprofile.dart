import 'dart:io';
import 'dart:typed_data';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../services/supabase_service.dart';

// ✅ Use ONE of these imports (pick the correct one for your project):
import 'package:project/l10n/app_localizations.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  static const Color green = Color(0xff00EFAB);

  final _formKey = GlobalKey<FormState>();

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  bool _loading = false;

  String profileImagePath = "";
  File? pickedImage;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _loadAdminProfile();
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    ageController.dispose();
    emailController.dispose();
    super.dispose();
  }

  // ---------------------------
  // ✅ Sweet Alert (localized)
  // ---------------------------
  void _sweet({
    required DialogType type,
    required String title,
    required String desc,
  }) {
    if (!mounted) return;
    final t = AppLocalizations.of(context)!;

    AwesomeDialog(
      context: context,
      dialogType: type,
      animType: AnimType.scale,
      title: title,
      desc: desc,
      btnOkText: t.ok,
      btnOkOnPress: () {},
    ).show();
  }

  // ---------------------------
  // ✅ Load Admin Profile
  // ---------------------------
  Future<void> _loadAdminProfile() async {
    try {
      final uid = _uid;
      final user = FirebaseAuth.instance.currentUser;
      if (uid == null || user == null) return;

      final doc =
      await FirebaseFirestore.instance.collection("users").doc(uid).get();
      final data = doc.data() ?? {};

      // ✅ first + last
      final first = (data["firstName"] ?? "").toString().trim();
      final last = (data["lastName"] ?? "").toString().trim();

      // fallback: if you ever stored "name"
      final legacyName = (data["name"] ?? "").toString().trim();
      String fallbackFirst = first;
      String fallbackLast = last;

      if ((fallbackFirst.isEmpty && fallbackLast.isEmpty) &&
          legacyName.isNotEmpty) {
        final parts = legacyName.replaceAll(RegExp(r"\s+"), " ").split(" ");
        fallbackFirst = parts.isNotEmpty ? parts.first.trim() : "";
        fallbackLast =
        (parts.length > 1) ? parts.sublist(1).join(" ").trim() : "";
      }

      final ageVal = data["age"];
      final age = (ageVal is num)
          ? ageVal.toInt().toString()
          : (ageVal ?? "").toString().trim();

      final email = (data["email"] ?? user.email ?? "").toString().trim();
      final img = (data["profileImagePath"] ?? "").toString().trim();

      if (!mounted) return;
      setState(() {
        firstNameController.text = fallbackFirst;
        lastNameController.text = fallbackLast;
        ageController.text = age;
        emailController.text = email;
        profileImagePath = img;
      });
    } catch (e) {
      if (!mounted) return;
      final t = AppLocalizations.of(context)!;

      _sweet(
        type: DialogType.error,
        title: t.loadFailedTitle,
        desc: "${t.couldNotLoadProfileDesc}\n$e",
      );
    }
  }

  // ---------------------------
  // ✅ Pick image
  // ---------------------------
  Future<void> _pickProfileImage() async {
    try {
      final picker = ImagePicker();
      final xfile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (xfile == null) return;

      setState(() => pickedImage = File(xfile.path));
    } catch (e) {
      if (!mounted) return;
      final t = AppLocalizations.of(context)!;

      _sweet(
        type: DialogType.error,
        title: t.imageErrorTitle,
        desc: "${t.couldNotPickImageDesc}\n$e",
      );
    }
  }

  ImageProvider _profileProvider() {
    if (pickedImage != null) return FileImage(pickedImage!);
    if (profileImagePath.trim().isNotEmpty) return NetworkImage(profileImagePath);
    return const AssetImage("assets/images/profilegreen.png");
  }

  // ---------------------------
  // ✅ Upload image to Supabase (ADMIN)
  // ---------------------------
  Future<String?> _uploadProfileImageIfNeeded(String uid) async {
    try {
      if (pickedImage == null) return null;

      final Uint8List bytes = await pickedImage!.readAsBytes();
      final lower = pickedImage!.path.toLowerCase();
      final mime = lower.endsWith(".png") ? "image/png" : "image/jpeg";
      final fileName =
      lower.endsWith(".png") ? "admin_profile.png" : "admin_profile.jpg";

      final url = await SupabaseService.instance.uploadAdminProfileImageViaEdge(
        firebaseUid: uid,
        bytes: bytes,
        fileName: fileName,
        mimeType: mime,
      );

      return url.trim().isEmpty ? null : url.trim();
    } catch (e) {
      // ✅ IMPORTANT: return null because function return type is String?
      if (!mounted) return null;

      final t = AppLocalizations.of(context)!;
      _sweet(
        type: DialogType.error,
        title: t.uploadFailedTitle,
        desc: "${t.imageUploadFailedDesc}\n$e",
      );

      return null;
    }
  }

  // ---------------------------
  // ✅ Validators (localized)
  // ---------------------------
  String? _validateFirst(String? v) {
    final t = AppLocalizations.of(context)!;
    final s = (v ?? "").trim();
    if (s.isEmpty) return t.firstNameRequired;
    if (s.length < 2) return t.firstNameMin2;
    return null;
  }

  String? _validateLast(String? v) {
    final t = AppLocalizations.of(context)!;
    final s = (v ?? "").trim();
    if (s.isEmpty) return t.lastNameRequired;
    if (s.length < 2) return t.lastNameMin2;
    return null;
  }

  String? _validateAge(String? v) {
    final t = AppLocalizations.of(context)!;
    final s = (v ?? "").trim();
    if (s.isEmpty) return t.ageRequired;
    final n = int.tryParse(s);
    if (n == null) return t.enterValidAge;
    if (n < 10 || n > 120) return t.ageRange10to120;
    return null;
  }

  // ---------------------------
  // ✅ Save Profile
  // ---------------------------
  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus();
    final t = AppLocalizations.of(context)!;

    if (!_formKey.currentState!.validate()) {
      _sweet(
        type: DialogType.warning,
        title: t.validationTitle,
        desc: t.fixHighlightedFieldsDesc,
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final uid = _uid;
      final user = FirebaseAuth.instance.currentUser;
      if (uid == null || user == null) {
        _sweet(
          type: DialogType.error,
          title: t.notLoggedInTitle,
          desc: t.pleaseLoginAgainDesc,
        );
        return;
      }

      final uploadedUrl = await _uploadProfileImageIfNeeded(uid);

      final firstName = firstNameController.text.trim();
      final lastName = lastNameController.text.trim();

      final updateData = <String, dynamic>{
        "firstName": firstName,
        "lastName": lastName,
        "age": int.parse(ageController.text.trim()),
        "updatedAt": FieldValue.serverTimestamp(),
      };

      if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
        updateData["profileImagePath"] = uploadedUrl;
      }

      await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .set(updateData, SetOptions(merge: true));

      // ✅ Add notification (FIXED: isRead instead of read)
      await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("notifications")
          .add({
        "type": "profile",
        "message": t.profileUpdatedNotificationMsg,
        "createdAt": FieldValue.serverTimestamp(),
        "isRead": false,
      });

      if (!mounted) return;

      setState(() {
        if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
          profileImagePath = uploadedUrl;
          pickedImage = null;
        }
      });

      _sweet(
        type: DialogType.success,
        title: t.updatedTitle,
        desc: t.profileUpdatedSuccessDesc,
      );
    } catch (e) {
      _sweet(
        type: DialogType.error,
        title: t.saveFailedTitle,
        desc: "${t.failedUpdateProfileDesc}\n$e",
      );
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
        borderSide: const BorderSide(color: green, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: green, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: green, width: 2),
      ),
    );
  }

  Widget _label(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: green,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

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
              t.appTitle,
              maxLines: 1,
              overflow: TextOverflow.visible,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: green,
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: green, width: 2),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: green,
                        size: 18,
                      ),
                      onPressed: () => Navigator.pop(context),
                      tooltip: t.back,
                    ),
                  ),
                ),
                Image.asset(
                  "assets/images/adminmanageprofile.png",
                  width: 373,
                  height: 249,
                ),
                Text(
                  t.editProfileTitle,
                  style: GoogleFonts.poppins(
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                    color: green,
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
                      onTap: _loading ? null : _pickProfileImage,
                      child: const CircleAvatar(
                        radius: 18,
                        backgroundColor: green,
                        child: Icon(Icons.edit, color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ✅ First Name
                _label(t.firstNameLabel),
                TextFormField(
                  controller: firstNameController,
                  validator: _validateFirst,
                  decoration: _decoration(hint: t.firstNameHint),
                ),

                const SizedBox(height: 15),

                // ✅ Last Name
                _label(t.lastNameLabel),
                TextFormField(
                  controller: lastNameController,
                  validator: _validateLast,
                  decoration: _decoration(hint: t.lastNameHint),
                ),

                const SizedBox(height: 15),

                _label(t.ageLabel),
                TextFormField(
                  controller: ageController,
                  keyboardType: TextInputType.number,
                  validator: _validateAge,
                  decoration: _decoration(hint: t.ageHint),
                ),

                const SizedBox(height: 15),

                _label(t.emailReadOnlyLabel),
                TextFormField(
                  controller: emailController,
                  readOnly: true,
                  decoration: _decoration(
                    hint: t.emailHint,
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                ),

                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: green,
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
                      t.save,
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
    );
  }
}