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

import 'package:project/doctor/patientprofile.dart';
import 'package:project/services/supabase_service.dart';
import 'package:project/l10n/app_localizations.dart';

class ChatWithPatients extends StatefulWidget {
  // ✅ NEW: coming from ChatRoom "Chat Now"
  final String? patientId;
  final String? patientName;
  final String? patientEmail;

  const ChatWithPatients({
    super.key,
    this.patientId,
    this.patientName,
    this.patientEmail,
  });

  @override
  State<ChatWithPatients> createState() => _ChatWithPatientsState();
}

class _ChatWithPatientsState extends State<ChatWithPatients> {
  static const Color blue = Color(0xff00AEEF);

  final TextEditingController _msgController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  bool _sending = false;
  bool _uploading = false;

  // Approved requests list for this doctor
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _approvedRequests = [];
  bool _loadingRequests = true;

  // Selected request (contains patientId, patientName, etc.)
  QueryDocumentSnapshot<Map<String, dynamic>>? _selectedRequest;

  // Patient details fetched from users collection
  Map<String, dynamic>? _patient;
  bool _loadingPatient = false;

  String get _doctorId => FirebaseAuth.instance.currentUser?.uid ?? "";
  String get _chatId => _selectedRequest?.id ?? "";

  @override
  void initState() {
    super.initState();
    _loadApprovedRequests();
  }

  @override
  void dispose() {
    _msgController.dispose();
    super.dispose();
  }

