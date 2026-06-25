import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ✅ Localization
import 'package:project/l10n/app_localizations.dart';

class AdminFeedbackDetail extends StatefulWidget {
  final String feedbackId;
  const AdminFeedbackDetail({super.key, required this.feedbackId});

  @override
  State<AdminFeedbackDetail> createState() => _AdminFeedbackDetailState();
}

class _AdminFeedbackDetailState extends State<AdminFeedbackDetail> {
  static const Color green = Color(0xff00EFAB);

  final TextEditingController _response = TextEditingController();
  bool _loading = false;

  // ✅ edit mode
  bool _editing = false;

  String? get _adminUid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void dispose() {
    _response.dispose();
    super.dispose();
  }

  String _asText(dynamic v) => (v ?? "").toString().trim();

  String _fullName(Map<String, dynamic> data) {
    final first = _asText(data["firstName"]);
    final last = _asText(data["lastName"]);
    final name = _asText(data["name"]);
    if (first.isNotEmpty || last.isNotEmpty) return ("$first $last").trim();
    if (name.isNotEmpty) return name;
    return "User";
  }

  String _roleLabel(AppLocalizations? t, String raw) {
    final r = raw.toLowerCase().trim();
    if (r == "patient") return t?.patient ?? "Patient";
    if (r == "doctor") return t?.doctor ?? "Doctor";
    if (r == "admin") return t?.admin ?? "Admin";
    return t?.user ?? "User";
  }

  void _sweet(AppLocalizations? t, DialogType type, String title, String msg) {
    AwesomeDialog(
      context: context,
      dialogType: type,
      animType: AnimType.scale,
      title: title,
      desc: msg,
      btnOkText: t?.ok ?? "OK",
      btnOkOnPress: () {},
    ).show();
  }

  Future<void> _notifyUser(String uid, String message) async {
    await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("notifications")
        .add({
      "message": message,
      "type": "feedback",
      "isRead": false,
      "createdAt": FieldValue.serverTimestamp(),
    });
  }

