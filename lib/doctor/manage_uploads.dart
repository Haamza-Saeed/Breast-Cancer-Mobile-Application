import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';

import 'package:project/doctor/doctorrootpage.dart';

// ✅ Localization
import 'package:project/l10n/app_localizations.dart';

class ManageUploads extends StatelessWidget {
  const ManageUploads({super.key});

  static const Color blue = Color(0xff00AEEF);

  String? get _doctorUid => FirebaseAuth.instance.currentUser?.uid;

  SupabaseClient get _supabase => Supabase.instance.client;

  // ---------------- DIALOG HELPERS ----------------
  void _sweet({
    required BuildContext context,
    required DialogType type,
    required String title,
    required String desc,
    required String okText,
  }) {
    if (!context.mounted) return;
    AwesomeDialog(
      context: context,
      dialogType: type,
      animType: AnimType.scale,
      title: title,
      desc: desc,
      btnOkText: okText,
      btnOkOnPress: () {},
    ).show();
  }

  // ---------------- DELETE ----------------
  Future<void> _deleteUpload(
      BuildContext context, {
        required AppLocalizations? t,
        required String firestoreDocId,
        required Map<String, dynamic> data,
      }) async {
    try {
      final myId = _doctorUid ?? "";
      if (myId.isEmpty) throw Exception(t?.doctorNotLoggedIn ?? "Doctor not logged in.");

      final ownerId = (data["doctorId"] ?? "").toString().trim();
      if (ownerId != myId) {
        throw Exception(t?.manageOwnUploadsOnly ?? "You can only manage your own uploads.");
      }

      final bucket = (data["bucket"] ?? "doctor-uploads").toString().trim();
      final filePath = (data["filePath"] ?? "").toString().trim();

      if (filePath.isEmpty) {
        throw Exception(
          t?.missingFilePathReupload ??
              "Missing filePath in Firestore. Please re-upload this media.",
        );
      }

      // ✅ delete from storage
      await _supabase.storage.from(bucket).remove([filePath]);

      // ✅ delete firestore record
      await FirebaseFirestore.instance
          .collection("doctorUploads")
          .doc(firestoreDocId)
          .delete();

      _sweet(
        context: context,
        type: DialogType.success,
        title: t?.deletedTitle ?? "Deleted ✅",
        desc: t?.uploadDeletedSuccessfully ?? "Upload deleted successfully.",
        okText: t?.ok ?? "OK",
      );
    } catch (e) {
      _sweet(
        context: context,
        type: DialogType.error,
        title: t?.errorTitle ?? "Error ❌",
        desc: e.toString(),
        okText: t?.ok ?? "OK",
      );
    }
  }

