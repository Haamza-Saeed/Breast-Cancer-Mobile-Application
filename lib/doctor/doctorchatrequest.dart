import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:project/doctor/doctorrootpage.dart';
import 'package:project/l10n/app_localizations.dart';
import 'package:project/doctor/patientprofile.dart';

class DoctorChatRequest extends StatefulWidget {
  const DoctorChatRequest({super.key});

  @override
  State<DoctorChatRequest> createState() => _DoctorChatRequestState();
}

class _DoctorChatRequestState extends State<DoctorChatRequest> {
  static const Color blue = Color(0xff00AEEF);

  String? doctorUid;

  @override
  void initState() {
    super.initState();
    doctorUid = FirebaseAuth.instance.currentUser?.uid;

    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted) return;
      setState(() => doctorUid = user?.uid);
    });
  }

  // ---------------- UI helpers ----------------

  void _confirmAction({
    required String title,
    required String desc,
    required String okText,
    required String cancelText,
    required VoidCallback onYes,
  }) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.question,
      animType: AnimType.scale,
      title: title,
      desc: desc,
      btnCancelText: cancelText,
      btnOkText: okText,
      btnCancelOnPress: () {},
      btnOkOnPress: onYes,
    ).show();
  }

  // ---------------- notifications ----------------

  Future<void> _addDoctorNotification({
    required String doctorId,
    required String message,
    required String patientId,
    required String requestId,
    required String status,
  }) async {
    await FirebaseFirestore.instance
        .collection("users")
        .doc(doctorId)
        .collection("notifications")
        .add({
      "message": message,
      "isRead": false,
      "createdAt": FieldValue.serverTimestamp(),
      "type": "chat_request",
      "patientId": patientId,
      "requestId": requestId,
      "status": status,
    });
  }

  Future<void> _addPatientNotification({
    required String patientId,
    required String message,
    required String doctorId,
    required String requestId,
    required String status,
  }) async {
    await FirebaseFirestore.instance
        .collection("users")
        .doc(patientId)
        .collection("notifications")
        .add({
      "message": message,
      "isRead": false,
      "createdAt": FieldValue.serverTimestamp(),
      "type": "chat_request",
      "doctorId": doctorId,
      "requestId": requestId,
      "status": status,
    });
  }

  // ---------------- data helpers ----------------

  String _fullDoctorName(Map<String, dynamic> d) {
    final fn = (d["firstName"] ?? "").toString().trim();
    final ln = (d["lastName"] ?? "").toString().trim();
    final name = ("$fn $ln").trim();
    if (name.isNotEmpty) return name;
    final n2 = (d["name"] ?? "").toString().trim();
    return n2.isNotEmpty ? n2 : "Doctor";
  }

  /// ✅ Deterministic chatId => ONLY ONE chat doc per doctor+patient
  DocumentReference<Map<String, dynamic>> _chatRef({
    required String doctorId,
    required String patientId,
  }) {
    final chatId = "${doctorId}_$patientId";
    return FirebaseFirestore.instance.collection("chats").doc(chatId);
  }

  // ---------------- main approve/reject ----------------

  Future<void> _updateStatus({
    required String requestId,
    required String status, // approved / rejected
    required String patientName,
    required String patientId,
    required String patientEmail,
  }) async {
    final t = AppLocalizations.of(context);
    final did = doctorUid;
    if (did == null || did.isEmpty) return;

    try {
      // ✅ Doctor details
      final doctorSnap =
      await FirebaseFirestore.instance.collection("users").doc(did).get();
      final doctorData = doctorSnap.data() ?? {};
      final doctorName = _fullDoctorName(doctorData);
      final doctorEmail = (doctorData["email"] ?? "").toString().trim();

      // ✅ Deterministic chat doc reference
      final chatRef = _chatRef(doctorId: did, patientId: patientId);

      final batch = FirebaseFirestore.instance.batch();

      // ✅ Update request
      final reqRef =
      FirebaseFirestore.instance.collection('chatRequests').doc(requestId);

      batch.update(reqRef, {
        "status": status,
        "updatedAt": FieldValue.serverTimestamp(),
      });

      // ✅ Update/Create chat doc based on status
      if (status == "approved") {
        batch.set(
          chatRef,
          <String, dynamic>{
            "chatId": chatRef.id,
            "doctorId": did,
            "doctorName": doctorName,
            "doctorEmail": doctorEmail,
            "patientId": patientId,
            "patientName": patientName,
            "patientEmail": patientEmail,
            "isActive": true, // ✅ IMPORTANT for Admin to see it
            "updatedAt": FieldValue.serverTimestamp(),

            // set only when first time doc is created (merge keeps existing)
            "createdAt": FieldValue.serverTimestamp(),
            "lastMessage": "",
          },
          SetOptions(merge: true),
        );
      } else if (status == "rejected") {
        // ✅ Mark chat inactive (if exists / or will exist)
        batch.set(
          chatRef,
          {
            "isActive": false,
            "updatedAt": FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      await batch.commit();

      // ✅ Notifications
      final doctorMsg = status == "approved"
          ? "You approved chat request from $patientName."
          : "You rejected chat request from $patientName.";

      final patientMsg = status == "approved"
          ? "Your chat request has been approved. You can now chat with the doctor."
          : "Your chat request has been rejected by the doctor.";

      await _addDoctorNotification(
        doctorId: did,
        message: doctorMsg,
        patientId: patientId,
        requestId: requestId,
        status: status,
      );

      await _addPatientNotification(
        patientId: patientId,
        message: patientMsg,
        doctorId: did,
        requestId: requestId,
        status: status,
      );

      if (!mounted) return;

      AwesomeDialog(
        context: context,
        dialogType: DialogType.success,
        animType: AnimType.scale,
        title: t?.done ?? "Done",
        desc: status == "approved"
            ? (t?.requestApprovedSuccessfully ?? "Request approved successfully!")
            : (t?.requestRejectedSuccessfully ?? "Request rejected successfully!"),
        btnOkText: t?.ok ?? "OK",
        btnOkOnPress: () {},
      ).show();
    } catch (e) {
      if (!mounted) return;

      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        animType: AnimType.scale,
        title: t?.errorTitle ?? "Error",
        desc:
        "${t?.failedToUpdateRequest ?? "Failed to update request. Try again."}\n$e",
        btnOkText: t?.ok ?? "OK",
        btnOkOnPress: () {},
      ).show();
    }
  }

  // ---------------- UI ----------------

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
                    icon: Icon(Icons.arrow_back_ios_new, color: blue, size: 18),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const DoctorRootPage()),
                      );
                    },
                  ),
                ),
              ),
              Image.asset(
                "assets/images/chatrequestdoctor.png",
                width: 373,
                height: 249,
              ),
              const SizedBox(height: 10),
              Text(
                t?.chatRequestsTitle ?? "Chat Requests",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 27,
                  color: blue,
                ),
              ),
              const SizedBox(height: 20),

              if (doctorUid == null)
                Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: Text(
                    t?.doctorNotLoggedInBang ?? "Doctor not logged in!",
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
                      .where('status', isEqualTo: 'pending')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 30),
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (snapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Text(
                          "${t?.queryErrorPrefix ?? "Query error:"} ${snapshot.error}",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: Colors.red,
                          ),
                        ),
                      );
                    }

                    final docs = (snapshot.data?.docs ?? []).toList();

                    // local sort by createdAt (newest first)
                    docs.sort((a, b) {
                      final aTime = (a.data()['createdAt'] as Timestamp?)
                          ?.millisecondsSinceEpoch ??
                          0;
                      final bTime = (b.data()['createdAt'] as Timestamp?)
                          ?.millisecondsSinceEpoch ??
                          0;
                      return bTime.compareTo(aTime);
                    });

                    if (docs.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 60),
                        child: Text(
                          t?.noRequestYet ?? "No request yet!",
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
                        final doc = docs[index];
                        final data = doc.data();

                        final patientName =
                        (data['patientName'] ?? (t?.patient ?? "Patient"))
                            .toString();
                        final patientEmail =
                        (data['patientEmail'] ?? '').toString();
                        final patientId =
                        (data['patientId'] ?? '').toString().trim();

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
                                patientName,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: blue,
                                ),
                              ),
                              const SizedBox(height: 6),
                              if (patientEmail.isNotEmpty)
                                Text(
                                  patientEmail,
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
                                    onPressed: patientId.isEmpty
                                        ? null
                                        : () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              PatientProfileView(
                                                  patientId: patientId),
                                        ),
                                      );
                                    },
                                    icon: Icon(Icons.person,
                                        size: 18, color: blue),
                                    label: Text(
                                      t?.viewProfile ?? "View Profile",
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                        color: blue,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                          color: blue, width: 2),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 10),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  // Approve
                                  IconButton(
                                    icon: Icon(
                                      Icons.check_circle,
                                      color: Colors.green.shade600,
                                      size: 30,
                                    ),
                                    onPressed: () {
                                      _confirmAction(
                                        title: t?.approveRequestTitle ??
                                            "Approve Request",
                                        desc: t?.approveRequestDesc(patientName) ??
                                            "Are you sure you want to approve $patientName?",
                                        okText: t?.yes ?? "Yes",
                                        cancelText: t?.no ?? "No",
                                        onYes: () {
                                          _updateStatus(
                                            requestId: doc.id,
                                            status: "approved",
                                            patientName: patientName,
                                            patientId: patientId,
                                            patientEmail: patientEmail,
                                          );
                                        },
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 10),

                                  // Reject
                                  IconButton(
                                    icon: Icon(
                                      Icons.cancel,
                                      color: Colors.red.shade600,
                                      size: 30,
                                    ),
                                    onPressed: () {
                                      _confirmAction(
                                        title: t?.rejectRequestTitle ??
                                            "Reject Request",
                                        desc: t?.rejectRequestDesc(patientName) ??
                                            "Are you sure you want to reject $patientName?",
                                        okText: t?.yes ?? "Yes",
                                        cancelText: t?.no ?? "No",
                                        onYes: () {
                                          _updateStatus(
                                            requestId: doc.id,
                                            status: "rejected",
                                            patientName: patientName,
                                            patientId: patientId,
                                            patientEmail: patientEmail,
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
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