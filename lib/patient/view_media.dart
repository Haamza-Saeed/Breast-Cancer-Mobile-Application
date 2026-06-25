import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';

import 'package:project/l10n/app_localizations.dart';

class ViewMedia extends StatefulWidget {
  const ViewMedia({super.key});

  @override
  State<ViewMedia> createState() => _ViewMediaState();
}

class _ViewMediaState extends State<ViewMedia> {
  static const Color pink = Color(0xffFF67CE);

  // ✅ cache doctor names to avoid repeated reads
  final Map<String, String> _doctorNameCache = {};

  Future<String> _getDoctorName(String doctorId) async {
    final id = doctorId.trim();
    if (id.isEmpty) return _doctorNameCache['__fallback__'] ?? "Doctor";

    if (_doctorNameCache.containsKey(id)) {
      return _doctorNameCache[id]!;
    }

    try {
      final doc = await FirebaseFirestore.instance.collection("users").doc(id).get();
      final data = doc.data() ?? {};

      final firstName = (data["firstName"] ?? "").toString().trim();
      final lastName = (data["lastName"] ?? "").toString().trim();

      final name = (firstName.isNotEmpty || lastName.isNotEmpty)
          ? ("$firstName $lastName").trim()
          : (_doctorNameCache['__fallback__'] ?? "Doctor");

      _doctorNameCache[id] = name;
      return name;
    } catch (_) {
      return _doctorNameCache['__fallback__'] ?? "Doctor";
    }
  }

  String _pickDoctorId(Map<String, dynamic> data) {
    return (data["doctorId"] ?? data["doctorUid"] ?? "").toString().trim();
  }

  String _pickUrl(Map<String, dynamic> data) {
    return (data["fileUrl"] ?? data["mediaUrl"] ?? data["url"] ?? "")
        .toString()
        .trim();
  }

  String _pickTitle(Map<String, dynamic> data) {
    return (data["title"] ?? data["mediaTitle"] ?? "").toString().trim();
  }

  String _pickDesc(Map<String, dynamic> data) {
    return (data["description"] ?? data["mediaDescription"] ?? "")
        .toString()
        .trim();
  }

  String _pickType(Map<String, dynamic> data, String url) {
    final raw =
    (data["type"] ?? data["mediaType"] ?? "").toString().toLowerCase().trim();

    if (raw.isNotEmpty) return raw;

    final u = url.toLowerCase();
    if (u.endsWith(".mp4") || u.endsWith(".mov") || u.endsWith(".mkv") || u.contains("video")) {
      return "video";
    }
    return "image";
  }

  Widget _label(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontWeight: FontWeight.w800,
        fontSize: 13,
        color: pink,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final uploadsRef = FirebaseFirestore.instance.collection("doctorUploads");

    // set fallback name into cache (localized)
    _doctorNameCache['__fallback__'] = t.doctorFallbackName;

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
                color: pink,
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
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: pink, width: 2),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: pink, size: 18),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              Image.asset(
                "assets/images/uploadexercise.png",
                width: 373,
                height: 249,
              ),
              const SizedBox(height: 10),

              Text(
                t.viewMediaTitle,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 27,
                  color: pink,
                ),
              ),

              const SizedBox(height: 18),

              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: uploadsRef.snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 30),
                      child: Text(
                        "${t.errorTitle}: ${snapshot.error}",
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
                        t.noUploadsYet,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: pink,
                        ),
                      ),
                    );
                  }

                  // ✅ client-side sort by createdAt desc
                  docs.sort((a, b) {
                    final ta = a.data()["createdAt"];
                    final tb = b.data()["createdAt"];
                    if (ta is Timestamp && tb is Timestamp) {
                      return tb.compareTo(ta);
                    }
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

                      final doctorId = _pickDoctorId(data);
                      final fileUrl = _pickUrl(data);
                      final title = _pickTitle(data);
                      final desc = _pickDesc(data);
                      final type = _pickType(data, fileUrl);

                      final typeText = type == "video" ? t.mediaTypeVideo : t.mediaTypeImage;

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: pink, width: 2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label("${t.doctorLabel}"),
                            FutureBuilder<String>(
                              future: _getDoctorName(doctorId),
                              builder: (context, snapName) {
                                final doctorName = snapName.data ?? t.doctorFallbackName;
                                return Text(
                                  doctorName,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: pink,
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 10),

                            _label("${t.titleLabelPlain}:"),
                            Text(
                              title.isEmpty ? t.untitled : title,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: Colors.black,
                              ),
                            ),

                            const SizedBox(height: 10),

                            _label("${t.descriptionLabelPlain}:"),
                            Text(
                              desc.isEmpty ? t.noDescriptionDash : desc,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),

                            const SizedBox(height: 12),

                            if (fileUrl.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: double.infinity,
                                  height: 180,
                                  color: Colors.black12,
                                  child: type == "video"
                                      ? _VideoPreview(url: fileUrl)
                                      : Image.network(
                                    fileUrl,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, progress) {
                                      if (progress == null) return child;
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    },
                                    errorBuilder: (_, __, ___) => const Center(
                                      child: Icon(Icons.broken_image, size: 42),
                                    ),
                                  ),
                                ),
                              )
                            else
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Text(
                                  t.invalidMediaUrl,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    color: Colors.red,
                                  ),
                                ),
                              ),

                            const SizedBox(height: 10),

                            Row(
                              children: [
                                Icon(
                                  type == "video" ? Icons.video_file : Icons.image,
                                  color: pink,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  typeText,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: pink,
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

/// ✅ Same minimal video preview widget (localized error)
class _VideoPreview extends StatefulWidget {
  final String url;
  const _VideoPreview({required this.url});

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
    final t = AppLocalizations.of(context)!;

    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_err != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Text(
            "${t.videoFailedToLoad}\n$_err",
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