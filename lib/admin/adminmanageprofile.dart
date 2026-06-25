import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project/admin/adminfeedback.dart';
import 'package:project/admin/adminsettings.dart';
import 'package:project/admin/editprofile.dart';
import 'package:project/admin/manage_announcements.dart';
import 'package:project/login.dart';

// ✅ Localization
import 'package:project/l10n/app_localizations.dart';

class AdminManageProfile extends StatefulWidget {
  const AdminManageProfile({super.key});

  @override
  State<AdminManageProfile> createState() => _AdminManageProfileState();
}

class _AdminManageProfileState extends State<AdminManageProfile> {
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
    } catch (_) {
      // keep defaults
    }
  }

  ImageProvider _avatarProvider() {
    if (_profileUrl.trim().isNotEmpty) return NetworkImage(_profileUrl);
    return const AssetImage("assets/images/profilegreen.png");
  }

  Future<void> _logoutConfirm(AppLocalizations? t) async {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.question,
      animType: AnimType.scale,
      title: t?.logout ?? "Logout",
      desc: t?.logoutConfirm ?? "Are you sure you want to logout?",
      btnCancelText: t?.cancel ?? "Cancel",
      btnOkText: t?.logout ?? "Logout",
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

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _logoutConfirm(t),
            icon: const Icon(Icons.logout, size: 30, color: Colors.black),
          ),
        ],
      ),

      // ✅ Localized Drawer
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

            // ✅ Settings
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminSettings()),
                  );
                },
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
                      const Icon(Icons.settings, color: Colors.white, size: 20),
                      const SizedBox(width: 15),
                      Text(
                        t?.settings ?? "Settings",
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
            ),

            // ✅ Feedback
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminFeedback()),
                  );
                },
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
                      Image.asset("assets/images/smileface.png", width: 24),
                      const SizedBox(width: 15),
                      Text(
                        t?.feedbackResponsesTitle ?? "Feedback & Responses",
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
            ),

            // ✅ Logout
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: ElevatedButton(
                onPressed: () => _logoutConfirm(t),
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
                      const Icon(Icons.logout, color: Colors.white, size: 20),
                      const SizedBox(width: 15),
                      Text(
                        t?.logout ?? "Logout",
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
            ),
          ],
        ),
      ),

      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            children: [
              Image.asset(
                "assets/images/adminmanageprofile.png",
                width: 373,
                height: 249,
              ),
              const SizedBox(height: 10),
              Text(
                t?.manageProfile ?? "Manage Profile",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 27,
                  color: green,
                ),
              ),
              const SizedBox(height: 13),

              Center(
                child: CircleAvatar(
                  radius: 52,
                  backgroundImage: _avatarProvider(),
                ),
              ),

              const SizedBox(height: 10),

              Text(
                _name,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: green,
                ),
              ),

              const SizedBox(height: 20),

              // ✅ Edit Profile
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EditProfile()),
                    );
                    _loadAdminHeader();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    t?.editProfile ?? "Edit Profile",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // ✅ Manage Feedback
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminFeedback()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    t?.manageResponse ?? "Manage Response",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // ✅ Manage Announcements
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ManageAnnouncements()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    t?.manageAnnouncements ?? "Manage Announcements",
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