  // -------------------- UI HELPERS --------------------

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: GoogleFonts.poppins())),
    );
  }

  void _showErrorDialog({
    required String title,
    required String desc,
    required String okText,
  }) {
    if (!mounted) return;
    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      animType: AnimType.scale,
      title: title,
      desc: desc,
      descTextStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
      titleTextStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w800),
      btnOkOnPress: () {},
      btnOkText: okText,
    ).show();
  }

  Uri? _parseUri(String url) {
    final u = url.trim();
    if (u.isEmpty) return null;
    return Uri.tryParse(u);
  }

  String _fixFileUrl(String rawUrl) {
    return SupabaseService.instance.tryConvertSignedToPublic(rawUrl);
  }

  Future<void> _openUrl(String url) async {
    final t = AppLocalizations.of(context);
    final fixed = _fixFileUrl(url);
    final uri = _parseUri(fixed);
    if (uri == null) {
      _showErrorDialog(
        title: t?.invalidUrlTitle ?? "Invalid URL",
        desc: "${t?.invalidUrlDesc ?? "URL is empty or malformed:"}\n\n$fixed",
        okText: t?.ok ?? "OK",
      );
      return;
    }

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) _snack(t?.couldNotOpenFile ?? "Could not open file.");
  }

  Future<void> _showNetworkDebugDialog(String url) async {
    final t = AppLocalizations.of(context);
    final fixed = _fixFileUrl(url);
    final uri = _parseUri(fixed);
    if (uri == null) {
      _showErrorDialog(
        title: t?.invalidUrlTitle ?? "Invalid URL",
        desc: "${t?.invalidUrlDesc ?? "URL is empty or malformed:"}\n\n$fixed",
        okText: t?.ok ?? "OK",
      );
      return;
    }

    try {
      final resp = await http.get(uri);
      final headers = resp.headers.entries.map((e) => "${e.key}: ${e.value}").join("\n");
      final bodyPreview = resp.body.length > 700 ? resp.body.substring(0, 700) : resp.body;

      final info = StringBuffer()
        ..writeln(t?.flutterErrorLabel ?? "Flutter error:")
        ..writeln("HTTP request failed, statusCode: ${resp.statusCode},\n$uri")
        ..writeln("\n=== URL INFO ===")
        ..writeln("scheme: ${uri.scheme}")
        ..writeln("host:   ${uri.host}")
        ..writeln("path:   ${uri.path}")
        ..writeln("query:  ${uri.hasQuery ? '(present)' : '(none)'}")
        ..writeln("\n=== HTTP CHECK ===")
        ..writeln("status: ${resp.statusCode}")
        ..writeln("\n=== HEADERS ===")
        ..writeln(headers)
        ..writeln("\n=== BODY (first 700 chars) ===")
        ..writeln(bodyPreview);

      _showErrorDialog(
        title: t?.imageFailedTitle ?? "Image Failed",
        desc: info.toString(),
        okText: t?.ok ?? "OK",
      );
    } catch (e) {
      _showErrorDialog(
        title: t?.imageFailedTitle ?? "Image Failed",
        desc: "${t?.requestErrorLabel ?? "Request error:"}\n$e\n\nURL:\n$uri",
        okText: t?.ok ?? "OK",
      );
    }
  }

  void _openImagePreview(String imageUrl) {
    final t = AppLocalizations.of(context);
    final fixed = _fixFileUrl(imageUrl);
    if (fixed.trim().isEmpty) return;

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
                    fixed,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            t?.failedToLoadImage ?? "Failed to load image.",
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 13),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () => _showNetworkDebugDialog(fixed),
                              child: Text(
                                t?.showErrorDetails ?? "Show Error Details",
                                style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: Colors.white),
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

  String _safeNameFromMap(Map<String, dynamic> m) {
    final t = AppLocalizations.of(context);
    final fn = (m['firstName'] ?? '').toString().trim();
    final ln = (m['lastName'] ?? '').toString().trim();
    final full = "$fn $ln".trim();
    if (full.isNotEmpty) return full;

    final alt = (m['patientName'] ?? m['name'] ?? (t?.patientFallbackName ?? 'Patient')).toString().trim();
    return alt.isEmpty ? (t?.patientFallbackName ?? "Patient") : alt;
  }

  // -------------------- LOAD APPROVED REQUESTS --------------------

  Future<void> _loadApprovedRequests() async {
    setState(() => _loadingRequests = true);

    try {
      if (_doctorId.isEmpty) {
        _approvedRequests = [];
        return;
      }

      final snap = await FirebaseFirestore.instance
          .collection('chatRequests')
          .where('doctorId', isEqualTo: _doctorId)
          .where('status', isEqualTo: 'approved')
          .get();

      _approvedRequests = snap.docs;

      if (_approvedRequests.isEmpty) {
        _selectedRequest = null;
        _patient = null;
        return;
      }

      // ✅ IMPORTANT FIX:
      // If we came from ChatRoom with a patientId, preselect THAT request.
      QueryDocumentSnapshot<Map<String, dynamic>>? preselected;

      final incomingPatientId = (widget.patientId ?? "").trim();
      if (incomingPatientId.isNotEmpty) {
        try {
          preselected = _approvedRequests.firstWhere((r) {
            final d = r.data();
            return (d['patientId'] ?? '').toString().trim() == incomingPatientId;
          });
        } catch (_) {
          preselected = null;
        }
      }

      _selectedRequest = preselected ?? _approvedRequests.first;

      await _loadPatientFromSelectedRequest();
      await _ensureChatDocExists();
    } catch (_) {
      _approvedRequests = [];
      _selectedRequest = null;
      _patient = null;
    } finally {
      if (mounted) setState(() => _loadingRequests = false);
    }
  }

  Future<void> _loadPatientFromSelectedRequest() async {
    final req = _selectedRequest;
    if (req == null) return;

    final data = req.data();
    final patientId = (data['patientId'] ?? '').toString().trim();
    if (patientId.isEmpty) return;

    setState(() => _loadingPatient = true);

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(patientId).get();
      _patient = userDoc.data();

      _patient ??= {
        "email": (data['patientEmail'] ?? widget.patientEmail ?? '').toString(),
        "firstName": (data['patientName'] ?? widget.patientName ?? 'Patient').toString(),
        "lastName": "",
        "profileImagePath": "",
      };
    } catch (_) {
      _patient = null;
    } finally {
      if (mounted) setState(() => _loadingPatient = false);
    }
  }

  Future<void> _ensureChatDocExists() async {
    if (_chatId.isEmpty || _selectedRequest == null) return;

    final reqData = _selectedRequest!.data();
    final patientId = (reqData['patientId'] ?? '').toString().trim();
    if (patientId.isEmpty) return;

    final patientEmail = (_patient?['email'] ?? reqData['patientEmail'] ?? widget.patientEmail ?? '').toString();
    final patientName = _safeNameFromMap(_patient ?? reqData);

    final chatRef = FirebaseFirestore.instance.collection('chats').doc(_chatId);

    await chatRef.set({
      "chatId": _chatId,
      "doctorId": _doctorId,
      "patientId": patientId,
      "patientName": patientName,
      "patientEmail": patientEmail,
      "updatedAt": FieldValue.serverTimestamp(),
      "createdAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // -------------------- SEND TEXT --------------------

  Future<void> _sendText() async {
    final t = AppLocalizations.of(context);

    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    if (_doctorId.isEmpty) {
      _snack(t?.doctorNotLoggedIn ?? "Doctor not logged in!");
      return;
    }

    if (_chatId.isEmpty || _selectedRequest == null) {
      _snack(t?.pleaseSelectPatientFirst ?? "Please select a patient first.");
      return;
    }

    if (_sending || _uploading) return;

    setState(() => _sending = true);

    try {
      final reqData = _selectedRequest!.data();
      final patientId = (reqData['patientId'] ?? '').toString().trim();
      final patientEmail = (_patient?['email'] ?? reqData['patientEmail'] ?? widget.patientEmail ?? '').toString();
      final patientName = _safeNameFromMap(_patient ?? reqData);

      _msgController.clear();

      final chatRef = FirebaseFirestore.instance.collection('chats').doc(_chatId);

      await chatRef.set({
        "chatId": _chatId,
        "doctorId": _doctorId,
        "patientId": patientId,
        "patientName": patientName,
        "patientEmail": patientEmail,
        "updatedAt": FieldValue.serverTimestamp(),
        "createdAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await chatRef.collection('messages').add({
        "senderId": _doctorId,
        "senderRole": "doctor",
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
    } catch (_) {
      _snack(t?.failedToSendMessage ?? "Failed to send message.");
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  // -------------------- PICK + SEND IMAGE --------------------

  Future<void> _pickAndSendImage({required ImageSource source}) async {
    final t = AppLocalizations.of(context);

    if (_chatId.isEmpty || _selectedRequest == null) {
      _snack(t?.pleaseSelectPatientFirst ?? "Please select a patient first.");
      return;
    }
    if (_uploading || _sending) return;

    final XFile? file = await _picker.pickImage(source: source, imageQuality: 95);
    if (file == null) return;

    final bytes = await file.readAsBytes();
    final fileName = (file.name.isNotEmpty) ? file.name : "image.jpg";
    final mimeType = fileName.toLowerCase().endsWith(".png") ? "image/png" : "image/jpeg";

    await _uploadAndSendFile(
      bytes: bytes,
      fileName: fileName,
      mimeType: mimeType,
      messageType: "image",
    );
  }

  // -------------------- PICK + SEND PDF --------------------

  Future<void> _pickAndSendPdf() async {
    final t = AppLocalizations.of(context);

    if (_chatId.isEmpty || _selectedRequest == null) {
      _snack(t?.pleaseSelectPatientFirst ?? "Please select a patient first.");
      return;
    }
    if (_uploading || _sending) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ["pdf"],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;
    final f = result.files.first;

    final bytes = f.bytes;
    if (bytes == null) {
      _snack(t?.unableToReadPdfBytes ?? "Unable to read PDF bytes.");
      return;
    }

    await _uploadAndSendFile(
      bytes: bytes,
      fileName: f.name.isEmpty ? "document.pdf" : f.name,
      mimeType: "application/pdf",
      messageType: "pdf",
    );
  }

  // -------------------- UPLOAD + SEND FILE --------------------

  Future<void> _uploadAndSendFile({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    required String messageType, // image | pdf
  }) async {
    final t = AppLocalizations.of(context);

    setState(() => _uploading = true);

    try {
      final reqData = _selectedRequest!.data();
      final patientId = (reqData['patientId'] ?? '').toString().trim();

      final url = await SupabaseService.instance.uploadChatFileViaEdge(
        firebaseUid: patientId,
        chatId: _chatId,
        bytes: bytes,
        fileName: fileName,
        mimeType: mimeType,
      );

      final chatRef = FirebaseFirestore.instance.collection('chats').doc(_chatId);

      await chatRef.collection('messages').add({
        "senderId": _doctorId,
        "senderRole": "doctor",
        "type": messageType,
        "text": "",
        "fileUrl": url,
        "fileName": fileName,
        "mimeType": mimeType,
        "createdAt": FieldValue.serverTimestamp(),
      });

      await chatRef.set({
        "lastMessage": messageType == "image"
            ? (t?.lastMessageImage ?? "📷 Image")
            : (t?.lastMessagePdf ?? "📄 PDF"),
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      _showErrorDialog(
        title: t?.uploadFailedTitle ?? "Upload failed",
        desc: e.toString(),
        okText: t?.ok ?? "OK",
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  // -------------------- BUBBLES --------------------

  Widget _bubble(Map<String, dynamic> m) {
    final t = AppLocalizations.of(context);

    final senderId = (m['senderId'] ?? '').toString();
    final mine = senderId == _doctorId;

    final type = (m['type'] ?? 'text').toString();
    final text = (m['text'] ?? '').toString();
    final rawFileUrl = (m['fileUrl'] ?? '').toString();
    final fileName = (m['fileName'] ?? '').toString();

    final fileUrl = _fixFileUrl(rawFileUrl);

    Widget child;

    if (type == "image" && fileUrl.isNotEmpty) {
      child = InkWell(
        onTap: () => _openImagePreview(rawFileUrl),
        onLongPress: () => _showNetworkDebugDialog(rawFileUrl),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            fileUrl,
            width: 200,
            height: 200,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Text(
              t?.failedToLoadImageShort ?? "Failed to load image",
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: mine ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ),
      );
    } else if (type == "pdf" && fileUrl.isNotEmpty) {
      child = InkWell(
        onTap: () => _openUrl(rawFileUrl),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.picture_as_pdf, color: mine ? Colors.white : blue),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                fileName.isEmpty ? (t?.pdfDocument ?? "PDF Document") : fileName,
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
          color: mine ? blue : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(14),
        ),
        child: child,
      ),
    );
  }

  // -------------------- HEADER --------------------

  Widget _patientHeaderLikeChatWithDoctor(AppLocalizations? t) {
    final patientName = _patient == null
        ? (t?.patientFallbackName ?? "Patient")
        : _safeNameFromMap(_patient!);

    final patientEmail = (_patient?['email'] ?? "").toString().trim();
    final profileImage = (_patient?['profileImagePath'] ?? "").toString().trim();

    final selectedPatientId = (_selectedRequest == null)
        ? ""
        : (_selectedRequest!.data()['patientId'] ?? "").toString().trim();

    if (_loadingPatient) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_selectedRequest == null) {
      return Padding(
        padding: const EdgeInsets.only(top: 35, bottom: 10),
        child: Text(
          t?.noApprovedPatientsYet ?? "No approved patients yet!",
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: blue,
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
            backgroundImage: profileImage.isNotEmpty
                ? NetworkImage(profileImage)
                : const AssetImage("assets/images/profileblue.png") as ImageProvider,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          patientName,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 23,
            fontWeight: FontWeight.w700,
            color: blue,
          ),
        ),
        const SizedBox(height: 6),
        if (patientEmail.isNotEmpty)
          Text(
            patientEmail,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: blue,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        const SizedBox(height: 8),
        Text(
          t?.connectedMessage ?? "You are now connected with each other.",
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: blue,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: selectedPatientId.isEmpty
              ? null
              : () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PatientProfileView(patientId: selectedPatientId),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: blue,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: Text(
            t?.viewProfile ?? "View Profile",
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

  // -------------------- BUILD --------------------

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    final messagesStream = (_chatId.isEmpty)
        ? null
        : FirebaseFirestore.instance
        .collection('chats')
        .doc(_chatId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots();

    return Scaffold(
      resizeToAvoidBottomInset: true,
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
                color: blue,
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: blue, width: 2),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: blue, size: 18),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ),

            // Dropdown area (unchanged)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      t?.approvedPatients ?? "Approved Patients",
                      style: GoogleFonts.poppins(
                        color: blue,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (_loadingRequests)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: CircularProgressIndicator(),
                    )
                  else if (_approvedRequests.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        t?.noApprovedPatientsYet ?? "No approved patients yet!",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: blue,
                        ),
                      ),
                    )
                  else
                    DropdownButtonFormField<String>(
                      value: _selectedRequest?.id,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: blue, width: 2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: blue, width: 2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: blue, width: 2),
                        ),
                      ),
                      icon: const Icon(Icons.arrow_drop_down_circle_outlined, color: blue),
                      items: _approvedRequests.map((req) {
                        final d = req.data();
                        final label = (d['patientName'] ?? (t?.patientFallbackName ?? 'Patient')).toString();
                        return DropdownMenuItem<String>(
                          value: req.id,
                          child: Text(
                            label,
                            style: GoogleFonts.poppins(color: blue, fontWeight: FontWeight.w600),
                          ),
                        );
                      }).toList(),
                      onChanged: (id) async {
                        if (id == null) return;
                        final found = _approvedRequests.firstWhere((e) => e.id == id);
                        setState(() {
                          _selectedRequest = found;
                          _patient = null;
                        });
                        await _loadPatientFromSelectedRequest();
                        await _ensureChatDocExists();
                      },
                    ),
                ],
              ),
            ),

            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: blue, width: 2),
                ),
                child: (_approvedRequests.isEmpty || _chatId.isEmpty || messagesStream == null)
                    ? Center(
                  child: Text(
                    t?.noChatYet ?? "No chat yet!",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: blue),
                  ),
                )
                    : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: messagesStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          "${t?.chatErrorPrefix ?? "Chat error"}: ${snapshot.error}",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: Colors.red,
                          ),
                        ),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final docs = snapshot.data?.docs ?? [];

                    return ListView.builder(
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      itemCount: docs.length + 2,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _patientHeaderLikeChatWithDoctor(t);
                        }
                        if (index == 1) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Divider(
                              color: blue.withOpacity(0.30),
                              thickness: 1,
                            ),
                          );
                        }

                        final m = docs[index - 2].data();
                        return _bubble(m);
                      },
                    );
                  },
                ),
              ),
            ),

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
                          hintText: t?.typeMessage ?? "Type Message",
                          suffixIcon: PopupMenuButton<String>(
                            icon: const Icon(Icons.attach_file, color: Colors.black87),
                            onSelected: (v) async {
                              if (v == "gallery") {
                                await _pickAndSendImage(source: ImageSource.gallery);
                              } else if (v == "camera") {
                                await _pickAndSendImage(source: ImageSource.camera);
                              } else if (v == "pdf") {
                                await _pickAndSendPdf();
                              }
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: "gallery",
                                child: Text(t?.imageGallery ?? "Image (Gallery)", style: GoogleFonts.poppins()),
                              ),
                              PopupMenuItem(
                                value: "camera",
                                child: Text(t?.imageCamera ?? "Image (Camera)", style: GoogleFonts.poppins()),
                              ),
                              PopupMenuItem(
                                value: "pdf",
                                child: Text(t?.pdf ?? "PDF", style: GoogleFonts.poppins()),
                              ),
                            ],
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: blue, width: 2),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: blue, width: 2),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: blue, width: 2),
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
                          backgroundColor: blue,
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
                          t?.send ?? "Send",
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