import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class MediaPreview extends StatefulWidget {
  final String type; // "image" | "video"
  final String url;  // fileUrl from Firestore (public or signed)
  final double height;
  final BorderRadius borderRadius;

  const MediaPreview({
    super.key,
    required this.type,
    required this.url,
    this.height = 160,
    this.borderRadius = const BorderRadius.all(Radius.circular(14)),
  });

  @override
  State<MediaPreview> createState() => _MediaPreviewState();
}

class _MediaPreviewState extends State<MediaPreview> {
  VideoPlayerController? _video;
  ChewieController? _chewie;
  bool _loadingVideo = false;
  String? _videoError;

  @override
  void initState() {
    super.initState();
    if (widget.type == "video") {
      _initVideo();
    }
  }

  Future<void> _initVideo() async {
    setState(() {
      _loadingVideo = true;
      _videoError = null;
    });

    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      await controller.initialize();

      final chewie = ChewieController(
        videoPlayerController: controller,
        autoPlay: false,
        looping: false,
        showControls: true,
        allowFullScreen: true,
        allowMuting: true,
      );

      if (!mounted) return;
      setState(() {
        _video = controller;
        _chewie = chewie;
        _loadingVideo = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _videoError = e.toString();
        _loadingVideo = false;
      });
    }
  }

  @override
  void dispose() {
    _chewie?.dispose();
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // IMAGE PREVIEW
    if (widget.type != "video") {
      return ClipRRect(
        borderRadius: widget.borderRadius,
        child: Container(
          height: widget.height,
          width: double.infinity,
          color: Colors.black12,
          child: Image.network(
            widget.url,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Center(
              child: Icon(Icons.broken_image, size: 42),
            ),
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const Center(child: CircularProgressIndicator());
            },
          ),
        ),
      );
    }

    // VIDEO PREVIEW
    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: Container(
        height: widget.height,
        width: double.infinity,
        color: Colors.black12,
        child: _loadingVideo
            ? const Center(child: CircularProgressIndicator())
            : (_videoError != null)
            ? Center(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
              "Video preview failed\n$_videoError",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        )
            : (_chewie == null)
            ? const Center(child: Text("No video"))
            : Chewie(controller: _chewie!),
      ),
    );
  }
}
