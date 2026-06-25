import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project/email.dart';

class Signup1 extends StatefulWidget {
  const Signup1({super.key});

  @override
  State<Signup1> createState() => _Signup1State();
}

class _Signup1State extends State<Signup1> {
  static const Color pink = Color(0xffFF67CE);
  static const Color blue = Color(0xff00AEEF);

  String selectedRole = "patient";
  bool _isLoading = false;

  Future<void> _runWithLoading(Future<void> Function() action) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      await Future.delayed(const Duration(milliseconds: 500));
      await action();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _goToEmailPage() async {
    await _runWithLoading(() async {
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Email(role: selectedRole),
        ),
      );
    });
  }

  Widget _roleCard({
    required String role,
    required String title,
    required String subtitle,
    required String image,
  }) {
    final bool isSelected = selectedRole == role;

    return GestureDetector(
      onTap: () {
        setState(() => selectedRole = role);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? pink.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? pink : Colors.blue.shade200,
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                image,
                width: 85,
                height: 85,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? pink : blue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: role,
              groupValue: selectedRole,
              activeColor: pink,
              onChanged: (value) {
                setState(() => selectedRole = value ?? "patient");
              },
            ),
          ],
        ),
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
                    color: pink,
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
                    Image.asset(
                      "assets/images/twohands.png",
                      width: 349,
                      height: 250,
                      fit: BoxFit.contain,
                    ),

                    const SizedBox(height: 10),

                    Text(
                      "Choose Account Type",
                      style: GoogleFonts.poppins(
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                        color: pink,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      "Please select how you want to create your account.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 20-5),

                    _roleCard(
                      role: "patient",
                      title: "Patient",
                      subtitle: "Create account as a patient",
                      image: "assets/images/women2.png",
                    ),

                    _roleCard(
                      role: "doctor",
                      title: "Doctor",
                      subtitle: "Create account as a doctor",
                      image: "assets/images/doctor.png",
                    ),

                    const SizedBox(height: 45),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _goToEmailPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: blue,
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