  Future<void> _notifyAdmins(String message) async {
    final admins = await FirebaseFirestore.instance
        .collection("users")
        .where("role", isEqualTo: "admin")
        .get();

    final batch = FirebaseFirestore.instance.batch();
    for (final a in admins.docs) {
      final ref = FirebaseFirestore.instance
          .collection("users")
          .doc(a.id)
          .collection("notifications")
          .doc();
      batch.set(ref, {
        "message": message,
        "type": "feedback",
        "isRead": false,
        "createdAt": FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  // ✅ send OR edit response depending on mode
  Future<void> _saveResponse(
      Map<String, dynamic> feedback, {
        required bool isEdit,
      }) async {
    final t = AppLocalizations.of(context);

    final adminUid = _adminUid;
    if (adminUid == null) {
      _sweet(
        t,
        DialogType.warning,
        t?.login ?? "Login",
        t?.adminNotLoggedIn ?? "Admin not logged in!",
      );
      return;
    }

    final createdBy = _asText(feedback["createdBy"]);
    if (createdBy.isEmpty) {
      _sweet(
        t,
        DialogType.error,
        t?.errorTitle ?? "Error",
        t?.feedbackUserNotFound ?? "Feedback user not found.",
      );
      return;
    }

    final txt = _response.text.trim();
    if (txt.isEmpty) {
      _sweet(
        t,
        DialogType.warning,
        t?.empty ?? "Empty",
        t?.pleaseWriteResponseFirst ?? "Please write a response first.",
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final ref =
      FirebaseFirestore.instance.collection("feedbacks").doc(widget.feedbackId);

      // ✅ If editing, store editedAt/editedBy. If sending first time, store respondedAt/respondedBy.
      final updateData = <String, dynamic>{
        "adminResponse": txt,
      };

      if (isEdit) {
        updateData.addAll({
          "editedAt": FieldValue.serverTimestamp(),
          "editedBy": adminUid,
        });
      } else {
        updateData.addAll({
          "respondedAt": FieldValue.serverTimestamp(),
          "respondedBy": adminUid,
        });
      }

      await ref.update(updateData);

      // ✅ Notifications
      if (isEdit) {
        await _notifyUser(
          createdBy,
          t?.adminUpdatedResponseToYourFeedback ??
              "Admin updated the response to your feedback.",
        );
        await _notifyAdmins(t?.feedbackResponseEdited ?? "A feedback response was edited.");
      } else {
        await _notifyUser(
          createdBy,
          t?.adminRespondedToYourFeedback ?? "Admin responded to your feedback.",
        );
        await _notifyAdmins(t?.feedbackResponseSent ?? "A feedback response was sent.");
      }

      if (!mounted) return;

      setState(() => _editing = false);
      _response.clear();
      FocusScope.of(context).unfocus();

      _sweet(
        t,
        DialogType.success,
        isEdit ? (t?.updated ?? "Updated") : (t?.sent ?? "Sent"),
        isEdit
            ? (t?.responseUpdatedSuccessfully ?? "Response updated successfully.")
            : (t?.responseSentToUser ?? "Response sent to the user."),
      );
    } catch (e) {
      if (!mounted) return;
      _sweet(
        t,
        DialogType.error,
        t?.failed ?? "Failed",
        "$e",
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final fbRef =
    FirebaseFirestore.instance.collection("feedbacks").doc(widget.feedbackId);

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
          child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: fbRef.snapshots(),
            builder: (context, snap) {
              if (snap.hasError) {
                return Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: Text(
                    t?.failedToLoadFeedback ?? "Failed to load feedback",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      color: Colors.red,
                    ),
                  ),
                );
              }

              if (!snap.hasData) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final fb = snap.data!.data() ?? {};
              final msg = _asText(fb["message"]);
              final roleRaw = _asText(fb["role"]);
              final response = _asText(fb["adminResponse"]);
              final createdBy = _asText(fb["createdBy"]);
              final alreadyResponded = response.isNotEmpty;

              final roleLabel = _roleLabel(t, roleRaw);

              return Column(
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
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                  Image.asset("assets/images/feedback.png", width: 373, height: 249),
                  const SizedBox(height: 10),

                  Text(
                    t?.feedbackDetailTitle ?? "Feedback Detail",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 25,
                      color: green,
                    ),
                  ),

                  const SizedBox(height: 18),

                  FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    future: createdBy.isEmpty
                        ? null
                        : FirebaseFirestore.instance.collection("users").doc(createdBy).get(),
                    builder: (context, uSnap) {
                      final u = uSnap.data?.data() ?? {};
                      final userName = _fullName(u);
                      final userEmail = _asText(u["email"]);
                      final userRole = _asText(u["role"]);

                      final userRoleLabel = _roleLabel(
                        t,
                        userRole.isEmpty ? roleRaw : userRole,
                      );

                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: green, width: 2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${userRoleLabel.toUpperCase()} • ${alreadyResponded ? (t?.responded ?? "Responded") : (t?.pending ?? "Pending")}",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w800,
                                fontSize: 12.5,
                                color: green,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "${t?.name ?? "Name"}: ${userName.isEmpty ? (t?.user ?? "User") : userName}",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 12.8,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${t?.email ?? "Email"}: ${userEmail.isEmpty ? (t?.na ?? "N/A") : userEmail}",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500,
                                fontSize: 12.2,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${t?.role ?? "Role"}: ${userRoleLabel.isEmpty ? (t?.na ?? "N/A") : userRoleLabel}",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500,
                                fontSize: 12.2,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              msg.isEmpty ? "-" : msg,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 13.2,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // ✅ RESPONDED SECTION (view + edit)
                  if (alreadyResponded && !_editing) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          t?.adminResponse ?? "Admin Response",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w800,
                            color: Colors.green,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _editing = true;
                              _response.text = response;
                            });
                          },
                          icon: const Icon(Icons.edit, size: 18, color: green),
                          label: Text(
                            t?.edit ?? "Edit",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              color: green,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.green, width: 2),
                      ),
                      child: Text(
                        response,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],

                  // ✅ EDIT MODE (or first-time response)
                  if (!alreadyResponded || _editing) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _editing
                            ? (t?.editResponseTitle ?? "Edit Response")
                            : (t?.writeResponseTitle ?? "Write Response"),
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w800,
                          color: green,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _response,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: t?.responseHint ?? "Write your response here...",
                        contentPadding:
                        const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: green, width: 2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: green, width: 2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: green, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ✅ Buttons: Save / Cancel when editing
                    if (_editing) ...[
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _loading ? null : () => _saveResponse(fb, isEdit: true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: green,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: _loading
                                  ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                                  : Text(
                                t?.saveChanges ?? "Save Changes",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _loading
                                  ? null
                                  : () {
                                setState(() {
                                  _editing = false;
                                  _response.clear();
                                });
                                FocusScope.of(context).unfocus();
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: green, width: 2),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: Text(
                                t?.cancel ?? "Cancel",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  color: green,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      // ✅ first-time send button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : () => _saveResponse(fb, isEdit: false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: green,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: _loading
                              ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : Text(
                            t?.sendResponse ?? "Send Response",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],

                  const SizedBox(height: 30),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}