// lib/patient/chatwithdoctor.dart
import 'dart:typed_data';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

import 'package:project/l10n/app_localizations.dart';
import 'package:project/patient/doctorprofile.dart';
import 'package:project/services/supabase_service.dart';

class ChatWithDoctor extends StatefulWidget {
  const ChatWithDoctor({super.key});

  @override
  State<ChatWithDoctor> createState() => _ChatWithDoctorState();
}

class _ChatWithDoctorState extends State<ChatWithDoctor> {
  static const Color pink = Color(0xffFF67CE);

  final TextEditingController _msgController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  bool _loading = true;
  bool _sending = false;
  bool _uploading = false;

  QueryDocumentSnapshot<Map<String, dynamic>>? _approvedRequest;

  String? _doctorId;
  String _doctorName = "Doctor";
  String _doctorEmail = "";
  String _doctorImage = "";
  String _doctorDescription = "";

  String get _patientId => FirebaseAuth.instance.currentUser?.uid ?? "";
  String get _chatId => _approvedRequest?.id ?? "";

  @override
  void initState() {
    super.initState();
    _loadLatestApprovedDoctorAndChatId();
  }

  @override
  void dispose() {
    _msgController.dispose();
    super.dispose();
  }

  // ------------------ URL / DEBUG HELPERS ------------------

  String _fixUrl(String raw) {
    return SupabaseService.instance.tryConvertSignedToPublic(raw);
  }

  Uri? _safeUri(String raw) {
    final u = raw.trim();
    if (u.isEmpty) return null;
    return Uri.tryParse(u);
  }

  void _showDebugDialog({
    required String title,
    required String desc,
    DialogType type = DialogType.error,
  }) {
    if (!mounted) return;
    final t = AppLocalizations.of(context);

    AwesomeDialog(
      context: context,
      dialogType: type,
      animType: AnimType.scale,
      title: title,
      desc: desc,
      btnOkOnPress: () {},
      btnOkText: t?.ok ?? "OK",
    ).show();
  }

  Future<void> _showNetworkDebug(String rawUrl) async {
    final t = AppLocalizations.of(context);
    final fixedUrl = _fixUrl(rawUrl);
    final uri = _safeUri(fixedUrl);
    if (uri == null) {
      _showDebugDialog(
        title: t?.invalidUrlTitle ?? "Invalid URL",
        desc:
        "${t?.rawLabel ?? "raw:"}\n$rawUrl\n\n${t?.fixedLabel ?? "fixed:"}\n$fixedUrl",
      );
      return;
    }

    try {
      final resp = await http.get(uri);
      final headers =
      resp.headers.entries.map((e) => "${e.key}: ${e.value}").join("\n");

      final bodyPreview = resp.body.isEmpty
          ? "(empty body)"
          : (resp.body.length > 900 ? resp.body.substring(0, 900) : resp.body);

      final msg = [
        "${t?.httpStatusLabel ?? "HTTP Status:"} ${resp.statusCode}",
        "",
        "${t?.urlLabel ?? "URL:"}",
        uri.toString(),
        "",
        "${t?.headersLabel ?? "Headers:"}",
        headers.isEmpty ? "(no headers)" : headers,
        "",
        "${t?.bodyPreviewLabel ?? "Body Preview:"}",
        bodyPreview,
      ].join("\n");

      _showDebugDialog(
        title: t?.fileLoadDebugTitle ?? "File Load Debug",
        desc: msg,
      );
    } catch (e) {
      _showDebugDialog(
        title: t?.requestFailedTitle ?? "Request Failed",
        desc: "${t?.urlLabel ?? "URL:"}\n$uri\n\n${t?.errorTitle ?? "Error"}:\n$e",
      );
    }
  }

