import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project/admin/adminrootpage.dart';

import 'package:project/l10n/app_localizations.dart';

enum UsersFilter { all, pendingDoctors, approvedDoctors, patients }

class AdminManageUsers extends StatefulWidget {
  const AdminManageUsers({super.key});

  @override
  State<AdminManageUsers> createState() => _AdminManageUsersState();
}

class _AdminManageUsersState extends State<AdminManageUsers> {
  String _search = "";
  bool _isWorking = false;
  UsersFilter _filter = UsersFilter.all;

  String _t(BuildContext context, String en, String ur) {
    final code = Localizations.localeOf(context).languageCode.toLowerCase();
    return code == "ur" ? ur : en;
  }

  void _showSuccess(BuildContext context, String title, String desc) {
    final t = AppLocalizations.of(context);
    AwesomeDialog(
      context: context,
      dialogType: DialogType.success,
      animType: AnimType.scale,
      title: title,
      desc: desc,
      btnOkOnPress: () {},
      btnOkText: t?.ok ?? _t(context, "OK", "ٹھیک ہے"),
    ).show();
  }

  void _showError(BuildContext context, String title, String desc) {
    final t = AppLocalizations.of(context);
    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      animType: AnimType.scale,
      title: title,
      desc: desc,
      btnOkOnPress: () {},
      btnOkText: t?.ok ?? _t(context, "OK", "ٹھیک ہے"),
    ).show();
  }

  void _showInfo(BuildContext context, String title, String desc) {
    final t = AppLocalizations.of(context);
    AwesomeDialog(
      context: context,
      dialogType: DialogType.info,
      animType: AnimType.scale,
      title: title,
      desc: desc,
      btnOkOnPress: () {},
      btnOkText: t?.ok ?? _t(context, "OK", "ٹھیک ہے"),
    ).show();
  }

  String _displayName(BuildContext context, String first, String last) {
    final full = "${first.trim()} ${last.trim()}".trim();
    return full.isEmpty ? _t(context, "No name", "نام موجود نہیں") : full;
  }

  Widget _detailRow({
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontSize: 13,
            height: 1.4,
          ),
          children: [
            TextSpan(
              text: "$title: ",
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xff0B3D2E),
              ),
            ),
            TextSpan(text: value.trim().isEmpty ? "N/A" : value),
          ],
        ),
      ),
    );
  }

  Widget _imageWrap({
    required BuildContext context,
    required List<String> images,
    required String emptyText,
  }) {
    if (images.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          emptyText,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: Colors.black54,
          ),
        ),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: images.map((url) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            url,
            width: 95,
            height: 95,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) {
              return Container(
                width: 95,
                height: 95,
                color: Colors.grey.shade200,
                child: const Icon(Icons.broken_image, color: Colors.grey),
              );
            },
          ),
        );
      }).toList(),
    );
  }

  void _showUserDetailsPopup({
    required BuildContext context,
    required Map<String, dynamic> data,
  }) {
    final role = (data["role"] ?? "patient").toString();

    if (role == "doctor") {
      _showDoctorDetailsPopup(context: context, data: data);
    } else {
      _showPatientDetailsPopup(context: context, data: data);
    }
  }

  void _showPatientDetailsPopup({
    required BuildContext context,
    required Map<String, dynamic> data,
  }) {
    final first = (data["firstName"] ?? "").toString();
    final last = (data["lastName"] ?? "").toString();
    final email = (data["email"] ?? "").toString();
    final age = (data["age"] ?? "N/A").toString();
    final maritalStatus = (data["maritalStatus"] ?? "N/A").toString();
    final anyMedication = (data["anyMedication"] ?? "N/A").toString();
    final medicationDetails = (data["medicationDetails"] ?? "N/A").toString();
    final cancerInFamily = (data["cancerInFamily"] ?? "N/A").toString();
    final cancerFamilyDetails =
    (data["cancerFamilyDetails"] ?? "N/A").toString();
    final profileComplete = (data["profileComplete"] ?? false) == true;
    final profileUrl = (data["profileImagePath"] ?? "").toString();

    final medicationImages = data["medicationImages"] is List
        ? (data["medicationImages"] as List)
        .map((e) => e.toString())
        .where((e) => e.trim().isNotEmpty)
        .toList()
        : <String>[];

    final name = _displayName(context, first, last);

    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 620),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.10),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close,
                              color: Colors.red, size: 22),
                        ),
                      ),
                    ),
                    Center(
                      child: CircleAvatar(
                        radius: 46,
                        backgroundColor:
                        Colors.pinkAccent.withOpacity(0.14),
                        backgroundImage:
                        profileUrl.isNotEmpty ? NetworkImage(profileUrl) : null,
                        child: profileUrl.isEmpty
                            ? const Icon(Icons.person,
                            color: Colors.pinkAccent, size: 44)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        name,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.pinkAccent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: Text(
                        _t(context, "Patient Profile Details",
                            "مریض پروفائل کی تفصیلات"),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF6FC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.pinkAccent.withOpacity(0.25),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _detailRow(title: _t(context, "Email", "ای میل"), value: email),
                          _detailRow(title: _t(context, "Age", "عمر"), value: age),
                          _detailRow(title: _t(context, "Marital Status", "ازدواجی حیثیت"), value: maritalStatus),
                          _detailRow(title: _t(context, "Any Medication", "کوئی دوا"), value: anyMedication),
                          if (anyMedication == "Yes")
                            _detailRow(title: _t(context, "Medication Details", "دوا کی تفصیلات"), value: medicationDetails),
                          _detailRow(title: _t(context, "Cancer in Family", "خاندان میں کینسر"), value: cancerInFamily),
                          if (cancerInFamily == "Yes")
                            _detailRow(title: _t(context, "Cancer Family Details", "خاندانی کینسر کی تفصیلات"), value: cancerFamilyDetails),
                          _detailRow(title: _t(context, "Profile Complete", "پروفائل مکمل"), value: profileComplete ? _t(context, "Yes", "ہاں") : _t(context, "No", "نہیں")),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _t(context, "Medication / Medical Report Images",
                          "دوا / میڈیکل رپورٹ تصاویر"),
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xff0B3D2E),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _imageWrap(
                      context: context,
                      images: medicationImages,
                      emptyText: _t(
                        context,
                        "No medical report images uploaded.",
                        "کوئی میڈیکل رپورٹ تصویر اپ لوڈ نہیں ہوئی۔",
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

  void _showDoctorDetailsPopup({
    required BuildContext context,
    required Map<String, dynamic> data,
  }) {
    final first = (data["firstName"] ?? "").toString();
    final last = (data["lastName"] ?? "").toString();
    final email = (data["email"] ?? "").toString();
    final age = (data["age"] ?? "N/A").toString();
    final experience =
    (data["experienceYears"] ?? data["experience"] ?? "N/A").toString();
    final specialization = (data["specialization"] ?? "N/A").toString();
    final qualifications =
    (data["qualifications"] ?? data["qualification"] ?? "N/A").toString();
    final description =
    (data["doctorDescription"] ?? data["description"] ?? "N/A").toString();
    final profileComplete = (data["profileComplete"] ?? false) == true;
    final approved = (data["approved"] ?? true) == true;
    final profileUrl = (data["profileImagePath"] ?? "").toString();

    final qualificationImages = data["qualificationImages"] is List
        ? (data["qualificationImages"] as List)
        .map((e) => e.toString())
        .where((e) => e.trim().isNotEmpty)
        .toList()
        : <String>[];

    final name = _displayName(context, first, last);

    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 620),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.10),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close,
                              color: Colors.red, size: 22),
                        ),
                      ),
                    ),
                    Center(
                      child: CircleAvatar(
                        radius: 46,
                        backgroundColor:
                        const Color(0xff00EFAB).withOpacity(0.16),
                        backgroundImage:
                        profileUrl.isNotEmpty ? NetworkImage(profileUrl) : null,
                        child: profileUrl.isEmpty
                            ? const Icon(Icons.person,
                            color: Color(0xff00EFAB), size: 44)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        name,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xff00A77A),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: Text(
                        _t(context, "Doctor Profile Details",
                            "ڈاکٹر پروفائل کی تفصیلات"),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6FFFB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xff00EFAB).withOpacity(0.30),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _detailRow(title: _t(context, "Email", "ای میل"), value: email),
                          _detailRow(title: _t(context, "Age", "عمر"), value: age),
                          _detailRow(title: _t(context, "Experience", "تجربہ"), value: experience == "N/A" ? "N/A" : "$experience ${_t(context, "years", "سال")}"),
                          _detailRow(title: _t(context, "Specialization", "مہارت"), value: specialization),
                          _detailRow(title: _t(context, "Qualifications", "قابلیت"), value: qualifications),
                          _detailRow(title: _t(context, "Description", "تفصیل"), value: description),
                          _detailRow(title: _t(context, "Approval Status", "منظوری کی حیثیت"), value: approved ? _t(context, "Approved", "منظور شدہ") : _t(context, "Pending", "زیرِ التواء")),
                          _detailRow(title: _t(context, "Profile Complete", "پروفائل مکمل"), value: profileComplete ? _t(context, "Yes", "ہاں") : _t(context, "No", "نہیں")),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _t(context, "Qualification / Degree Images",
                          "قابلیت / ڈگری تصاویر"),
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xff0B3D2E),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _imageWrap(
                      context: context,
                      images: qualificationImages,
                      emptyText: _t(
                        context,
                        "No qualification images uploaded.",
                        "کوئی قابلیت کی تصویر اپ لوڈ نہیں ہوئی۔",
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

  Future<void> _runWithWorking(Future<void> Function() action) async {
    if (_isWorking) return;
    setState(() => _isWorking = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  void _confirmRejectAndDelete({
    required BuildContext context,
    required String uid,
    required String email,
    required String role,
  }) {
    final t = AppLocalizations.of(context);

    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.scale,
      title: _t(context, "Reject & Delete", "مسترد کریں اور حذف کریں"),
      desc: _t(
        context,
        "Are you sure you want to reject and delete this $role?\n\n$email",
        "کیا آپ واقعی اس $role کو مسترد اور حذف کرنا چاہتے ہیں؟\n\n$email",
      ),
      btnCancelText: t?.cancel ?? _t(context, "Cancel", "منسوخ"),
      btnOkText: t?.delete ?? _t(context, "Delete", "حذف کریں"),
      btnCancelOnPress: () {},
      btnOkOnPress: () async {
        await _deleteFromFirestore(context: context, uid: uid, email: email);
      },
    ).show();
  }

  void _confirmDelete({
    required BuildContext context,
    required String uid,
    required String email,
    required String role,
  }) {
    final t = AppLocalizations.of(context);

    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.scale,
      title: _t(context, "Delete Account", "اکاؤنٹ حذف کریں"),
      desc: _t(
        context,
        "Are you sure you want to delete this $role?\n\n$email",
        "کیا آپ واقعی اس $role کو حذف کرنا چاہتے ہیں؟\n\n$email",
      ),
      btnCancelText: t?.cancel ?? _t(context, "Cancel", "منسوخ"),
      btnOkText: t?.delete ?? _t(context, "Delete", "حذف کریں"),
      btnCancelOnPress: () {},
      btnOkOnPress: () async {
        await _deleteFromFirestore(context: context, uid: uid, email: email);
      },
    ).show();
  }

  Future<void> _approveDoctor({
    required BuildContext context,
    required String uid,
    required String email,
  }) async {
    await _runWithWorking(() async {
      try {
        final currentUid = FirebaseAuth.instance.currentUser?.uid;
        if (currentUid != null && currentUid == uid) {
          _showInfo(
            context,
            _t(context, "Not Allowed", "اجازت نہیں"),
            _t(context, "You cannot approve your own account.",
                "آپ اپنا اکاؤنٹ منظور نہیں کر سکتے۔"),
          );
          return;
        }

        await FirebaseFirestore.instance.collection("users").doc(uid).set({
          "approved": true,
          "approvedAt": FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        if (!mounted) return;
        _showSuccess(
          context,
          _t(context, "Approved", "منظور ہوگیا"),
          _t(context, "Doctor approved successfully.",
              "ڈاکٹر کامیابی سے منظور ہوگیا۔"),
        );
      } catch (e) {
        if (!mounted) return;
        _showError(
          context,
          _t(context, "Approve Failed", "منظوری ناکام"),
          _t(context, "Error: $e", "خرابی: $e"),
        );
      }
    });
  }

  Future<void> _deleteFromFirestore({
    required BuildContext context,
    required String uid,
    required String email,
  }) async {
    await _runWithWorking(() async {
      try {
        final currentUid = FirebaseAuth.instance.currentUser?.uid;
        if (currentUid != null && currentUid == uid) {
          _showInfo(
            context,
            _t(context, "Not Allowed", "اجازت نہیں"),
            _t(context, "You cannot delete your own account.",
                "آپ اپنا اکاؤنٹ حذف نہیں کر سکتے۔"),
          );
          return;
        }

        final db = FirebaseFirestore.instance;

        try {
          final itemsSnap =
          await db.collection("reports").doc(uid).collection("items").get();
          for (final doc in itemsSnap.docs) {
            await doc.reference.delete();
          }
          await db.collection("reports").doc(uid).delete().catchError((_) {});
        } catch (_) {}

        await db
            .collection("symptomAssessments")
            .doc(uid)
            .delete()
            .catchError((_) {});

        await db.collection("users").doc(uid).delete();

        if (!mounted) return;
        _showSuccess(
          context,
          _t(context, "Deleted", "حذف ہوگیا"),
          _t(context, "User deleted successfully.",
              "صارف کامیابی سے حذف ہوگیا۔"),
        );
      } catch (e) {
        if (!mounted) return;
        _showError(
          context,
          _t(context, "Delete Failed", "حذف ناکام"),
          _t(context, "Error: $e", "خرابی: $e"),
        );
      }
    });
  }

  String _roleLabel(BuildContext context, String role) {
    if (role == "doctor") return _t(context, "Doctor", "ڈاکٹر");
    if (role == "patient") return _t(context, "Patient", "مریض");
    if (role == "admin") return _t(context, "Admin", "ایڈمن");
    return _t(context, "User", "صارف");
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    final usersStream =
    FirebaseFirestore.instance.collection("users").snapshots();

    final bool keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Stack(
      children: [
        Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: const Color(0xFFF6FFFB),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
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
                  t?.appTitle ??
                      _t(
                        context,
                        "AI-Based Breast Cancer Detection App",
                        "اے آئی پر مبنی بریسٹ کینسر ڈیٹیکشن ایپ",
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: const Color(0xff00EFAB),
                  ),
                ),
              ),
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  flex: keyboardOpen ? 0 : 0,
                  child: SingleChildScrollView(
                    physics: keyboardOpen
                        ? const BouncingScrollPhysics()
                        : const NeverScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xff00EFAB),
                                  width: 2,
                                ),
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.arrow_back_ios_new,
                                  color: Color(0xff00EFAB),
                                  size: 18,
                                ),
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const AdminRootPage(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOut,
                            height: keyboardOpen ? 80 : 200,
                            width: double.infinity,
                            child: FittedBox(
                              fit: BoxFit.contain,
                              child:
                              Image.asset("assets/images/adminmanageuser.png"),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _t(context, "Manage Users", "صارفین مینیج کریں"),
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 27,
                              color: const Color(0xff00EFAB),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color:
                                const Color(0xff00EFAB).withOpacity(0.30),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.search,
                                    color: Color(0xff00EFAB)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    onChanged: (v) => setState(
                                          () => _search = v.trim().toLowerCase(),
                                    ),
                                    decoration: InputDecoration(
                                      hintText: _t(
                                        context,
                                        "Search by name or email",
                                        "نام یا ای میل سے تلاش کریں",
                                      ),
                                      hintStyle: GoogleFonts.poppins(
                                        color: Colors.black38,
                                      ),
                                      border: InputBorder.none,
                                    ),
                                    style: GoogleFonts.poppins(),
                                  ),
                                ),
                                if (_search.isNotEmpty)
                                  IconButton(
                                    onPressed: () =>
                                        setState(() => _search = ""),
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.black45,
                                    ),
                                    tooltip: _t(context, "Clear", "صاف کریں"),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _FilterChip(
                                label: _t(context, "All", "تمام"),
                                selected: _filter == UsersFilter.all,
                                onTap: () =>
                                    setState(() => _filter = UsersFilter.all),
                              ),
                              _FilterChip(
                                label: _t(
                                  context,
                                  "Pending Doctors",
                                  "زیرِ التواء ڈاکٹر",
                                ),
                                selected:
                                _filter == UsersFilter.pendingDoctors,
                                onTap: () => setState(
                                      () => _filter = UsersFilter.pendingDoctors,
                                ),
                              ),
                              _FilterChip(
                                label: _t(
                                  context,
                                  "Approved Doctors",
                                  "منظور شدہ ڈاکٹر",
                                ),
                                selected:
                                _filter == UsersFilter.approvedDoctors,
                                onTap: () => setState(
                                      () => _filter = UsersFilter.approvedDoctors,
                                ),
                              ),
                              _FilterChip(
                                label: _t(context, "Patients", "مریض"),
                                selected: _filter == UsersFilter.patients,
                                onTap: () => setState(
                                      () => _filter = UsersFilter.patients,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: StreamBuilder<QuerySnapshot>(
                      stream: usersStream,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              _t(
                                context,
                                "Error: ${snapshot.error}",
                                "خرابی: ${snapshot.error}",
                              ),
                              style: GoogleFonts.poppins(
                                color: const Color(0xff00EFAB),
                              ),
                            ),
                          );
                        }

                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final docs = snapshot.data?.docs ?? [];

                        docs.sort((a, b) {
                          final ad = a.data() as Map<String, dynamic>;
                          final bd = b.data() as Map<String, dynamic>;
                          final at = ad["createdAt"];
                          final bt = bd["createdAt"];
                          final aMillis =
                          at is Timestamp ? at.millisecondsSinceEpoch : 0;
                          final bMillis =
                          bt is Timestamp ? bt.millisecondsSinceEpoch : 0;
                          return bMillis.compareTo(aMillis);
                        });

                        final filtered = docs.where((doc) {
                          final d = doc.data() as Map<String, dynamic>;

                          final role = (d["role"] ?? "patient").toString();
                          final approved = (d["approved"] ?? true) == true;

                          if (role == "admin") return false;

                          final passFilter = switch (_filter) {
                            UsersFilter.all => true,
                            UsersFilter.pendingDoctors =>
                            (role == "doctor" && !approved),
                            UsersFilter.approvedDoctors =>
                            (role == "doctor" && approved),
                            UsersFilter.patients => (role == "patient"),
                          };

                          if (!passFilter) return false;

                          final first =
                          (d["firstName"] ?? "").toString().toLowerCase();
                          final last =
                          (d["lastName"] ?? "").toString().toLowerCase();
                          final email =
                          (d["email"] ?? "").toString().toLowerCase();
                          final name = "$first $last".trim();

                          if (_search.isEmpty) return true;
                          return name.contains(_search) ||
                              email.contains(_search);
                        }).toList();

                        if (filtered.isEmpty) {
                          return Center(
                            child: Text(
                              _t(
                                context,
                                "No users found!",
                                "کوئی صارف نہیں ملا!",
                              ),
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: const Color(0xff00EFAB),
                              ),
                            ),
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.only(bottom: 12),
                          keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                          const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final data =
                            filtered[index].data() as Map<String, dynamic>;

                            final uid =
                            (data["uid"] ?? filtered[index].id).toString();
                            final first = (data["firstName"] ?? "").toString();
                            final last = (data["lastName"] ?? "").toString();
                            final email = (data["email"] ?? "").toString();
                            final age = data["age"];
                            final profileUrl =
                            (data["profileImagePath"] ?? "").toString();

                            final role =
                            (data["role"] ?? "patient").toString();
                            final approved =
                                (data["approved"] ?? true) == true;
                            final isPendingDoctor =
                                role == "doctor" && !approved;

                            final roleText = _roleLabel(context, role);

                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xff00EFAB)
                                      .withOpacity(0.28),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 26,
                                    backgroundColor: const Color(0xff00EFAB)
                                        .withOpacity(0.18),
                                    backgroundImage: profileUrl.isNotEmpty
                                        ? NetworkImage(profileUrl)
                                        : null,
                                    child: profileUrl.isEmpty
                                        ? const Icon(
                                      Icons.person,
                                      color: Color(0xff00EFAB),
                                    )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _displayName(context, first, last),
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                            color: const Color(0xff0B3D2E),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          email,
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 13,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 6,
                                          children: [
                                            Container(
                                              padding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xff00EFAB)
                                                    .withOpacity(0.10),
                                                borderRadius:
                                                BorderRadius.circular(999),
                                              ),
                                              child: Text(
                                                _t(
                                                  context,
                                                  "Age: ${age == null ? "N/A" : age.toString()}",
                                                  "عمر: ${age == null ? "موجود نہیں" : age.toString()}",
                                                ),
                                                style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12,
                                                  color:
                                                  const Color(0xff00A77A),
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: role == "doctor"
                                                    ? Colors.orange
                                                    .withOpacity(0.12)
                                                    : Colors.blue
                                                    .withOpacity(0.10),
                                                borderRadius:
                                                BorderRadius.circular(999),
                                              ),
                                              child: Text(
                                                roleText,
                                                style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 12,
                                                  color: role == "doctor"
                                                      ? Colors.orange.shade800
                                                      : Colors.blue.shade700,
                                                ),
                                              ),
                                            ),
                                            if (role == "doctor")
                                              Container(
                                                padding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: approved
                                                      ? Colors.green
                                                      .withOpacity(0.12)
                                                      : Colors.red
                                                      .withOpacity(0.10),
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                      999),
                                                ),
                                                child: Text(
                                                  approved
                                                      ? _t(
                                                    context,
                                                    "Approved",
                                                    "منظور شدہ",
                                                  )
                                                      : _t(
                                                    context,
                                                    "Pending",
                                                    "زیرِ التواء",
                                                  ),
                                                  style: GoogleFonts.poppins(
                                                    fontWeight:
                                                    FontWeight.w700,
                                                    fontSize: 12,
                                                    color: approved
                                                        ? Colors.green.shade800
                                                        : Colors.red.shade700,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xff00EFAB)
                                          .withOpacity(0.10),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: IconButton(
                                      tooltip: _t(
                                        context,
                                        "View details",
                                        "تفصیلات دیکھیں",
                                      ),
                                      icon: const Icon(
                                        Icons.remove_red_eye_outlined,
                                        color: Color(0xff00A77A),
                                      ),
                                      onPressed: () => _showUserDetailsPopup(
                                        context: context,
                                        data: data,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (isPendingDoctor) ...[
                                    Container(
                                      decoration: BoxDecoration(
                                        color:
                                        Colors.green.withOpacity(0.10),
                                        borderRadius:
                                        BorderRadius.circular(12),
                                      ),
                                      child: IconButton(
                                        tooltip: _t(
                                          context,
                                          "Approve doctor",
                                          "ڈاکٹر کو منظور کریں",
                                        ),
                                        icon: const Icon(
                                          Icons.check_circle_outline,
                                          color: Colors.green,
                                        ),
                                        onPressed: _isWorking
                                            ? null
                                            : () => _approveDoctor(
                                          context: context,
                                          uid: uid,
                                          email: email,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.08),
                                        borderRadius:
                                        BorderRadius.circular(12),
                                      ),
                                      child: IconButton(
                                        tooltip: _t(
                                          context,
                                          "Reject doctor",
                                          "ڈاکٹر مسترد کریں",
                                        ),
                                        icon: const Icon(
                                          Icons.cancel_outlined,
                                          color: Colors.red,
                                        ),
                                        onPressed: _isWorking
                                            ? null
                                            : () => _confirmRejectAndDelete(
                                          context: context,
                                          uid: uid,
                                          email: email,
                                          role: _t(
                                            context,
                                            "doctor",
                                            "ڈاکٹر",
                                          ),
                                        ),
                                      ),
                                    ),
                                  ] else ...[
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.08),
                                        borderRadius:
                                        BorderRadius.circular(12),
                                      ),
                                      child: IconButton(
                                        tooltip: _t(
                                          context,
                                          "Delete user",
                                          "صارف حذف کریں",
                                        ),
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.red,
                                        ),
                                        onPressed: _isWorking
                                            ? null
                                            : () => _confirmDelete(
                                          context: context,
                                          uid: uid,
                                          email: email,
                                          role: roleText,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_isWorking)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.25),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xff00EFAB).withOpacity(0.16)
              : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? const Color(0xff00EFAB)
                : const Color(0xff00EFAB).withOpacity(0.30),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            color: const Color(0xff0B3D2E),
          ),
        ),
      ),
    );
  }
}