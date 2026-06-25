import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project/patient/rootpage.dart';
import 'package:project/l10n/app_localizations.dart';

class FeedBack extends StatefulWidget {
  const FeedBack({super.key});

  @override
  State<FeedBack> createState() => _FeedBackState();
}

class _FeedBackState extends State<FeedBack> {
  static const Color pink = Color(0xffFF67CE);

  final TextEditingController _controller = TextEditingController();
  bool _loading = false;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ✅ show sweet safely (after dialog pop / rebuild)
  Future<void> _sweetSafe({
    required DialogType type,
    required String title,
    required String message,
  }) async {
    if (!mounted) return;

    // wait a tiny bit so any dialog pop completes cleanly
    await Future.delayed(const Duration(milliseconds: 120));

    if (!mounted) return;

    final t = AppLocalizations.of(context);

    AwesomeDialog(
      context: context,
      dialogType: type,
      animType: AnimType.scale,
      title: title,
      desc: message,
      btnOkText: t?.ok ?? "OK",
      btnOkOnPress: () {},
    ).show();
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

  Future<void> _addFeedback() async {
    final t = AppLocalizations.of(context)!;

    final uid = _uid;
    if (uid == null) {
      await _sweetSafe(
        type: DialogType.warning,
        title: t.fbLoginTitle,
        message: t.pleaseLoginFirst,
      );
      return;
    }

    final text = _controller.text.trim();
    if (text.isEmpty) {
      await _sweetSafe(
        type: DialogType.warning,
        title: t.fbEmptyTitle,
        message: t.fbEmptyDesc,
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final fbRef = FirebaseFirestore.instance.collection("feedbacks").doc();

      await fbRef.set({
        "message": text,
        "createdBy": uid,
        "role": "patient",
        "createdAt": FieldValue.serverTimestamp(),
        "adminResponse": "",
        "respondedAt": null,
        "respondedBy": "",
      });

      await _notifyAdmins(t.fbNotifyAdminsNewFeedback);
      await _notifyUser(uid, t.fbNotifyUserSent);

      _controller.clear();

      if (!mounted) return;
      await _sweetSafe(
        type: DialogType.success,
        title: t.fbSuccessTitle,
        message: t.fbSuccessDesc,
      );
    } catch (e) {
      if (!mounted) return;
      await _sweetSafe(
        type: DialogType.error,
        title: t.fbFailedTitle,
        message: "${t.fbFailedDesc}\n$e",
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _editFeedback({
    required DocumentReference<Map<String, dynamic>> ref,
    required Map<String, dynamic> data,
  }) async {
    final t = AppLocalizations.of(context)!;

    final uid = _uid;
    if (uid == null) return;

    final response = (data["adminResponse"] ?? "").toString().trim();
    if (response.isNotEmpty) {
      await _sweetSafe(
        type: DialogType.info,
        title: t.fbLockedTitle,
        message: t.fbLockedEditDesc,
      );
      return;
    }

    final TextEditingController edit = TextEditingController(
      text: (data["message"] ?? "").toString(),
    );

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            t.fbEditDialogTitle,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
          ),
          content: TextField(
            controller: edit,
            maxLines: 4,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(t.cancel, style: GoogleFonts.poppins()),
            ),
            TextButton(
              onPressed: () async {
                final newText = edit.text.trim();
                if (newText.isEmpty) return;

                Navigator.of(dialogContext).pop();

                try {
                  await ref.update({"message": newText});
                  await _notifyAdmins(t.fbNotifyAdminsUpdated);
                  await _notifyUser(uid, t.fbNotifyUserUpdated);

                  if (!mounted) return;
                  await _sweetSafe(
                    type: DialogType.success,
                    title: t.fbUpdatedTitle,
                    message: t.fbUpdatedDesc,
                  );
                } catch (e) {
                  if (!mounted) return;
                  await _sweetSafe(
                    type: DialogType.error,
                    title: t.fbFailedTitle,
                    message: "$e",
                  );
                }
              },
              child: Text(
                t.save,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: pink),
              ),
            ),
          ],
        );
      },
    );

    edit.dispose();
  }

  Future<void> _deleteFeedback({
    required DocumentReference<Map<String, dynamic>> ref,
    required Map<String, dynamic> data,
  }) async {
    final t = AppLocalizations.of(context)!;

    final uid = _uid;
    if (uid == null) return;

    final response = (data["adminResponse"] ?? "").toString().trim();
    if (response.isNotEmpty) {
      await _sweetSafe(
        type: DialogType.info,
        title: t.fbLockedTitle,
        message: t.fbLockedDeleteDesc,
      );
      return;
    }

    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.scale,
      title: t.fbDeleteTitle,
      desc: t.fbDeleteConfirmDesc,
      btnCancelText: t.cancel,
      btnOkText: t.delete,
      btnCancelOnPress: () {},
      btnOkOnPress: () async {
        try {
          await ref.delete();
          await _notifyAdmins(t.fbNotifyAdminsDeleted);
          await _notifyUser(uid, t.fbNotifyUserDeleted);

          if (!mounted) return;
          await _sweetSafe(
            type: DialogType.success,
            title: t.fbDeletedTitle,
            message: t.fbDeletedDesc,
          );
        } catch (e) {
          if (!mounted) return;
          await _sweetSafe(
            type: DialogType.error,
            title: t.fbFailedTitle,
            message: "$e",
          );
        }
      },
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final uid = _uid;

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
                    icon: const Icon(Icons.arrow_back_ios_new, color: pink, size: 18),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RootPage()),
                      );
                    },
                  ),
                ),
              ),
              Image.asset("assets/images/feedback.png", width: 373, height: 249),
              Text(
                t.feedbackTitle,
                style: GoogleFonts.poppins(
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                  color: pink,
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  t.addFeedback,
                  style: GoogleFonts.poppins(
                    color: pink,
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
                  hintText: t.feedbackHint,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: pink, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: pink, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: pink, width: 2),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _addFeedback,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: pink,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: _loading
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                      : Text(
                    t.addButton,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              if (uid == null)
                Text(t.userNotLoggedIn, style: GoogleFonts.poppins(color: Colors.red))
              else
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection("feedbacks")
                      .where("createdBy", isEqualTo: uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 30),
                        child: CircularProgressIndicator(),
                      );
                    }

                    final docs = snapshot.data!.docs;

                    docs.sort((a, b) {
                      final ta = a.data()["createdAt"];
                      final tb = b.data()["createdAt"];
                      if (ta is Timestamp && tb is Timestamp) return tb.compareTo(ta);
                      return 0;
                    });

                    if (docs.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 30),
                        child: Text(
                          t.noFeedbackYet,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: pink,
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
                        final ref = docs[i].reference;
                        final data = docs[i].data();

                        final msg = (data["message"] ?? "").toString().trim();
                        final response = (data["adminResponse"] ?? "").toString().trim();
                        final canEdit = response.isEmpty;

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: pink, width: 2),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.yourFeedback,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: pink,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                msg.isEmpty ? "-" : msg,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 10),

                              if (response.isNotEmpty) ...[
                                Text(
                                  t.adminResponse,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  response,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ] else ...[
                                Text(
                                  t.noResponseYet,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12.5,
                                    color: Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],

                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: canEdit ? () => _editFeedback(ref: ref, data: data) : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: pink,
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(30),
                                        ),
                                      ),
                                      child: Text(
                                        t.edit,
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: canEdit ? () => _deleteFeedback(ref: ref, data: data) : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(30),
                                        ),
                                      ),
                                      child: Text(
                                        t.delete,
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
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
                ),
            ],
          ),
        ),
      ),
    );
  }
}