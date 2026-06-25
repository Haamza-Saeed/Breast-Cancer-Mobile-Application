import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project/admin/adminrootpage.dart';
import 'package:project/admin/adminfeedback_detail.dart';

// ✅ Localization
import 'package:project/l10n/app_localizations.dart';

class AdminFeedback extends StatelessWidget {
  const AdminFeedback({super.key});

  static const Color green = Color(0xff00EFAB);

  String _fullName(Map<String, dynamic> data) {
    final first = (data["firstName"] ?? "").toString().trim();
    final last = (data["lastName"] ?? "").toString().trim();
    final name = (data["name"] ?? "").toString().trim();

    if (first.isNotEmpty || last.isNotEmpty) return ("$first $last").trim();
    if (name.isNotEmpty) return name;
    return "User";
  }

  String _asText(dynamic v) => (v ?? "").toString().trim();

  String _roleLabel(AppLocalizations? t, String roleRaw) {
    final r = roleRaw.toLowerCase().trim();
    if (r == "patient") return t?.patient ?? "Patient";
    if (r == "doctor") return t?.doctor ?? "Doctor";
    return t?.user ?? "User";
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

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
                color: green,
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
                    border: Border.all(color: green, width: 2),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: green, size: 18),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminRootPage()),
                      );
                    },
                  ),
                ),
              ),
              Image.asset("assets/images/feedback.png", width: 373, height: 249),
              const SizedBox(height: 10),

              Text(
                t?.adminFeedbackResponsesTitle ?? "Feedback & Responses",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 25,
                  color: green,
                ),
              ),

              const SizedBox(height: 18),

              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection("feedbacks")
                    .orderBy("createdAt", descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 50),
                      child: Text(
                        t?.failedToLoadFeedbacks ?? "Failed to load feedbacks",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          color: Colors.red,
                        ),
                      ),
                    );
                  }

                  if (!snapshot.hasData) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      child: Column(
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 10),
                          Text(t?.loading ?? "Loading...", style: GoogleFonts.poppins()),
                        ],
                      ),
                    );
                  }

                  final docs = snapshot.data!.docs;

                  if (docs.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 80),
                      child: Text(
                        t?.noFeedbackYet ?? "No feedback yet!",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: green,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final fbDoc = docs[i];
                      final data = fbDoc.data();

                      final msg = _asText(data["message"]);
                      final roleRaw = _asText(data["role"]); // patient/doctor
                      final response = _asText(data["adminResponse"]);
                      final createdBy = _asText(data["createdBy"]);

                      final isResponded = response.isNotEmpty;

                      return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                        future: createdBy.isEmpty
                            ? null
                            : FirebaseFirestore.instance.collection("users").doc(createdBy).get(),
                        builder: (context, userSnap) {
                          final uData = userSnap.data?.data() ?? {};

                          final userName = _fullName(uData);
                          final userEmail = _asText(uData["email"]);
                          final userRole = _asText(uData["role"]); // optional, if exists

                          final roleLabel = _roleLabel(t, userRole.isEmpty ? roleRaw : userRole);

                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AdminFeedbackDetail(feedbackId: fbDoc.id),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: green, width: 2),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    isResponded ? Icons.mark_email_read : Icons.mark_email_unread,
                                    color: green,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "${roleLabel.toUpperCase()} • ${isResponded ? (t?.responded ?? "Responded") : (t?.pending ?? "Pending")}",
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 12.5,
                                            color: green,
                                          ),
                                        ),
                                        const SizedBox(height: 8),

                                        Text(
                                          "${t?.name ?? "Name"}: ${userName.isEmpty ? (t?.user ?? "User") : userName}",
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12.5,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "${t?.email ?? "Email"}: ${userEmail.isEmpty ? (t?.na ?? "N/A") : userEmail}",
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 12,
                                            color: Colors.black54,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "${t?.role ?? "Role"}: ${roleLabel.isEmpty ? (t?.na ?? "N/A") : roleLabel}",
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 12,
                                            color: Colors.black54,
                                          ),
                                        ),

                                        const SizedBox(height: 10),

                                        Text(
                                          msg.isEmpty ? (t?.feedback ?? "Feedback") : msg,
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                            color: Colors.black87,
                                          ),
                                        ),

                                        const SizedBox(height: 12),

                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => AdminFeedbackDetail(
                                                    feedbackId: fbDoc.id,
                                                  ),
                                                ),
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: green,
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(30),
                                              ),
                                            ),
                                            child: Text(
                                              isResponded
                                                  ? (t?.viewResponse ?? "View Response")
                                                  : (t?.response ?? "Response"),
                                              style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
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