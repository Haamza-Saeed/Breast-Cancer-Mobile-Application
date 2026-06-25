import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project/doctor/doctorrootpage.dart';

// ✅ Localization
import 'package:project/l10n/app_localizations.dart';

class DoctorFeedBack extends StatefulWidget {
  const DoctorFeedBack({super.key});

  @override
  State<DoctorFeedBack> createState() => _DoctorFeedBackState();
}

class _DoctorFeedBackState extends State<DoctorFeedBack> {
  static const Color blue = Color(0xff00AEEF);

  final TextEditingController _controller = TextEditingController();
  bool _loading = false;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ✅ Safe localized fallback (if you haven't added keys in ARB yet)
  String _tr(AppLocalizations? t, String key, String fallback) {
    // If you already generated keys in ARB, replace these fallbacks
    // with direct calls like: t!.feedbackTitle etc.
    return fallback;
  }

  // ✅ AwesomeDialog helpers (Sweet Alert style)
  void _successDialog(AppLocalizations? t, String msg) {
    if (!mounted) return;
    AwesomeDialog(
      context: context,
      dialogType: DialogType.success,
      animType: AnimType.scale,
      title: t?.successTitle ?? "Success",
      desc: msg,
      btnOkText: t?.ok ?? "OK",
      btnOkOnPress: () {},
    ).show();
  }

  void _errorDialog(AppLocalizations? t, String msg) {
    if (!mounted) return;
    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      animType: AnimType.scale,
      title: t?.errorTitle ?? "Error",
      desc: msg,
      btnOkText: t?.ok ?? "OK",
      btnOkOnPress: () {},
    ).show();
  }

  void _infoDialog(AppLocalizations? t, String msg) {
    if (!mounted) return;
    AwesomeDialog(
      context: context,
      dialogType: DialogType.info,
      animType: AnimType.scale,
      title: t?.infoTitle ?? "Info",
      desc: msg,
      btnOkText: t?.ok ?? "OK",
      btnOkOnPress: () {},
    ).show();
  }

