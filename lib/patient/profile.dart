import 'dart:io';
import 'dart:typed_data';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project/login.dart';
import 'package:project/patient/aboutus.dart';
import 'package:project/patient/feedback.dart';
import 'package:project/patient/settings.dart' as app_settings;
import 'package:project/patient/view_media.dart';
import 'package:project/l10n/app_localizations.dart';

import '../services/supabase_service.dart';

class PatientProfile extends StatefulWidget {
  const PatientProfile({super.key});

  @override
  State<PatientProfile> createState() => _PatientProfileState();
}

class _PatientProfileState extends State<PatientProfile> {
  static const Color pink = Color(0xffFF67CE);
  static const String medQualBucket = "med_qual";

  final _formKey = GlobalKey<FormState>();

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController medicationDetailsController =
  TextEditingController();
  final TextEditingController cancerFamilyDetailsController =
  TextEditingController();

  String? maritalStatus;
  String? anyMedication;
  String? cancerInFamily;

  bool _loading = false;

  String profileImagePath = "";
  File? pickedImage;

  List<String> medicationImages = [];

  final ImagePicker _picker = ImagePicker();

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _loadProfileFromFirestore();
  }

  @override
  void dispose() {
    firstNameController.dispose();
    ageController.dispose();
    emailController.dispose();
    medicationDetailsController.dispose();
    cancerFamilyDetailsController.dispose();
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

  bool _isProfileComplete() {
    final age = int.tryParse(ageController.text.trim()) ?? 0;
    final name = firstNameController.text.trim();
    final email = emailController.text.trim();

    final medicationOk = anyMedication == "Yes"
        ? medicationDetailsController.text.trim().isNotEmpty
        : anyMedication == "No";

    final cancerOk = cancerInFamily == "Yes"
        ? cancerFamilyDetailsController.text.trim().isNotEmpty
        : cancerInFamily == "No";

    return name.isNotEmpty &&
        email.isNotEmpty &&
        email.contains("@") &&
        age >= 10 &&
        age <= 120 &&
        (maritalStatus?.trim().isNotEmpty ?? false) &&
        medicationOk &&
        cancerOk;
  }

  Future<void> _loadProfileFromFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = doc.data() ?? {};
      final imgs = data["medicationImages"];

      if (!mounted) return;

      setState(() {
        firstNameController.text = (data['firstName'] ?? '').toString().trim();
        emailController.text =
            (data['email'] ?? user.email ?? '').toString().trim();
        ageController.text = (data['age'] ?? '').toString().trim();

        maritalStatus = (data['maritalStatus'] ?? '').toString().trim().isEmpty
            ? null
            : (data['maritalStatus'] ?? '').toString().trim();

        anyMedication = (data['anyMedication'] ?? '').toString().trim().isEmpty
            ? null
            : (data['anyMedication'] ?? '').toString().trim();

        cancerInFamily =
        (data['cancerInFamily'] ?? '').toString().trim().isEmpty
            ? null
            : (data['cancerInFamily'] ?? '').toString().trim();

        medicationDetailsController.text =
            (data["medicationDetails"] ?? "").toString().trim();

        cancerFamilyDetailsController.text =
            (data["cancerFamilyDetails"] ?? "").toString().trim();

        medicationImages = imgs is List
            ? imgs
            .map((e) => e.toString())
            .where((e) => e.trim().isNotEmpty)
            .toList()
            : [];

        profileImagePath = (data['profileImagePath'] ?? '').toString().trim();
      });
    } catch (e) {
      _sweet(
        type: DialogType.error,
        title: "Load Failed",
        desc: "Could not load profile.\n$e",
      );
    }
  }

  Future<void> _pickProfileImage() async {
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
        title: "Image Error",
        desc: "Could not pick image.\n$e",
      );
    }
  }

  Future<String?> _uploadProfileImageIfNeeded(String uid) async {
    try {
      if (pickedImage == null) return null;

      final Uint8List bytes = await pickedImage!.readAsBytes();
      final lower = pickedImage!.path.toLowerCase();

      final mime = lower.endsWith(".png") ? "image/png" : "image/jpeg";
      final fileName = lower.endsWith(".png")
          ? "patient_profile.png"
          : "patient_profile.jpg";

      final url =
      await SupabaseService.instance.uploadPatientProfileImageViaEdge(
        firebaseUid: uid,
        bytes: bytes,
        fileName: fileName,
        mimeType: mime,
      );

      return url.trim().isEmpty ? null : url.trim();
    } catch (e) {
      _sweet(
        type: DialogType.error,
        title: "Upload Failed",
        desc: "Profile image upload failed.\n$e",
      );
      return null;
    }
  }

  Future<void> _pickAndUploadMedicationImage() async {
    final uid = _uid;
    if (uid == null) return;

    setState(() => _loading = true);

    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 1000,
        maxHeight: 1000,
      );

      if (picked == null) return;

      final file = File(picked.path);
      final bytes = await file.readAsBytes();
      final lower = file.path.toLowerCase();

      final isPng = lower.endsWith(".png");
      final mimeType = isPng ? "image/png" : "image/jpeg";
      final ext = isPng ? "png" : "jpg";

      final fileName =
          "medication_${uid}_${DateTime.now().millisecondsSinceEpoch}.$ext";

      final url = await SupabaseService.instance.uploadFileViaEdgeToBucket(
        firebaseUid: uid,
        folderId: "medications/$uid",
        bytes: bytes,
        fileName: fileName,
        mimeType: mimeType,
        targetBucket: medQualBucket,
      );

      if (url.trim().isEmpty) {
        throw Exception("Uploaded image URL is empty.");
      }

      medicationImages.add(url.trim());

      await FirebaseFirestore.instance.collection("users").doc(uid).set({
        "medicationImages": medicationImages,
        "medicationBucket": medQualBucket,
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      setState(() {});

      _sweet(
        type: DialogType.success,
        title: "Image Added",
        desc: "Medical report image added successfully.",
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

  Future<void> _removeMedicationImage(int index) async {
    final uid = _uid;
    if (uid == null) return;

    if (index < 0 || index >= medicationImages.length) return;

    setState(() {
      medicationImages.removeAt(index);
    });

    await FirebaseFirestore.instance.collection("users").doc(uid).set({
      "medicationImages": medicationImages,
      "medicationBucket": medQualBucket,
      "updatedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  String? _validateName(AppLocalizations t, String? v) {
    final s = (v ?? "").trim();
    if (s.isEmpty) return t.profileNameRequired;
    if (s.length < 2) return t.profileNameMin2;
    if (!RegExp(r"^[A-Za-z ]+$").hasMatch(s)) return t.profileNameLettersOnly;
    return null;
  }

  String? _validateEmail(AppLocalizations t, String? v) {
    final s = (v ?? "").trim();
    if (s.isEmpty) return t.profileEmailRequired;
    if (!s.contains("@")) return t.profileEmailInvalid;
    return null;
  }

  String? _validateAge(AppLocalizations t, String? v) {
    final s = (v ?? "").trim();
    if (s.isEmpty) return t.profileAgeRequired;

    final n = int.tryParse(s);

    if (n == null) return t.profileAgeInvalid;
    if (n < 10 || n > 120) return t.profileAgeRange;

    return null;
  }

  String? _validateDropdown(AppLocalizations t, String? v, String fieldName) {
    final s = (v ?? "").trim();
    if (s.isEmpty) return t.profileFieldRequired(fieldName);
    return null;
  }

  Future<void> _saveProfile(AppLocalizations t) async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      _sweet(
        type: DialogType.warning,
        title: t.validation,
        desc: t.profileFixHighlighted,
      );
      return;
    }

    if (anyMedication == "Yes" &&
        medicationDetailsController.text.trim().isEmpty) {
      _sweet(
        type: DialogType.warning,
        title: "Medication Details",
        desc: "Please enter your medication details.",
      );
      return;
    }

    if (cancerInFamily == "Yes" &&
        cancerFamilyDetailsController.text.trim().isEmpty) {
      _sweet(
        type: DialogType.warning,
        title: "Cancer Family Details",
        desc: "Please enter cancer family details.",
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
          title: t.notLoggedIn,
          desc: t.profileLoginAgain,
        );
        return;
      }

      final uploadedUrl = await _uploadProfileImageIfNeeded(uid);
      final completeNow = _isProfileComplete();

      final updateData = <String, dynamic>{
        "uid": uid,
        "role": "patient",
        "firstName": firstNameController.text.trim(),
        "email": emailController.text.trim(),
        "age": int.parse(ageController.text.trim()),
        "maritalStatus": maritalStatus,
        "anyMedication": anyMedication,
        "medicationDetails": anyMedication == "Yes"
            ? medicationDetailsController.text.trim()
            : "",
        "medicationImages": anyMedication == "Yes" ? medicationImages : [],
        "medicationBucket": medQualBucket,
        "cancerInFamily": cancerInFamily,
        "cancerFamilyDetails": cancerInFamily == "Yes"
            ? cancerFamilyDetailsController.text.trim()
            : "",
        "profileComplete": completeNow,
        "updatedAt": FieldValue.serverTimestamp(),
      };

      if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
        updateData["profileImagePath"] = uploadedUrl;
      }

      await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .set(updateData, SetOptions(merge: true));

      if (!mounted) return;

      setState(() {
        if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
          profileImagePath = uploadedUrl;
          pickedImage = null;
        }

        if (anyMedication == "No") {
          medicationDetailsController.clear();
          medicationImages = [];
        }

        if (cancerInFamily == "No") {
          cancerFamilyDetailsController.clear();
        }
      });

      _sweet(
        type: DialogType.success,
        title: completeNow ? t.profileCompletedTitle : t.profileSavedTitle,
        desc: completeNow ? t.profileCompletedDesc : t.profileSavedDesc,
      );
    } catch (e) {
      _sweet(
        type: DialogType.error,
        title: t.saveFailed,
        desc: "${t.profileSaveFailedDesc}\n$e",
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    final t = AppLocalizations.of(context);

    _sweetConfirm(
      title: t?.logout ?? "Logout",
      desc: t?.logoutConfirm ?? "Do you really want to logout?",
      okText: t?.yes ?? "Yes",
      cancelText: t?.no ?? "No",
      onOk: () async {
        await FirebaseAuth.instance.signOut();

        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const Login()),
              (route) => false,
        );
      },
    );
  }

  ImageProvider _drawerAvatarProvider(String url) {
    final u = url.trim();
    if (u.isNotEmpty) return NetworkImage(u);
    return const AssetImage("assets/images/profilepink.png");
  }

  ImageProvider _profileProvider() {
    if (pickedImage != null) return FileImage(pickedImage!);
    if (profileImagePath.trim().isNotEmpty) {
      return NetworkImage(profileImagePath);
    }
    return const AssetImage("assets/images/profilepink.png");
  }

  InputDecoration _decoration({String? hint, Widget? prefixIcon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: prefixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: pink, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: pink, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: pink, width: 2),
      ),
    );
  }

  Widget _label(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: pink,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _drawerButton({
    IconData? icon,
    Widget? iconWidget,
    required String text,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: pink,
          padding: const EdgeInsets.symmetric(vertical: 17),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              iconWidget ?? Icon(icon, color: Colors.white, size: 20),
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
      ),
    );
  }

  String _displayMarital(AppLocalizations t, String value) {
    switch (value) {
      case "Single":
        return t.single;
      case "Married":
        return t.married;
      default:
        return value;
    }
  }

  String _displayYesNo(AppLocalizations t, String value) {
    switch (value) {
      case "Yes":
        return t.yes;
      case "No":
        return t.no;
      default:
        return value;
    }
  }

  Widget _medicationImageCard(String url, int index) {
    return Container(
      width: 115,
      height: 125,
      margin: const EdgeInsets.only(right: 10, bottom: 10),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        border: Border.all(color: pink, width: 2),
        borderRadius: BorderRadius.circular(14),
        color: Colors.white,
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
              onTap: _loading ? null : () => _removeMedicationImage(index),
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

  Widget _medicationImagesSection() {
    if (medicationImages.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          "No medical reports added.",
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.black54),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        children: List.generate(
          medicationImages.length,
              (index) => _medicationImageCard(medicationImages[index], index),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final uid = _uid;

    final docRef =
    uid == null ? null : FirebaseFirestore.instance.collection("users").doc(uid);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: docRef?.snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? {};

        final firstName =
        (data["firstName"] ?? firstNameController.text).toString().trim();
        final name = firstName.isNotEmpty ? firstName : (t?.user ?? "User");

        final imgUrl =
        (data["profileImagePath"] ?? profileImagePath).toString().trim();

        return Scaffold(
          appBar: AppBar(
            actions: [
              IconButton(
                onPressed: _loading ? null : _logout,
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
                    backgroundImage: _drawerAvatarProvider(imgUrl),
                  ),
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    name,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 27,
                      color: pink,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                _drawerButton(
                  icon: Icons.settings,
                  text: t?.settings ?? "Settings",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const app_settings.Settings(),
                      ),
                    );
                  },
                ),
                _drawerButton(
                  iconWidget: Image.asset(
                    "assets/images/smileface.png",
                    width: 24,
                  ),
                  text: t?.feedbackTitle ?? t?.feedback ?? "Feedback",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FeedBack()),
                    );
                  },
                ),
                _drawerButton(
                  icon: Icons.perm_media,
                  text: t?.viewMedia ?? "View Media",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ViewMedia()),
                    );
                  },
                ),
                _drawerButton(
                  iconWidget: Image.asset("assets/images/info.png", width: 24),
                  text: t?.aboutUs ?? "About Us",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AboutUs()),
                    );
                  },
                ),
                _drawerButton(
                  icon: Icons.logout,
                  text: t?.logout ?? "Logout",
                  onTap: _loading ? () {} : _logout,
                ),
              ],
            ),
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                      t?.patientProfileTitle ?? "Patient Profile",
                      style: GoogleFonts.poppins(
                        fontSize: 23,
                        fontWeight: FontWeight.w700,
                        color: pink,
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
                            backgroundColor: pink,
                            child: Icon(Icons.edit,
                                color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    _label(t?.name ?? "Name"),
                    TextFormField(
                      controller: firstNameController,
                      validator: (v) => t == null ? null : _validateName(t, v),
                      decoration:
                      _decoration(hint: t?.enterName ?? "Enter your name"),
                    ),

                    const SizedBox(height: 15),

                    _label(t?.age ?? "Age"),
                    TextFormField(
                      controller: ageController,
                      keyboardType: TextInputType.number,
                      validator: (v) => t == null ? null : _validateAge(t, v),
                      decoration: _decoration(hint: t?.enterAge ?? "Enter age"),
                    ),

                    const SizedBox(height: 15),

                    _label(t?.email ?? "Email"),
                    TextFormField(
                      controller: emailController,
                      readOnly: true,
                      enabled: true,
                      validator: (v) => t == null ? null : _validateEmail(t, v),
                      decoration: _decoration(
                        hint: t?.email ?? "Email",
                        prefixIcon: const Icon(Icons.email_outlined),
                      ),
                    ),

                    const SizedBox(height: 15),

                    _label(t?.maritalStatus ?? "Marital Status"),
                    DropdownButtonFormField<String>(
                      value: maritalStatus,
                      validator: (v) =>
                      t == null ? null : _validateDropdown(t, v, t.maritalStatus),
                      decoration: _decoration(hint: t?.select ?? "Select"),
                      items: [
                        DropdownMenuItem(
                          value: "Single",
                          child: Text(t == null ? "Single" : t.single),
                        ),
                        DropdownMenuItem(
                          value: "Married",
                          child: Text(t == null ? "Married" : t.married),
                        ),
                      ],
                      selectedItemBuilder: (_) => [
                        Text(_displayMarital(t!, "Single")),
                        Text(_displayMarital(t, "Married")),
                      ],
                      onChanged:
                      _loading ? null : (v) => setState(() => maritalStatus = v),
                    ),

                    const SizedBox(height: 15),

                    _label(t?.anyMedication ?? "Any Medication"),
                    DropdownButtonFormField<String>(
                      value: anyMedication,
                      validator: (v) =>
                      t == null ? null : _validateDropdown(t, v, t.anyMedication),
                      decoration: _decoration(hint: t?.select ?? "Select"),
                      items: [
                        DropdownMenuItem(
                          value: "Yes",
                          child: Text(t == null ? "Yes" : t.yes),
                        ),
                        DropdownMenuItem(
                          value: "No",
                          child: Text(t == null ? "No" : t.no),
                        ),
                      ],
                      selectedItemBuilder: (_) => [
                        Text(_displayYesNo(t!, "Yes")),
                        Text(_displayYesNo(t, "No")),
                      ],
                      onChanged: _loading
                          ? null
                          : (v) {
                        setState(() {
                          anyMedication = v;
                          if (v == "No") {
                            medicationDetailsController.clear();
                            medicationImages = [];
                          }
                        });
                      },
                    ),

                    if (anyMedication == "Yes") ...[
                      const SizedBox(height: 15),

                      _label("Medication Details"),
                      TextFormField(
                        controller: medicationDetailsController,
                        minLines: 3,
                        maxLines: 5,
                        decoration: _decoration(
                          hint: "Enter medication details",
                        ),
                      ),

                      const SizedBox(height: 12),

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed:
                          _loading ? null : _pickAndUploadMedicationImage,
                          icon: const Icon(
                            Icons.add_photo_alternate,
                            color: pink,
                          ),
                          label: Text(
                            "Add More Medical Reports",
                            style: GoogleFonts.poppins(
                              color: pink,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      _medicationImagesSection(),
                    ],

                    const SizedBox(height: 15),

                    _label(t?.cancerInFamily ?? "Cancer in family?"),
                    DropdownButtonFormField<String>(
                      value: cancerInFamily,
                      validator: (v) =>
                      t == null ? null : _validateDropdown(t, v, t.cancerInFamily),
                      decoration: _decoration(hint: t?.select ?? "Select"),
                      items: [
                        DropdownMenuItem(
                          value: "Yes",
                          child: Text(t == null ? "Yes" : t.yes),
                        ),
                        DropdownMenuItem(
                          value: "No",
                          child: Text(t == null ? "No" : t.no),
                        ),
                      ],
                      selectedItemBuilder: (_) => [
                        Text(_displayYesNo(t!, "Yes")),
                        Text(_displayYesNo(t, "No")),
                      ],
                      onChanged: _loading
                          ? null
                          : (v) {
                        setState(() {
                          cancerInFamily = v;
                          if (v == "No") {
                            cancerFamilyDetailsController.clear();
                          }
                        });
                      },
                    ),

                    if (cancerInFamily == "Yes") ...[
                      const SizedBox(height: 15),

                      _label("Cancer Family Details"),
                      TextFormField(
                        controller: cancerFamilyDetailsController,
                        minLines: 3,
                        maxLines: 5,
                        decoration: _decoration(
                          hint:
                          "Example: Mother had breast cancer, diagnosed at age 45",
                        ),
                      ),
                    ],

                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                        (_loading || t == null) ? null : () => _saveProfile(t),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: pink,
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
                          t?.save ?? "Save",
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
      },
    );
  }
}