import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:project/doctor/doctorrootpage.dart';
import 'package:project/doctor/chatwithpatients.dart';
import 'package:project/doctor/patientprofile.dart'; // ✅ contains PatientProfileView
import 'package:project/l10n/app_localizations.dart';

class ChatRoom extends StatelessWidget {
  const ChatRoom({super.key});

  static const Color blue = Color(0xff00AEEF);

  String _fullName(Map<String, dynamic> d, AppLocalizations? t) {
    final fn = (d['firstName'] ?? '').toString().trim();
    final ln = (d['lastName'] ?? '').toString().trim();
    final name = "$fn $ln".trim();
    return name.isEmpty ? (t?.patientFallbackName ?? "Patient") : name;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final doctorUid = FirebaseAuth.instance.currentUser?.uid;

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
              t?.appTitle ?? "AI-Based Breast Cancer Detection App",
              maxLines: 1,
              overflow: TextOverflow.visible,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: blue,
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
                    border: Border.all(color: blue, width: 2),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: blue, size: 18),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const DoctorRootPage()),
                      );
                    },
                  ),
                ),
              ),
              Image.asset("assets/images/chatroom.png", width: 373, height: 249),
              const SizedBox(height: 10),
              Text(
                t?.chatRoomTitle ?? "Chat Room",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 27,
                  color: blue,
                ),
              ),
              const SizedBox(height: 18),

              if (doctorUid == null)
                Padding(
                  padding: const EdgeInsets.only(top: 50),
                  child: Text(
                    t?.doctorNotLoggedIn ?? "Doctor not logged in!",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: blue,
                    ),
                  ),
                )
              else
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('chatRequests')
                      .where('doctorId', isEqualTo: doctorUid)
                      .where('status', isEqualTo: 'approved')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 30),
                        child: Text(
                          "${t?.errorTitle ?? "Error"}: ${snapshot.error}",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: Colors.red,
                          ),
                        ),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 30),
                        child: CircularProgressIndicator(),
                      );
                    }

                    final docs = snapshot.data?.docs ?? [];

                    if (docs.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 60),
                        child: Text(
                          t?.noChatYet ?? "No chat yet!",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: blue,
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final req = docs[index].data();

                        // ✅ patientId must exist to open profile
                        final patientId = (req['patientId'] ?? '').toString().trim();

                        // fallback values from chatRequests
                        final fallbackName =
                        (req['patientName'] ?? (t?.patientFallbackName ?? 'Patient')).toString();
                        final fallbackEmail = (req['patientEmail'] ?? '').toString().trim();

                        if (patientId.isEmpty) {
                          // show View Profile disabled
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: blue, width: 2),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fallbackName,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: blue,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                if (fallbackEmail.isNotEmpty)
                                  Text(
                                    fallbackEmail,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                      color: Colors.black54,
                                    ),
                                  ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: null, // disabled
                                      icon: const Icon(Icons.person, size: 18, color: blue),
                                      label: Text(
                                        t?.viewProfile ?? "View Profile",
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                          color: blue,
                                        ),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(color: blue, width: 2),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(30),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    ElevatedButton.icon(
                                      onPressed: null, // ✅ disable chat if no patientId
                                      icon: const Icon(Icons.chat, size: 18),
                                      label: Text(
                                        t?.chatNow ?? "Chat Now",
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.grey,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(30),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }

                        // ✅ fetch patient doc from users
                        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                          stream: FirebaseFirestore.instance.collection('users').doc(patientId).snapshots(),
                          builder: (context, patientSnap) {
                            if (patientSnap.connectionState == ConnectionState.waiting) {
                              return Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: blue, width: 2),
                                ),
                                child: const Center(
                                  child: SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                              );
                            }

                            final p = patientSnap.data?.data();

                            final patientName = p == null ? fallbackName : _fullName(p, t);
                            final patientEmail =
                            p == null ? fallbackEmail : (p['email'] ?? '').toString().trim();
                            final img =
                            p == null ? '' : (p['profileImagePath'] ?? '').toString().trim();

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: blue, width: 2),
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
                                            : const AssetImage("assets/images/profileblue.png")
                                        as ImageProvider,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              patientName,
                                              style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 16,
                                                color: blue,
                                              ),
                                            ),
                                            if (patientEmail.isNotEmpty)
                                              Text(
                                                patientEmail,
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
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => PatientProfileView(patientId: patientId),
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.person, size: 18, color: blue),
                                        label: Text(
                                          t?.viewProfile ?? "View Profile",
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                            color: blue,
                                          ),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(color: blue, width: 2),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(30),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => ChatWithPatients(
                                                patientId: patientId,
                                                patientName: patientName,
                                                patientEmail: patientEmail,
                                              ),
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.chat, size: 18),
                                        label: Text(
                                          t?.chatNow ?? "Chat Now",
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: blue,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(30),
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
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}