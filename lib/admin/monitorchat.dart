import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project/admin/adminrootpage.dart';
import 'package:project/admin/monitor_chat_view.dart';
import 'package:project/l10n/app_localizations.dart';

class MonitorChats extends StatelessWidget {
  const MonitorChats({super.key});

  static const Color green = Color(0xff00EFAB);

  int _updatedAtMillis(Map<String, dynamic> d) {
    final ts = d['updatedAt'];
    if (ts is Timestamp) return ts.millisecondsSinceEpoch;
    return 0;
  }

  /// ✅ deterministic chatId (Option A)
  String _deterministicChatId(String doctorId, String patientId) {
    return "${doctorId}_$patientId";
  }

  /// ✅ Find the chat doc that actually contains messages.
  /// 1) Try deterministic
  /// 2) If empty, try to find old auto-id chat for same doctor+patient
  Future<String> _resolveChatIdWithMessages({
    required String doctorId,
    required String patientId,
  }) async {
    final fs = FirebaseFirestore.instance;

    final detId = _deterministicChatId(doctorId, patientId);
    final detMsgSnap = await fs
        .collection("chats")
        .doc(detId)
        .collection("messages")
        .limit(1)
        .get();

    if (detMsgSnap.docs.isNotEmpty) {
      return detId;
    }

    // fallback: look for any old chat doc between same doctor+patient
    final qs = await fs
        .collection("chats")
        .where("doctorId", isEqualTo: doctorId)
        .where("patientId", isEqualTo: patientId)
        .get();

    if (qs.docs.isEmpty) {
      // nothing found, return deterministic anyway
      return detId;
    }

    // Prefer the one with messages OR the newest updatedAt
    String bestId = detId;
    int bestUpdated = -1;

    for (final doc in qs.docs) {
      final id = doc.id;

      // check if it has messages
      final ms = await fs.collection("chats").doc(id).collection("messages").limit(1).get();
      if (ms.docs.isNotEmpty) {
        return id; // ✅ first chat with messages wins
      }

      final data = doc.data();
      final u = _updatedAtMillis(data);
      if (u > bestUpdated) {
        bestUpdated = u;
        bestId = id;
      }
    }

    return bestId;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    // ✅ ONLY connected chats
    final chatsStream = FirebaseFirestore.instance
        .collection('chats')
        .where('isActive', isEqualTo: true)
        .snapshots();

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
              t.appTitle,
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
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
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
                        icon: const Icon(Icons.arrow_back_ios_new,
                            color: green, size: 18),
                        tooltip: t.back,
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const AdminRootPage()),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Image.asset("assets/images/monitorchat.png",
                      width: 373, height: 249),
                  const SizedBox(height: 10),
                  Text(
                    t.monitorChatsTitle,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w800,
                      fontSize: 27,
                      color: green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t.monitorChatsSubtitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

            // List
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: green, width: 2),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                        color: Colors.black.withOpacity(0.06),
                      )
                    ],
                  ),
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: chatsStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            "${t.errorLabel}: ${snapshot.error}",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting &&
                          !snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final docs = (snapshot.data?.docs ?? []).toList();

                      // ✅ local sort by updatedAt DESC
                      docs.sort((a, b) => _updatedAtMillis(b.data())
                          .compareTo(_updatedAtMillis(a.data())));

                      if (docs.isEmpty) {
                        return Center(
                          child: Text(
                            t.noChatYet,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: green,
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                        itemCount: docs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final d = docs[index].data();
                          final activeChatDocId = docs[index].id;

                          final patientName =
                          (d['patientName'] ?? t.patientFallback).toString();
                          final patientEmail =
                          (d['patientEmail'] ?? '').toString();

                          final doctorName =
                          (d['doctorName'] ?? t.doctorFallback).toString();
                          final doctorEmail =
                          (d['doctorEmail'] ?? '').toString();

                          final lastMessage =
                          (d['lastMessage'] ?? '').toString().trim();

                          final doctorId = (d['doctorId'] ?? '').toString();
                          final patientId = (d['patientId'] ?? '').toString();

                          return _ChatTile(
                            green: green,
                            chatId: activeChatDocId,
                            patientName: patientName,
                            patientEmail: patientEmail,
                            doctorName: doctorName,
                            doctorEmail: doctorEmail,
                            lastMessage: lastMessage,
                            onMonitor: () async {
                              if (doctorId.isEmpty || patientId.isEmpty) {
                                // fallback open same doc id
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MonitorChatView(
                                      chatId: activeChatDocId,
                                      patientName: patientName,
                                      doctorName: doctorName,
                                    ),
                                  ),
                                );
                                return;
                              }

                              final realChatId =
                              await _resolveChatIdWithMessages(
                                doctorId: doctorId,
                                patientId: patientId,
                              );

                              if (!context.mounted) return;

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MonitorChatView(
                                    chatId: realChatId,
                                    patientName: patientName,
                                    doctorName: doctorName,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  const _ChatTile({
    required this.green,
    required this.chatId,
    required this.patientName,
    required this.patientEmail,
    required this.doctorName,
    required this.doctorEmail,
    required this.lastMessage,
    required this.onMonitor,
  });

  final Color green;
  final String chatId;
  final String patientName;
  final String patientEmail;
  final String doctorName;
  final String doctorEmail;
  final String lastMessage;
  final VoidCallback onMonitor;

  Widget _chip({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color green,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: green.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: green.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: green.withOpacity(0.18),
            ),
            child: Icon(icon, color: green, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      color: Colors.black54,
                    ),
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

    return Material(
      elevation: 0,
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              blurRadius: 18,
              offset: const Offset(0, 6),
              color: Colors.black.withOpacity(0.06),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: green.withOpacity(0.16),
                  ),
                  child: Icon(Icons.forum, color: green, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    t.chatRoom,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: green.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: green.withOpacity(0.35)),
                  ),
                  child: Text(
                    t.active,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      color: green,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _chip(
              icon: Icons.person,
              title: "${t.patientLabel}: $patientName",
              subtitle: patientEmail,
              green: green,
            ),
            const SizedBox(height: 10),
            _chip(
              icon: Icons.medical_services,
              title: "${t.doctorLabel}: $doctorName",
              subtitle: doctorEmail,
              green: green,
            ),
            if (lastMessage.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  lastMessage,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: onMonitor,
                icon: const Icon(Icons.visibility, size: 18, color: Colors.white),
                label: Text(
                  t.monitor,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: green,
                  elevation: 0,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}