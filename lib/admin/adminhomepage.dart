import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:project/admin/adminannouncements.dart';
import 'package:project/admin/adminfeedback.dart';
import 'package:project/admin/adminmanageusers.dart';
import 'package:project/admin/adminsettings.dart';
import 'package:project/admin/monitorchat.dart';
import 'package:project/login.dart';

// ✅ Localization
import 'package:project/l10n/app_localizations.dart';

class AdminHomepage extends StatefulWidget {
  const AdminHomepage({super.key});

  @override
  State<AdminHomepage> createState() => _AdminHomepageState();
}

class _AdminHomepageState extends State<AdminHomepage> {
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

  void _logoutConfirm(AppLocalizations? t) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.question,
      animType: AnimType.scale,
      title: t?.logout ?? "Logout",
      desc: t?.logoutConfirm ?? "Are you sure you want to logout?",
      btnCancelText: t?.no ?? "No",
      btnOkText: t?.yes ?? "Yes",
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
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

  Widget _homeButton({
    required Widget leading,
    required String text,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: green,
          padding: const EdgeInsets.symmetric(vertical: 17),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () => _logoutConfirm(t),
            icon: const Icon(Icons.logout, size: 30, color: Colors.black),
          ),
        ],
      ),

      // ✅ Drawer updated (localized)
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
              leading: const Icon(Icons.settings, color: Colors.white, size: 20),
              text: t?.settings ?? "Settings",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminSettings()),
                );
              },
            ),

            _drawerBtn(
              leading: Image.asset("assets/images/smileface.png", width: 24),
              text: t?.feedbackResponsesTitle ?? "Feedback & Responses",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminFeedback()),
                );
              },
            ),

            _drawerBtn(
              leading: const Icon(Icons.logout, color: Colors.white, size: 20),
              text: t?.logout ?? "Logout",
              onPressed: () => _logoutConfirm(t),
            ),
          ],
        ),
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            children: [
              Image.asset("assets/images/adminhomepage.png",
                  width: 373, height: 249),
              const SizedBox(height: 20),

              Text(
                t?.welcome(_name) ?? "Welcome $_name!",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 27,
                  color: green,
                ),
              ),

              const SizedBox(height: 15),

              _homeButton(
                leading: Image.asset("assets/images/manageusers.png", width: 24),
                text: t?.manageUsers ?? "Manage Users",
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminManageUsers()),
                  );
                  _loadAdminHeader();
                },
              ),

              const SizedBox(height: 15),

              _homeButton(
                leading: const Icon(Icons.chat, color: Colors.white, size: 20),
                text: t?.monitorChats ?? "Monitor Chats",
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MonitorChats()),
                  );
                  _loadAdminHeader();
                },
              ),

              const SizedBox(height: 15),

              _homeButton(
                leading: Image.asset("assets/images/megaphone.png", width: 24),
                text: t?.announcements ?? "Announcements",
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AdminAnnouncements()),
                  );
                  _loadAdminHeader();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}