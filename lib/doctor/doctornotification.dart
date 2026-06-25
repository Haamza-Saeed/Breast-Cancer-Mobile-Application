import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project/doctor/doctorrootpage.dart';
import 'package:project/login.dart';

// Drawer pages
import 'doctorfeedback.dart';
import 'doctorsettings.dart';
import 'manage_uploads.dart';

// Localization
import 'package:project/l10n/app_localizations.dart';

class DoctorNotifications extends StatefulWidget {
  const DoctorNotifications({super.key});

  @override
  State<DoctorNotifications> createState() => _DoctorNotificationsState();
}

class _DoctorNotificationsState extends State<DoctorNotifications>
    with SingleTickerProviderStateMixin {
  static const Color blue = Color(0xff00AEEF);

  bool _logoutDialogOpen = false;
  bool _selectionMode = false;
  final Set<String> _selectedIds = {};

  String _name = "Doctor";
  String _profileUrl = "";

  late AnimationController _hintController;
  late Animation<double> _hintAnimation;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _loadDrawerHeader();

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

  Future<void> _loadDrawerHeader() async {
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
    if (_profileUrl.trim().isNotEmpty) return NetworkImage(_profileUrl);
    return const AssetImage("assets/images/profileblue.png");
  }

  void _goTo(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  void _successDialog(AppLocalizations? t, String msg) {
    if (!mounted) return;
    AwesomeDialog(
      context: context,
      dialogType: DialogType.success,
      animType: AnimType.scale,
      title: t?.success ?? "Success",
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
      title: t?.error ?? "Error",
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
      title: t?.info ?? "Info",
      desc: msg,
      btnOkText: t?.ok ?? "OK",
      btnOkOnPress: () {},
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

  void _logoutConfirm(AppLocalizations? t) {
    if (_logoutDialogOpen) return;
    _logoutDialogOpen = true;

    _sweetConfirm(
      title: t?.logout ?? "Logout",
      desc: t?.logoutConfirm ?? "Are you sure you want to logout?",
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
          _errorDialog(t, "${t?.logoutFailed ?? "Logout failed"}: $e");
        } finally {
          _logoutDialogOpen = false;
        }
      },
    );

    Future.delayed(const Duration(milliseconds: 600), () {
      _logoutDialogOpen = false;
    });
  }

  bool _isProfileIncomplete(Map<String, dynamic> data) {
    final exp = data["experience"];
    final specialization = (data["specialization"] ?? "").toString().trim();
    final qualification = (data["qualification"] ?? "").toString().trim();
    final description = (data["description"] ?? "").toString().trim();

    final expMissing = exp == null || (exp is num && exp.toInt() <= 0);

    return expMissing ||
        specialization.isEmpty ||
        qualification.isEmpty ||
        description.isEmpty;
  }

  Future<void> _toggleReadStatus({
    required DocumentReference ref,
    required bool isRead,
    required AppLocalizations? t,
  }) async {
    try {
      await ref.update({"isRead": !isRead});

      if (!mounted) return;
      _successDialog(
        t,
        isRead
            ? "Notification marked as unread."
            : "Notification marked as read.",
      );
    } catch (e) {
      if (!mounted) return;
      _errorDialog(t, "Failed to update notification: $e");
    }
  }

  Future<void> _deleteNotificationDirect({
    required DocumentReference ref,
    required AppLocalizations? t,
  }) async {
    try {
      await ref.delete();

      if (!mounted) return;
      _successDialog(t, "Notification deleted successfully.");
    } catch (e) {
      if (!mounted) return;
      _errorDialog(t, "Failed to delete notification: $e");
    }
  }

  void _confirmDeleteNotification({
    required DocumentReference ref,
    required AppLocalizations? t,
  }) {
    _sweetConfirm(
      title: "Delete Notification",
      desc: "Are you sure you want to delete this notification?",
      okText: "Delete",
      cancelText: t?.no ?? "Cancel",
      onOk: () async {
        await _deleteNotificationDirect(ref: ref, t: t);
      },
    );
  }

  void _confirmDeleteSelectedNotifications(AppLocalizations? t) {
    if (_selectedIds.isEmpty) return;

    _sweetConfirm(
      title: "Delete Selected Notifications",
      desc:
      "Are you sure you want to delete ${_selectedIds.length} selected notification(s)?",
      okText: "Delete",
      cancelText: t?.no ?? "Cancel",
      onOk: () async {
        await _deleteSelectedNotifications(t);
      },
    );
  }

  Future<void> _deleteSelectedNotifications(AppLocalizations? t) async {
    if (_selectedIds.isEmpty) return;

    final uid = _uid;
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

      _successDialog(t, "Selected notifications deleted successfully.");
    } catch (e) {
      if (!mounted) return;
      _errorDialog(t, "Failed to delete selected notifications: $e");
    }
  }

  Future<void> _readAll(AppLocalizations? t, String uid) async {
    try {
      final unreadSnap = await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("notifications")
          .where("isRead", isEqualTo: false)
          .get();

      if (unreadSnap.docs.isEmpty) {
        _infoDialog(
          t,
          t?.noUnreadNotifications ?? "No unread notifications found.",
        );
        return;
      }

      final batch = FirebaseFirestore.instance.batch();

      for (final d in unreadSnap.docs) {
        batch.update(d.reference, {"isRead": true});
      }

      await batch.commit();

      _successDialog(
        t,
        t?.allNotificationsRead ?? "All notifications marked as read.",
      );
    } catch (e) {
      _errorDialog(t, "${t?.failed ?? "Failed"}: $e");
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
              color: blue.withOpacity(0.07),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: blue.withOpacity(0.45), width: 1.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.swipe, color: blue, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Swipe right to mark read/unread • Swipe left to delete",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                      color: blue,
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
            await _toggleReadStatus(
              ref: doc.reference,
              isRead: isRead,
              t: t,
            );
            return false;
          }

          if (direction == DismissDirection.endToStart) {
            _confirmDeleteNotification(ref: doc.reference, t: t);
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
                    : blue,
                width: 2,
              ),
              color: selected
                  ? Colors.red.withOpacity(0.06)
                  : isRead
                  ? Colors.white
                  : blue.withOpacity(0.05),
              boxShadow: [
                if (!isRead)
                  BoxShadow(
                    color: blue.withOpacity(0.16),
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
                      color: isRead ? Colors.grey : blue,
                    ),
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    msg.isEmpty
                        ? (t?.newAnnouncement ??
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
                  onPressed: () {
                    _confirmDeleteNotification(ref: doc.reference, t: t);
                  },
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
    final uid = _uid;

    if (uid == null) {
      return Scaffold(
        body: Center(
          child: Text(
            t?.doctorNotLoggedIn ?? "Doctor not logged in!",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    final userRef = FirebaseFirestore.instance.collection("users").doc(uid);

    final unreadStream = userRef
        .collection("notifications")
        .where("isRead", isEqualTo: false)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: _selectionMode
            ? Text(
          "${_selectedIds.length} Selected",
          style: GoogleFonts.poppins(
            color: blue,
            fontWeight: FontWeight.w700,
          ),
        )
            : null,
        actions: [
          if (_selectionMode)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 30),
              onPressed: () => _confirmDeleteSelectedNotifications(t),
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
              onPressed: () => _logoutConfirm(t),
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
                  color: blue,
                ),
              ),
            ),
            const SizedBox(height: 15),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: ElevatedButton(
                onPressed: () => _goTo(const DoctorSettings()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: blue,
                  padding: const EdgeInsets.symmetric(vertical: 17),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    children: [
                      const Icon(Icons.settings, color: Colors.white, size: 20),
                      const SizedBox(width: 15),
                      Text(
                        t?.settings ?? "Settings",
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
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: ElevatedButton(
                onPressed: () => _goTo(const DoctorFeedBack()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: blue,
                  padding: const EdgeInsets.symmetric(vertical: 17),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    children: [
                      Image.asset("assets/images/smileface.png", width: 24),
                      const SizedBox(width: 15),
                      Text(
                        t?.feedbackTitle ?? "Feedback",
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
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: ElevatedButton(
                onPressed: () => _goTo(const ManageUploads()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: blue,
                  padding: const EdgeInsets.symmetric(vertical: 17),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.folder_open,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 15),
                      Text(
                        t?.manageUploads ?? "Manage Uploads",
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
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: ElevatedButton(
                onPressed: () => _logoutConfirm(t),
                style: ElevatedButton.styleFrom(
                  backgroundColor: blue,
                  padding: const EdgeInsets.symmetric(vertical: 17),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    children: [
                      const Icon(Icons.logout, color: Colors.white, size: 20),
                      const SizedBox(width: 15),
                      Text(
                        t?.logout ?? "Logout",
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
            ),
          ],
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: userRef.snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snap.data!.data() ?? {};
          final incomplete = _isProfileIncomplete(data);

          return SingleChildScrollView(
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
                    t?.doctorNotificationsTitle ?? "Doctor Notifications",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 27,
                      color: blue,
                    ),
                  ),
                  const SizedBox(height: 12),

                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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
                              border: Border.all(color: blue, width: 2),
                            ),
                            child: Text(
                              "${t?.unread ?? "Unread"}: $unreadCount",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                color: blue,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                          const Spacer(),
                          ElevatedButton(
                            onPressed: unreadCount == 0
                                ? () => _infoDialog(
                              t,
                              t?.noUnreadNotifications ??
                                  "No unread notifications found.",
                            )
                                : () => _readAll(t, uid),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: blue,
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
                                color: Colors.white,
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

                  if (incomplete)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: blue, width: 2),
                        color: blue.withOpacity(0.04),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t?.completeYourProfile ?? "Complete your profile",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: blue,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            t?.completeProfileDesc ??
                                "Add experience, specialization, qualification and description to complete your doctor profile.",
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
                                backgroundColor: blue,
                                padding:
                                const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              onPressed: () {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                    const DoctorRootPage(initialIndex: 2),
                                  ),
                                      (route) => false,
                                );
                              },
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
                    ),

                  const SizedBox(height: 14),

                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: userRef
                        .collection("notifications")
                        .orderBy("createdAt", descending: true)
                        .snapshots(),
                    builder: (context, ns) {
                      if (!ns.hasData) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 30),
                          child: CircularProgressIndicator(),
                        );
                      }

                      final docs = ns.data!.docs;

                      if (docs.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 130),
                          child: Center(
                            child: Text(
                              t?.noNotificationYet ?? "No notification yet!",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: blue,
                              ),
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
          );
        },
      ),
    );
  }
}