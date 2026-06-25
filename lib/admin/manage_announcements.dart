import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:project/l10n/app_localizations.dart';

class ManageAnnouncements extends StatefulWidget {
  const ManageAnnouncements({super.key});

  @override
  State<ManageAnnouncements> createState() => _ManageAnnouncementsState();
}

class _ManageAnnouncementsState extends State<ManageAnnouncements> {
  static const Color green = Color(0xff00EFAB);

  // ✅ Keep Firestore values in English (DO NOT change these)
  static const List<String> _audiences = ["Patient", "Doctor", "Both"];

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // ✅ Convert stored audience to localized label (UI only)
  String _audienceLabel(BuildContext context, String audience) {
    final t = AppLocalizations.of(context)!;
    switch (audience) {
      case "Patient":
        return t.audiencePatient;
      case "Doctor":
        return t.audienceDoctor;
      case "Both":
        return t.audienceBoth;
      default:
        return audience; // fallback
    }
  }

  void _sweet(DialogType type, String title, String msg) {
    if (!mounted) return;
    final t = AppLocalizations.of(context)!;

    AwesomeDialog(
      context: context,
      dialogType: type,
      animType: AnimType.scale,
      title: title,
      desc: msg,
      btnOkText: t.ok,
      btnOkOnPress: () {},
    ).show();
  }

