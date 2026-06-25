import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project/l10n/app_localizations.dart';
import 'package:project/patient/announcements.dart';
import 'package:project/patient/homepage.dart';
import 'package:project/patient/notifications.dart';
import 'package:project/patient/profile.dart';

// ✅ locale controller
import 'package:project/services/locale_controller.dart';

class RootPage extends StatefulWidget {
  final int initialIndex;
  const RootPage({super.key, this.initialIndex = 0});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  static const Color pink = Color(0xffFF67CE);

  late int selectedIndex;

  String? _lastAppliedLanguageCode;

  bool _patientProfileIncomplete(Map<String, dynamic> data) {
    final marital = (data["maritalStatus"] ?? "").toString().trim();
    final anyMed = (data["anyMedication"] ?? "").toString().trim();
    final cancerFam = (data["cancerInFamily"] ?? "").toString().trim();
    return marital.isEmpty || anyMed.isEmpty || cancerFam.isEmpty;
  }

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialIndex;
  }

  final List<Widget> screenList = const [
    Homepage(),
    Announcements(),
    PatientProfile(),
    Notifications(),
  ];

  Widget _badgeIcon({
    required Widget icon,
    required int count,
    bool showExclamation = false,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        icon,
        if (showExclamation)
          const Positioned(
            right: -2,
            top: -6,
            child: CircleAvatar(
              radius: 7,
              backgroundColor: Colors.red,
              child: Text(
                "!",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        if (count > 0)
          Positioned(
            right: -6,
            top: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              constraints: const BoxConstraints(minWidth: 18),
              child: Center(
                child: Text(
                  count > 99 ? "99+" : "$count",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Stream<int> _unreadNotificationsCountStream(String uid) {
    return FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("notifications")
        .where("isRead", isEqualTo: false)
        .snapshots()
        .map((s) => s.docs.length);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return Scaffold(
        body: Center(child: Text(t?.pleaseLoginFirst ?? "Please login first.")),
      );
    }

    final userDocStream =
    FirebaseFirestore.instance.collection("users").doc(uid).snapshots();

    final unreadNotifStream = _unreadNotificationsCountStream(uid);

    // ✅ announcements and reads streams (to compute unread)
    final announcementsStream = FirebaseFirestore.instance
        .collection("announcements")
        .where("audience", whereIn: const ["Patient", "Both"])
        .snapshots();

    final announcementReadsStream = FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("announcementReads")
        .where("isRead", isEqualTo: true)
        .snapshots();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: userDocStream,
      builder: (context, userSnap) {
        if (userSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (userSnap.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  t?.failedToLoadReports != null
                      ? "${t!.failedToLoadReports} ${userSnap.error}"
                      : "Failed to load user data: ${userSnap.error}",
                ),
              ),
            ),
          );
        }

        final data = userSnap.data?.data() ?? {};
        final String languageCode = (data["languageCode"] ?? "en").toString();

        if (_lastAppliedLanguageCode != languageCode) {
          _lastAppliedLanguageCode = languageCode;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            LocaleController.setLocale(languageCode);
          });
        }

        final profileIncomplete = _patientProfileIncomplete(data);

        // ✅ Compute announcements unread using nested StreamBuilders (no extra packages)
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: announcementsStream,
          builder: (context, annSnap) {
            final annDocs = annSnap.data?.docs ?? [];
            final totalAnnouncements = annDocs.length;

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: announcementReadsStream,
              builder: (context, readSnap) {
                final readIds = (readSnap.data?.docs ?? []).map((d) => d.id).toSet();
                final announcementsUnread =
                (totalAnnouncements - readIds.length).clamp(0, totalAnnouncements);

                return StreamBuilder<int>(
                  stream: unreadNotifStream,
                  builder: (context, unreadSnap) {
                    final unreadNotif = unreadSnap.data ?? 0;

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
                                color: pink,
                              ),
                            ),
                          ),
                        ),
                      ),
                      body: IndexedStack(index: selectedIndex, children: screenList),
                      bottomNavigationBar: BottomNavigationBar(
                        type: BottomNavigationBarType.fixed,
                        backgroundColor: pink,
                        selectedItemColor: Colors.black,
                        unselectedItemColor: Colors.white,
                        showSelectedLabels: true,
                        showUnselectedLabels: true,
                        selectedFontSize: 15,
                        currentIndex: selectedIndex,
                        onTap: (val) => setState(() => selectedIndex = val),
                        items: [
                          BottomNavigationBarItem(
                            icon: const Icon(Icons.home),
                            label: t?.home ?? "Home",
                          ),

                          // ✅ Announcements badge added here
                          BottomNavigationBarItem(
                            icon: _badgeIcon(
                              icon: Image.asset(
                                "assets/images/megaphone.png",
                                width: 25,
                                height: 25,
                                color: Colors.white,
                              ),
                              count: announcementsUnread,
                            ),
                            activeIcon: _badgeIcon(
                              icon: Image.asset(
                                "assets/images/megaphone.png",
                                width: 25,
                                height: 25,
                                color: Colors.black,
                              ),
                              count: announcementsUnread,
                            ),
                            label: t?.announcements ?? "Announcements",
                          ),

                          BottomNavigationBarItem(
                            icon: _badgeIcon(
                              icon: Image.asset(
                                "assets/images/profilewhite.png",
                                width: 25,
                                height: 25,
                              ),
                              count: 0,
                              showExclamation: profileIncomplete,
                            ),
                            activeIcon: _badgeIcon(
                              icon: Image.asset(
                                "assets/images/profilewhite.png",
                                width: 25,
                                height: 25,
                                color: Colors.black,
                              ),
                              count: 0,
                              showExclamation: profileIncomplete,
                            ),
                            label: t?.profile ?? "Profile",
                          ),

                          BottomNavigationBarItem(
                            icon: _badgeIcon(
                              icon: const Icon(Icons.notifications),
                              count: unreadNotif,
                            ),
                            activeIcon: _badgeIcon(
                              icon: const Icon(Icons.notifications, color: Colors.black),
                              count: unreadNotif,
                            ),
                            label: t?.notifications ?? "Notifications",
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}