import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project/patient/rootpage.dart';
import 'package:project/l10n/app_localizations.dart'; // ✅ add this

class AboutUs extends StatelessWidget {
  const AboutUs({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!; // ✅ add this

    return Scaffold(
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
              t.appTitle, // ✅ translated
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => RootPage()),
                      );
                    },
                  ),
                ),
              ),
              Image.asset(
                "assets/images/longribbion.png",
                width: 373,
                height: 249,
              ),
              Text(
                t.aboutUs, // ✅ translated
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 27,
                  color: const Color(0xffFF67CE),
                ),
              ),
              const SizedBox(height: 15),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.ourMission, // ✅ translated
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xffFF67CE),
                          ),
                        ),
                        Text(
                          t.ourMissionDesc, // ✅ translated
                          maxLines: 10,
                          softWrap: true,
                          overflow: TextOverflow.visible,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xffFF67CE),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Image.asset(
                    "assets/images/threewomen.png",
                    width: 130,
                    height: 130,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset(
                    "assets/images/onewomen.png",
                    width: 130,
                    height: 130,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.whatWeDo, // ✅ translated
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xffFF67CE),
                          ),
                        ),
                        Text(
                          t.whatWeDoDesc, // ✅ translated
                          maxLines: 10,
                          softWrap: true,
                          overflow: TextOverflow.visible,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xffFF67CE),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
