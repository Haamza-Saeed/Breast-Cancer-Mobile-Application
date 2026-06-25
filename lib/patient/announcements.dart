import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Settings;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project/login.dart';
import 'package:project/l10n/app_localizations.dart';
import 'package:project/patient/aboutus.dart';
import 'package:project/patient/feedback.dart';
import 'package:project/patient/settings.dart' as app_settings;
import 'package:project/patient/view_media.dart';

class Announcements extends StatefulWidget {
  const Announcements({super.key});

  @override
  State<Announcements> createState() => _AnnouncementsState();
}

class _AnnouncementsState extends State<Announcements>
    with SingleTickerProviderStateMixin {
  static const Color pink = Color(0xffFF67CE);

  late AnimationController _hintController;
  late Animation<double> _hintAnimation;

  @override
  void initState() {
    super.initState();

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

  void _success(String message) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.success,
      animType: AnimType.scale,
      title: message,
      btnOkText: "OK",
      btnOkOnPress: () {},
    ).show();
  }

  void _error(String message) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      animType: AnimType.scale,
      title: "Error",
      desc: message,
      btnOkText: "OK",
      btnOkOnPress: () {},
    ).show();
  }

  void _logoutConfirm(BuildContext context) {
    final t = AppLocalizations.of(context);

    AwesomeDialog(
      context: context,
      dialogType: DialogType.question,
      animType: AnimType.scale,
      title: t?.logout ?? "Logout",
      desc: t?.logoutConfirm ?? "Do you really want to logout?",
      btnCancelText: t?.no ?? "No",
      btnOkText: t?.yes ?? "Yes",
      btnCancelOnPress: () {},
      btnOkOnPress: () async {
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const Login()),
              (route) => false,
        );
      },
    ).show();
  }

  ImageProvider _drawerAvatarProvider(String url) {
    final u = url.trim();
    if (u.isNotEmpty) return NetworkImage(u);
    return const AssetImage("assets/images/profilepink.png");
  }

  Widget _drawerButton({
    IconData? icon,
    Widget? iconWidget,
    required String text,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: pink,
          padding: const EdgeInsets.symmetric(vertical: 17),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              iconWidget ?? Icon(icon, color: Colors.white, size: 20),
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
              color: pink.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: pink.withValues(alpha: 0.45), width: 1.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.swipe, color: pink, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Swipe right to mark read/unread • Swipe left to mark unread",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                      color: pink,
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

  Future<void> _setAnnouncementReadStatus({
    required String uid,
    required String announcementId,
    required bool isRead,
  }) async {
    final ref = FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("announcementReads")
        .doc(announcementId);

    if (isRead) {
      await ref.set({
        "isRead": true,
        "readAt": FieldValue.serverTimestamp(),
        "announcementId": announcementId,
      }, SetOptions(merge: true));
    } else {
      await ref.delete();
    }
  }

  Future<void> _toggleReadStatus({
    required String uid,
    required String announcementId,
    required bool isRead,
  }) async {
    try {
      await _setAnnouncementReadStatus(
        uid: uid,
        announcementId: announcementId,
        isRead: !isRead,
      );

      if (!mounted) return;

      _success(
        isRead
            ? "Announcement Marked As Unread!"
            : "Announcement Marked As Read!",
      );
    } catch (e) {
      if (!mounted) return;
      _error("Failed to update announcement: $e");
    }
  }

  Future<void> _markUnread({
    required String uid,
    required String announcementId,
  }) async {
    try {
      await _setAnnouncementReadStatus(
        uid: uid,
        announcementId: announcementId,
        isRead: false,
      );

      if (!mounted) return;
      _success("Announcement Marked As Unread!");
    } catch (e) {
      if (!mounted) return;
      _error("Failed to mark unread: $e");
    }
  }

  Future<void> _readAllAnnouncements({
    required String uid,
    required AppLocalizations t,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> allAnnouncementDocs,
    required Set<String> readIds,
  }) async {
    try {
      final unreadDocs =
      allAnnouncementDocs.where((d) => !readIds.contains(d.id)).toList();

      if (unreadDocs.isEmpty) {
        _success("All announcements are already read.");
        return;
      }

      final batch = FirebaseFirestore.instance.batch();

      final readsCol = FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("announcementReads");

      for (final doc in unreadDocs) {
        batch.set(
          readsCol.doc(doc.id),
          {
            "isRead": true,
            "readAt": FieldValue.serverTimestamp(),
            "announcementId": doc.id,
          },
          SetOptions(merge: true),
        );
      }

      await batch.commit();

      if (!mounted) return;
      _success("Announcements Marked As Read!");
    } catch (e) {
      if (!mounted) return;
      _error("Failed to mark announcements as read: $e");
    }
  }

  Widget _announcementCard({
    required AppLocalizations t,
    required String uid,
    required String announcementId,
    required Map<String, dynamic> data,
    required bool isRead,
    required int index,
  }) {
    final msg = (data["message"] ?? "").toString().trim();
    final audience = (data["audience"] ?? "").toString().trim();

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
        key: ValueKey(announcementId),
        direction: DismissDirection.horizontal,
        background: Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          decoration: BoxDecoration(
            color: isRead ? Colors.orange : Colors.green,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(
                isRead ? Icons.mark_email_unread : Icons.done_all,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                isRead ? "Mark Unread" : "Mark Read",
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
            color: Colors.orange,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                "Mark Unread",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.mark_email_unread, color: Colors.white, size: 28),
            ],
          ),
        ),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            await _toggleReadStatus(
              uid: uid,
              announcementId: announcementId,
              isRead: isRead,
            );
            return false;
          }

          if (direction == DismissDirection.endToStart) {
            await _markUnread(
              uid: uid,
              announcementId: announcementId,
            );
            return false;
          }

          return false;
        },
        child: GestureDetector(
          onTap: () async {
            if (!isRead) {
              await _setAnnouncementReadStatus(
                uid: uid,
                announcementId: announcementId,
                isRead: true,
              );
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isRead ? Colors.grey.shade300 : pink,
                width: 2,
              ),
              color: isRead ? Colors.white : pink.withValues(alpha: 0.04),
              boxShadow: [
                if (!isRead)
                  BoxShadow(
                    color: pink.withValues(alpha: 0.16),
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
                    color: isRead ? Colors.grey : pink,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        audience.isEmpty
                            ? t.announcements
                            : t.forAudience(audience),
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                          color: isRead ? Colors.black54 : pink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        msg.isEmpty ? t.noAnnouncementYet : msg,
                        style: GoogleFonts.poppins(
                          fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return Scaffold(
        body: Center(child: Text(t.userNotLoggedIn)),
      );
    }

    final userDoc = FirebaseFirestore.instance.collection("users").doc(uid);

    final announcementsStream = FirebaseFirestore.instance
        .collection("announcements")
        .where("audience", whereIn: const ["Patient", "Both"])
        .snapshots();

    final readsStream = FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("announcementReads")
        .where("isRead", isEqualTo: true)
        .snapshots();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: userDoc.snapshots(),
      builder: (context, userSnap) {
        final u = userSnap.data?.data() ?? {};
        final firstName = (u["firstName"] ?? "").toString().trim();
        final name = firstName.isNotEmpty ? firstName : t.user;
        final imgUrl = (u["profileImagePath"] ?? "").toString().trim();

        return Scaffold(
          appBar: AppBar(
            actions: [
              IconButton(
                onPressed: () => _logoutConfirm(context),
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
                    backgroundImage: _drawerAvatarProvider(imgUrl),
                  ),
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    name,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 27,
                      color: pink,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                _drawerButton(
                  icon: Icons.settings,
                  text: t.settings,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const app_settings.Settings(),
                      ),
                    );
                  },
                ),
                _drawerButton(
                  iconWidget: Image.asset("assets/images/smileface.png", width: 24),
                  text: t.feedbackTitle,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FeedBack()),
                    );
                  },
                ),
                _drawerButton(
                  icon: Icons.perm_media,
                  text: t.viewMedia,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ViewMedia()),
                    );
                  },
                ),
                _drawerButton(
                  iconWidget: Image.asset("assets/images/info.png", width: 24),
                  text: t.aboutUs,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AboutUs()),
                    );
                  },
                ),
                _drawerButton(
                  icon: Icons.logout,
                  text: t.logout,
                  onTap: () => _logoutConfirm(context),
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
                    t.announcements,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 27,
                      color: pink,
                    ),
                  ),
                  const SizedBox(height: 12),

                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: announcementsStream,
                    builder: (context, annSnap) {
                      final announcementDocs = annSnap.data?.docs ?? [];

                      announcementDocs.sort((a, b) {
                        final ta = a.data()["createdAt"];
                        final tb = b.data()["createdAt"];
                        final aTs = ta is Timestamp ? ta : null;
                        final bTs = tb is Timestamp ? tb : null;

                        if (aTs == null && bTs == null) return 0;
                        if (aTs == null) return 1;
                        if (bTs == null) return -1;

                        return bTs.compareTo(aTs);
                      });

                      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: readsStream,
                        builder: (context, readSnap) {
                          final readDocs = readSnap.data?.docs ?? [];
                          final readIds = readDocs.map((d) => d.id).toSet();

                          final unreadCount = announcementDocs
                              .where((d) => !readIds.contains(d.id))
                              .length;

                          return Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: pink, width: 2),
                                ),
                                child: Text(
                                  "${t.unreadLabel}: $unreadCount",
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700,
                                    color: pink,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              ElevatedButton(
                                onPressed: unreadCount == 0
                                    ? null
                                    : () => _readAllAnnouncements(
                                  uid: uid,
                                  t: t,
                                  allAnnouncementDocs: announcementDocs,
                                  readIds: readIds,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: pink,
                                  disabledBackgroundColor: Colors.grey.shade300,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                                child: Text(
                                  t.readAll,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700,
                                    color: unreadCount == 0
                                        ? Colors.black45
                                        : Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  _swipeHintCard(),

                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: announcementsStream,
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
                              "${t.failedToLoadAnnouncements}\n${snapshot.error}",
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
                            t.noAnnouncementYet,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: pink,
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

                      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: readsStream,
                        builder: (context, readSnap) {
                          final readDocs = readSnap.data?.docs ?? [];
                          final readIds = readDocs.map((d) => d.id).toSet();

                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: docs.length,
                            separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                            itemBuilder: (context, i) {
                              final id = docs[i].id;
                              final data = docs[i].data();
                              final isRead = readIds.contains(id);

                              return _announcementCard(
                                t: t,
                                uid: uid,
                                announcementId: id,
                                data: data,
                                isRead: isRead,
                                index: i,
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
      },
    );
  }
}