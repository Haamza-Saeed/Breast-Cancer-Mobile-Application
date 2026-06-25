import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project/login.dart';
import 'package:project/l10n/app_localizations.dart';
import 'package:project/patient/aboutus.dart';
import 'package:project/patient/chatarequest.dart';
import 'package:project/patient/diagnosesymptom.dart';
import 'package:project/patient/feedback.dart';
import 'package:project/patient/report.dart';
import 'package:project/patient/requestchat.dart';
import 'package:project/patient/settings.dart' as app_settings;
import 'package:project/patient/uploadimage.dart';
import 'package:project/patient/view_media.dart';

// ✅ IMPORTANT: import your real profile screen here
// Change the file name if your profile screen file is named differently.
import 'package:project/patient/profile.dart'; // must contain: class PatientProfile extends StatefulWidget

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  bool _checkedProfileOnce = false; // ✅ show only once per app open

  bool _isProfileIncomplete(Map<String, dynamic> data) {
    final firstName = (data["firstName"] ?? "").toString().trim();
    final email = (data["email"] ?? "").toString().trim();

    final ageVal = data["age"];
    final age = (ageVal is num)
        ? ageVal.toInt()
        : int.tryParse(ageVal?.toString() ?? "") ?? 0;

    final marital = (data["maritalStatus"] ?? "").toString().trim();
    final anyMed = (data["anyMedication"] ?? "").toString().trim();
    final cancerFam = (data["cancerInFamily"] ?? "").toString().trim();

    // ✅ If you store profileComplete, use it as truth
    if (data.containsKey("profileComplete")) {
      return data["profileComplete"] != true;
    }

    // fallback completion check
    return firstName.isEmpty ||
        email.isEmpty ||
        !email.contains("@") ||
        age < 10 ||
        marital.isEmpty ||
        anyMed.isEmpty ||
        cancerFam.isEmpty;
  }

  Future<void> _maybeShowIncompleteProfileDialog({
    required DocumentReference<Map<String, dynamic>> docRef,
    required Map<String, dynamic> data,
    required AppLocalizations t,
  }) async {
    if (_checkedProfileOnce) return;
    _checkedProfileOnce = true;

    final incomplete = _isProfileIncomplete(data);
    final alreadyShown = (data["profileIncompleteAlertShown"] == true);

    if (!incomplete) return;
    if (alreadyShown) return;
    if (!mounted) return;

    // ✅ mark shown in Firestore so it never shows again for this account
    await docRef.set(
      {"profileIncompleteAlertShown": true},
      SetOptions(merge: true),
    );

    if (!mounted) return;

    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.scale,
      title: t.incompleteProfileTitle,
      desc: t.incompleteProfileDesc,
      btnOkText: t.completeNow,
      btnCancelText: t.later,
      btnCancelOnPress: () {},
      btnOkOnPress: () {
        // ✅ FIX: open your REAL profile page (profile.dart)
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PatientProfile()),
        );
      },
    ).show();
  }

  void _logoutConfirm(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    AwesomeDialog(
      context: context,
      dialogType: DialogType.question,
      animType: AnimType.scale,
      title: t.logout,
      desc: t.logoutConfirm,
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

  ImageProvider _drawerAvatarProvider(String url) {
    final u = url.trim();
    if (u.isNotEmpty) return NetworkImage(u);
    return const AssetImage("assets/images/profilepink.png");
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;

    if (uid == null) {
      return Scaffold(
        body: Center(child: Text(t.userNotLoggedIn)),
      );
    }

    final docRef = FirebaseFirestore.instance.collection("users").doc(uid);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: docRef.snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? {};

        final firstName = (data["firstName"] ?? "").toString().trim();
        final name = firstName.isNotEmpty ? firstName : (t.user);

        final imgUrl = (data["profileImagePath"] ?? "").toString().trim();

        // ✅ show dialog only once after first data load
        if (snapshot.connectionState == ConnectionState.active ||
            snapshot.connectionState == ConnectionState.done) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _maybeShowIncompleteProfileDialog(docRef: docRef, data: data, t: t);
          });
        }

        return Scaffold(
          appBar: AppBar(
            actions: [
              IconButton(
                onPressed: () => _logoutConfirm(context),
                icon: const Icon(Icons.logout, size: 30, color: Colors.black),
              )
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
                      color: const Color(0xffFF67CE),
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                // Settings
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const app_settings.Settings()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xffFF67CE),
                      padding: const EdgeInsets.symmetric(vertical: 17),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        children: [
                          const Icon(Icons.settings, color: Colors.white, size: 20),
                          const SizedBox(width: 15),
                          Text(
                            t.settings,
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

                // Feedback
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const FeedBack()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xffFF67CE),
                      padding: const EdgeInsets.symmetric(vertical: 17),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        children: [
                          Image.asset("assets/images/smileface.png", width: 24),
                          const SizedBox(width: 15),
                          Text(
                            t.feedbackTitle,
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

                // View Media
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ViewMedia()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xffFF67CE),
                      padding: const EdgeInsets.symmetric(vertical: 17),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        children: [
                          const Icon(Icons.perm_media, color: Colors.white, size: 20),
                          const SizedBox(width: 15),
                          Text(
                            t.viewMedia,
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

                // About Us
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AboutUs()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xffFF67CE),
                      padding: const EdgeInsets.symmetric(vertical: 17),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        children: [
                          Image.asset("assets/images/info.png", width: 24),
                          const SizedBox(width: 15),
                          Text(
                            t.aboutUs,
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

                // Logout
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: ElevatedButton(
                    onPressed: () => _logoutConfirm(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xffFF67CE),
                      padding: const EdgeInsets.symmetric(vertical: 17),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        children: [
                          const Icon(Icons.logout, color: Colors.white, size: 20),
                          const SizedBox(width: 15),
                          Text(
                            t.logout,
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  Image.asset("assets/images/homepage.png", width: 373, height: 249),
                  const SizedBox(height: 20),
                  Text(
                    t.welcome(name),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 27,
                      color: const Color(0xffFF67CE),
                    ),
                  ),
                  const SizedBox(height: 15),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const UploadImage()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xffFF67CE),
                        padding: const EdgeInsets.symmetric(vertical: 17),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            const Icon(Icons.upload_file_sharp,
                                color: Colors.white, size: 20),
                            const SizedBox(width: 15),
                            Text(
                              t.uploadImage,
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

                  const SizedBox(height: 15),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const DiagnoseSymptoms()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xffFF67CE),
                        padding: const EdgeInsets.symmetric(vertical: 17),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Image.asset("assets/images/search.png", width: 24),
                            const SizedBox(width: 15),
                            Text(
                              t.diagnoseSymptom,
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

                  const SizedBox(height: 15),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ChataRequest()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xffFF67CE),
                        padding: const EdgeInsets.symmetric(vertical: 17),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            const Icon(Icons.chat, color: Colors.white, size: 20),
                            const SizedBox(width: 15),
                            Text(
                              t.chatWithDoctors,
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

                  const SizedBox(height: 15),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ChatRequest()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xffFF67CE),
                        padding: const EdgeInsets.symmetric(vertical: 17),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Image.asset("assets/images/chat.png", width: 24),
                            const SizedBox(width: 15),
                            Text(
                              t.requestChat,
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

                  const SizedBox(height: 15),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => Report()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xffFF67CE),
                        padding: const EdgeInsets.symmetric(vertical: 17),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Image.asset("assets/images/bargraph.png", width: 24),
                            const SizedBox(width: 15),
                            Text(
                              t.viewReport,
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
          ),
        );
      },
    );
  }
}