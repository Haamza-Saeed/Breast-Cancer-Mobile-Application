import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project/signup3.dart';

class Signup2 extends StatefulWidget {
  final String email;
  final String role;

  const Signup2({
    super.key,
    required this.email,
    required this.role,
  });

  @override
  State<Signup2> createState() => _Signup2State();
}

class _Signup2State extends State<Signup2> {
  static const Color kPink = Color(0xffFF67CE);
  static const Color kBlue = Color(0xff00AEEF);

  bool _isLoading = false;
  static const String _tempPassword = "Temp@123456";

  void _showSweet({
    required DialogType type,
    required String title,
    required String desc,
    VoidCallback? onOk,
  }) {
    if (!mounted) return;

    AwesomeDialog(
      context: context,
      dialogType: type,
      animType: AnimType.scale,
      title: title,
      desc: desc,
      btnOkText: "OK",
      btnOkOnPress: onOk ?? () {},
    ).show();
  }

  Widget _backButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        onTap: () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        },
        borderRadius: BorderRadius.circular(28),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: kBlue, width: 2.5),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new,
            color: kBlue,
            size: 22,
          ),
        ),
      ),
    );
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

  PreferredSizeWidget _signupAppBar() {
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

  Widget _loadingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.35),
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

  Future<User?> _ensureTempAuthUser() async {
    final auth = FirebaseAuth.instance;
    final email = widget.email.trim().toLowerCase();

    if (auth.currentUser != null &&
        auth.currentUser!.email?.toLowerCase() == email) {
      return auth.currentUser;
    }

    try {
      final cred = await auth.createUserWithEmailAndPassword(
        email: email,
        password: _tempPassword,
      );
      return cred.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        try {
          final cred = await auth.signInWithEmailAndPassword(
            email: email,
            password: _tempPassword,
          );
          return cred.user;
        } on FirebaseAuthException {
          _showSweet(
            type: DialogType.error,
            title: "Email Already Registered",
            desc: "This email is already registered. Please login instead.",
          );
          return null;
        }
      }

      _showSweet(
        type: DialogType.error,
        title: "Error",
        desc: e.message ?? "Unable to create verification user.",
      );
      return null;
    } catch (e) {
      _showSweet(
        type: DialogType.error,
        title: "Error",
        desc: e.toString(),
      );
      return null;
    }
  }

  Future<void> _savePendingByUid({
    required String uid,
    required int step,
    required String status,
  }) async {
    await FirebaseFirestore.instance.collection('pending_signups').doc(uid).set({
      "uid": uid,
      "email": widget.email.trim().toLowerCase(),
      "role": widget.role,
      "step": step,
      "status": status,
      "updatedAt": FieldValue.serverTimestamp(),
      "createdAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _sendVerificationEmail() async {
    await _runWithLoading(() async {
      final user = await _ensureTempAuthUser();
      if (user == null) return;

      await user.sendEmailVerification();

      await _savePendingByUid(
        uid: user.uid,
        step: 2,
        status: "verification_sent",
      );

      _showSweet(
        type: DialogType.success,
        title: "Verification Email Sent",
        desc: "Please check your inbox and verify your email.",
      );
    });
  }

  Future<void> _resendEmail() async {
    await _runWithLoading(() async {
      final user = await _ensureTempAuthUser();
      if (user == null) return;

      await user.sendEmailVerification();

      await _savePendingByUid(
        uid: user.uid,
        step: 2,
        status: "verification_resent",
      );

      _showSweet(
        type: DialogType.success,
        title: "Verification Email Resent",
        desc: "Please check your inbox again.",
      );
    });
  }

  Future<void> _checkEmailVerifiedAndContinue() async {
    await _runWithLoading(() async {
      final user = await _ensureTempAuthUser();
      if (user == null) return;

      await user.reload();
      final refreshed = FirebaseAuth.instance.currentUser;

      if (refreshed != null && refreshed.emailVerified) {
        await _savePendingByUid(
          uid: refreshed.uid,
          step: 3,
          status: "email_verified",
        );

        if (!mounted) return;

        _showSweet(
          type: DialogType.success,
          title: "Email Verified",
          desc: "Your email has been verified successfully.",
          onOk: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => Signup3(
                  email: widget.email.trim().toLowerCase(),
                  uid: refreshed.uid,
                  role: widget.role,
                ),
              ),
            );
          },
        );
      } else {
        _showSweet(
          type: DialogType.warning,
          title: "Email Not Verified",
          desc: "Please open your email and verify it first.",
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendVerificationEmail();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: _signupAppBar(),
          body: AbsorbPointer(
            absorbing: _isLoading,
            child: SingleChildScrollView(
              child: Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  children: [
                    _backButton(),
                    const SizedBox(height: 15),

                    Image.asset(
                      "assets/images/emailletter2.png",
                      width: 349,
                      height: 300,
                    ),

                    Text(
                      "CHECK YOUR EMAIL",
                      style: GoogleFonts.poppins(
                        fontSize: 23,
                        fontWeight: FontWeight.w700,
                        color: kPink,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      widget.role == "doctor"
                          ? "Doctor Account Verification"
                          : "Patient Account Verification",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: kBlue,
                      ),
                    ),

                    const SizedBox(height: 15),

                    Text(
                      "Follow the link in the email we sent to ${widget.email}. The email can take up to 1 minute to arrive.",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 165),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _checkEmailVerifiedAndContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kBlue,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          "Next",
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
                        onPressed: _resendEmail,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPink,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          "Resend email",
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
        ),
        if (_isLoading) _loadingOverlay(),
      ],
    );
  }
}