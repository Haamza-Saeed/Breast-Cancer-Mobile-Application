import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project/signup5.dart';
import 'package:project/signup7.dart';
import 'package:project/signup10.dart';


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


class Signup6 extends StatefulWidget {
  final String uid;
  final String email;
  final String role;
  const Signup6({super.key, required this.uid, required this.email, required this.role});

  @override
  State<Signup6> createState() => _Signup6State();
}

class _Signup6State extends State<Signup6> {
  bool _isLoading = false;
  String selectedLanguage = 'English';
  final List<String> languages = const ['English', 'Urdu'];

  Future<void> _runWithLoading(Future<void> Function() action) async {
    if (_isLoading) return; setState(() => _isLoading = true);
    try { await action(); } finally { if (mounted) setState(() => _isLoading = false); }
  }

  String _languageToCode(String lang) => lang == 'Urdu' ? 'ur' : 'en';

  Future<void> _saveLanguageAndNext() async {
    final code = _languageToCode(selectedLanguage);
    await _runWithLoading(() async {
      await FirebaseFirestore.instance.collection("pending_signups").doc(widget.uid).set({
        "uid": widget.uid,
        "email": widget.email,
        "role": widget.role,
        "language": selectedLanguage,
        "languageCode": code,
        "step": 6,
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      if (widget.role == "doctor") {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => Signup10(uid: widget.uid, email: widget.email, role: widget.role)));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => Signup7(uid: widget.uid, email: widget.email, role: widget.role)));
      }
    });
  }

  void _goBack() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => Signup5(uid: widget.uid, email: widget.email, role: widget.role)));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Scaffold(appBar: signupAppBar(), body: SingleChildScrollView(child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Image.asset("assets/images/womens.png", width: 349, height: 300),
          Text("Select your language", style: GoogleFonts.poppins(fontSize: 23, fontWeight: FontWeight.w700, color: kPink)),
          const SizedBox(height: 10),
          Text("Language", style: GoogleFonts.poppins(color: kBlue, fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: selectedLanguage,
            decoration: signupInputDecoration(),
            icon: const Icon(Icons.arrow_drop_down_circle_outlined, color: Colors.blue),
            items: languages.map((language) => DropdownMenuItem<String>(value: language, child: Text(language, style: GoogleFonts.poppins(color: Colors.blue, fontSize: 15, fontWeight: FontWeight.w500)))).toList(),
            onChanged: (v) => setState(() => selectedLanguage = v ?? "English"),
          ),
          const SizedBox(height: 130),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _saveLanguageAndNext, style: ElevatedButton.styleFrom(backgroundColor: kBlue, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))), child: Text("Next", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)))),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _goBack, style: ElevatedButton.styleFrom(backgroundColor: kPink, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))), child: Text("Back", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)))),
        ]),
      ))),
      loadingOverlay(_isLoading),
    ]);
  }
}
