import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project/l10n/app_localizations.dart';
import 'package:project/patient/chatwithdoctor.dart';
import 'package:project/patient/rootpage.dart';
import 'package:project/patient/doctorprofile.dart'; // ✅ ADD this import (adjust path if different)

class ChataRequest extends StatelessWidget {
  const ChataRequest({super.key});

  static const Color pink = Color(0xffFF67CE);

  String _fullName(Map<String, dynamic> d, AppLocalizations t) {
    final fn = (d['firstName'] ?? '').toString().trim();
    final ln = (d['lastName'] ?? '').toString().trim();
    final name = "$fn $ln".trim();
    return name.isEmpty ? (t.doctor) : name; // ✅ localized fallback
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
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
              t.appTitle,
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
                    border: Border.all(color: pink, width: 2),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: pink,
                      size: 18,
                    ),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const RootPage()),
                      );
                    },
                  ),
                ),
              ),
              Image.asset(
                "assets/images/announcments.png",
                width: 373,
                height: 249,
              ),
              const SizedBox(height: 10),
              Text(
                t.requestChat,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 27,
                  color: pink,
                ),
              ),
              const SizedBox(height: 18),

              if (user == null)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Text(
                    t.pleaseLoginFirst, // ✅ localized
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: pink,
                    ),
                  ),
                )
              else
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('chatRequests')
                      .where('patientId', isEqualTo: user.uid)
                      .where('status', isEqualTo: 'approved')
                  // ✅ REMOVED orderBy to avoid index requirement
                      .snapshots(),
                  builder: (context, reqSnap) {
                    if (reqSnap.hasError) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 30),
                        child: Text(
                          "${t.errorTitle}: ${reqSnap.error}", // ✅ localized label
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: Colors.red,
                          ),
                        ),
                      );
                    }

                    if (reqSnap.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 30),
                        child: CircularProgressIndicator(),
                      );
                    }

                    final requests = reqSnap.data?.docs ?? [];
                    if (requests.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 60),
                        child: Text(
                          t.noDoctorsAvailable,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: pink,
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: requests.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final r = requests[index].data();
                        final doctorId = (r['doctorId'] ?? '').toString().trim();

                        if (doctorId.isEmpty) return const SizedBox.shrink();

                        return StreamBuilder<
                            DocumentSnapshot<Map<String, dynamic>>>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(doctorId)
                              .snapshots(),
                          builder: (context, docSnap) {
                            if (docSnap.connectionState ==
                                ConnectionState.waiting) {
                              return Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: pink, width: 2),
                                ),
                                child: const Center(
                                  child: SizedBox(
                                    height: 18,
                                    width: 18,
                                    child:
                                    CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                              );
                            }

                            final d = docSnap.data?.data();
                            final name = d == null ? t.doctor : _fullName(d, t);
                            final email = d == null
                                ? ""
                                : (d['email'] ?? '').toString().trim();
                            final img = d == null
                                ? ""
                                : (d['profileImagePath'] ?? '')
                                .toString()
                                .trim();

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: pink, width: 2),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 26,
                                        backgroundImage: img.isNotEmpty
                                            ? NetworkImage(img)
                                            : const AssetImage(
                                          "assets/images/profilepink.png",
                                        ) as ImageProvider,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name,
                                              style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 16,
                                                color: pink,
                                              ),
                                            ),
                                            if (email.isNotEmpty)
                                              Text(
                                                email,
                                                style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 13,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // ✅ Buttons row: View Profile + Chat Now
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => DoctorProfile(
                                                doctorId: doctorId,
                                              ),
                                            ),
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.person,
                                          size: 18,
                                          color: pink,
                                        ),
                                        label: Text(
                                          // If you have localization key use it, otherwise fallback:
                                          t.viewProfile ?? "View Profile",
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                            color: pink,
                                          ),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(
                                              color: pink, width: 2),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 10),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                            BorderRadius.circular(30),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => const ChatWithDoctor(),
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.chat, size: 18),
                                        label: Text(
                                          t.chatNow, // ✅ localized
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: pink,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 10),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                            BorderRadius.circular(30),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}