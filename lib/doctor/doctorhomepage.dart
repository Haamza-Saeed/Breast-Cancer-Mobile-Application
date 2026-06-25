import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project/doctor/chatroom.dart';
import 'package:project/doctor/doctorchatrequest.dart';
import 'package:project/doctor/doctorfeedback.dart';
import 'package:project/doctor/doctorsettings.dart';
import 'package:project/doctor/uploadexercise.dart';
import 'package:project/login.dart';

import 'doctormanageprofile.dart';
import 'manage_uploads.dart';

// ✅ Localization
import 'package:project/l10n/app_localizations.dart';

class DoctorHomepage extends StatefulWidget {
  const DoctorHomepage({super.key});

  @override
  State<DoctorHomepage> createState() => _DoctorHomepageState();
}

class _DoctorHomepageState extends State<DoctorHomepage> {
  static const Color blue = Color(0xff00AEEF);

  bool _checkedProfileOnce = false; // ✅ show dialog only once per session
  bool _logoutDialogOpen = false; // ✅ avoid double dialogs

  // ---------------------------
  // ✅ Sweet alerts helpers
  // ---------------------------
  void _sweet({
    required DialogType type,
    required String title,
    required String desc,
    required String okText,
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

  // ---------------------------
  // ✅ Profile incomplete logic
  // ---------------------------
  bool _isProfileIncomplete(Map<String, dynamic> data) {
    final exp = data["experience"];
    final specialization = (data["specialization"] ?? "").toString().trim();
    final qualification = (data["qualification"] ?? "").toString().trim();
    final description = (data["description"] ?? "").toString().trim();

    final expMissing = exp == null || (exp is num && exp.toInt() <= 0);

    return expMissing ||
        specialization.isEmpty ||
        qualification.isEmpty ||
        description.isEmpty;
  }

  Future<void> _maybeShowIncompleteProfileDialog({
    required AppLocalizations? t,
    required DocumentReference<Map<String, dynamic>> docRef,
    required Map<String, dynamic> data,
  }) async {
    // ✅ show only once in this session
    if (_checkedProfileOnce) return;
    _checkedProfileOnce = true;

    final incomplete = _isProfileIncomplete(data);
    final alreadyShown = (data["profileIncompleteAlertShown"] == true);

    if (!incomplete) return;
    if (alreadyShown) return;
    if (!mounted) return;

    // ✅ mark shown in Firestore so it never shows again for this account
    try {
      await docRef.set(
        {"profileIncompleteAlertShown": true},
        SetOptions(merge: true),
      );
    } catch (_) {
      // ignore write failure; still show dialog
    }

    if (!mounted) return;

    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.scale,
      title: t?.completeYourProfileTitle ?? "Complete Your Profile",
      desc: t?.profileIncompleteDesc ?? "Your profile is incomplete.",
      btnOkText: t?.completeNow ?? "Complete Now",
      btnCancelText: t?.later ?? "Later",
      btnCancelOnPress: () {},
      btnOkOnPress: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DoctorManageProfile()),
        );
      },
    ).show();
  }

  // ---------------------------
  // ✅ Logout confirm
  // ---------------------------
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
        } catch (e) {
          _sweet(
            type: DialogType.error,
            title: t?.logoutFailed ?? "Logout Failed",
            desc: "$e",
            okText: t?.ok ?? "OK",
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

  // ---------------------------
  // ✅ Drawer button navigation helper
  // ---------------------------
  void _goTo(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;

    if (uid == null) {
      return Scaffold(
        body: Center(child: Text(t?.doctorNotLoggedIn ?? "Doctor not logged in")),
      );
    }

    final docRef = FirebaseFirestore.instance.collection("users").doc(uid);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: docRef.snapshots(),
      builder: (context, snapshot) {
        // ✅ loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // ✅ error state
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text(
                "${t?.failedToLoadProfile ?? "Failed to load profile."}\n${snapshot.error}",
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final data = snapshot.data?.data() ?? {};

        final firstName = (data["firstName"] ?? "").toString().trim();
        final name = firstName.isNotEmpty ? firstName : (t?.doctor ?? "Doctor");

        // ✅ public url
        final imgUrl = (data["profileImagePath"] ?? "").toString().trim();

        final ImageProvider avatarProvider = imgUrl.isNotEmpty
            ? NetworkImage(imgUrl)
            : const AssetImage("assets/images/profileblue.png");

        // ✅ show incomplete profile dialog once (after first frame)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _maybeShowIncompleteProfileDialog(docRef: docRef, data: data, t: t);
        });

        return Scaffold(
          appBar: AppBar(
            actions: [
              IconButton(
                onPressed: () => _logoutConfirm(t),
                icon: const Icon(Icons.logout, size: 30, color: Colors.black),
              )
            ],
          ),

          // ✅ Drawer always shows latest name + image from Firestore
          drawer: Drawer(
            child: ListView(
              children: [
                const SizedBox(height: 20),
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: avatarProvider,
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
                      color: blue,
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                // Settings
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: ElevatedButton(
                    onPressed: () => _goTo(const DoctorSettings()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: blue,
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

                // Feedback
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: ElevatedButton(
                    onPressed: () => _goTo(const DoctorFeedBack()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: blue,
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
                            t?.feedbackTitle ?? "Feedback",
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

                // Manage Uploads
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: ElevatedButton(
                    onPressed: () => _goTo(const ManageUploads()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: blue,
                      padding: const EdgeInsets.symmetric(vertical: 17),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        children: [
                          const Icon(Icons.folder_open, color: Colors.white, size: 20),
                          const SizedBox(width: 15),
                          Text(
                            t?.manageUploads ?? "Manage Uploads",
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
                    onPressed: () => _logoutConfirm(t),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: blue,
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  Image.asset("assets/images/doctorhomepage.png", width: 373, height: 249),
                  const SizedBox(height: 20),

                  Text(
                    t?.welcome(name) ?? "Welcome $name!",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 27,
                      color: blue,
                    ),
                  ),

                  const SizedBox(height: 15),

                  // View Chat Request
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const DoctorChatRequest()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: blue,
                        padding: const EdgeInsets.symmetric(vertical: 17),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Image.asset("assets/images/chat.png", width: 24),
                            const SizedBox(width: 15),
                            Text(
                              t?.viewChatRequest ?? "View Chat Request",
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

                  // Chat Room
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ChatRoom()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: blue,
                        padding: const EdgeInsets.symmetric(vertical: 17),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            const Icon(Icons.chat, color: Colors.white, size: 20),
                            const SizedBox(width: 15),
                            Text(
                              t?.chatRoom ?? "Chat Room",
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

                  // Upload Exercise
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const UploadExercise()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: blue,
                        padding: const EdgeInsets.symmetric(vertical: 17),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            const Icon(Icons.upload_file_sharp, color: Colors.white, size: 20),
                            const SizedBox(width: 15),
                            Text(
                              t?.uploadExerciseTitle ?? "Upload Exercise",
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