  void _confirmDelete({
    required String annId,
    required String audience,
    required String message,
  }) {
    final t = AppLocalizations.of(context)!;

    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.scale,
      title: t.deleteTitle,
      desc: t.deleteAnnouncementConfirmDesc,
      btnCancelText: t.cancel,
      btnOkText: t.delete,
      btnCancelOnPress: () {},
      btnOkOnPress: () => _deleteAnnouncement(
        annId: annId,
        audience: audience,
        message: message,
      ),
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
        "type": "announcement",
        "isRead": false,
        "createdAt": FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  Future<void> _pushNotificationToRole({
    required String role,
    required String message,
  }) async {
    final usersSnap = await FirebaseFirestore.instance
        .collection("users")
        .where("role", isEqualTo: role)
        .get();

    final batch = FirebaseFirestore.instance.batch();
    for (final u in usersSnap.docs) {
      final notifRef = FirebaseFirestore.instance
          .collection("users")
          .doc(u.id)
          .collection("notifications")
          .doc();

      batch.set(notifRef, {
        "message": message,
        "type": "announcement",
        "isRead": false,
        "createdAt": FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  Future<void> _notifyAudienceUsers({
    required String audience,
    required String message,
  }) async {
    if (audience == "Patient") {
      await _pushNotificationToRole(role: "patient", message: message);
    } else if (audience == "Doctor") {
      await _pushNotificationToRole(role: "doctor", message: message);
    } else {
      await _pushNotificationToRole(role: "patient", message: message);
      await _pushNotificationToRole(role: "doctor", message: message);
    }
  }

  Future<void> _deleteAnnouncement({
    required String annId,
    required String audience,
    required String message,
  }) async {
    final t = AppLocalizations.of(context)!;
    final uid = _uid;

    if (uid == null) {
      _sweet(DialogType.warning, t.loginTitle, t.adminNotLoggedIn);
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection("announcements")
          .doc(annId)
          .delete();

      await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("notifications")
          .add({
        "message": "${t.announcementDeletedFor} $audience: $message",
        "type": "announcement",
        "isRead": false,
        "createdAt": FieldValue.serverTimestamp(),
      });

      await _notifyAdmins(t.adminAnnouncementDeletedNotif);
      await _notifyAudienceUsers(
        audience: audience,
        message: t.userAnnouncementRemovedNotif,
      );

      _sweet(DialogType.success, t.deletedTitle, t.announcementDeletedSuccessDesc);
    } catch (e) {
      _sweet(DialogType.error, t.failedTitle, "$e");
    }
  }

  // ✅ Edit dialog (localized, and safe controller lifecycle)
  void _openEditDialog({
    required String annId,
    required String currentMessage,
    required String currentAudience,
  }) {
    final t = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        final TextEditingController msgCtrl =
        TextEditingController(text: currentMessage);

        String selectedAudience =
        _audiences.contains(currentAudience) ? currentAudience : "Patient";

        bool saving = false;

        return StatefulBuilder(
          builder: (stCtx, setLocal) {
            Future<void> save() async {
              final uid = _uid;
              if (uid == null) {
                Navigator.of(dialogCtx).pop();
                _sweet(DialogType.warning, t.loginTitle, t.adminNotLoggedIn);
                return;
              }

              final newMsg = msgCtrl.text.trim();
              if (newMsg.isEmpty) {
                _sweet(DialogType.warning, t.emptyTitle, t.writeAnnouncementFirstDesc);
                return;
              }

              setLocal(() => saving = true);

              try {
                await FirebaseFirestore.instance
                    .collection("announcements")
                    .doc(annId)
                    .update({
                  "message": newMsg,
                  "audience": selectedAudience, // ✅ stored in English
                  "editedAt": FieldValue.serverTimestamp(),
                  "editedBy": uid,
                });

                await FirebaseFirestore.instance
                    .collection("users")
                    .doc(uid)
                    .collection("notifications")
                    .add({
                  "message": "${t.announcementEditedFor} $selectedAudience: $newMsg",
                  "type": "announcement",
                  "isRead": false,
                  "createdAt": FieldValue.serverTimestamp(),
                });

                await _notifyAdmins(t.adminAnnouncementEditedNotif);
                await _notifyAudienceUsers(
                  audience: selectedAudience,
                  message: t.userAnnouncementUpdatedNotif,
                );

                Navigator.of(dialogCtx).pop();
                _sweet(DialogType.success, t.updatedTitle, t.announcementUpdatedSuccessDesc);
              } catch (e) {
                Navigator.of(dialogCtx).pop();
                _sweet(DialogType.error, t.failedTitle, "$e");
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                t.editAnnouncementTitle,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w800,
                  color: green,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      t.sendToLabel,
                      style: GoogleFonts.poppins(
                        color: green,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: green, width: 2),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedAudience,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down, color: green),
                          items: _audiences.map((v) {
                            return DropdownMenuItem(
                              value: v,
                              child: Text(
                                _audienceLabel(context, v), // ✅ UI localized
                                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                              ),
                            );
                          }).toList(),
                          onChanged: saving
                              ? null
                              : (v) {
                            if (v != null) setLocal(() => selectedAudience = v);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: msgCtrl,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: t.announcementHint,
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
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.of(dialogCtx).pop(),
                  child: Text(
                    t.cancel,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                  ),
                ),
                ElevatedButton(
                  onPressed: saving ? null : save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: saving
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                      : Text(
                    t.save,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _announcementCard({
    required String annId,
    required Map<String, dynamic> data,
  }) {
    final t = AppLocalizations.of(context)!;

    final msg = (data["message"] ?? "").toString().trim();
    final audience = (data["audience"] ?? "Patient").toString().trim();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: green, width: 2),
        color: Colors.white,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.campaign, color: green),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _audienceLabel(context, audience).toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                    color: green,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  msg.isEmpty ? "-" : msg,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _openEditDialog(
                          annId: annId,
                          currentMessage: msg,
                          currentAudience: audience,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: green,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        icon: const Icon(Icons.edit, size: 18, color: Colors.white),
                        label: Text(
                          t.edit,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _confirmDelete(
                          annId: annId,
                          audience: audience,
                          message: msg,
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red, width: 2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                        label: Text(
                          t.delete,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Image.asset("assets/images/ribon.png", width: 24),
            ),
            const SizedBox(width: 10),
            Text(
              t.appTitle,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: green,
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
                    tooltip: t.back,
                  ),
                ),
              ),
              Image.asset("assets/images/greenmegaphone.png", width: 373, height: 249),
              const SizedBox(height: 10),
              Text(
                t.manageAnnouncementsTitle,
                style: GoogleFonts.poppins(
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                  color: green,
                ),
              ),
              const SizedBox(height: 18),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection("announcements")
                    .orderBy("createdAt", descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text(
                      t.errorLoadingData,
                      style: GoogleFonts.poppins(color: Colors.red),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return Text(
                      t.noAnnouncementsYet,
                      style: GoogleFonts.poppins(color: green),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) =>
                        _announcementCard(annId: docs[i].id, data: docs[i].data()),
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