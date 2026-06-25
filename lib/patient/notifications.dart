import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project/login.dart';
import 'package:project/patient/aboutus.dart';
import 'package:project/patient/feedback.dart';
import 'package:project/patient/settings.dart' as app_settings;
import 'package:project/patient/view_media.dart';
import 'package:project/l10n/app_localizations.dart';
import 'package:project/patient/rootpage.dart';

class Notifications extends StatefulWidget {
  const Notifications({super.key});

  @override
  State<Notifications> createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications>
    with SingleTickerProviderStateMixin {
  static const Color pink = Color(0xffFF67CE);

  bool _selectionMode = false;
  final Set<String> _selectedIds = {};

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

  bool _patientProfileIncomplete(Map<String, dynamic> data) {
    final marital = (data["maritalStatus"] ?? "").toString().trim();
    final anyMed = (data["anyMedication"] ?? "").toString().trim();
    final cancerFam = (data["cancerInFamily"] ?? "").toString().trim();
    return marital.isEmpty || anyMed.isEmpty || cancerFam.isEmpty;
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

  Future<void> _deleteNotification(DocumentReference ref) async {
    try {
      await ref.delete();
      if (!mounted) return;
      _success("Notification Deleted!");
    } catch (e) {
      if (!mounted) return;
      _error("Failed to delete notification: $e");
    }
  }

  Future<void> _toggleReadStatus({
    required DocumentReference ref,
    required bool isRead,
  }) async {
    try {
      await ref.update({"isRead": !isRead});

      if (!mounted) return;

      _success(
        isRead
            ? "Notification Marked As Unread!"
            : "Notification Marked As Read!",
      );
    } catch (e) {
      if (!mounted) return;
      _error("Failed to update notification: $e");
    }
  }

  Future<void> _deleteSelectedNotifications() async {
    if (_selectedIds.isEmpty) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final batch = FirebaseFirestore.instance.batch();

      for (final id in _selectedIds) {
        final ref = FirebaseFirestore.instance
            .collection("users")
            .doc(uid)
            .collection("notifications")
            .doc(id);

        batch.delete(ref);
      }

      await batch.commit();

      if (!mounted) return;
      setState(() {
        _selectedIds.clear();
        _selectionMode = false;
      });

      _success("Selected Notifications Deleted!");
    } catch (e) {
      if (!mounted) return;
      _error("Failed to delete selected notifications: $e");
    }
  }

  Future<void> _readAll(String uid) async {
    try {
      final unreadSnap = await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("notifications")
          .where("isRead", isEqualTo: false)
          .get();

      if (unreadSnap.docs.isEmpty) {
        if (!mounted) return;
        _success("No unread notifications found.");
        return;
      }

      final batch = FirebaseFirestore.instance.batch();

      for (final d in unreadSnap.docs) {
        batch.update(d.reference, {"isRead": true});
      }

      await batch.commit();

      if (!mounted) return;
      _success("Notifications Marked As Read!");
    } catch (e) {
      if (!mounted) return;
      _error("Failed: $e");
    }
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

  void _goToProfileTab() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const RootPage(initialIndex: 2)),
          (route) => false,
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
              color: pink.withOpacity(0.07),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: pink.withOpacity(0.45), width: 1.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.swipe, color: pink, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Swipe right to mark read/unread • Swipe left to delete",
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

  Widget _completeProfileCard(AppLocalizations? t) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: pink, width: 2),
        color: pink.withOpacity(0.04),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t?.completeYourProfile ?? "Complete your profile",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: pink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            t?.completeProfileDesc ??
                "Please complete: Marital Status, Any Medication, Cancer in Family.",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
              fontSize: 13,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: pink,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: _goToProfileTab,
              child: Text(
                t?.completeNow ?? "Complete Now",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _notificationCard({
    required QueryDocumentSnapshot<Map<String, dynamic>> doc,
    required AppLocalizations? t,
    required int index,
  }) {
    final d = doc.data();
    final msg = (d["message"] ?? "").toString().trim();
    final isRead = (d["isRead"] ?? false) == true;
    final selected = _selectedIds.contains(doc.id);

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
            color: Colors.red,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                "Delete",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.delete, color: Colors.white, size: 28),
            ],
          ),
        ),

        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            await _toggleReadStatus(ref: doc.reference, isRead: isRead);
            return false;
          }

          if (direction == DismissDirection.endToStart) {
            await _deleteNotification(doc.reference);
            return false;
          }

          return false;
        },

        child: GestureDetector(
          onLongPress: () {
            setState(() {
              _selectionMode = true;
              _selectedIds.add(doc.id);
            });
          },
          onTap: () async {
            if (_selectionMode) {
              setState(() {
                if (selected) {
                  _selectedIds.remove(doc.id);
                  if (_selectedIds.isEmpty) _selectionMode = false;
                } else {
                  _selectedIds.add(doc.id);
                }
              });
              return;
            }

            if (!isRead) {
              await doc.reference.update({"isRead": true});
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? Colors.red
                    : isRead
                    ? Colors.grey.shade300
                    : pink,
                width: 2,
              ),
              color: selected
                  ? Colors.red.withOpacity(0.06)
                  : isRead
                  ? Colors.white
                  : pink.withOpacity(0.05),
              boxShadow: [
                if (!isRead)
                  BoxShadow(
                    color: pink.withOpacity(0.16),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Row(
              children: [
                if (_selectionMode)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Icon(
                      selected ? Icons.check_circle : Icons.circle_outlined,
                      color: selected ? Colors.red : Colors.grey,
                    ),
                  )
                else
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      isRead ? Icons.mark_email_read : Icons.notifications,
                      key: ValueKey(isRead),
                      color: isRead ? Colors.grey : pink,
                    ),
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    msg.isEmpty
                        ? (t?.defaultNotificationMessage ??
                        "You have received a new notification.")
                        : msg,
                    style: GoogleFonts.poppins(
                      fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                      fontSize: 13,
                      color: isRead ? Colors.black54 : Colors.black87,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _deleteNotification(doc.reference),
                  icon: const Icon(Icons.delete, color: Colors.red),
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
    final t = AppLocalizations.of(context);
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return Scaffold(
        body: Center(
          child: Text(
            t?.userNotLoggedIn ?? "User not logged in",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: pink),
          ),
        ),
      );
    }

    final userDoc = FirebaseFirestore.instance.collection("users").doc(uid);

    final unreadStream = FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("notifications")
        .where("isRead", isEqualTo: false)
        .snapshots();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: userDoc.snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? {};
        final firstName = (data["firstName"] ?? "").toString().trim();
        final name = firstName.isNotEmpty ? firstName : (t?.user ?? "User");
        final imgUrl = (data["profileImagePath"] ?? "").toString().trim();
        final incomplete = _patientProfileIncomplete(data);

        return Scaffold(
          appBar: AppBar(
            title: _selectionMode
                ? Text(
              "${_selectedIds.length} Selected",
              style: GoogleFonts.poppins(
                color: pink,
                fontWeight: FontWeight.w700,
              ),
            )
                : null,
            actions: [
              if (_selectionMode)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 30),
                  onPressed: _deleteSelectedNotifications,
                ),
              if (_selectionMode)
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.black, size: 30),
                  onPressed: () {
                    setState(() {
                      _selectionMode = false;
                      _selectedIds.clear();
                    });
                  },
                ),
              if (!_selectionMode)
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
                  text: t?.settings ?? "Settings",
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
                  iconWidget:
                  Image.asset("assets/images/smileface.png", width: 24),
                  text: t?.feedbackTitle ?? t?.feedback ?? "Feedback",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FeedBack()),
                    );
                  },
                ),
                _drawerButton(
                  icon: Icons.perm_media,
                  text: t?.viewMedia ?? "View Media",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ViewMedia()),
                    );
                  },
                ),
                _drawerButton(
                  iconWidget: Image.asset("assets/images/info.png", width: 24),
                  text: t?.aboutUs ?? "About Us",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AboutUs()),
                    );
                  },
                ),
                _drawerButton(
                  icon: Icons.logout,
                  text: t?.logout ?? "Logout",
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
                    "assets/images/notification.png",
                    width: 373,
                    height: 249,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    t?.notifications ?? "Notifications",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 27,
                      color: pink,
                    ),
                  ),
                  const SizedBox(height: 12),

                  StreamBuilder<QuerySnapshot>(
                    stream: unreadStream,
                    builder: (context, unreadSnap) {
                      final unreadCount = unreadSnap.data?.docs.length ?? 0;

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
                              "${t?.unreadLabel ?? "Unread"}: $unreadCount",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                color: pink,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                          const Spacer(),
                          ElevatedButton(
                            onPressed:
                            unreadCount == 0 ? null : () => _readAll(uid),
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
                              t?.readAll ?? "Read All",
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
                  ),

                  const SizedBox(height: 16),

                  _swipeHintCard(),

                  if (_selectionMode)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.red, width: 1.5),
                      ),
                      child: Text(
                        "Tap notifications to select. Press delete icon above to remove selected notifications.",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                          fontSize: 12.5,
                        ),
                      ),
                    ),

                  if (incomplete) ...[
                    _completeProfileCard(t),
                    const SizedBox(height: 14),
                  ],

                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection("users")
                        .doc(uid)
                        .collection("notifications")
                        .orderBy("createdAt", descending: true)
                        .snapshots(),
                    builder: (context, snap) {
                      if (!snap.hasData) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 30),
                          child: CircularProgressIndicator(),
                        );
                      }

                      final docs = snap.data!.docs;

                      if (docs.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 80),
                          child: Text(
                            t?.noNotificationYet ?? "No notification yet!",
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
                          return _notificationCard(
                            doc: docs[i],
                            t: t,
                            index: i,
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