import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project/admin/adminfeedback.dart';
import 'package:project/admin/adminsettings.dart';
import 'package:project/login.dart';
import 'package:project/l10n/app_localizations.dart';

class ViewDoctors extends StatefulWidget {
  const ViewDoctors({super.key});

  @override
  State<ViewDoctors> createState() => _ViewDoctorsState();
}

class _ViewDoctorsState extends State<ViewDoctors> {
  static const Color green = Color(0xff00EFAB);

  String _name = "Admin";
  String _profileUrl = "";

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _loadAdminHeader();
  }

  Future<void> _loadAdminHeader() async {
    try {
      final uid = _uid;
      if (uid == null) return;

      final doc =
      await FirebaseFirestore.instance.collection("users").doc(uid).get();
      final data = doc.data() ?? {};

      final first = (data["firstName"] ?? "").toString().trim();
      final name = first.isNotEmpty ? first : "Admin";
      final img = (data["profileImagePath"] ?? "").toString().trim();

      if (!mounted) return;
      setState(() {
        _name = name;
        _profileUrl = img;
      });
    } catch (_) {}
  }

  ImageProvider _avatarProvider() {
    if (_profileUrl.trim().isNotEmpty) return NetworkImage(_profileUrl);
    return const AssetImage("assets/images/profilegreen.png");
  }

  void _logoutConfirm(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    AwesomeDialog(
      context: context,
      dialogType: DialogType.question,
      animType: AnimType.scale,
      title: t.logoutTitle,
      desc: t.logoutConfirmDesc,
      btnCancelText: t.no,
      btnOkText: t.yes,
      btnCancelOnPress: () {},
      btnOkOnPress: () async {
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const Login()),
              (route) => false,
        );
      },
    ).show();
  }

  Widget _drawerBtn({
    required Widget leading,
    required String text,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: green,
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
              leading,
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

  Stream<QuerySnapshot<Map<String, dynamic>>> _approvedDoctorsStream() {
    final users = FirebaseFirestore.instance.collection("users");
    return users
        .where("role", isEqualTo: "doctor")
        .where("approved", isEqualTo: true)
        .snapshots();
  }

  String _fullName(BuildContext context, Map<String, dynamic> data) {
    final t = AppLocalizations.of(context)!;

    final first = (data["firstName"] ?? "").toString().trim();
    final last = (data["lastName"] ?? "").toString().trim();
    final name = (data["name"] ?? "").toString().trim();

    if (first.isNotEmpty || last.isNotEmpty) return "$first $last".trim();
    if (name.isNotEmpty) return name;
    return t.doctorFallback;
  }

  String _asText(dynamic v) => (v ?? "").toString().trim();

  int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString().trim());
  }

  bool _hasAnyExtra({
    required String qualification,
    required String specialization,
    required String experience,
  }) {
    return qualification.isNotEmpty ||
        specialization.isNotEmpty ||
        experience.isNotEmpty;
  }

  Widget _popupRow(String title, String value) {
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
                color: Color(0xFF0F172A),
              ),
            ),
            TextSpan(text: value.trim().isEmpty ? "N/A" : value),
          ],
        ),
      ),
    );
  }

  void _showDoctorDetailsPopup(
      BuildContext context,
      Map<String, dynamic> data,
      ) {
    final name = _fullName(context, data);
    final email = _asText(data["email"]);
    final age = _asText(data["age"]);

    final qualification = _asText(data["qualifications"]).isNotEmpty
        ? _asText(data["qualifications"])
        : _asText(data["qualification"]);

    final specialization = _asText(data["specialization"]);

    final experience = _asText(data["experienceYears"]).isNotEmpty
        ? _asText(data["experienceYears"])
        : _asText(data["experience"]);

    final description = _asText(data["doctorDescription"]).isNotEmpty
        ? _asText(data["doctorDescription"])
        : _asText(data["description"]);

    final profileUrl = _asText(data["profileImagePath"]);
    final approved = (data["approved"] ?? true) == true;
    final profileComplete = (data["profileComplete"] ?? false) == true;

    final qualificationImages = data["qualificationImages"] is List
        ? (data["qualificationImages"] as List)
        .map((e) => e.toString())
        .where((e) => e.trim().isNotEmpty)
        .toList()
        : <String>[];

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
                            color: Colors.red.withOpacity(.10),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.red,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: CircleAvatar(
                        radius: 46,
                        backgroundColor: green.withOpacity(.16),
                        backgroundImage:
                        profileUrl.isNotEmpty ? NetworkImage(profileUrl) : null,
                        child: profileUrl.isEmpty
                            ? const Icon(
                          Icons.person,
                          color: green,
                          size: 44,
                        )
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
                          color: green,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: Text(
                        "Doctor Profile Details",
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
                        border: Border.all(color: green.withOpacity(.30)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _popupRow("Email", email),
                          _popupRow("Age", age),
                          _popupRow(
                            "Experience",
                            experience.isEmpty ? "N/A" : "$experience years",
                          ),
                          _popupRow("Specialization", specialization),
                          _popupRow("Qualification", qualification),
                          _popupRow("Description", description),
                          _popupRow(
                            "Approval Status",
                            approved ? "Approved" : "Pending",
                          ),
                          _popupRow(
                            "Profile Complete",
                            profileComplete ? "Yes" : "No",
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Qualification / Degree Images",
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (qualificationImages.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "No qualification images uploaded.",
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: qualificationImages.map((url) {
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
                                  child: const Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            ),
                          );
                        }).toList(),
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

  Widget _doctorCard(BuildContext context, Map<String, dynamic> data) {
    final t = AppLocalizations.of(context)!;

    final name = _fullName(context, data);
    final email = _asText(data["email"]);
    final age = _asInt(data["age"]);

    final qualification = _asText(data["qualifications"]).isNotEmpty
        ? _asText(data["qualifications"])
        : _asText(data["qualification"]);

    final specialization = _asText(data["specialization"]);

    final experience = _asText(data["experienceYears"]).isNotEmpty
        ? _asText(data["experienceYears"])
        : _asText(data["experience"]);

    final showExtras = _hasAnyExtra(
      qualification: qualification,
      specialization: specialization,
      experience: experience,
    );

    const accent = green;
    const dark = Color(0xFF0F172A);
    const muted = Color(0xFF475569);
    const surface = Color(0xFFF8FAFC);

    Widget pill({required IconData icon, required String text}) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: accent.withOpacity(.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: accent),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                  color: dark,
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget kvRow({
      required IconData icon,
      required String label,
      required String value,
    }) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: muted),
            const SizedBox(width: 10),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: GoogleFonts.inter(fontSize: 13.5, height: 1.25),
                  children: [
                    TextSpan(
                      text: "$label  ",
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        color: dark,
                      ),
                    ),
                    TextSpan(
                      text: value,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w500,
                        color: muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: accent.withOpacity(.25), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [accent.withOpacity(.20), Colors.white],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: accent.withOpacity(.35)),
                      ),
                      child: const Icon(
                        Icons.medical_services,
                        color: accent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800,
                          fontSize: 16.5,
                          color: dark,
                        ),
                      ),
                    ),
                    if (age != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          "${age}${t.yearsSuffix}",
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                            color: accent,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: green.withOpacity(.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        tooltip: "View doctor details",
                        icon: const Icon(
                          Icons.remove_red_eye_outlined,
                          color: green,
                        ),
                        onPressed: () =>
                            _showDoctorDetailsPopup(context, data),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    pill(
                      icon: Icons.mail_outline,
                      text: email.isNotEmpty ? email : t.na,
                    ),
                    const SizedBox(height: 6),
                    if (showExtras) ...[
                      if (qualification.isNotEmpty)
                        kvRow(
                          icon: Icons.school_outlined,
                          label: t.qualificationLabel,
                          value: qualification,
                        ),
                      if (specialization.isNotEmpty)
                        kvRow(
                          icon: Icons.medical_information_outlined,
                          label: t.specializationLabel,
                          value: specialization,
                        ),
                      if (experience.isNotEmpty)
                        kvRow(
                          icon: Icons.work_outline,
                          label: t.experienceLabel,
                          value: experience,
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _logoutConfirm(context),
            icon: const Icon(Icons.logout, size: 30, color: Colors.black),
            tooltip: t.logoutTitle,
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
                backgroundImage: _avatarProvider(),
              ),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.center,
              child: Text(
                _name,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 27,
                  color: green,
                ),
              ),
            ),
            const SizedBox(height: 15),
            _drawerBtn(
              leading: const Icon(
                Icons.settings,
                color: Colors.white,
                size: 20,
              ),
              text: t.settings,
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminSettings()),
                );
                _loadAdminHeader();
              },
            ),
            _drawerBtn(
              leading: Image.asset("assets/images/smileface.png", width: 24),
              text: t.feedbackResponses,
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminFeedback()),
                );
                _loadAdminHeader();
              },
            ),
            _drawerBtn(
              leading: const Icon(
                Icons.logout,
                color: Colors.white,
                size: 20,
              ),
              text: t.logoutTitle,
              onPressed: () => _logoutConfirm(context),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            children: [
              Image.asset(
                "assets/images/manageprofile.png",
                width: 373,
                height: 249,
              ),
              const SizedBox(height: 10),
              Text(
                t.viewDoctorsTitle,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 27,
                  color: green,
                ),
              ),
              const SizedBox(height: 18),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _approvedDoctorsStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 30),
                      child: Text(
                        "${t.errorLabel}: ${snapshot.error}",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: Colors.red,
                        ),
                      ),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 30),
                      child: CircularProgressIndicator(),
                    );
                  }

                  final docs = snapshot.data!.docs;

                  if (docs.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 60),
                      child: Text(
                        t.noApprovedDoctorsYet,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: green,
                        ),
                      ),
                    );
                  }

                  docs.sort((a, b) {
                    final ta = a.data()["createdAt"];
                    final tb = b.data()["createdAt"];
                    if (ta is Timestamp && tb is Timestamp) {
                      return tb.compareTo(ta);
                    }
                    return 0;
                  });

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final data = docs[index].data();

                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutCubic,
                        builder: (context, tt, child) {
                          return Transform.translate(
                            offset: Offset(0, (1 - tt) * 10),
                            child: Opacity(opacity: tt, child: child),
                          );
                        },
                        child: _doctorCard(context, data),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}