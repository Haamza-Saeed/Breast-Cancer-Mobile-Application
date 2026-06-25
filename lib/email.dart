import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project/signup2.dart';

class Email extends StatefulWidget {
  final String role;
  final String? prefilledEmail;

  const Email({
    super.key,
    required this.role,
    this.prefilledEmail,
  });

  @override
  State<Email> createState() => _EmailState();
}

class _EmailState extends State<Email> {
  final TextEditingController emailController = TextEditingController();

  bool _isLoading = false;

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Future<void> _runWithLoading(Future<void> Function() action) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      await action();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();

    if (widget.prefilledEmail != null &&
        widget.prefilledEmail!.trim().isNotEmpty) {
      emailController.text = widget.prefilledEmail!.trim();
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    final e = email.trim();

    if (!e.contains("@")) return false;
    if (!e.contains(".")) return false;
    if (e.startsWith("@") || e.endsWith("@")) return false;

    return true;
  }

  Future<void> _onNextPressed() async {
    final email = emailController.text.trim().toLowerCase();

    if (email.isEmpty) {
      _showSnack("Email cannot be empty");
      return;
    }

    if (!_isValidEmail(email)) {
      _showSnack("Please enter a valid email address.");
      return;
    }

    await _runWithLoading(() async {
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Signup2(
            email: email,
            role: widget.role,
          ),
        ),
      );
    });
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
          appBar: AppBar(
            automaticallyImplyLeading: false,
            elevation: 0,
            titleSpacing: 0,
            leading: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Image.asset(
                "assets/images/ribon.png",
                width: 24,
              ),
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
                            Icons.arrow_back_ios_new,
                            color: Color(0xffFF67CE),
                            size: 18,
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Image.asset(
                      "assets/images/twohands.png",
                      width: 349,
                      height: 300,
                    ),

                    const SizedBox(height: 15),

                    Text(
                      "Enter your email address",
                      style: GoogleFonts.poppins(
                        fontSize: 23,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xffFF67CE),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      widget.role == "doctor"
                          ? "Creating Doctor Account"
                          : "Creating Patient Account",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xff00AEEF),
                      ),
                    ),

                    const SizedBox(height: 15),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Your Email",
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
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                          const BorderSide(color: Colors.blue, width: 2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                          const BorderSide(color: Colors.blue, width: 2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Colors.blueAccent,
                            width: 2,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 110),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w400,
                            fontSize: 11,
                            color: Colors.black,
                          ),
                          children: [
                            const TextSpan(
                              text: "By signing up you agree to our ",
                            ),
                            TextSpan(
                              text: "Terms of Use ",
                              style: GoogleFonts.poppins(
                                color: const Color(0xff00AEEF),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const TextSpan(text: "and "),
                            TextSpan(
                              text: "Privacy Policy",
                              style: GoogleFonts.poppins(
                                color: const Color(0xff00AEEF),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _onNextPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff00AEEF),
                          padding: const EdgeInsets.symmetric(vertical: 14),
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

        if (_isLoading) _loadingOverlay(),
      ],
    );
  }
}