import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:project/doctor/doctorfeedback.dart';
import 'package:project/doctor/doctorsettings.dart';
import 'package:project/login.dart';
import 'manage_uploads.dart';

import 'package:project/l10n/app_localizations.dart';

class DoctorAnnouncements extends StatefulWidget {
  const DoctorAnnouncements({super.key});

  static const Color blue = Color(0xff00AEEF);

  @override
  State<DoctorAnnouncements> createState() => _DoctorAnnouncementsState();
}

class _DoctorAnnouncementsState extends State<DoctorAnnouncements>
    with SingleTickerProviderStateMixin {
  bool _logoutDialogOpen = false;

  String _name = "Doctor";
  String _profileUrl = "";

  late AnimationController _hintController;
  late Animation<double> _hintAnimation;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _loadDoctorHeader();

    _hintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _hintAnimation = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _hintController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _hintController.dispose();
    super.dispose();
  }

  void _sweet({
    required DialogType type,
    required String title,
    required String desc,
    required String okText,
    VoidCallback? onOk,
  }) {
    if (!mounted) return;

    AwesomeDialog(
      context: context,
      dialogType: type,
      animType: AnimType.scale,
      title: title,
      desc: desc,
      btnOkText: okText,
      btnOkOnPress: onOk ?? () {},
    ).show();
  }

  void _sweetConfirm({
    required String title,
    required String desc,
    required String okText,
    required String cancelText,
    required VoidCallback onOk,
  }) {
    if (!mounted) return;

    AwesomeDialog(
      context: context,
      dialogType: DialogType.question,
      animType: AnimType.scale,
      title: title,
      desc: desc,
      btnOkText: okText,
      btnCancelText: cancelText,
      btnCancelOnPress: () {},
      btnOkOnPress: onOk,
    ).show();
  }

  Future<void> _loadDoctorHeader() async {
    try {
      final uid = _uid;
      if (uid == null) return;

      final doc =
      await FirebaseFirestore.instance.collection("users").doc(uid).get();

      final data = doc.data() ?? {};

      final first = (data["firstName"] ?? "").toString().trim();
      final name = first.isNotEmpty ? first : "Doctor";
      final img = (data["profileImagePath"] ?? "").toString().trim();

      if (!mounted) return;

      setState(() {
        _name = name;
        _profileUrl = img;
      });
    } catch (_) {}
  }

  ImageProvider _avatarProvider() {
    if (_profileUrl.trim().isNotEmpty) {
      return NetworkImage(_profileUrl);
    }

    return const AssetImage("assets/images/profileblue.png");
  }

  void _goTo(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  void _logoutConfirm() {
    final t = AppLocalizations.of(context);

    if (_logoutDialogOpen) return;
    _logoutDialogOpen = true;

    _sweetConfirm(
      title: t?.logout ?? "Logout",
      desc: t?.logoutConfirmDesc ?? "Are you sure you want to logout?",
      okText: t?.yes ?? "Yes",
      cancelText: t?.no ?? "No",
      onOk: () async {
        try {
          await FirebaseAuth.instance.signOut();

          if (!mounted) return;

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const Login()),
                (route) => false,
          );
        } catch (e) {
          _sweet(
            type: DialogType.error,
            title: t?.logoutFailed ?? "Logout Failed",
            desc: e.toString(),
            okText: t?.ok ?? "OK",
          );
        } finally {
          _logoutDialogOpen = false;
        }
      },
    );

    Future.delayed(const Duration(milliseconds: 600), () {
      _logoutDialogOpen = false;
    });
  }

  DocumentReference<Map<String, dynamic>> _readRef({
    required String uid,
    required String announcementId,
  }) {
    return FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("announcement_reads")
        .doc(announcementId);
  }

  Future<void> _setAnnouncementReadStatus({
    required String uid,
    required String announcementId,
    required bool isRead,
  }) async {
    final t = AppLocalizations.of(context);

    try {
      await _readRef(uid: uid, announcementId: announcementId).set({
        "isRead": isRead,
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      _sweet(
        type: DialogType.success,
        title: isRead ? "Marked as Read" : "Marked as Unread",
        desc: isRead
            ? "Announcement marked as read."
            : "Announcement marked as unread.",
        okText: t?.ok ?? "OK",
      );
    } catch (e) {
      if (!mounted) return;

      _sweet(
        type: DialogType.error,
        title: t?.error ?? "Error",
        desc: "Failed to update announcement: $e",
        okText: t?.ok ?? "OK",
      );
    }
  }

  Future<void> _toggleAnnouncementStatus({
    required String uid,
    required String announcementId,
    required bool currentIsRead,
  }) async {
    await _setAnnouncementReadStatus(
      uid: uid,
      announcementId: announcementId,
      isRead: !currentIsRead,
    );
  }

  Future<void> _readAll(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
      ) async {
    final t = AppLocalizations.of(context);
    final uid = _uid;

    if (uid == null) return;

    try {
      final batch = FirebaseFirestore.instance.batch();

      for (final doc in docs) {
        final ref = _readRef(uid: uid, announcementId: doc.id);

        batch.set(
          ref,
          {
            "isRead": true,
            "updatedAt": FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      await batch.commit();

      if (!mounted) return;

      _sweet(
        type: DialogType.success,
        title: "Announcements Marked As Read",
        desc: "All announcements have been marked as read.",
        okText: t?.ok ?? "OK",
      );
    } catch (e) {
      if (!mounted) return;

      _sweet(
        type: DialogType.error,
        title: t?.error ?? "Error",
        desc: "Failed to mark all announcements as read: $e",
        okText: t?.ok ?? "OK",
      );
    }
  }

  Widget _swipeHintCard() {
    return AnimatedBuilder(
      animation: _hintAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_hintAnimation.value, 0),
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: DoctorAnnouncements.blue.withOpacity(0.07),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: DoctorAnnouncements.blue.withOpacity(0.45),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.swipe,
                  color: DoctorAnnouncements.blue,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Swipe right or left to toggle Read / Unread",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                      color: DoctorAnnouncements.blue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _announcementCard({
    required String uid,
    required QueryDocumentSnapshot<Map<String, dynamic>> doc,
    required int index,
  }) {
    final t = AppLocalizations.of(context);

    final data = doc.data();
    final msg = (data["message"] ?? "").toString().trim();
    final audience = (data["audience"] ?? "").toString().trim();

    final title = audience.isEmpty
        ? (t?.announcement ?? "Announcement")
        : "${t?.forAudiencePrefix ?? "For:"} $audience";

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _readRef(uid: uid, announcementId: doc.id).snapshots(),
      builder: (context, readSnap) {
        final readData = readSnap.data?.data() ?? {};
        final isRead = readData["isRead"] == true;

        final actionText = isRead ? "Mark Unread" : "Mark Read";
        final actionIcon =
        isRead ? Icons.mark_email_unread : Icons.done_all;
        final actionColor = isRead ? Colors.orange : Colors.green;

        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 300 + (index * 45)),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Opacity(
              opacity: value.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0, 18 * (1 - value)),
                child: child,
              ),
            );
          },
          child: Dismissible(
            key: ValueKey(doc.id),
            direction: DismissDirection.horizontal,

            background: Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 22),
              decoration: BoxDecoration(
                color: actionColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(actionIcon, color: Colors.white, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    actionText,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            secondaryBackground: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 22),
              decoration: BoxDecoration(
                color: actionColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    actionText,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(actionIcon, color: Colors.white, size: 28),
                ],
              ),
            ),

            confirmDismiss: (direction) async {
              await _toggleAnnouncementStatus(
                uid: uid,
                announcementId: doc.id,
                currentIsRead: isRead,
              );

              return false;
            },

            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isRead
                      ? Colors.grey.shade300
                      : DoctorAnnouncements.blue,
                  width: 2,
                ),
                color: isRead
                    ? Colors.white
                    : DoctorAnnouncements.blue.withOpacity(0.05),
                boxShadow: [
                  if (!isRead)
                    BoxShadow(
                      color: DoctorAnnouncements.blue.withOpacity(0.16),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      isRead ? Icons.mark_email_read : Icons.campaign,
                      key: ValueKey(isRead),
                      color: isRead
                          ? Colors.grey
                          : DoctorAnnouncements.blue,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontWeight:
                            isRead ? FontWeight.w600 : FontWeight.w800,
                            fontSize: 12.5,
                            color: isRead
                                ? Colors.black54
                                : DoctorAnnouncements.blue,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          msg.isEmpty
                              ? (t?.announcement ?? "Announcement")
                              : msg,
                          style: GoogleFonts.poppins(
                            fontWeight:
                            isRead ? FontWeight.w500 : FontWeight.w700,
                            fontSize: 13,
                            color: isRead ? Colors.black54 : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _drawerButton({
    required Widget icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: DoctorAnnouncements.blue,
          padding: const EdgeInsets.symmetric(vertical: 17),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            children: [
              icon,
              const SizedBox(width: 15),
              Text(
                text,
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final uid = _uid;

    if (uid == null) {
      return Scaffold(
        body: Center(
          child: Text(
            t?.doctorNotLoggedIn ?? "Doctor not logged in",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: _logoutConfirm,
            icon: const Icon(Icons.logout, size: 30, color: Colors.black),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const SizedBox(height: 20),
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _avatarProvider(),
              ),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.center,
              child: Text(
                _name,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 27,
                  color: DoctorAnnouncements.blue,
                ),
              ),
            ),
            const SizedBox(height: 15),
            _drawerButton(
              icon: const Icon(Icons.settings, color: Colors.white, size: 20),
              text: t?.settings ?? "Settings",
              onTap: () => _goTo(const DoctorSettings()),
            ),
            _drawerButton(
              icon: Image.asset("assets/images/smileface.png", width: 24),
              text: t?.feedback ?? "Feedback",
              onTap: () => _goTo(const DoctorFeedBack()),
            ),
            _drawerButton(
              icon: const Icon(
                Icons.folder_open,
                color: Colors.white,
                size: 20,
              ),
              text: t?.manageUploads ?? "Manage Uploads",
              onTap: () => _goTo(const ManageUploads()),
            ),
            _drawerButton(
              icon: const Icon(Icons.logout, color: Colors.white, size: 20),
              text: t?.logout ?? "Logout",
              onTap: _logoutConfirm,
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            children: [
              Image.asset(
                "assets/images/announcments.png",
                width: 373,
                height: 249,
              ),
              const SizedBox(height: 10),
              Text(
                t?.announcements ?? "Announcements",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 27,
                  color: DoctorAnnouncements.blue,
                ),
              ),
              const SizedBox(height: 18),

              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection("announcements")
                    .where("audience", whereIn: const ["Doctor", "Both"])
                    .snapshots(),
                builder: (context, snapshot) {
                  final docs = snapshot.data?.docs ?? [];

                  if (snapshot.connectionState == ConnectionState.waiting &&
                      docs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 30),
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (docs.isEmpty) {
                    if (snapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 50),
                        child: Text(
                          "${t?.failedToLoadAnnouncements ?? "Failed to load announcements."}\n${snapshot.error}",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.only(top: 80),
                      child: Text(
                        t?.noAnnouncementYet ?? "No announcement yet!",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: DoctorAnnouncements.blue,
                        ),
                      ),
                    );
                  }

                  docs.sort((a, b) {
                    final ta = a.data()["createdAt"];
                    final tb = b.data()["createdAt"];

                    final aTs = ta is Timestamp ? ta : null;
                    final bTs = tb is Timestamp ? tb : null;

                    if (aTs == null && bTs == null) return 0;
                    if (aTs == null) return 1;
                    if (bTs == null) return -1;

                    return bTs.compareTo(aTs);
                  });

                  return Column(
                    children: [
                      _swipeHintCard(),

                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: () => _readAll(docs),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: DoctorAnnouncements.blue,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          child: Text(
                            t?.readAll ?? "Read All",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      if (snapshot.hasError)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: DoctorAnnouncements.blue.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color:
                              DoctorAnnouncements.blue.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            t?.showingCachedAnnouncements ??
                                "Showing latest loaded announcements.",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 12.5,
                              color: DoctorAnnouncements.blue,
                            ),
                          ),
                        ),

                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: docs.length,
                        separatorBuilder: (_, __) =>
                        const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          return _announcementCard(
                            uid: uid,
                            doc: docs[i],
                            index: i,
                          );
                        },
                      ),
                    ],
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