  // ---------------- EDIT ----------------
  void _editUpload(
      BuildContext context, {
        required AppLocalizations? t,
        required String firestoreDocId,
        required String oldTitle,
        required String oldDesc,
      }) {
    final titleController = TextEditingController(text: oldTitle);
    final descController = TextEditingController(text: oldDesc);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          t?.editUpload ?? "Edit Upload",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: t?.titleLabel ?? "Title"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descController,
              decoration: InputDecoration(labelText: t?.descriptionLabel ?? "Description"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t?.cancel ?? "Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: blue),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection("doctorUploads")
                  .doc(firestoreDocId)
                  .update({
                "title": titleController.text.trim(),
                "description": descController.text.trim(),
                "updatedAt": FieldValue.serverTimestamp(),
              });

              if (!context.mounted) return;
              Navigator.pop(context);

              _sweet(
                context: context,
                type: DialogType.success,
                title: t?.updatedTitle ?? "Updated ✅",
                desc: t?.uploadUpdatedSuccessfully ?? "Upload updated successfully.",
                okText: t?.ok ?? "OK",
              );
            },
            child: Text(t?.save ?? "Save"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final doctorUid = _doctorUid;

    return Scaffold(
      // ✅ SAME APPBAR STYLE
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

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            children: [
              // ✅ BACK BUTTON
              Align(
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
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const DoctorRootPage()),
                      );
                    },
                  ),
                ),
              ),

              // ✅ TOP IMAGE
              Image.asset(
                "assets/images/uploadexercise.png",
                width: 373,
                height: 249,
              ),
              const SizedBox(height: 10),

              // ✅ TITLE
              Text(
                t?.manageUploads ?? "Manage Uploads",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 27,
                  color: blue,
                ),
              ),

              const SizedBox(height: 18),

              // ✅ NOT LOGGED IN
              if (doctorUid == null)
                Padding(
                  padding: const EdgeInsets.only(top: 50),
                  child: Text(
                    t?.doctorNotLoggedIn ?? "Doctor not logged in!",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: blue,
                    ),
                  ),
                )
              else
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection("doctorUploads")
                      .where("doctorId", isEqualTo: doctorUid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 30),
                        child: Text(
                          "${t?.errorPrefix ?? "Error"}: ${snapshot.error}",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: Colors.red,
                          ),
                        ),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 30),
                        child: CircularProgressIndicator(),
                      );
                    }

                    final docs = snapshot.data?.docs ?? [];

                    if (docs.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 60),
                        child: Text(
                          t?.noUploadsYet ?? "No uploads yet!",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: blue,
                          ),
                        ),
                      );
                    }

                    // ✅ optional: client-side sort by createdAt desc
                    docs.sort((a, b) {
                      final ta = a.data()["createdAt"];
                      final tb = b.data()["createdAt"];
                      if (ta is Timestamp && tb is Timestamp) return tb.compareTo(ta);
                      return 0;
                    });

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data();

                        final title = (data["title"] ?? "").toString();
                        final desc = (data["description"] ?? "").toString();
                        final type = (data["type"] ?? "image").toString().toLowerCase();

                        // ✅ preview url
                        final fileUrl = (data["fileUrl"] ?? "").toString().trim();

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: blue, width: 2),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title
                              Text(
                                title.isEmpty ? (t?.untitled ?? "Untitled") : title,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: blue,
                                ),
                              ),

                              const SizedBox(height: 6),

                              // Description
                              if (desc.isNotEmpty)
                                Text(
                                  desc,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                    color: Colors.black54,
                                  ),
                                ),

                              const SizedBox(height: 10),

                              // ✅ PREVIEW (IMAGE / VIDEO)
                              if (fileUrl.isNotEmpty)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    width: double.infinity,
                                    height: 180,
                                    color: Colors.black12,
                                    child: type == "video"
                                        ? _VideoPreview(
                                      url: fileUrl,
                                      t: t,
                                    )
                                        : Image.network(
                                      fileUrl,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, progress) {
                                        if (progress == null) return child;
                                        return const Center(child: CircularProgressIndicator());
                                      },
                                      errorBuilder: (_, __, ___) => const Center(
                                        child: Icon(Icons.broken_image, size: 42),
                                      ),
                                    ),
                                  ),
                                ),

                              const SizedBox(height: 10),

                              // Type label
                              Row(
                                children: [
                                  Icon(type == "video" ? Icons.video_file : Icons.image, color: blue),
                                  const SizedBox(width: 8),
                                  Text(
                                    type.toUpperCase(),
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: blue,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              // Buttons row
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => _editUpload(
                                        context,
                                        t: t,
                                        firestoreDocId: doc.id,
                                        oldTitle: title,
                                        oldDesc: desc,
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: blue,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(30),
                                        ),
                                      ),
                                      child: Text(
                                        t?.edit ?? "Edit",
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => _deleteUpload(
                                        context,
                                        t: t,
                                        firestoreDocId: doc.id,
                                        data: data,
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(30),
                                        ),
                                      ),
                                      child: Text(
                                        t?.delete ?? "Delete",
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
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

/// Minimal video preview to make the VIDEO visible inside the card.
class _VideoPreview extends StatefulWidget {
  final String url;
  final AppLocalizations? t;
  const _VideoPreview({required this.url, required this.t});

  @override
  State<_VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<_VideoPreview> {
  VideoPlayerController? _controller;
  bool _loading = true;
  String? _err;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final c = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      await c.initialize();
      c.setLooping(false);
      if (!mounted) return;
      setState(() {
        _controller = c;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _err = e.toString();
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_err != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Text(
            "${widget.t?.videoFailedToLoad ?? "Video failed to load"}\n$_err",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      );
    }

    final c = _controller!;
    return Stack(
      alignment: Alignment.center,
      children: [
        FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: c.value.size.width,
            height: c.value.size.height,
            child: VideoPlayer(c),
          ),
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              if (c.value.isPlaying) {
                c.pause();
              } else {
                c.play();
              }
            });
          },
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.black45,
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(14),
            child: Icon(
              c.value.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 42,
            ),
          ),
        ),
      ],
    );
  }
}