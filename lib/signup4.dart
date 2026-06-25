import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project/signup3.dart';
import 'package:project/signup5.dart';


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

void showSnack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}


class Signup4 extends StatefulWidget {
  final String uid;
  final String email;
  final String role;
  const Signup4({super.key, required this.uid, required this.email, required this.role});

  @override
  State<Signup4> createState() => _Signup4State();
}

class _Signup4State extends State<Signup4> {
  final TextEditingController ageController = TextEditingController();
  bool _isLoading = false;

  Future<void> _runWithLoading(Future<void> Function() action) async {
    if (_isLoading) return; setState(() => _isLoading = true);
    try { await action(); } finally { if (mounted) setState(() => _isLoading = false); }
  }

  Future<void> _onNextPressed() async {
    final ageText = ageController.text.trim();
    if (ageText.isEmpty) return showSnack(context, "Age cannot be empty");
    final age = int.tryParse(ageText);
    if (age == null) return showSnack(context, "Age must be a valid number");
    if (age < 15 || age > 100) return showSnack(context, "Please enter a valid age (15 - 100)");

    await _runWithLoading(() async {
      await FirebaseFirestore.instance.collection("pending_signups").doc(widget.uid).set({
        "uid": widget.uid,
        "email": widget.email,
        "role": widget.role,
        "age": age,
        "step": 4,
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => Signup5(uid: widget.uid, email: widget.email, role: widget.role)));
    });
  }

  Future<void> _onBackPressed() async {
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => Signup3(uid: widget.uid, email: widget.email, role: widget.role)));
  }

  @override
  void dispose() { ageController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Scaffold(appBar: signupAppBar(), body: SingleChildScrollView(child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(children: [
          Image.asset("assets/images/yoga.png", width: 349, height: 300),
          Text("Enter your age", style: GoogleFonts.poppins(fontSize: 23, fontWeight: FontWeight.w700, color: kPink)),
          Align(alignment: Alignment.centerLeft, child: Text("Your Age", style: GoogleFonts.poppins(color: kBlue, fontWeight: FontWeight.w700, fontSize: 18))),
          TextField(controller: ageController, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)], decoration: signupInputDecoration()),
          const SizedBox(height: 130),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _onNextPressed, style: ElevatedButton.styleFrom(backgroundColor: kBlue, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))), child: Text("Next", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)))),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _onBackPressed, style: ElevatedButton.styleFrom(backgroundColor: kPink, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))), child: Text("Back", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)))),
        ]),
      ))),
      loadingOverlay(_isLoading),
    ]);
  }
}
