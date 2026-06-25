import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project/l10n/app_localizations.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

class PatientProfileView extends StatefulWidget {
  final String patientId;
  const PatientProfileView({super.key, required this.patientId});

  @override
  State<PatientProfileView> createState() => _PatientProfileViewState();
}

class _PatientProfileViewState extends State<PatientProfileView> {
  static const Color blue = Color(0xff00AEEF);

  String _connectionValue = "connected";
  bool _disconnecting = false;

  String? get _doctorId => FirebaseAuth.instance.currentUser?.uid;

  // ------------------ helpers ------------------

  String _fullName(Map<String, dynamic> d, AppLocalizations t) {
    final fn = (d['firstName'] ?? '').toString().trim();
    final ln = (d['lastName'] ?? '').toString().trim();
    final name = "$fn $ln".trim();
    return name.isEmpty ? t.patientFallbackName : name;
  }

  int? _readInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  String _dashIfEmpty(String v) => v.trim().isEmpty ? "—" : v.trim();

  String _displayYesNo(AppLocalizations t, String value) {
    switch (value) {
      case "Yes":
        return t.yes;
      case "No":
        return t.no;
      default:
        return value;
    }
  }

  String _displayMarital(AppLocalizations t, String value) {
    switch (value) {
      case "Single":
        return t.single;
      case "Married":
        return t.married;
      default:
        return value;
    }
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: GoogleFonts.poppins(
            color: blue,
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: blue, width: 1.8),
      ),
      child: Text(
        _dashIfEmpty(value),
        style: GoogleFonts.poppins(
          color: Colors.black87,
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _field({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        _valueBox(value),
      ],
    );
  }

  Widget _readOnlyMedicationImageCard(String url) {
    return Container(
      width: 115,
      height: 115,
      margin: const EdgeInsets.only(right: 10, bottom: 10),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        border: Border.all(color: blue, width: 2),
        borderRadius: BorderRadius.circular(14),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          url,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return Container(
              color: Colors.grey.shade200,
              child: const Icon(Icons.broken_image, color: Colors.grey),
            );
          },
        ),
      ),
    );
  }

  // ------------------ FIRESTORE HELPERS ------------------

  /// ✅ Find ONLY the approved request between this doctor and patient
  Future<QueryDocumentSnapshot<Map<String, dynamic>>?> _findApprovedRequestDoc({
    required String doctorId,
    required String patientId,
  }) async {
    final qs = await FirebaseFirestore.instance
        .collection("chatRequests")
        .where("doctorId", isEqualTo: doctorId)
        .where("patientId", isEqualTo: patientId)
        .where("status", isEqualTo: "approved")
        .limit(1)
        .get();

    if (qs.docs.isEmpty) return null;
    return qs.docs.first;
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
      "doctorId": _doctorId,
    });
  }

  /// ✅ Doctor notifications collection (adjust path if yours is different)
  Future<void> _sendNotificationToDoctor({
    required String doctorId,
    required String message,
    required String patientId,
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

  // ------------------ SWEET ALERTS ------------------

  Future<bool> _confirmDisconnect(AppLocalizations t) async {
    bool confirmed = false;

    await AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.scale,
      dismissOnTouchOutside: true,
      headerAnimationLoop: false,
      title: "Disconnect Patient?",
      desc:
      "This will end the connection and chat permanently. You can’t undo this action.",
      titleTextStyle: GoogleFonts.poppins(
        fontWeight: FontWeight.w800,
        fontSize: 18,
        color: blue,
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

  void _successDialog({
    required String title,
    required String desc,
    VoidCallback? onOk,
  }) {
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
        color: blue,
      ),
      descTextStyle: GoogleFonts.poppins(
        fontSize: 13,
        height: 1.35,
        color: Colors.black87,
      ),
      btnOkText: "OK",
      btnOkColor: blue,
      btnOkOnPress: onOk ?? () {},
      buttonsTextStyle: GoogleFonts.poppins(
        fontWeight: FontWeight.w800,
        fontSize: 13,
        color: Colors.white,
      ),
    ).show();
  }

  void _errorDialog(String msg) {
    if (!mounted) return;

    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      animType: AnimType.scale,
      dismissOnTouchOutside: true,
      headerAnimationLoop: false,
      title: "Error",
      desc: msg,
      titleTextStyle: GoogleFonts.poppins(
        fontWeight: FontWeight.w800,
        fontSize: 18,
        color: Colors.red.shade700,
      ),
      descTextStyle: GoogleFonts.poppins(
        fontSize: 13,
        height: 1.35,
      ),
      btnOkText: "OK",
      btnOkColor: Colors.red.shade700,
      btnOkOnPress: () {},
      buttonsTextStyle: GoogleFonts.poppins(
        fontWeight: FontWeight.w800,
        fontSize: 13,
        color: Colors.white,
      ),
    ).show();
  }

  // ------------------ DISCONNECT FLOW ------------------

  Future<void> _disconnectPatient({
    required AppLocalizations t,
    required QueryDocumentSnapshot<Map<String, dynamic>> reqDoc,
  }) async {
    if (_disconnecting) return;

    final did = _doctorId;
    if (did == null) {
      _errorDialog("Doctor not logged in.");
      return;
    }

    final ok = await _confirmDisconnect(t);
    if (!ok) {
      if (mounted) setState(() => _connectionValue = "connected");
      return;
    }

    setState(() => _disconnecting = true);

    try {
      // 1) cancel request
      await reqDoc.reference.update({
        "status": "cancelled",
        "cancelledAt": FieldValue.serverTimestamp(),
        "cancelledBy": did,
      });

      // 2) set chat inactive (ADMIN will not see it)
      final chatRef = _chatRef(doctorId: did, patientId: widget.patientId);
      await chatRef.set({
        "chatId": chatRef.id,
        "doctorId": did,
        "patientId": widget.patientId,
        "isActive": false,
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 3) notifications
      await _sendNotificationToPatient(
        patientId: widget.patientId,
        message:
        "Your connection with the doctor has been disconnected. The chat session has ended.",
      );

      await _sendNotificationToDoctor(
        doctorId: did,
        patientId: widget.patientId,
        message: "You disconnected this patient successfully.",
      );

      if (!mounted) return;

      _successDialog(
        title: "Disconnected",
        desc: "Patient disconnected successfully.\nNotifications sent.",
        onOk: () {
          if (Navigator.canPop(context)) Navigator.pop(context);
        },
      );
    } catch (e) {
      if (!mounted) return;
      _errorDialog("Something went wrong.\n$e");
      setState(() => _connectionValue = "connected");
    } finally {
      if (mounted) setState(() => _disconnecting = false);
    }
  }

  // ------------------ TOP ROW (BACK + DROPDOWN) ------------------

  Widget _topRow({
    required AppLocalizations t,
    required bool showDropdown,
    required QueryDocumentSnapshot<Map<String, dynamic>>? approvedDoc,
  }) {
    return Row(
      children: [
        // back
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: blue, width: 2),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: blue, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        const Spacer(),

        if (showDropdown && approvedDoc != null)
          Opacity(
            opacity: _disconnecting ? 0.6 : 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              decoration: BoxDecoration(
                color: blue,
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
                  dropdownColor: blue,
                  iconEnabledColor: Colors.white,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: "connected", child: Text("Connected")),
                    DropdownMenuItem(
                        value: "disconnected", child: Text("Disconnected")),
                  ],
                  onChanged: _disconnecting
                      ? null
                      : (v) async {
                    if (v == null) return;
                    setState(() => _connectionValue = v);

                    if (v == "disconnected") {
                      await _disconnectPatient(t: t, reqDoc: approvedDoc);
                    }
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ------------------ UI ------------------

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final did = _doctorId;

    return Scaffold(
      backgroundColor: Colors.white,
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
                color: blue,
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: (did == null)
            ? Center(
          child: Text(
            "Doctor not logged in!",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              color: blue,
            ),
          ),
        )
            : FutureBuilder<QueryDocumentSnapshot<Map<String, dynamic>>?>(
          future: _findApprovedRequestDoc(
            doctorId: did,
            patientId: widget.patientId,
          ),
          builder: (context, reqSnap) {
            final approvedDoc = reqSnap.data;

            // dropdown shows only if approvedDoc exists
            final showDropdown = approvedDoc != null;

            // default is connected after approved
            if (showDropdown && _connectionValue != "connected") {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                setState(() => _connectionValue = "connected");
              });
            }

            return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.patientId)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(
                    child: Text(
                      "${t.error}: ${snap.error}",
                      style: GoogleFonts.poppins(color: Colors.red),
                      textAlign: TextAlign.center,
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
                      t.patientProfileNotFound,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        color: blue,
                      ),
                    ),
                  );
                }

                final name = _fullName(d, t);
                final email = (d['email'] ?? '').toString().trim();

                final ageInt = _readInt(d['age']);
                final age = ageInt == null ? "" : ageInt.toString();

                final maritalRaw =
                (d['maritalStatus'] ?? '').toString().trim();
                final anyMedRaw =
                (d['anyMedication'] ?? '').toString().trim();
                final cancerRaw =
                (d['cancerInFamily'] ?? '').toString().trim();

                final maritalStatus = maritalRaw.isEmpty
                    ? ""
                    : _displayMarital(t, maritalRaw);
                final anyMedication =
                anyMedRaw.isEmpty ? "" : _displayYesNo(t, anyMedRaw);
                final cancerInFamily =
                cancerRaw.isEmpty ? "" : _displayYesNo(t, cancerRaw);

                // --- NEW DATA FETCHING START ---
                final medicationDetails =
                (d['medicationDetails'] ?? '').toString().trim();
                final cancerFamilyDetails =
                (d['cancerFamilyDetails'] ?? '').toString().trim();

                final imgsRaw = d["medicationImages"];
                final List<String> medicationImages = imgsRaw is List
                    ? imgsRaw.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList()
                    : [];
                // --- NEW DATA FETCHING END ---

                final img =
                (d['profileImagePath'] ?? '').toString().trim();

                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _topRow(
                          t: t,
                          showDropdown: showDropdown,
                          approvedDoc: approvedDoc,
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            "assets/images/doctorprofile.png",
                            width: double.infinity,
                            height: 170,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            t.patientProfileTitle,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w800,
                              fontSize: 26,
                              color: blue,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border:
                                Border.all(color: blue, width: 2),
                              ),
                              child: CircleAvatar(
                                radius: 30,
                                backgroundImage: img.isNotEmpty
                                    ? NetworkImage(img)
                                    : const AssetImage(
                                    "assets/images/profileblue.png")
                                as ImageProvider,
                                backgroundColor: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                name,
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: blue,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _field(label: t.age, value: age),
                        _field(label: t.email, value: email),
                        _field(label: t.maritalStatus, value: maritalStatus),

                        // --- NEW UI START ---
                        _field(label: t.anyMedication, value: anyMedication),
                        if (anyMedRaw == "Yes" && medicationDetails.isNotEmpty)
                          _field(label: "Medication Details", value: medicationDetails),

                        if (anyMedRaw == "Yes" && medicationImages.isNotEmpty) ...[
                          _label("Medical Reports"),
                          Wrap(
                            children: medicationImages.map((url) => _readOnlyMedicationImageCard(url)).toList(),
                          ),
                        ],

                        _field(label: t.cancerInFamily, value: cancerInFamily),
                        if (cancerRaw == "Yes" && cancerFamilyDetails.isNotEmpty)
                          _field(label: "Cancer Family Details", value: cancerFamilyDetails),
                        // --- NEW UI END ---

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}