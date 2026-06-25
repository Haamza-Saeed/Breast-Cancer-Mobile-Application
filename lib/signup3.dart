import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project/signup4.dart';

const Color kPink = Color(0xffFF67CE);
const Color kBlue = Color(0xff00AEEF);
const String kSignupBucket = "signup-documents";

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
      color: Colors.black.withOpacity(0.35),
      child: Center(
        child: Image.asset("assets/images/loading.gif", width: 90, height: 90),
      ),
    ),
  );
}

class Signup3 extends StatefulWidget {
  final String email;
  final String uid;
  final String role;

  const Signup3({
    super.key,
    required this.email,
    required this.uid,
    required this.role,
  });

  @override
  State<Signup3> createState() => _Signup3State();
}

class _Signup3State extends State<Signup3> {
  final TextEditingController firstController = TextEditingController();
  final TextEditingController lastController = TextEditingController();

  bool _isLoading = false;

  final RegExp _nameRegex = RegExp(r'^[a-zA-Z ]+$');

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

  Future<void> _runWithLoading(Future<void> Function() action) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      await action();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onNextPressed() async {
    final firstName = firstController.text.trim();
    final lastName = lastController.text.trim();

    if (firstName.isEmpty) {
      _showSweet(
        type: DialogType.warning,
        title: "Missing First Name",
        desc: "First name cannot be empty.",
      );
      return;
    }

    if (lastName.isEmpty) {
      _showSweet(
        type: DialogType.warning,
        title: "Missing Last Name",
        desc: "Last name cannot be empty.",
      );
      return;
    }

    if (!_nameRegex.hasMatch(firstName)) {
      _showSweet(
        type: DialogType.warning,
        title: "Invalid First Name",
        desc: "First name can only contain alphabets.",
      );
      return;
    }

    if (!_nameRegex.hasMatch(lastName)) {
      _showSweet(
        type: DialogType.warning,
        title: "Invalid Last Name",
        desc: "Last name can only contain alphabets.",
      );
      return;
    }

    await _runWithLoading(() async {
      try {
        await FirebaseFirestore.instance
            .collection("pending_signups")
            .doc(widget.uid)
            .set({
          "uid": widget.uid,
          "email": widget.email,
          "role": widget.role,
          "firstName": firstName,
          "lastName": lastName,
          "step": 3,
          "updatedAt": FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        if (!mounted) return;

        _showSweet(
          type: DialogType.success,
          title: "Saved Successfully",
          desc: "Your name has been saved successfully.",
          onOk: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => Signup4(
                  uid: widget.uid,
                  email: widget.email,
                  role: widget.role,
                ),
              ),
            );
          },
        );
      } catch (e) {
        if (!mounted) return;

        _showSweet(
          type: DialogType.error,
          title: "Error",
          desc: "Failed to save your name: $e",
        );
      }
    });
  }

  @override
  void dispose() {
    firstController.dispose();
    lastController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: signupAppBar(),
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
                      "assets/images/women2.png",
                      width: 349,
                      height: 300,
                    ),

                    Text(
                      "Enter your name",
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
                        "First Name",
                        style: GoogleFonts.poppins(
                          color: kBlue,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ),

                    TextField(
                      controller: firstController,
                      keyboardType: TextInputType.name,
                      textCapitalization: TextCapitalization.words,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z ]")),
                        LengthLimitingTextInputFormatter(30),
                      ],
                      decoration: signupInputDecoration(),
                    ),

                    const SizedBox(height: 15),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Last Name",
                        style: GoogleFonts.poppins(
                          color: kBlue,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ),

                    TextField(
                      controller: lastController,
                      keyboardType: TextInputType.name,
                      textCapitalization: TextCapitalization.words,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z ]")),
                        LengthLimitingTextInputFormatter(30),
                      ],
                      decoration: signupInputDecoration(),
                    ),

                    const SizedBox(height: 80),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _onNextPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kBlue,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          "Next",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
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
        loadingOverlay(_isLoading),
      ],
    );
  }
}