import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project/signup6.dart';
import 'package:project/signup11.dart';


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


class Signup10 extends StatefulWidget {
  final String uid;
  final String email;
  final String role;
  const Signup10({super.key, required this.uid, required this.email, required this.role});

  @override
  State<Signup10> createState() => _Signup10State();
}

class _Signup10State extends State<Signup10> {
  final TextEditingController experienceController = TextEditingController();
  bool _isLoading = false;

  Future<void> _runWithLoading(Future<void> Function() action) async { if (_isLoading) return; setState(() => _isLoading = true); try { await action(); } finally { if (mounted) setState(() => _isLoading = false); } }

  Future<void> _next() async {
    final exp = int.tryParse(experienceController.text.trim());
    if (exp == null) return showSnack(context, "Experience must be numeric.");
    if (exp < 0 || exp > 70) return showSnack(context, "Please enter valid experience years.");
    await _runWithLoading(() async {
      await FirebaseFirestore.instance.collection("pending_signups").doc(widget.uid).set({
        "experienceYears": exp,
        "step": 10,
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => Signup11(uid: widget.uid, email: widget.email, role: widget.role)));
    });
  }

  void _back() => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => Signup6(uid: widget.uid, email: widget.email, role: widget.role)));

  @override
  void dispose() { experienceController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Scaffold(appBar: signupAppBar(), body: SingleChildScrollView(child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(children: [
          Image.asset("assets/images/doctor.png", width: 349, height: 300),
          Text("Doctor Experience", style: GoogleFonts.poppins(fontSize: 23, fontWeight: FontWeight.w700, color: kPink)),
          const SizedBox(height: 15),
          Align(alignment: Alignment.centerLeft, child: Text("Experience (Years)", style: GoogleFonts.poppins(color: kBlue, fontWeight: FontWeight.w700, fontSize: 18))),
          TextField(controller: experienceController, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)], decoration: signupInputDecoration(hint: "Example: 5")),
          const SizedBox(height: 140),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _next, style: ElevatedButton.styleFrom(backgroundColor: kBlue, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))), child: Text("Next", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)))),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _back, style: ElevatedButton.styleFrom(backgroundColor: kPink, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))), child: Text("Back", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)))),
        ]),
      ))),
      loadingOverlay(_isLoading),
    ]);
  }
}
