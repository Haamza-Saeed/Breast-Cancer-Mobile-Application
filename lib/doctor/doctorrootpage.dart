import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:project/doctor/doctorannouncements.dart';
import 'package:project/doctor/doctorhomepage.dart';
import 'package:project/doctor/doctormanageprofile.dart';
import 'package:project/doctor/doctornotification.dart';

import 'package:project/l10n/app_localizations.dart';
import 'package:project/services/locale_controller.dart';

class DoctorRootPage extends StatefulWidget {
  final int initialIndex;

  const DoctorRootPage({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<DoctorRootPage> createState() => _DoctorRootPageState();
}

class _DoctorRootPageState extends State<DoctorRootPage> {
  late int selectedindex;

  static const Color doctorBlue = Color(0xff00AEEF);

  String? _lastAppliedLang;

  @override
  void initState() {
    super.initState();
    selectedindex = widget.initialIndex;
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

  void _applyUserLocaleIfNeeded(String code) {
    final normalized = code == "ur" ? "ur" : "en";

    if (_lastAppliedLang == normalized) return;
    _lastAppliedLang = normalized;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      LocaleController.setLocale(normalized);
    });
  }

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
            right: -7,
            top: -7,
            child: CircleAvatar(
              radius: 8,
              backgroundColor: Colors.red,
              child: Text(
                "!",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        if (count > 0)
          Positioned(
            right: -8,
            top: -8,
            child: CircleAvatar(
              radius: 10,
              backgroundColor: Colors.red,
              child: Text(
                count > 9 ? "9+" : "$count",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Stream<int> _unreadNotificationsStream(String uid) {
    return FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("notifications")
        .where("isRead", isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  Stream<int> _unreadAnnouncementsStream(String uid) {
    final controller = StreamController<int>();

    QuerySnapshot<Map<String, dynamic>>? latestAnnouncements;
    QuerySnapshot<Map<String, dynamic>>? latestReads;

    void emitCount() {
      if (latestAnnouncements == null || latestReads == null) return;

      final announcementIds =
      latestAnnouncements!.docs.map((doc) => doc.id).toSet();

      final readIds = latestReads!.docs
          .where((doc) => doc.data()["isRead"] == true)
          .map((doc) => doc.id)
          .toSet();

      final unreadCount = announcementIds
          .where((announcementId) => !readIds.contains(announcementId))
          .length;

      if (!controller.isClosed) {
        controller.add(unreadCount);
      }
    }

    final annSub = FirebaseFirestore.instance
        .collection("announcements")
        .where("audience", whereIn: const ["Doctor", "Both"])
        .snapshots()
        .listen(
          (snap) {
        latestAnnouncements = snap;
        emitCount();
      },
      onError: controller.addError,
    );

    final readSub = FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("announcement_reads")
        .snapshots()
        .listen(
          (snap) {
        latestReads = snap;
        emitCount();
      },
      onError: controller.addError,
    );

    controller.onCancel = () async {
      await annSub.cancel();
      await readSub.cancel();
    };

    return controller.stream;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final uid = FirebaseAuth.instance.currentUser?.uid;

    final screens = const [
      DoctorHomepage(),
      DoctorAnnouncements(),
      DoctorManageProfile(),
      DoctorNotifications(),
    ];

    final userDocStream = uid == null
        ? const Stream<DocumentSnapshot<Map<String, dynamic>>>.empty()
        : FirebaseFirestore.instance.collection("users").doc(uid).snapshots();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: userDocStream,
      builder: (context, userSnap) {
        final data = userSnap.data?.data() ?? {};

        final languageCode = (data["languageCode"] ?? "en").toString();
        _applyUserLocaleIfNeeded(languageCode);

        final profileIncomplete = _isProfileIncomplete(data);

        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            elevation: 0,
            titleSpacing: 0,
            leading: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Image.asset(
                "assets/images/ribon.png",
                width: 24,
              ),
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
                    color: doctorBlue,
                  ),
                ),
              ),
            ),
          ),
          body: screens.elementAt(selectedindex),
          bottomNavigationBar: uid == null
              ? _buildBottomNav(
            t: t,
            profileIncomplete: profileIncomplete,
            notificationCount: 0,
            announcementCount: 0,
          )
              : StreamBuilder<int>(
            stream: _unreadNotificationsStream(uid),
            builder: (context, notificationSnap) {
              final notificationCount = notificationSnap.data ?? 0;

              return StreamBuilder<int>(
                stream: _unreadAnnouncementsStream(uid),
                builder: (context, announcementSnap) {
                  final announcementCount = announcementSnap.data ?? 0;

                  return _buildBottomNav(
                    t: t,
                    profileIncomplete: profileIncomplete,
                    notificationCount: notificationCount,
                    announcementCount: announcementCount,
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  BottomNavigationBar _buildBottomNav({
    required AppLocalizations? t,
    required bool profileIncomplete,
    required int notificationCount,
    required int announcementCount,
  }) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: doctorBlue,
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.white,
      showSelectedLabels: true,
      selectedFontSize: 15,
      currentIndex: selectedindex,
      onTap: (val) {
        setState(() {
          selectedindex = val;
        });
      },
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.home),
          label: t?.home ?? "Home",
        ),
        BottomNavigationBarItem(
          icon: _badgeIcon(
            icon: Image.asset(
              "assets/images/megaphone.png",
              width: 25,
              height: 25,
            ),
            count: announcementCount,
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
          label: t?.profile ?? "Profile",
        ),
        BottomNavigationBarItem(
          icon: _badgeIcon(
            icon: const Icon(Icons.notifications),
            count: notificationCount,
          ),
          label: t?.notifications ?? "Notifications",
        ),
      ],
    );
  }
}