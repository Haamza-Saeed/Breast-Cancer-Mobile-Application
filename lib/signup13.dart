import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project/login.dart';
import 'package:project/signup9.dart';
import 'package:project/signup12.dart';

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
        child: Image.asset("assets/images/loading.gif", width: 90, height: 90),
      ),
    ),
  );
}

void showSnack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}

class Signup13 extends StatefulWidget {
  final String uid;
  final String email;
  final String role;

  const Signup13({
    super.key,
    required this.uid,
    required this.email,
    required this.role,
  });

  @override
  State<Signup13> createState() => _Signup13State();
}

class _Signup13State extends State<Signup13> {
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  static const String _tempPassword = "Temp@123456";

  Future<void> _runWithLoading(Future<void> Function() action) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      await action();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<User?> _reauthenticateTempUser(String email) async {
    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: _tempPassword,
      );

      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        await currentUser.reauthenticateWithCredential(credential);
        await currentUser.reload();
        return FirebaseAuth.instance.currentUser;
      }

      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: _tempPassword,
      );

      return cred.user;
    } on FirebaseAuthException catch (e) {
      showSnack(
        context,
        e.message ??
            "Session expired. Please go back to email verification and continue again.",
      );
      return null;
    } catch (e) {
      showSnack(context, "Re-authentication failed: $e");
      return null;
    }
  }

  Future<void> _finishSignup() async {
    final pass = passwordController.text.trim();
    final confirm = confirmController.text.trim();
    final email = widget.email.trim().toLowerCase();
    final uid = widget.uid.trim();

    if (pass.isEmpty) {
      showSnack(context, "Password cannot be empty");
      return;
    }

    if (confirm.isEmpty) {
      showSnack(context, "Confirm password cannot be empty");
      return;
    }

    if (pass.length < 8) {
      showSnack(context, "Password can't be less than 8 characters");
      return;
    }

    if (pass != confirm) {
      showSnack(context, "Passwords do not match");
      return;
    }

    await _runWithLoading(() async {
      final pendingRef =
      FirebaseFirestore.instance.collection('pending_signups').doc(uid);

      final pendingSnap = await pendingRef.get();

      if (!pendingSnap.exists) {
        showSnack(context, "Signup data not found. Please start signup again.");
        return;
      }

      final data = pendingSnap.data() ?? {};

      final user = await _reauthenticateTempUser(email);
      if (user == null) return;

      if ((user.email ?? '').trim().toLowerCase() != email) {
        showSnack(context, "Wrong session detected. Please restart signup.");
        return;
      }

      await user.reload();
      final refreshed = FirebaseAuth.instance.currentUser;

      if (refreshed == null || !refreshed.emailVerified) {
        showSnack(context, "Please verify your email first.");
        return;
      }

      try {
        await refreshed.updatePassword(pass);
      } on FirebaseAuthException catch (e) {
        showSnack(context, e.message ?? "Failed to set password.");
        return;
      }

      final isDoctor = widget.role == "doctor";

      final userData = <String, dynamic>{
        ...data,

        "uid": uid,
        "email": email,
        "role": widget.role,
        "approved": isDoctor ? false : true,
        "darkMode": false,

        // ✅ Normalize doctor fields
        "experience": data["experience"] ?? data["experienceYears"] ?? "",
        "experienceYears": data["experienceYears"] ?? data["experience"] ?? "",

        "specialization": data["specialization"] ?? "",

        "qualification": data["qualification"] ?? data["qualifications"] ?? "",
        "qualifications": data["qualifications"] ?? data["qualification"] ?? "",

        "description": data["description"] ?? data["doctorDescription"] ?? "",
        "doctorDescription": data["doctorDescription"] ?? data["description"] ?? "",

        "createdAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
      };

      userData.remove("status");
      userData.remove("step");

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(userData, SetOptions(merge: true));

      await pendingRef.delete();

      if (!mounted) return;

      AwesomeDialog(
        context: context,
        dialogType: DialogType.success,
        animType: AnimType.scale,
        title: "Success",
        desc: isDoctor
            ? "Doctor account created! Please wait for admin approval before login."
            : "Your account has been created successfully!",
        btnOkText: "Go to Login",
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
    });
  }

  void _goBack() {
    if (widget.role == "doctor") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => Signup12(
            uid: widget.uid,
            email: widget.email,
            role: widget.role,
          ),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => Signup9(
            uid: widget.uid,
            email: widget.email,
            role: widget.role,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: signupAppBar(),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  Image.asset(
                    "assets/images/handsribbion.png",
                    width: 349,
                    height: 300,
                  ),
                  Text(
                    "Create your account",
                    style: GoogleFonts.poppins(
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                      color: kPink,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Password",
                      style: GoogleFonts.poppins(
                        color: kBlue,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  TextField(
                    controller: passwordController,
                    obscureText: _obscurePassword,
                    decoration: signupInputDecoration(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.blue,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Confirm password",
                      style: GoogleFonts.poppins(
                        color: kBlue,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  TextField(
                    controller: confirmController,
                    obscureText: _obscureConfirm,
                    decoration: signupInputDecoration(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.blue,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirm = !_obscureConfirm;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 90),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _finishSignup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kBlue,
                        disabledBackgroundColor: Colors.grey.shade300,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        "Finish",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
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