// lib/patient/doctorprofile.dart
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project/l10n/app_localizations.dart';

class DoctorProfile extends StatefulWidget {
  final String doctorId;
  const DoctorProfile({super.key, required this.doctorId});

  @override
  State<DoctorProfile> createState() => _DoctorProfileState();
}

class _DoctorProfileState extends State<DoctorProfile> {
  static const Color pink = Color(0xffFF67CE);

  // dropdown value
  String _connectionValue = "connected";
  bool _disconnecting = false;

  String _fullName(Map<String, dynamic> d) {
    final fn = (d['firstName'] ?? '').toString().trim();
    final ln = (d['lastName'] ?? '').toString().trim();
    final name = "$fn $ln".trim();
    return name.isEmpty ? "Doctor" : name;
  }

  /// ✅ Deterministic chat doc reference
  /// chats/{doctorId_patientId}
  DocumentReference<Map<String, dynamic>> _chatRef({
    required String doctorId,
    required String patientId,
  }) {
    final chatId = "${doctorId}_$patientId";
    return FirebaseFirestore.instance.collection("chats").doc(chatId);
  }

  Widget _circleIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: pink, width: 2),
      ),
      child: IconButton(
        icon: Icon(icon, color: pink, size: 18),
        onPressed: onTap,
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: GoogleFonts.poppins(
            color: pink,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _valueBox(String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: pink.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: pink, width: 1.6),
      ),
      child: Text(
        value,
        style: GoogleFonts.poppins(
          color: Colors.black87,
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _field({required String label, required String value}) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        _label(label),
        _valueBox(value),
      ],
    );
  }

  int? _readInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  // -------------------- FIRESTORE HELPERS --------------------

  Future<QueryDocumentSnapshot<Map<String, dynamic>>?> _findApprovedRequestDoc({
    required String patientId,
  }) async {
    final qs = await FirebaseFirestore.instance
        .collection('chatRequests')
        .where('patientId', isEqualTo: patientId)
        .where('doctorId', isEqualTo: widget.doctorId)
        .where('status', isEqualTo: 'approved')
        .limit(1)
        .get();

    if (qs.docs.isEmpty) return null;
    return qs.docs.first;
  }

  Future<void> _sendNotificationToPatient({
    required String patientId,
    required String message,
  }) async {
    await FirebaseFirestore.instance
        .collection("users")
        .doc(patientId)
        .collection("notifications")
        .add({
      "message": message,
      "isRead": false,
      "createdAt": FieldValue.serverTimestamp(),
      "type": "disconnect",
      "doctorId": widget.doctorId,
    });
  }

  /// ✅ Doctor notifications (same as doctor side)
  Future<void> _sendNotificationToDoctor({
    required String doctorId,
    required String patientId,
    required String message,
  }) async {
    await FirebaseFirestore.instance
        .collection("doctornotifications")
        .doc(doctorId)
        .collection("items")
        .add({
      "message": message,
      "patientId": patientId,
      "isRead": false,
      "createdAt": FieldValue.serverTimestamp(),
      "type": "disconnect",
    });
  }

  // -------------------- SWEET ALERTS --------------------

  Future<bool> _confirmDisconnect(AppLocalizations t, String doctorName) async {
    bool confirmed = false;

    await AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.scale,
      dismissOnTouchOutside: true,
      headerAnimationLoop: false,
      title: "Disconnect $doctorName?",
      desc:
      "This will end the chat permanently. You won’t be connected with this doctor again.",
      titleTextStyle: GoogleFonts.poppins(
        fontWeight: FontWeight.w800,
        fontSize: 18,
        color: pink,
      ),
      descTextStyle: GoogleFonts.poppins(
        fontSize: 13,
        height: 1.35,
        color: Colors.black87,
      ),
      btnCancelText: t.no,
      btnCancelColor: Colors.grey.shade400,
      btnCancelOnPress: () => confirmed = false,
      btnOkText: t.yes,
      btnOkColor: Colors.red.shade600,
      btnOkOnPress: () => confirmed = true,
      buttonsTextStyle: GoogleFonts.poppins(
        fontWeight: FontWeight.w800,
        fontSize: 13,
        color: Colors.white,
      ),
    ).show();

    return confirmed;
  }

  void _successDialog(
      AppLocalizations t, String title, String desc, VoidCallback onOk) {
    if (!mounted) return;
    AwesomeDialog(
      context: context,
      dialogType: DialogType.success,
      animType: AnimType.scale,
      dismissOnTouchOutside: false,
      headerAnimationLoop: false,
      title: title,
      desc: desc,
      titleTextStyle: GoogleFonts.poppins(
        fontWeight: FontWeight.w800,
        fontSize: 18,
        color: pink,
      ),
      descTextStyle: GoogleFonts.poppins(
        fontSize: 13,
        height: 1.35,
        color: Colors.black87,
      ),
      btnOkText: t.ok,
      btnOkColor: pink,
      btnOkOnPress: onOk,
      buttonsTextStyle: GoogleFonts.poppins(
        fontWeight: FontWeight.w800,
        fontSize: 13,
        color: Colors.white,
      ),
    ).show();
  }

  void _errorDialog(AppLocalizations t, String desc, VoidCallback onOk) {
    if (!mounted) return;
    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      animType: AnimType.scale,
      dismissOnTouchOutside: true,
      headerAnimationLoop: false,
      title: t.failed,
      desc: desc,
      titleTextStyle: GoogleFonts.poppins(
        fontWeight: FontWeight.w800,
        fontSize: 18,
        color: Colors.red.shade700,
      ),
      descTextStyle: GoogleFonts.poppins(
        fontSize: 13,
        height: 1.35,
      ),
      btnOkText: t.ok,
      btnOkColor: Colors.red.shade700,
      btnOkOnPress: onOk,
      buttonsTextStyle: GoogleFonts.poppins(
        fontWeight: FontWeight.w800,
        fontSize: 13,
        color: Colors.white,
      ),
    ).show();
  }

  // -------------------- DISCONNECT FLOW --------------------

  Future<void> _disconnectDoctor({
    required String doctorName,
  }) async {
    if (_disconnecting) return;
    final t = AppLocalizations.of(context)!;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _errorDialog(t, "Patient not logged in.", () {});
      return;
    }

    final ok = await _confirmDisconnect(t, doctorName);
    if (!ok) {
      if (mounted) setState(() => _connectionValue = "connected");
      return;
    }

    setState(() => _disconnecting = true);

    try {
      // 1) find approved request doc
      final reqDoc = await _findApprovedRequestDoc(patientId: user.uid);
      if (reqDoc == null) {
        if (!mounted) return;
        _errorDialog(t, "No active approved connection found.", () {
          if (mounted) setState(() => _connectionValue = "connected");
        });
        return;
      }

      // 2) cancel request
      await reqDoc.reference.update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
        'cancelledBy': user.uid,
      });

      // 3) mark chat inactive (admin should only see isActive:true)
      final chatRef =
      _chatRef(doctorId: widget.doctorId, patientId: user.uid);
      await chatRef.set({
        "chatId": chatRef.id,
        "doctorId": widget.doctorId,
        "patientId": user.uid,
        "isActive": false,
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 4) notifications
      await _sendNotificationToPatient(
        patientId: user.uid,
        message: "You disconnected from $doctorName. The chat room has been finished.",
      );

      await _sendNotificationToDoctor(
        doctorId: widget.doctorId,
        patientId: user.uid,
        message: "Patient disconnected from you. Chat ended.",
      );

      if (!mounted) return;

      // 5) success dialog
      _successDialog(
        t,
        t.success,
        "Disconnected successfully.\nNotifications sent.",
            () {
          if (Navigator.canPop(context)) Navigator.pop(context);
        },
      );
    } catch (e) {
      if (!mounted) return;
      _errorDialog(t, "Error: $e", () {
        if (mounted) setState(() => _connectionValue = "connected");
      });
    } finally {
      if (mounted) setState(() => _disconnecting = false);
    }
  }

  // -------------------- UI --------------------

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(widget.doctorId)
              .snapshots(),
          builder: (context, snap) {
            if (snap.hasError) {
              return Center(
                child: Text(
                  "Error: ${snap.error}",
                  style: GoogleFonts.poppins(color: Colors.red),
                ),
              );
            }
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final d = snap.data?.data();
            if (d == null) {
              return Center(
                child: Text(
                  "Doctor profile not found.",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    color: pink,
                  ),
                ),
              );
            }

            final name = _fullName(d);
            final email = (d['email'] ?? '').toString().trim();

            final ageInt = _readInt(d['age']);
            final age = ageInt == null ? "" : ageInt.toString();

            final specialization = (d['specialization'] ?? '').toString().trim();

            final expInt = _readInt(d['experience']);
            final experience = expInt == null ? "" : "$expInt+";

            final qualification = (d['qualification'] ?? '').toString().trim();
            final description = (d['description'] ?? '').toString().trim();
            final img = (d['profileImagePath'] ?? '').toString().trim();

            return SingleChildScrollView(
              child: Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: ribbon + title
                    Row(
                      children: [
                        Image.asset("assets/images/ribon.png", width: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            t.appTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: pink,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // ✅ Connected dropdown + back arrow
                    Row(
                      children: [
                        Opacity(
                          opacity: _disconnecting ? 0.6 : 1,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 2),
                            decoration: BoxDecoration(
                              color: pink,
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                  color: Colors.black.withOpacity(0.08),
                                )
                              ],
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _connectionValue,
                                dropdownColor: pink,
                                iconEnabledColor: Colors.white,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: "connected",
                                    child: Text("Connected"),
                                  ),
                                  DropdownMenuItem(
                                    value: "disconnected",
                                    child: Text("Disconnected"),
                                  ),
                                ],
                                onChanged: _disconnecting
                                    ? null
                                    : (v) async {
                                  if (v == null) return;
                                  setState(() => _connectionValue = v);

                                  if (v == "disconnected") {
                                    await _disconnectDoctor(
                                        doctorName: name);
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),

                        _circleIconButton(
                          icon: Icons.arrow_back_ios_new,
                          onTap: () {
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            }
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Banner
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: SizedBox(
                        width: double.infinity,
                        height: 170,
                        child: Image.asset(
                          "assets/images/doctorprofile.png",
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    Center(
                      child: Text(
                        t.doctorProfileTitle,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w800,
                          fontSize: 26,
                          color: pink,
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: pink, width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 28,
                            backgroundImage: img.isNotEmpty
                                ? NetworkImage(img)
                                : const AssetImage(
                                "assets/images/profilepink.png")
                            as ImageProvider,
                            backgroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: pink,
                                ),
                              ),
                              if (description.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  description,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w400,
                                    color: pink,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    _field(label: t.age, value: age),
                    _field(label: t.email, value: email),
                    _field(label: t.specialization, value: specialization),
                    _field(label: t.experience, value: experience),
                    _field(label: t.qualifications, value: qualification),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}