  Future<void> _notifyAdmins(String message) async {
    try {
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
    } catch (e) {
      debugPrint("Notification error: $e");
    }
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

  // ✅ ADD Feedback
  Future<void> _addFeedback() async {
    final t = AppLocalizations.of(context);

    final uid = _uid;
    if (uid == null) {
      _errorDialog(t, t?.doctorNotLoggedIn ?? "Doctor not logged in!");
      return;
    }

    final text = _controller.text.trim();
    if (text.isEmpty) {
      _infoDialog(t, t?.pleaseWriteFeedbackFirst ?? "Please write feedback first.");
      return;
    }

    setState(() => _loading = true);
    try {
      final fbRef = FirebaseFirestore.instance.collection("feedbacks").doc();

      await fbRef.set({
        "message": text,
        "createdBy": uid,
        "role": "doctor",
        "createdAt": FieldValue.serverTimestamp(),
        "adminResponse": "",
        "respondedAt": null,
        "respondedBy": "",
      });

      await _notifyAdmins("New doctor feedback received.");
      await _notifyUser(uid, "Your feedback has been sent to admin.");

      _controller.clear();
      _successDialog(t, t?.feedbackSentSuccessfully ?? "Feedback sent successfully!");
    } catch (e) {
      _errorDialog(t, "${t?.failedToSendFeedback ?? "Failed to send feedback"}: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ✅ EDIT Feedback
  Future<void> _editFeedback({
    required DocumentReference<Map<String, dynamic>> ref,
    required Map<String, dynamic> data,
  }) async {
    final t = AppLocalizations.of(context);

    final uid = _uid;
    if (uid == null) return;

    final response = (data["adminResponse"] ?? "").toString().trim();
    if (response.isNotEmpty) {
      _infoDialog(t, t?.cantEditAdminResponded ?? "You can’t edit because admin already responded.");
      return;
    }

    final editController = TextEditingController(
      text: (data["message"] ?? "").toString(),
    );

    try {
      final String? newText = await showDialog<String>(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.edit_note, size: 60, color: blue),
                const SizedBox(height: 10),
                Text(
                  t?.editFeedback ?? "Edit Feedback",
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: editController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: t?.updateYourMessage ?? "Update your message...",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, null),
                      child: Text(
                        t?.cancelUpper ?? "CANCEL",
                        style: GoogleFonts.poppins(color: Colors.grey),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: blue),
                      onPressed: () {
                        final val = editController.text.trim();
                        Navigator.pop(dialogContext, val);
                      },
                      child: Text(
                        t?.updateUpper ?? "UPDATE",
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      );

      if (newText == null) return;
      if (newText.trim().isEmpty) {
        _infoDialog(t, t?.messageCannotBeEmpty ?? "Message cannot be empty.");
        return;
      }

      await ref.update({"message": newText.trim()});
      await _notifyAdmins("A doctor updated their feedback.");
      await _notifyUser(uid, "Your feedback has been updated.");

      _successDialog(t, t?.feedbackUpdatedSuccessfully ?? "Feedback updated successfully!");
    } catch (e) {
      _errorDialog(t, "${t?.errorUpdatingFeedback ?? "Error updating feedback"}: $e");
    } finally {
      editController.dispose();
    }
  }

  // ✅ DELETE Feedback
  Future<void> _deleteFeedback({
    required DocumentReference<Map<String, dynamic>> ref,
    required Map<String, dynamic> data,
  }) async {
    final t = AppLocalizations.of(context);

    final uid = _uid;
    if (uid == null) return;

    final response = (data["adminResponse"] ?? "").toString().trim();
    if (response.isNotEmpty) {
      _infoDialog(t, t?.cantDeleteAdminResponded ?? "You can’t delete because admin already responded.");
      return;
    }

    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.scale,
      title: t?.deleteFeedbackTitle ?? "Delete Feedback",
      desc: t?.deleteFeedbackConfirm ?? "Are you sure you want to delete this feedback?",
      btnCancelText: t?.cancel ?? "Cancel",
      btnOkText: t?.delete ?? "Delete",
      btnCancelOnPress: () {},
      btnOkOnPress: () async {
        try {
          await ref.delete();
          await _notifyAdmins("A doctor deleted their feedback.");
          await _notifyUser(uid, "Your feedback has been deleted.");
          _successDialog(t, t?.feedbackDeletedSuccessfully ?? "Feedback deleted successfully!");
        } catch (e) {
          _errorDialog(t, "${t?.failedToDeleteFeedback ?? "Failed to delete feedback"}: $e");
        }
      },
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final uid = _uid;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Row(
          children: [
            Image.asset("assets/images/ribon.png", width: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                t?.appTitle ?? "AI-Based Breast Cancer Detection App",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: blue,
                ),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: InkWell(
                  onTap: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const DoctorRootPage()),
                  ),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: blue, width: 2),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      color: blue,
                      size: 18,
                    ),
                  ),
                ),
              ),
              Image.asset("assets/images/feedback.png", width: 250, height: 200),
              Text(
                t?.feedbackTitle ?? "Feedback",
                style: GoogleFonts.poppins(
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                  color: blue,
                ),
              ),
              const SizedBox(height: 20),

              // Input Field
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  t?.addFeedbackTitle ?? "Add Feedback",
                  style: GoogleFonts.poppins(
                    color: blue,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _controller,
                maxLines: 4,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(15),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: blue, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: blue, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: blue, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _addFeedback,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: blue,
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
                    t?.add ?? "Add",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 10),

              // Feedback List
              if (uid == null)
                Text(t?.userNotLoggedIn ?? "User not logged in.",
                    style: GoogleFonts.poppins())
              else
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection("feedbacks")
                      .where("createdBy", isEqualTo: uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }

                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return Text(
                        t?.noFeedbackYet ?? "No feedback yet!",
                        style: GoogleFonts.poppins(color: blue),
                      );
                    }

                    // Optional: latest first (client sort)
                    docs.sort((a, b) {
                      final ta = a.data()["createdAt"];
                      final tb = b.data()["createdAt"];
                      if (ta is Timestamp && tb is Timestamp) {
                        return tb.compareTo(ta);
                      }
                      return 0;
                    });

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final data = docs[i].data();
                        final ref = docs[i].reference;

                        final response =
                        (data["adminResponse"] ?? "").toString().trim();

                        final canEditDelete = response.isEmpty;

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: blue.withOpacity(0.5)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t?.yourMessage ?? "Your Message:",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  color: blue,
                                ),
                              ),
                              Text(
                                (data["message"] ?? "").toString(),
                                style: GoogleFonts.poppins(),
                              ),
                              if (response.isNotEmpty) ...[
                                const Divider(),
                                Text(
                                  t?.adminResponse ?? "Admin Response:",
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                Text(response, style: GoogleFonts.poppins()),
                              ],
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.edit,
                                      color: canEditDelete ? blue : Colors.grey,
                                    ),
                                    onPressed: canEditDelete
                                        ? () => _editFeedback(ref: ref, data: data)
                                        : () => _infoDialog(
                                      t,
                                      t?.cantEditAdminResponded ??
                                          "Can't edit: admin already responded.",
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete,
                                      color: canEditDelete
                                          ? Colors.redAccent
                                          : Colors.grey,
                                    ),
                                    onPressed: canEditDelete
                                        ? () => _deleteFeedback(ref: ref, data: data)
                                        : () => _infoDialog(
                                      t,
                                      t?.cantDeleteAdminResponded ??
                                          "Can't delete: admin already responded.",
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
                ),
            ],
          ),
        ),
      ),
    );
  }
}