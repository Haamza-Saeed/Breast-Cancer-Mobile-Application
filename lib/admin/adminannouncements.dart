import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project/admin/adminrootpage.dart';

// ✅ Localization
import 'package:project/l10n/app_localizations.dart';

class AdminAnnouncements extends StatefulWidget {
  const AdminAnnouncements({super.key});

  @override
  State<AdminAnnouncements> createState() => _AdminAnnouncementsState();
}

class _AdminAnnouncementsState extends State<AdminAnnouncements> {
  static const Color green = Color(0xff00EFAB);

  final TextEditingController _announcementController = TextEditingController();

  // Keep stored values in English for Firestore consistency
  final List<String> _audiences = const ["Patient", "Doctor", "Both"];
  String _selectedAudience = "Patient";

  bool _loading = false;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void dispose() {
    _announcementController.dispose();
    super.dispose();
  }

  // ✅ Show localized audience label in UI (but keep Firestore value as English)
  String _audienceLabel(AppLocalizations? t, String v) {
    switch (v) {
      case "Patient":
        return t?.patient ?? "Patient";
      case "Doctor":
        return t?.doctor ?? "Doctor";
      case "Both":
        return t?.both ?? "Both";
      default:
        return v;
    }
  }

  void _showSweet({
    required AppLocalizations? t,
    required DialogType type,
    required String title,
    required String message,
  }) {
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

  Future<void> _addAnnouncement() async {
    final t = AppLocalizations.of(context);

    final uid = _uid;
    if (uid == null) {
      _showSweet(
        t: t,
        type: DialogType.warning,
        title: t?.notLoggedIn ?? "Not Logged In",
        message: t?.adminNotLoggedIn ?? "Admin not logged in!",
      );
      return;
    }

    final text = _announcementController.text.trim();
    if (text.isEmpty) {
      _showSweet(
        t: t,
        type: DialogType.warning,
        title: t?.emptyAnnouncementTitle ?? "Empty Announcement",
        message: t?.emptyAnnouncementDesc ?? "Please write an announcement first.",
      );
      return;
    }

    setState(() => _loading = true);

    try {
      // 1) Save announcement globally
      final annRef = FirebaseFirestore.instance.collection("announcements").doc();

      await annRef.set({
        "message": text,
        "audience": _selectedAudience, // Patient / Doctor / Both (stored EN)
        "createdBy": uid,
        "createdAt": FieldValue.serverTimestamp(),
      });

      // 2) Add admin's own notification
      await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("notifications")
          .add({
        "message":
        "${t?.announcementAddedFor ?? "Announcement added for"} ${_selectedAudience}: $text",
        "type": "announcement",
        "isRead": false,
        "createdAt": FieldValue.serverTimestamp(),
      });

      // 3) Push notifications to target users
      final msg = t?.newAnnouncement ?? "You have received a new announcement.";

      if (_selectedAudience == "Patient") {
        await _pushNotificationToRole(role: "patient", message: msg);
      } else if (_selectedAudience == "Doctor") {
        await _pushNotificationToRole(role: "doctor", message: msg);
      } else {
        // Both
        await _pushNotificationToRole(role: "patient", message: msg);
        await _pushNotificationToRole(role: "doctor", message: msg);
      }

      _announcementController.clear();

      if (!mounted) return;

      final audienceText = _audienceLabel(t, _selectedAudience);

      _showSweet(
        t: t,
        type: DialogType.success,
        title: t?.successTitle ?? "Success",
        message: t?.announcementAddedSuccessfullyFor(audienceText) ??
            "Announcement added successfully for $audienceText!",
      );
    } catch (e) {
      if (!mounted) return;
      _showSweet(
        t: t,
        type: DialogType.error,
        title: t?.failed ?? "Failed",
        message:
        "${t?.failedToAddAnnouncement ?? "Failed to add announcement."}\n$e",
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: green,
                      size: 18,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminRootPage()),
                      );
                    },
                  ),
                ),
              ),
              Image.asset("assets/images/greenmegaphone.png",
                  width: 373, height: 249),

              Text(
                t?.announcements ?? "Announcements",
                style: GoogleFonts.poppins(
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                  color: green,
                ),
              ),
              const SizedBox(height: 20),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  t?.addAnnouncementTitle ?? "Add Announcement",
                  style: GoogleFonts.poppins(
                    color: green,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  t?.sendTo ?? "Send To",
                  style: GoogleFonts.poppins(
                    color: green,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
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
                    value: _selectedAudience,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down, color: green),
                    items: _audiences.map((v) {
                      return DropdownMenuItem(
                        value: v,
                        child: Text(
                          _audienceLabel(t, v),
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _selectedAudience = v);
                    },
                  ),
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: _announcementController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText:
                  t?.announcementHint ?? "Write your announcement here...",
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

              const SizedBox(height: 70),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _addAnnouncement,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
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
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}