  // ------------------ UI HELPERS ------------------

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: GoogleFonts.poppins())),
    );
  }

  Future<void> _openUrl(String rawUrl) async {
    final t = AppLocalizations.of(context);
    final fixedUrl = _fixUrl(rawUrl);
    final uri = _safeUri(fixedUrl);
    if (uri == null) {
      _snack(t?.invalidFileUrl ?? "Invalid file URL");
      return;
    }

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      _showDebugDialog(
        title: t?.couldNotOpenFileTitle ?? "Could not open file",
        desc: uri.toString(),
      );
    }
  }

  void _openImagePreview(String rawUrl) {
    final t = AppLocalizations.of(context);
    final fixedUrl = _fixUrl(rawUrl);
    if (fixedUrl.trim().isEmpty) return;

    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            InteractiveViewer(
              child: Image.network(
                fixedUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        t?.failedToLoadImage ?? "Failed to load image.",
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        t?.tapBelowToSeeWhy ??
                            "Tap below to see why (HTTP details).",
                        style: GoogleFonts.poppins(fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => _showNetworkDebug(rawUrl),
                        style: ElevatedButton.styleFrom(backgroundColor: pink),
                        child: Text(
                          t?.showErrorDetails ?? "Show Error Details",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
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
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fullNameFromUserDoc(
      Map<String, dynamic> d, {
        required String fallback,
      }) {
    final fn = (d['firstName'] ?? '').toString().trim();
    final ln = (d['lastName'] ?? '').toString().trim();
    final name = "$fn $ln".trim();
    return name.isEmpty ? fallback : name;
  }

  // ------------------ LOAD APPROVED DOCTOR ------------------

  Future<void> _loadLatestApprovedDoctorAndChatId() async {
    setState(() => _loading = true);

    if (_patientId.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      final reqSnap = await FirebaseFirestore.instance
          .collection('chatRequests')
          .where('patientId', isEqualTo: _patientId)
          .where('status', isEqualTo: 'approved')
          .get();

      if (reqSnap.docs.isEmpty) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      QueryDocumentSnapshot<Map<String, dynamic>> latest = reqSnap.docs.first;
      DateTime latestTime = DateTime.fromMillisecondsSinceEpoch(0);

      for (final doc in reqSnap.docs) {
        final ts = doc.data()['createdAt'];
        DateTime dt = DateTime.fromMillisecondsSinceEpoch(0);
        if (ts is Timestamp) dt = ts.toDate();
        if (dt.isAfter(latestTime)) {
          latestTime = dt;
          latest = doc;
        }
      }

      final req = latest.data();
      final doctorId = (req['doctorId'] ?? '').toString().trim();
      if (doctorId.isEmpty) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      final doctorDoc =
      await FirebaseFirestore.instance.collection('users').doc(doctorId).get();
      final d = doctorDoc.data();
      if (d == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      if (!mounted) return;
      setState(() {
        _approvedRequest = latest;
        _doctorId = doctorId;

        _doctorName = _fullNameFromUserDoc(
          d,
          fallback: AppLocalizations.of(context)?.doctor ?? "Doctor",
        );

        _doctorEmail = (d['email'] ?? '').toString().trim();
        _doctorImage = (d['profileImagePath'] ?? '').toString().trim();
        _doctorDescription = (d['description'] ?? '').toString().trim();
        _loading = false;
      });

      await _ensureChatDoc();
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      // ignore: avoid_print
      print("LOAD DOCTOR FAILED: $e");
    }
  }

  Future<void> _ensureChatDoc() async {
    if (_chatId.isEmpty || _doctorId == null || _patientId.isEmpty) return;

    final patientDoc =
    await FirebaseFirestore.instance.collection('users').doc(_patientId).get();
    final p = patientDoc.data() ?? {};

    final t = AppLocalizations.of(context);

    final patientName = _fullNameFromUserDoc(
      p,
      fallback: t?.user ?? "Patient",
    );

    final patientEmail =
    (p['email'] ?? FirebaseAuth.instance.currentUser?.email ?? '')
        .toString()
        .trim();

    final chatRef = FirebaseFirestore.instance.collection('chats').doc(_chatId);

    await chatRef.set({
      "chatId": _chatId,
      "doctorId": _doctorId,
      "doctorName": _doctorName,
      "doctorEmail": _doctorEmail,
      "patientId": _patientId,
      "patientName": patientName,
      "patientEmail": patientEmail,
      "updatedAt": FieldValue.serverTimestamp(),
      "createdAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ------------------ SEND TEXT ------------------

  Future<void> _sendText() async {
    final t = AppLocalizations.of(context)!;
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    if (_chatId.isEmpty || _doctorId == null) {
      _snack(t.noApprovedDoctorFound);
      return;
    }

    if (_sending || _uploading) return;

    setState(() => _sending = true);

    try {
      _msgController.clear();

      final chatRef = FirebaseFirestore.instance.collection('chats').doc(_chatId);

      await chatRef.collection('messages').add({
        "senderId": _patientId,
        "senderRole": "patient",
        "type": "text",
        "text": text,
        "fileUrl": "",
        "fileName": "",
        "mimeType": "",
        "createdAt": FieldValue.serverTimestamp(),
      });

      await chatRef.set({
        "lastMessage": text,
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      _showDebugDialog(title: t.sendFailedTitle, desc: e.toString());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  // ------------------ PICK + SEND IMAGE/PDF ------------------

  Future<void> _pickAndSendImage({required ImageSource source}) async {
    final t = AppLocalizations.of(context)!;

    if (_chatId.isEmpty || _doctorId == null) {
      _snack(t.noChatAvailableYet);
      return;
    }
    if (_sending || _uploading) return;

    final XFile? file = await _picker.pickImage(source: source, imageQuality: 95);
    if (file == null) return;

    final bytes = await file.readAsBytes();
    final fileName = (file.name.isNotEmpty) ? file.name : "image.jpg";
    final mime =
    fileName.toLowerCase().endsWith(".png") ? "image/png" : "image/jpeg";

    await _uploadAndSendFile(
      bytes: bytes,
      fileName: fileName,
      mimeType: mime,
      messageType: "image",
    );
  }

  Future<void> _pickAndSendPdf() async {
    final t = AppLocalizations.of(context)!;

    if (_chatId.isEmpty || _doctorId == null) {
      _snack(t.noChatAvailableYet);
      return;
    }
    if (_sending || _uploading) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ["pdf"],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;
    final f = result.files.first;

    final bytes = f.bytes;
    if (bytes == null) {
      _showDebugDialog(title: t.pdfErrorTitle, desc: t.unableToReadPdfBytes);
      return;
    }

    await _uploadAndSendFile(
      bytes: bytes,
      fileName: f.name.isEmpty ? "document.pdf" : f.name,
      mimeType: "application/pdf",
      messageType: "pdf",
    );
  }

  Future<void> _uploadAndSendFile({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    required String messageType,
  }) async {
    setState(() => _uploading = true);

    try {
      final url = await SupabaseService.instance.uploadChatFileViaEdge(
        firebaseUid: _patientId,
        chatId: _chatId,
        bytes: bytes,
        fileName: fileName,
        mimeType: mimeType,
      );

      final fixedUrl = _fixUrl(url);

      final chatRef = FirebaseFirestore.instance.collection('chats').doc(_chatId);

      await chatRef.collection('messages').add({
        "senderId": _patientId,
        "senderRole": "patient",
        "type": messageType,
        "text": "",
        "fileUrl": fixedUrl,
        "fileName": fileName,
        "mimeType": mimeType,
        "createdAt": FieldValue.serverTimestamp(),
      });

      await chatRef.set({
        "lastMessage": messageType == "image" ? "📷 Image" : "📄 PDF",
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e, st) {
      final t = AppLocalizations.of(context)!;
      _showDebugDialog(
        title: t.uploadFailedTitle,
        desc: "${t.errorTitle}:\n$e\n\n${t.stackLabel}:\n$st",
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  // ------------------ MESSAGE BUBBLE ------------------

  Widget _bubble(Map<String, dynamic> m) {
    final t = AppLocalizations.of(context)!;

    final senderId = (m['senderId'] ?? '').toString();
    final mine = senderId == _patientId;

    final type = (m['type'] ?? 'text').toString();
    final text = (m['text'] ?? '').toString();
    final rawFileUrl = (m['fileUrl'] ?? '').toString();
    final fileUrl = _fixUrl(rawFileUrl);
    final fileName = (m['fileName'] ?? '').toString();

    Widget child;

    if (type == "image" && fileUrl.isNotEmpty) {
      child = InkWell(
        onTap: () => _openImagePreview(rawFileUrl),
        onLongPress: () => _showNetworkDebug(rawFileUrl),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            fileUrl,
            width: 200,
            height: 200,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  t.failedToLoadImageNoPeriod,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: mine ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  t.holdToDebug,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: mine ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else if (type == "pdf" && fileUrl.isNotEmpty) {
      child = InkWell(
        onTap: () => _openUrl(rawFileUrl),
        onLongPress: () => _showNetworkDebug(rawFileUrl),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.picture_as_pdf, color: mine ? Colors.white : pink),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                fileName.isEmpty ? t.pdfDocument : fileName,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                  color: mine ? Colors.white : Colors.black87,
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
          fontWeight: FontWeight.w500,
          color: mine ? Colors.white : Colors.black87,
        ),
      );
    }

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: mine ? pink : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(14),
        ),
        child: child,
      ),
    );
  }

  // ------------------ DOCTOR HEADER (SAME DESIGN AS BEFORE) ------------------

  Widget _doctorHeaderSameAsBefore(AppLocalizations t) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_doctorId == null) {
      return Padding(
        padding: const EdgeInsets.only(top: 35, bottom: 10),
        child: Text(
          t.noApprovedDoctorFound,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: pink,
          ),
        ),
      );
    }

    return Column(
      children: [
        Center(
          child: CircleAvatar(
            radius: 52,
            backgroundColor: Colors.transparent,
            backgroundImage: _doctorImage.isNotEmpty
                ? NetworkImage(_doctorImage)
                : const AssetImage("assets/images/profilepink.png")
            as ImageProvider,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _doctorName,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 23,
            fontWeight: FontWeight.w700,
            color: pink,
          ),
        ),
        const SizedBox(height: 6),
        if (_doctorEmail.isNotEmpty)
          Text(
            _doctorEmail,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: pink,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        const SizedBox(height: 8),
        Text(
          t.connectedMessage,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: pink,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DoctorProfile(doctorId: _doctorId!),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: pink,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: Text(
            t.viewProfile,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  // ------------------ BUILD ------------------

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    // ✅ use ascending so we can show header at top normally
    final messagesStream = (_chatId.isEmpty)
        ? null
        : FirebaseFirestore.instance
        .collection('chats')
        .doc(_chatId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots();

    return Scaffold(
      resizeToAvoidBottomInset: true, // ✅ IMPORTANT: let scaffold resize on keyboard
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
                color: pink,
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // back button (same style)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: pink, width: 2),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: pink, size: 18),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ),

            // ✅ ONE big chat box (header + messages scroll together)
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: pink, width: 2),
                ),
                child: (_doctorId == null || _chatId.isEmpty)
                    ? Center(
                  child: Text(
                    t.noChatYet,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      color: pink,
                    ),
                  ),
                )
                    : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: messagesStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          "${t.chatErrorLabel} ${snapshot.error}",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: Colors.red,
                          ),
                        ),
                      );
                    }

                    if (snapshot.connectionState ==
                        ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final docs = snapshot.data?.docs ?? [];

                    return ListView.builder(
                      keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                      itemCount: docs.length + 2, // ✅ header + divider + messages
                      itemBuilder: (context, index) {
                        // 0 = header
                        if (index == 0) {
                          return _doctorHeaderSameAsBefore(t); // ✅ same design
                        }
                        // 1 = divider
                        if (index == 1) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Divider(
                              color: pink.withOpacity(0.30),
                              thickness: 1,
                            ),
                          );
                        }

                        // messages
                        final m = docs[index - 2].data();
                        return _bubble(m);
                      },
                    );
                  },
                ),
              ),
            ),

            // ✅ Input bar (no manual viewInsets padding needed now)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _msgController,
                        minLines: 1,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: t.typeMessage,
                          suffixIcon: PopupMenuButton<String>(
                            icon: const Icon(Icons.attach_file,
                                color: Colors.black87),
                            onSelected: (v) async {
                              if (v == "gallery") {
                                await _pickAndSendImage(
                                    source: ImageSource.gallery);
                              } else if (v == "camera") {
                                await _pickAndSendImage(
                                    source: ImageSource.camera);
                              } else if (v == "pdf") {
                                await _pickAndSendPdf();
                              }
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: "gallery",
                                child: Text(t.imageGallery,
                                    style: GoogleFonts.poppins()),
                              ),
                              PopupMenuItem(
                                value: "camera",
                                child: Text(t.imageCamera,
                                    style: GoogleFonts.poppins()),
                              ),
                              PopupMenuItem(
                                value: "pdf",
                                child: Text(t.pdf, style: GoogleFonts.poppins()),
                              ),
                            ],
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: pink, width: 2),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: pink, width: 2),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: pink, width: 2),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: (_sending || _uploading) ? null : _sendText,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: pink,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: (_sending || _uploading)
                            ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : Text(
                          t.send,
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
          ],
        ),
      ),
    );
  }
}