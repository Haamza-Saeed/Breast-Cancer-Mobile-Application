import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:project/admin/adminhomepage.dart';
import 'package:project/admin/adminmanageprofile.dart';
import 'package:project/admin/adminnotification.dart';
import 'package:project/admin/viewdoctors.dart';

// ✅ Localization
import 'package:project/l10n/app_localizations.dart';

class AdminRootPage extends StatefulWidget {
  const AdminRootPage({super.key});

  @override
  State<AdminRootPage> createState() => _AdminRootPageState();
}

class _AdminRootPageState extends State<AdminRootPage> {
  int selectedindex = 0;

  final List<Widget> screenList = const [
    AdminHomepage(),
    ViewDoctors(),
    AdminManageProfile(),
    AdminNotifications(),
  ];

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // ✅ Badge icon widget
  Widget _notifIconWithBadge(int unreadCount) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.notifications),
        if (unreadCount > 0)
          Positioned(
            right: -6,
            top: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Center(
                child: Text(
                  unreadCount > 99 ? "99+" : unreadCount.toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final uid = _uid;

    // If not logged in, just show without badge
    final unreadStream = uid == null
        ? const Stream<QuerySnapshot<Map<String, dynamic>>>.empty()
        : FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("notifications")
        .where("isRead", isEqualTo: false)
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: unreadStream,
      builder: (context, snap) {
        final unreadCount =
        (uid == null) ? 0 : (snap.hasData ? snap.data!.docs.length : 0);

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
                    color: const Color(0xff00EFAB),
                  ),
                ),
              ),
            ),
          ),
          body: screenList.elementAt(selectedindex),
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: const Color(0xff00EFAB),
            selectedItemColor: Colors.black,
            unselectedItemColor: Colors.white,
            showSelectedLabels: true,
            selectedFontSize: 15,
            onTap: (val) {
              setState(() => selectedindex = val);
            },
            currentIndex: selectedindex,
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.home),
                label: t?.home ?? 'Home',
              ),
              BottomNavigationBarItem(
                icon: Image.asset(
                  "assets/images/viewdoctors.png",
                  width: 25,
                  height: 25,
                ),
                label: t?.selectDoctor ?? 'View Doctor',
                // If you have a dedicated key like "viewDoctors",
                // replace the above with: t?.viewDoctors ?? 'View Doctor'
              ),
              BottomNavigationBarItem(
                icon: Image.asset(
                  "assets/images/profilewhite.png",
                  width: 25,
                  height: 25,
                ),
                label: t?.profile ?? 'Profile',
              ),
              BottomNavigationBarItem(
                icon: _notifIconWithBadge(unreadCount),
                label: t?.notifications ?? 'Notifications',
              ),
            ],
          ),
        );
      },
    );
  }
}