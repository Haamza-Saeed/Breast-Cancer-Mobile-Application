import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project/admin/adminfeedback.dart';
import 'package:project/admin/adminsettings.dart';
import 'package:project/login.dart';
import 'package:project/l10n/app_localizations.dart';

class AdminNotifications extends StatefulWidget {
  const AdminNotifications({super.key});

  @override
  State<AdminNotifications> createState() => _AdminNotificationsState();
}

class _AdminNotificationsState extends State<AdminNotifications>
    with SingleTickerProviderStateMixin {
  static const Color green = Color(0xff00EFAB);

  String _name = "Admin";
  String _profileUrl = "";

  bool _selectionMode = false;
  final Set<String> _selectedIds = {};

  late AnimationController _hintController;
  late Animation<double> _hintAnimation;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _loadAdminHeader();

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

  Future<void> _loadAdminHeader() async {
    try {
      final uid = _uid;
      if (uid == null) return;

      final doc =
      await FirebaseFirestore.instance.collection("users").doc(uid).get();

      final data = doc.data() ?? {};

      final first = (data["firstName"] ?? "").toString().trim();
      final last = (data["lastName"] ?? "").toString().trim();

      final name =
      (first.isNotEmpty || last.isNotEmpty) ? "$first $last".trim() : "Admin";

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
    return const AssetImage("assets/images/profilegreen.png");
  }

  void _success(String title, String desc) {
    if (!mounted) return;

    AwesomeDialog(
      context: context,
      dialogType: DialogType.success,
      animType: AnimType.scale,
      title: title,
      desc: desc,
      btnOkText: "OK",
      btnOkOnPress: () {},
    ).show();
  }

  void _info(String title, String desc) {
    if (!mounted) return;

    AwesomeDialog(
      context: context,
      dialogType: DialogType.info,
      animType: AnimType.scale,
      title: title,
      desc: desc,
      btnOkText: "OK",
      btnOkOnPress: () {},
    ).show();
  }

  void _error(String desc) {
    if (!mounted) return;

    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      animType: AnimType.scale,
      title: "Error",
      desc: desc,
      btnOkText: "OK",
      btnOkOnPress: () {},
    ).show();
  }

  void _confirm({
    required String title,
    required String desc,
    required String okText,
    required VoidCallback onOk,
  }) {
    if (!mounted) return;

    AwesomeDialog(
      context: context,
      dialogType: DialogType.question,
      animType: AnimType.scale,
      title: title,
      desc: desc,
      btnCancelText: "No",
      btnOkText: okText,
      btnCancelOnPress: () {},
      btnOkOnPress: onOk,
    ).show();
  }

  void _logoutConfirm(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    _confirm(
      title: t.logoutTitle,
      desc: t.logoutConfirmDesc,
      okText: t.yes,
      onOk: () async {
        await FirebaseAuth.instance.signOut();

        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const Login()),
              (route) => false,
        );
      },
    );
  }

  Future<void> _toggleReadStatus({
    required DocumentReference ref,
    required bool isRead,
  }) async {
    try {
      await ref.update({"isRead": !isRead});

      if (!mounted) return;

      _success(
        isRead ? "Marked As Unread" : "Marked As Read",
        isRead
            ? "Notification marked as unread successfully."
            : "Notification marked as read successfully.",
      );
    } catch (e) {
      if (!mounted) return;
      _error("Failed to update notification: $e");
    }
  }

  Future<void> _deleteNotification(DocumentReference ref) async {
    try {
      await ref.delete();

      if (!mounted) return;

      _success(
        "Notification Deleted",
        "Notification deleted successfully.",
      );
    } catch (e) {
      if (!mounted) return;
      _error("Failed to delete notification: $e");
    }
  }

  void _confirmDeleteNotification(DocumentReference ref) {
    _confirm(
      title: "Delete Notification",
      desc: "Are you sure you want to delete this notification?",
      okText: "Delete",
      onOk: () async {
        await _deleteNotification(ref);
      },
    );
  }

  Future<void> _deleteSelectedNotifications() async {
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

      _success(
        "Selected Notifications Deleted",
        "Selected notifications deleted successfully.",
      );
    } catch (e) {
      if (!mounted) return;
      _error("Failed to delete selected notifications: $e");
    }
  }

  void _confirmDeleteSelectedNotifications() {
    if (_selectedIds.isEmpty) return;

    _confirm(
      title: "Delete Selected Notifications",
      desc:
      "Are you sure you want to delete ${_selectedIds.length} selected notification(s)?",
      okText: "Delete",
      onOk: () async {
        await _deleteSelectedNotifications();
      },
    );
  }

  Future<void> _markAllAsRead() async {
    final uid = _uid;
    if (uid == null) return;

    try {
      final snap = await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("notifications")
          .where("isRead", isEqualTo: false)
          .get();

      if (snap.docs.isEmpty) {
        _info("Nothing New", "No unread notifications found.");
        return;
      }

      final batch = FirebaseFirestore.instance.batch();

      for (final d in snap.docs) {
        batch.update(d.reference, {"isRead": true});
      }

      await batch.commit();

      if (!mounted) return;

      _success(
        "Notifications Marked As Read",
        "All notifications have been marked as read.",
      );
    } catch (e) {
      if (!mounted) return;
      _error("Failed to mark all notifications as read: $e");
    }
  }

  Widget _drawerBtn({
    required Widget leading,
    required String text,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: green,
          padding: const EdgeInsets.symmetric(vertical: 17),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            children: [
              leading,
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
              color: green.withOpacity(0.07),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: green.withOpacity(0.45),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.swipe, color: green, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Swipe right to mark read/unread • Swipe left to delete",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                      color: green,
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
    required int index,
  }) {
    final data = doc.data();

    final msg = (data["message"] ?? "").toString().trim();
    final type = (data["type"] ?? "info").toString().trim();
    final isRead = (data["isRead"] ?? false) == true;
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
            );
            return false;
          }

          if (direction == DismissDirection.endToStart) {
            _confirmDeleteNotification(doc.reference);
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
                    : green,
                width: 2,
              ),
              color: selected
                  ? Colors.red.withOpacity(0.06)
                  : isRead
                  ? Colors.grey.shade100
                  : Colors.white,
              boxShadow: [
                if (!isRead)
                  BoxShadow(
                    color: green.withOpacity(0.16),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                      type == "profile" ? Icons.person : Icons.notifications,
                      key: ValueKey("$type-$isRead"),
                      color: isRead ? Colors.grey : green,
                    ),
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    msg.isEmpty ? "You have received a new notification." : msg,
                    style: GoogleFonts.poppins(
                      fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                      fontSize: 13,
                      color: isRead ? Colors.black54 : Colors.black87,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _confirmDeleteNotification(doc.reference),
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
    final t = AppLocalizations.of(context)!;
    final uid = _uid;

    return Scaffold(
      appBar: AppBar(
        title: _selectionMode
            ? Text(
          "${_selectedIds.length} Selected",
          style: GoogleFonts.poppins(
            color: green,
            fontWeight: FontWeight.w700,
          ),
        )
            : null,
        actions: [
          if (_selectionMode)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 30),
              onPressed: _confirmDeleteSelectedNotifications,
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
              tooltip: t.logoutTitle,
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
                  color: green,
                ),
              ),
            ),
            const SizedBox(height: 15),
            _drawerBtn(
              leading: const Icon(Icons.settings, color: Colors.white, size: 20),
              text: t.settings,
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminSettings()),
                );
                _loadAdminHeader();
              },
            ),
            _drawerBtn(
              leading: Image.asset("assets/images/smileface.png", width: 24),
              text: t.feedbackResponses,
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminFeedback()),
                );
                _loadAdminHeader();
              },
            ),
            _drawerBtn(
              leading: const Icon(Icons.logout, color: Colors.white, size: 20),
              text: t.logoutTitle,
              onPressed: () => _logoutConfirm(context),
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
                t.notificationsTitle,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 27,
                  color: green,
                ),
              ),
              const SizedBox(height: 14),

              _swipeHintCard(),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _markAllAsRead,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    t.readAll,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

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

              if (uid == null)
                Padding(
                  padding: const EdgeInsets.only(top: 80),
                  child: Text(
                    t.adminNotLoggedIn,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: green,
                    ),
                  ),
                )
              else
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection("users")
                      .doc(uid)
                      .collection("notifications")
                      .orderBy("createdAt", descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 50),
                        child: Text(
                          t.failedLoadNotifications,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            color: Colors.red,
                          ),
                        ),
                      );
                    }

                    if (!snapshot.hasData) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 30),
                        child: CircularProgressIndicator(),
                      );
                    }

                    final docs = snapshot.data!.docs;

                    if (docs.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 60),
                        child: Text(
                          t.noNotificationsYet,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: green,
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        return _notificationCard(
                          doc: docs[i],
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
  }
}