import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:project/Description.dart';
import 'package:project/admin/adminrootpage.dart';
import 'package:project/doctor/doctorrootpage.dart';
import 'package:project/forget_password.dart';
import 'package:project/patient/rootpage.dart';
import 'package:project/signup1.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  static const String adminEmail = "chhamza3886@gmail.com";

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showSuccessDialog({
    required String title,
    required String desc,
    required VoidCallback onOk,
  }) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.success,
      animType: AnimType.scale,
      title: title,
      desc: desc,
      btnOkText: "OK",
      btnOkOnPress: onOk,
    ).show();
  }

  void _showErrorDialog(String title, String desc) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      animType: AnimType.scale,
      title: title,
      desc: desc,
      btnOkText: "OK",
      btnOkOnPress: () {},
    ).show();
  }

  void _showWarningDialog(String title, String desc) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.scale,
      title: title,
      desc: desc,
      btnOkText: "OK",
      btnOkOnPress: () {},
    ).show();
  }

  Future<void> _runWithLoading(Future<void> Function() action) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      await action();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _validateEmailPassword() {
    final email = emailController.text.trim();
    final pass = passwordController.text.trim();

    if (email.isEmpty) {
      _showSnack("Email cannot be empty");
      return false;
    }

    if (!email.contains('@')) {
      _showSnack("Your Email does not have @. Please enter @ too.");
      return false;
    }

    if (pass.isEmpty) {
      _showSnack("Password cannot be empty");
      return false;
    }

    if (pass.length < 8) {
      _showSnack("Password can't be less than 8 digits");
      return false;
    }

    return true;
  }

  Future<Map<String, dynamic>> _ensureUserProfileAndGetData(User user) async {
    final uid = user.uid;
    final email = (user.email ?? "").trim().toLowerCase();

    final docRef = FirebaseFirestore.instance.collection("users").doc(uid);
    final snap = await docRef.get();

    if (!snap.exists) {
      final isAdmin = email == adminEmail;

      await docRef.set({
        "uid": uid,
        "email": email,
        "firstName": user.displayName?.split(" ").first ?? "",
        "lastName": user.displayName?.split(" ").length == 2
            ? (user.displayName?.split(" ").last ?? "")
            : "",
        "age": null,
        "profileImagePath": user.photoURL ?? "",
        "languageCode": "en",
        "darkMode": false,
        "role": isAdmin ? "admin" : "patient",
        "approved": true,
        "createdAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return {
        "role": isAdmin ? "admin" : "patient",
        "approved": true,
      };
    }

    final data = snap.data() ?? {};
    String role = (data["role"] ?? "patient").toString();

    if (email == adminEmail && role != "admin") {
      await docRef.set({
        "role": "admin",
        "approved": true,
      }, SetOptions(merge: true));

      role = "admin";
    }

    final dynamic ap = data["approved"];
    final bool approved = ap is bool ? ap : (role == "doctor" ? false : true);

    return {
      "role": role,
      "approved": approved,
    };
  }

  Future<void> _goAfterLogin(User user) async {
    final info = await _ensureUserProfileAndGetData(user);
    if (!mounted) return;

    final role = (info["role"] ?? "patient").toString();
    final approved = (info["approved"] ?? false) as bool;

    if (role == "doctor" && !approved) {
      _showWarningDialog(
        "Pending Approval",
        "Your doctor account is pending approval by admin.",
      );
      await FirebaseAuth.instance.signOut();
      return;
    }

    _showSuccessDialog(
      title: "Login Successful!",
      desc: role == "admin"
          ? "Welcome Admin!"
          : role == "doctor"
          ? "Welcome Doctor!"
          : "Welcome!",
      onOk: () {
        if (!mounted) return;

        if (role == "admin") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminRootPage()),
          );
        } else if (role == "doctor") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DoctorRootPage()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => RootPage()),
          );
        }
      },
    );
  }

  Future<void> _loginWithEmailPassword() async {
    if (!_validateEmailPassword()) return;

    final email = emailController.text.trim();
    final pass = passwordController.text.trim();

    await _runWithLoading(() async {
      try {
        final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: pass,
        );

        final user = cred.user;

        if (user == null) {
          _showErrorDialog("Login Failed", "No user found.");
          return;
        }

        await _goAfterLogin(user);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
          _showErrorDialog("Login Failed", "No user found for this email.");
        } else if (e.code == 'wrong-password') {
          _showErrorDialog("Login Failed", "Wrong password. Try again.");
        } else if (e.code == 'invalid-email') {
          _showErrorDialog("Login Failed", "Invalid email address.");
        } else {
          _showErrorDialog("Login Failed", e.message ?? "Login failed");
        }
      } catch (e) {
        _showErrorDialog("Error", "Something went wrong: $e");
      }
    });
  }

  Future<void> _googleLoginPressed() async {
    await _runWithLoading(() async {
      try {
        final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

        if (googleUser == null) {
          _showWarningDialog("Cancelled", "Google sign-in cancelled.");
          return;
        }

        final googleAuth = await googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);

        final user = userCredential.user;

        if (user == null) {
          _showErrorDialog("Google Login Failed", "No user returned.");
          return;
        }

        await _goAfterLogin(user);
      } on FirebaseAuthException catch (e) {
        _showErrorDialog(
          "Google Login Failed",
          e.message ?? "Google Login Failed",
        );
      } catch (e) {
        _showErrorDialog("Error", "Something went wrong: $e");
      }
    });
  }

  Future<void> _continueWithEmail() async {
    await _runWithLoading(() async {
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const Signup1()),
      );
    });
  }

  Future<void> _openForgetPassword() async {
    await _runWithLoading(() async {
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ForgetPassword()),
      );
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  InputDecoration _blueBorderFieldDecoration({Widget? suffixIcon}) {
    return InputDecoration(
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

  Widget _loadingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.35),
        child: Center(
          child: Image.asset(
            "assets/images/loading.gif",
            width: 90,
            height: 90,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          resizeToAvoidBottomInset: true,
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
                  "AI-Based Breast Cancer Detection App",
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: const Color(0xffFF67CE),
                  ),
                ),
              ),
            ),
          ),
          body: AbsorbPointer(
            absorbing: _isLoading,
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xffFF67CE),
                            width: 2,
                          ),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Color(0xffFF67CE),
                            size: 18,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const Description(),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    Image.asset(
                      "assets/images/eimage.png",
                      width: 349,
                      height: 300,
                    ),

                    const SizedBox(height: 15),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Email",
                        style: GoogleFonts.poppins(
                          color: const Color(0xff00AEEF),
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ),

                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _blueBorderFieldDecoration(),
                    ),

                    const SizedBox(height: 12),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Password",
                        style: GoogleFonts.poppins(
                          color: const Color(0xff00AEEF),
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ),

                    TextField(
                      controller: passwordController,
                      obscureText: _obscurePassword,
                      decoration: _blueBorderFieldDecoration(
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

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _openForgetPassword,
                        child: Text(
                          "Forget Password",
                          style: GoogleFonts.poppins(
                            color: const Color(0xff00AEEF),
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loginWithEmailPassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff00AEEF),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          "Login",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _continueWithEmail,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xffFF67CE),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          "Sign Up",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    GestureDetector(
                      onTap: _googleLoginPressed,
                      child: Image.asset(
                        "assets/images/googleicon.png",
                        width: 35,
                        height: 35,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        if (_isLoading) _loadingOverlay(),
      ],
    );
  }
}