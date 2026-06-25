import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project/login.dart';
import 'package:project/models/onboarding.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class Description extends StatefulWidget {
  const Description({super.key});

  @override
  State<Description> createState() => _DescriptionState();
}

class _DescriptionState extends State<Description> {
  final PageController controller5 = PageController();

  int currentIndex = 0;
  bool _isLoading = false;

  final List<OnBodyModel5> onboardingList5 = [
    OnBodyModel5(
      title: "About App",
      image: 'assets/images/docrib.png',
      description:
      "BreastScan AI helps women detect breast cancer early through smart, AI-powered image analysis.\n"
          "Upload microscopic tissue images or describe your symptoms — and let our intelligent models guide you toward timely awareness.",
    ),
    OnBodyModel5(
      title: "About App",
      image: 'assets/images/handrib.png',
      description:
      "All your health data, images, and chats are securely stored using Firebase and Supabase encryption.\n"
          "You decide what to share — we only analyze to help you stay safe and informed.",
    ),
    OnBodyModel5(
      title: "About App",
      image: 'assets/images/armsrib.png',
      description:
      "Chat directly with verified doctors, access personalized exercise plans, and track your progress.\n"
          "Join a caring digital community focused on early diagnosis, recovery, and confidence.",
    ),
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    controller5.dispose();
    super.dispose();
  }

  Future<void> _runWithLoading(Future<void> Function() action) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      await Future.delayed(const Duration(milliseconds: 650));
      await action();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _goToLogin() async {
    await _runWithLoading(() async {
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Login()),
      );
    });
  }

  void nextPage() {
    if (currentIndex < onboardingList5.length - 1) {
      controller5.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void prevPage() {
    if (currentIndex > 0) {
      controller5.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> onNextPressed() async {
    if (currentIndex == onboardingList5.length - 1) {
      await _goToLogin();
    } else {
      nextPage();
    }
  }

  Widget _skipButton() {
    if (currentIndex > 1) return const SizedBox(height: 40);

    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: _goToLogin,
        icon: const Icon(
          Icons.skip_next_rounded,
          color: Color(0xffFF67CE),
        ),
        label: Text(
          "Skip",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: const Color(0xffFF67CE),
            fontSize: 15,
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            elevation: 0,
            titleSpacing: 0,
            backgroundColor: Colors.white,
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  _skipButton(),

                  Expanded(
                    child: PageView.builder(
                      controller: controller5,
                      itemCount: onboardingList5.length,
                      onPageChanged: (index) {
                        setState(() => currentIndex = index);
                      },
                      itemBuilder: (context, i) {
                        final data = onboardingList5[i];

                        return SingleChildScrollView(
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.asset(
                                  data.image,
                                  width: double.infinity,
                                  height: 220,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(height: 25),
                              Text(
                                data.title,
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xffFF67CE),
                                ),
                              ),
                              const SizedBox(height: 15),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  "Description:",
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xffFF67CE),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                data.description,
                                textAlign: TextAlign.justify,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 20),
                              SmoothPageIndicator(
                                controller: controller5,
                                count: onboardingList5.length,
                                effect: const WormEffect(
                                  spacing: 55,
                                  dotHeight: 12,
                                  dotWidth: 12,
                                  dotColor: Colors.blue,
                                  activeDotColor: Color(0xffFF67CE),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 25),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (currentIndex > 0)
                        ElevatedButton(
                          onPressed: prevPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xffFF67CE),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 10,
                            ),
                          ),
                          child: Text(
                            "Back",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        )
                      else
                        const SizedBox(width: 80),

                      ElevatedButton(
                        onPressed: onNextPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 10,
                          ),
                        ),
                        child: Text(
                          currentIndex == onboardingList5.length - 1
                              ? "Get Started"
                              : "Next",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),

        if (_isLoading) _loadingOverlay(),
      ],
    );
  }
}