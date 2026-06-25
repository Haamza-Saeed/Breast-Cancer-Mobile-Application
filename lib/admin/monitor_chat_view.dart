import 'dart:convert';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project/admin/adminrootpage.dart';
import 'package:project/services/supabase_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

import 'package:project/l10n/app_localizations.dart';

class MonitorChatView extends StatelessWidget {
  const MonitorChatView({
    super.key,
    required this.chatId,
    required this.patientName,
    required this.doctorName,
  });

  final String chatId;
  final String patientName;
  final String doctorName;

  static const Color green = Color(0xff00EFAB);

  // ------------------------- URL HELPERS -------------------------

  Uri? _parseUri(String url) {
    final u = url.trim();
    if (u.isEmpty) return null;
    return Uri.tryParse(u);
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    final t = AppLocalizations.of(context)!;

    final uri = _parseUri(url);
    if (uri == null) {
      _showErrorDialog(
        context,
        title: t.invalidUrlTitle,
        desc: "${t.invalidUrlDesc}\n\n$url",
      );
      return;
    }

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      _showErrorDialog(
        context,
        title: t.couldNotOpenFileTitle,
        desc: "${t.couldNotOpenFileDesc}\n\n$uri",
      );
    }
  }

  // Convert old signed url -> public url if possible (bucket is public)
  String _fixFileUrl(String rawUrl) {
    return SupabaseService.instance.tryConvertSignedToPublic(rawUrl);
  }

  // ------------------------- ERROR DIALOG -------------------------

  void _showErrorDialog(
      BuildContext context, {
        required String title,
        required String desc,
      }) {
    final t = AppLocalizations.of(context)!;

    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      animType: AnimType.scale,
      title: title,
      desc: desc,
      descTextStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
      titleTextStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w800),
      btnOkOnPress: () {},
      btnOkText: t.ok,
    ).show();
  }

  Future<void> _showNetworkDebugDialog(BuildContext context, String url) async {
    final t = AppLocalizations.of(context)!;

    final uri = _parseUri(url);
    if (uri == null) {
      _showErrorDialog(
        context,
        title: t.invalidUrlTitle,
        desc: "${t.urlEmptyOrMalformedDesc}\n\n$url",
      );
      return;
    }

    try {
      final resp = await http.get(uri);
      final headers =
      resp.headers.entries.map((e) => "${e.key}: ${e.value}").join("\n");
      final bodyPreview = resp.body.length > 700 ? resp.body.substring(0, 700) : resp.body;

      final info = StringBuffer()
        ..writeln(t.flutterErrorLabel)
        ..writeln("${t.httpStatusCodeLabel} ${resp.statusCode}")
        ..writeln(uri.toString())
        ..writeln("\n=== URL INFO ===")
        ..writeln("scheme: ${uri.scheme}")
        ..writeln("host:   ${uri.host}")
        ..writeln("path:   ${uri.path}")
        ..writeln("query:  ${uri.hasQuery ? t.present : t.none}")
        ..writeln("\n=== HTTP CHECK ===")
        ..writeln("${t.statusLabel} ${resp.statusCode}")
        ..writeln("${t.redirectsLabel} 0")
        ..writeln("\n=== HEADERS ===")
        ..writeln(headers)
        ..writeln("\n=== BODY (${t.first700CharsLabel}) ===")
        ..writeln(bodyPreview);

      _showErrorDialog(
        context,
        title: t.imageFailedTitle,
        desc: info.toString(),
      );
    } catch (e) {
      _showErrorDialog(
        context,
        title: t.imageFailedTitle,
        desc: "${t.requestErrorDesc}\n$e\n\n${t.urlLabel}\n$uri",
      );
    }
  }

  // ------------------------- IMAGE PREVIEW -------------------------

  void _openImagePreview(BuildContext context, String rawUrl) {
    final t = AppLocalizations.of(context)!;
    final url = _fixFileUrl(rawUrl);

    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              Positioned.fill(
                child: InteractiveViewer(
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            t.failedToLoadImageDesc,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () => _showNetworkDebugDialog(context, url),
                              child: Text(
                                t.showErrorDetails,
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
                  ),
                ),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------- MESSAGE BUBBLE -------------------------

  Widget _bubble(BuildContext context, Map<String, dynamic> m) {
    final t = AppLocalizations.of(context)!;

    final senderRole = (m['senderRole'] ?? '').toString();
    final isDoctor = senderRole == "doctor";

    final type = (m['type'] ?? 'text').toString();
    final text = (m['text'] ?? '').toString();
    final rawFileUrl = (m['fileUrl'] ?? '').toString();
    final fileName = (m['fileName'] ?? '').toString();

    final fileUrl = _fixFileUrl(rawFileUrl);

    final bg = isDoctor ? green : Colors.grey.shade200;
    final fg = isDoctor ? Colors.white : Colors.black87;

    Widget child;

    if (type == "image" && fileUrl.isNotEmpty) {
      child = InkWell(
        onTap: () => _openImagePreview(context, rawFileUrl),
        onLongPress: () => _showNetworkDebugDialog(context, fileUrl),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.network(
            fileUrl,
            width: 210,
            height: 210,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.failedToLoadImageShort,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _showNetworkDebugDialog(context, fileUrl),
                    child: Text(
                      t.showErrorDetails,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else if (type == "pdf" && fileUrl.isNotEmpty) {
      child = InkWell(
        onTap: () => _openUrl(context, fileUrl),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.picture_as_pdf, color: fg),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                fileName.isEmpty ? t.pdfDocument : fileName,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                  color: fg,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      child = Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      );
    }

    return Align(
      alignment: isDoctor ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              blurRadius: 12,
              offset: const Offset(0, 6),
              color: Colors.black.withOpacity(0.06),
            ),
          ],
        ),
        child: child,
      ),
    );
  }

  // ------------------------- BUILD -------------------------

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    final messagesStream = FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
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
                fontWeight: FontWeight.w800,
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
            SizedBox(
              height: 220,
              child: SingleChildScrollView(
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
                            icon: const Icon(Icons.arrow_back_ios_new,
                                color: green, size: 18),
                            tooltip: t.back,
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => const AdminRootPage()),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Info card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: green, width: 2),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                              color: Colors.black.withOpacity(0.06),
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: green.withOpacity(0.15),
                                  ),
                                  child: const Icon(Icons.visibility,
                                      color: green, size: 20),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    t.monitoringModeTitle,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: green.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(color: green.withOpacity(0.35)),
                                  ),
                                  child: Text(
                                    t.readOnly,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 11,
                                      color: green,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            Row(
                              children: [
                                const Icon(Icons.person, color: green, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "${t.patientLabel}: $patientName",
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.medical_services, color: green, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "${t.doctorLabel}: $doctorName",
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              t.monitorTipLongPress,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.black54,
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

            // Messages
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
                        offset: const Offset(0, 8),
                        color: Colors.black.withOpacity(0.06),
                      )
                    ],
                  ),
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: messagesStream,
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

                      final docs = snapshot.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return Center(
                          child: Text(
                            t.noMessagesYet,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              color: green,
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        reverse: true,
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final m = docs[index].data();
                          return _bubble(context, m);
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