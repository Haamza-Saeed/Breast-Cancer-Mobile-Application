import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project/signup6.dart';
import 'package:project/signup8.dart';


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


class Signup7 extends StatefulWidget {
  final String uid;
  final String email;
  final String role;
  const Signup7({super.key, required this.uid, required this.email, required this.role});

  @override
  State<Signup7> createState() => _Signup7State();
}

class _Signup7State extends State<Signup7> {
  bool _isLoading = false;
  String maritalStatus = "Single";
  final statuses = const ["Single", "Married"];

  Future<void> _runWithLoading(Future<void> Function() action) async {
    if (_isLoading) return; setState(() => _isLoading = true);
    try { await action(); } finally { if (mounted) setState(() => _isLoading = false); }
  }

  Future<void> _next() async {
    await _runWithLoading(() async {
      await FirebaseFirestore.instance.collection("pending_signups").doc(widget.uid).set({
        "maritalStatus": maritalStatus,
        "step": 7,
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => Signup8(uid: widget.uid, email: widget.email, role: widget.role)));
    });
  }

  void _back() => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => Signup6(uid: widget.uid, email: widget.email, role: widget.role)));

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Scaffold(appBar: signupAppBar(), body: SingleChildScrollView(child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Image.asset("assets/images/handsribbion.png", width: 349, height: 300),
          Text("Marital Status", style: GoogleFonts.poppins(fontSize: 23, fontWeight: FontWeight.w700, color: kPink)),
          const SizedBox(height: 20),
          Text("Select your marital status", style: GoogleFonts.poppins(color: kBlue, fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(value: maritalStatus, decoration: signupInputDecoration(), items: statuses.map((s) => DropdownMenuItem(value: s, child: Text(s, style: GoogleFonts.poppins(color: Colors.blue)))).toList(), onChanged: (v) => setState(() => maritalStatus = v ?? "Single")),
          const SizedBox(height: 180),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _next, style: ElevatedButton.styleFrom(backgroundColor: kBlue, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))), child: Text("Next", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)))),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _back, style: ElevatedButton.styleFrom(backgroundColor: kPink, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))), child: Text("Back", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)))),
        ]),
      ))),
      loadingOverlay(_isLoading),
    ]);
  }
}
