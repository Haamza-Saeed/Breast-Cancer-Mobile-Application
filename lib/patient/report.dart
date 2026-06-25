// lib/patient/report.dart
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart' as pdfc;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:project/l10n/app_localizations.dart';
import 'package:project/patient/rootpage.dart';
import 'package:project/services/ai_report_service.dart';
import 'package:project/services/supabase_service.dart';

class Report extends StatefulWidget {
  const Report({super.key});

  @override
  State<Report> createState() => _ReportState();
}

class _ReportState extends State<Report> {
  final _auth = FirebaseAuth.instance;
  static const _pink = Color(0xffFF67CE);

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final user = _auth.currentUser;

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
                color: _pink,
              ),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xffffeef8), Color(0xffffffff), Color(0xfffff5fb)],
          ),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
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
                      border: Border.all(color: _pink, width: 2),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: _pink,
                        size: 18,
                      ),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const RootPage()),
                        );
                      },
                    ),
                  ),
                ),
                _AnimatedEntry(
                  delayMs: 80,
                  child: _ReportHeroHeader(title: t.myReport),
                ),
                const SizedBox(height: 22),
                if (user == null)
                  Center(
                    child: Text(
                      t.pleaseLoginToViewReports,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: _pink,
                      ),
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionTitle(title: t.imageReportsTitle),
                      const SizedBox(height: 10),
                      _ReportsList(firebaseUid: user.uid),
                      const SizedBox(height: 22),
                      _SectionTitle(title: t.symptomReportsTitle),
                      const SizedBox(height: 10),
                      _SymptomAssessmentsList(firebaseUid: user.uid),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  static const _pink = Color(0xffFF67CE);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w800,
          fontSize: 15,
          color: _pink,
        ),
      ),
    );
  }
}


class _AnimatedEntry extends StatelessWidget {
  final Widget child;
  final int delayMs;

  const _AnimatedEntry({required this.child, this.delayMs = 0});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 520 + delayMs.clamp(0, 450)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 24),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _ReportHeroHeader extends StatelessWidget {
  final String title;
  const _ReportHeroHeader({required this.title});

  static const _pink = Color(0xffFF67CE);
  static const _purple = Color(0xff7C4DFF);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xffffe7f6), Color(0xffffffff)],
        ),
        boxShadow: [
          BoxShadow(
            color: _pink.withOpacity(0.18),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          Image.asset(
            "assets/images/announcments.png",
            width: 310,
            height: 200,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _pink.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome, color: _purple, size: 18),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w800,
                    fontSize: 28,
                    color: _pink,
                    height: 1.05,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "AI-powered report with diagnosis details, uploaded images and complete PDF export.",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

// ===================== IMAGE REPORTS LIST =====================

class _ReportsList extends StatelessWidget {
  final String firebaseUid;
  const _ReportsList({required this.firebaseUid});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    final query = FirebaseFirestore.instance
        .collection("reports")
        .doc(firebaseUid)
        .collection("items")
        .orderBy("createdAt", descending: true);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Text(
            "${t.failedToLoadReports} ${snap.error}",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: const Color(0xffFF67CE),
            ),
          );
        }

        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.only(top: 40),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Center(
              child: Text(
                t.noReportsYet,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: const Color(0xffFF67CE),
                ),
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: docs.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, i) {
            return _AnimatedEntry(
              delayMs: 80 + (i * 70),
              child: _DiagnosisReportCard(
                firebaseUid: firebaseUid,
                docId: docs[i].id,
                data: docs[i].data(),
              ),
            );
          },
        );
      },
    );
  }
}

class _DiagnosisReportCard extends StatefulWidget {
  final String firebaseUid;
  final String docId;
  final Map<String, dynamic> data;

  const _DiagnosisReportCard({
    required this.firebaseUid,
    required this.docId,
    required this.data,
  });

  @override
  State<_DiagnosisReportCard> createState() => _DiagnosisReportCardState();
}

class _DiagnosisReportCardState extends State<_DiagnosisReportCard> {
  static const _pink = Color(0xffFF67CE);
  static const _purple = Color(0xff7C4DFF);
  static const _teal = Color(0xff00BFA5);
  static const _orange = Color(0xffFF8A65);
  static const _bg = Color(0xffFFF5FB);

  late Future<_ResolvedReportAssets> _assetsFuture;
  bool _generatingAi = false;
  String _aiText = "";
  String _aiError = "";

  @override
  void initState() {
    super.initState();
    _assetsFuture = _loadAssets();
    _aiText = _existingAiText(widget.data);

    // Auto-generate AI report for this specific diagnosis only if missing.
    // It updates the same Firestore report document, so it will not regenerate next time.
    if (_aiText.trim().isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _generateAiForThisReport(showDialogOnSuccess: false);
      });
    }
  }

  String get _reportId => (widget.data["reportId"] ?? widget.docId).toString();

  String get _label => (widget.data["predictedLabel"] ?? "unknown").toString();

  bool get _isMalignant => (widget.data["isMalignant"] ?? false) == true;

  double get _confidence {
    final v = widget.data["confidence"];
    return v is num ? v.toDouble().clamp(0.0, 1.0) : 0.0;
  }

  DateTime? get _createdAt {
    final v = widget.data["createdAt"];
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }

  String _existingAiText(Map<String, dynamic> data) {
    return (data["aiReportText"] ?? data["aiGeneratedReport"] ?? "").toString();
  }

  String _displayLabel(String label) {
    final s = label.replaceAll("_", " ").trim();
    if (s.isEmpty) return "Unknown";
    return s
        .split(" ")
        .where((e) => e.trim().isNotEmpty)
        .map((e) => e[0].toUpperCase() + e.substring(1))
        .join(" ");
  }

  String _dateStr(DateTime? dt) {
    if (dt == null) return "";
    return DateFormat("yyyy-MM-dd").format(dt);
  }

  String _statusText(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return _isMalignant ? t.statusMalignant : t.statusBenign;
  }

  Color _statusColor() => _isMalignant ? _orange : _teal;

  String _riskLevel(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final c = _confidence.clamp(0.0, 1.0);

    if (!_isMalignant) {
      if (c >= 0.80) return t.riskLowConcern;
      if (c >= 0.60) return t.riskMildConcern;
      return t.riskReviewRecommended;
    } else {
      if (c >= 0.80) return t.riskHighConcern;
      if (c >= 0.60) return t.riskModerateConcern;
      return t.riskReviewUrgently;
    }
  }

  Color _riskColor() {
    final c = _confidence.clamp(0.0, 1.0);
    if (!_isMalignant) {
      if (c >= 0.80) return _teal;
      if (c >= 0.60) return _purple;
      return _orange;
    } else {
      if (c >= 0.80) return _orange;
      if (c >= 0.60) return _purple;
      return _pink;
    }
  }

  double _likelihoodMeterValue() {
    final c = _confidence.clamp(0.0, 1.0);
    return _isMalignant ? c : (1.0 - c);
  }

  Future<_ResolvedReportAssets> _loadAssets() async {
    final patientUid = await _resolvePatientUid(firebaseUid: widget.firebaseUid);

    final urls = await SupabaseService.instance.getReportImageUrls(
      firebaseUid: patientUid,
      reportId: _reportId,
      fallbackToStorageList: true,
    );

    return _ResolvedReportAssets(patientUid: patientUid, imageUrls: urls);
  }

  Future<String> _resolvePatientUid({required String firebaseUid}) async {
    try {
      final doc =
      await FirebaseFirestore.instance.collection("users").doc(firebaseUid).get();
      final data = doc.data();
      final uid = data?["uid"];
      if (uid is String && uid.trim().isNotEmpty) return uid.trim();
    } catch (_) {}
    return firebaseUid;
  }

  void _refreshImages() {
    setState(() => _assetsFuture = _loadAssets());
  }

  Future<void> _generateAiForThisReport({bool showDialogOnSuccess = true}) async {
    if (_generatingAi) return;

    setState(() {
      _generatingAi = true;
      _aiError = "";
    });

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(widget.firebaseUid)
          .get();
      final patientData = userDoc.data() ?? <String, dynamic>{};

      final diagnosisData = <String, dynamic>{
        ...widget.data,
        "docId": widget.docId,
        "reportId": _reportId,
        "predictedLabel": _label,
        "displayLabel": _displayLabel(_label),
        "isMalignant": _isMalignant,
        "confidence": _confidence,
      };

      final report = await AiReportService.instance.generateDiagnosisReport(
        patientData: patientData,
        diagnosisData: diagnosisData,
      );

      await FirebaseFirestore.instance
          .collection("reports")
          .doc(widget.firebaseUid)
          .collection("items")
          .doc(widget.docId)
          .set({
        "aiReportText": report,
        "aiGeneratedAt": FieldValue.serverTimestamp(),
        "aiReportSource": "ollama_or_dynamic_backend",
      }, SetOptions(merge: true));

      if (!mounted) return;

      setState(() => _aiText = report);

      if (showDialogOnSuccess) {
        AwesomeDialog(
          context: context,
          dialogType: DialogType.success,
          animType: AnimType.scale,
          title: "AI Report Generated",
          desc: "AI report generated for this diagnosis only.",
          btnOkText: "OK",
          btnOkOnPress: () {},
        ).show();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _aiError = e.toString());
    } finally {
      if (mounted) setState(() => _generatingAi = false);
    }
  }

  Future<void> _downloadPdf(_ResolvedReportAssets assets) async {
    final t = AppLocalizations.of(context)!;
    final doc = pw.Document();
    final baseFont = await PdfGoogleFonts.poppinsRegular();
    final boldFont = await PdfGoogleFonts.poppinsBold();

    final imageBytesList = <Uint8List>[];
    for (final url in assets.imageUrls.take(12)) {
      try {
        final res = await http.get(Uri.parse(url));
        if (res.statusCode == 200) imageBytesList.add(res.bodyBytes);
      } catch (_) {}
    }

    final pdfPink = pdfc.PdfColor.fromInt(_pink.toARGB32());
    final pdfPurple = pdfc.PdfColor.fromInt(_purple.toARGB32());
    final pdfTeal = pdfc.PdfColor.fromInt(_teal.toARGB32());
    final pdfOrange = pdfc.PdfColor.fromInt(_orange.toARGB32());
    final pdfBg = pdfc.PdfColor.fromInt(_bg.toARGB32());

    final confPct = (_confidence * 100).toStringAsFixed(1);
    final status = _statusText(context);
    final title = _displayLabel(_label);
    final aiText = _aiText.trim().isNotEmpty
        ? _aiText.trim()
        : "AI report is not generated yet for this diagnosis.";

    pw.Widget pill(String text, pdfc.PdfColor color) {
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: pw.BoxDecoration(
          color: color,
          borderRadius: pw.BorderRadius.circular(999),
        ),
        child: pw.Text(
          text,
          style: pw.TextStyle(
            font: boldFont,
            fontSize: 10,
            color: pdfc.PdfColors.white,
          ),
        ),
      );
    }

    pw.Widget imagesGrid(List<Uint8List> imgs) {
      if (imgs.isEmpty) {
        return pw.Text(
          t.noImagesForReport,
          style: pw.TextStyle(
            font: baseFont,
            fontSize: 11,
            color: pdfc.PdfColors.grey700,
          ),
        );
      }

      return pw.GridView(
        crossAxisCount: 3,
        childAspectRatio: 1,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        children: imgs.map((bytes) {
          return pw.ClipRRect(
            horizontalRadius: 10,
            verticalRadius: 10,
            child: pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: pdfPink, width: 1),
              ),
              child: pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.cover),
            ),
          );
        }).toList(),
      );
    }

    doc.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: baseFont, bold: boldFont),
        pageFormat: pdfc.PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (_) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: pdfBg,
              borderRadius: pw.BorderRadius.circular(18),
              border: pw.Border.all(color: pdfPink, width: 1.5),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  "AI Breast Health Report",
                  style: pw.TextStyle(font: boldFont, fontSize: 18, color: pdfPink),
                ),
                pw.SizedBox(height: 8),
                pw.Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    pill(title, pdfPurple),
                    pill(status, _isMalignant ? pdfOrange : pdfTeal),
                    pill("Confidence: $confPct%", pdfPurple),
                  ],
                ),
                pw.SizedBox(height: 10),
                if (_dateStr(_createdAt).isNotEmpty)
                  pw.Text(
                    "Date: ${_dateStr(_createdAt)}",
                    style: pw.TextStyle(font: baseFont, fontSize: 11),
                  ),
              ],
            ),
          ),
          pw.SizedBox(height: 14),
          pw.Text(
            "Uploaded Images",
            style: pw.TextStyle(font: boldFont, fontSize: 14, color: pdfPink),
          ),
          pw.SizedBox(height: 8),
          imagesGrid(imageBytesList),
          pw.SizedBox(height: 14),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: pdfc.PdfColors.white,
              borderRadius: pw.BorderRadius.circular(16),
              border: pw.Border.all(color: pdfPink, width: 1.1),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  "Complete AI Generated Report",
                  style: pw.TextStyle(font: boldFont, fontSize: 14, color: pdfPurple),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  aiText,
                  style: pw.TextStyle(font: baseFont, fontSize: 11, lineSpacing: 4),
                  textAlign: pw.TextAlign.justify,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) async => doc.save(),
      name: "ai_breast_health_report_${_reportId}.pdf",
    );

    if (!mounted) return;

    AwesomeDialog(
      context: context,
      dialogType: DialogType.success,
      animType: AnimType.scale,
      title: t.pdfReadyTitle,
      desc: t.pdfReadyDesc,
      btnOkText: t.ok,
      btnOkOnPress: () {},
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final pct = (_confidence * 100).toStringAsFixed(1);
    final dateStr = _dateStr(_createdAt);
    final status = _statusText(context);
    final statusColor = _statusColor();
    final title = _displayLabel(_label);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xffffffff), Color(0xfffff3fb)],
        ),
        border: Border.all(color: _pink, width: 1.8),
        boxShadow: [
          BoxShadow(
            color: _pink.withOpacity(0.16),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: FutureBuilder<_ResolvedReportAssets>(
        future: _assetsFuture,
        builder: (context, snap) {
          final assets = snap.data;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: _pink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        status,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: statusColor,
                        ),
                      ),
                      Text(
                        "$pct%",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: _purple,
                        ),
                      ),
                      if (dateStr.isNotEmpty)
                        Text(
                          dateStr,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                            color: _pink,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _ConfidenceBar(
                title: t.confidence,
                value: _confidence,
                barColor: _isMalignant ? _orange : _teal,
                accent: _purple,
              ),
              const SizedBox(height: 10),
              _RiskRow(
                title: "${t.riskLevel}:",
                label: _riskLevel(context),
                color: _riskColor(),
              ),
              const SizedBox(height: 10),
              _LikelihoodMeter(
                title: t.likelihoodMeter,
                value: _likelihoodMeterValue(),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _pink, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _refreshImages,
                      icon: const Icon(Icons.refresh, color: _pink, size: 18),
                      label: Text(
                        t.refreshImages,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: _pink,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _pink,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: (assets == null) ? null : () => _downloadPdf(assets),
                      icon: const Icon(Icons.download, color: Colors.white, size: 18),
                      label: Text(
                        t.downloadPdf,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (snap.connectionState == ConnectionState.waiting)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (snap.hasError)
                Text(
                  t.failedToLoadImages,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: _orange,
                  ),
                )
              else
                _ImagesGrid(urls: assets?.imageUrls ?? const []),
              const SizedBox(height: 12),
              _AiGeneratedReportBox(
                aiText: _aiText,
                isGenerating: _generatingAi,
                error: _aiError,
                onGenerateAgain: () => _generateAiForThisReport(showDialogOnSuccess: true),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AiGeneratedReportBox extends StatefulWidget {
  final String aiText;
  final bool isGenerating;
  final String error;
  final VoidCallback onGenerateAgain;

  const _AiGeneratedReportBox({
    required this.aiText,
    required this.isGenerating,
    required this.error,
    required this.onGenerateAgain,
  });

  @override
  State<_AiGeneratedReportBox> createState() => _AiGeneratedReportBoxState();
}

class _AiGeneratedReportBoxState extends State<_AiGeneratedReportBox>
    with SingleTickerProviderStateMixin {
  static const _pink = Color(0xffFF67CE);
  static const _purple = Color(0xff7C4DFF);
  static const _teal = Color(0xff00BFA5);
  static const _orange = Color(0xffFF8A65);
  static const _blue = Color(0xff3D8BFF);
  static const _green = Color(0xff2ECC71);

  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant _AiGeneratedReportBox oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.aiText != widget.aiText ||
        oldWidget.isGenerating != widget.isGenerating ||
        oldWidget.error != widget.error) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_AiSection> _parseSections(String text) {
    final cleaned = text.trim();
    if (cleaned.isEmpty) return [];

    final regex = RegExp(r'(?=\n?\d+\.\s)', multiLine: true);
    final parts = cleaned
        .split(regex)
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return [_AiSection(title: "AI Report", body: cleaned)];
    }

    return parts.map((part) {
      final lines = part.split("\n");
      final rawTitle = lines.first.trim();
      final body = lines.skip(1).join("\n").trim();

      return _AiSection(
        title: rawTitle,
        body: body.isEmpty ? part : body,
      );
    }).toList();
  }

  Color _sectionColor(int index) {
    final colors = [_purple, _teal, _orange, _pink, _blue, _green];
    return colors[index % colors.length];
  }

  IconData _sectionIcon(int index) {
    final icons = [
      Icons.person_rounded,
      Icons.biotech_rounded,
      Icons.psychology_alt_rounded,
      Icons.health_and_safety_rounded,
      Icons.check_circle_rounded,
      Icons.info_rounded,
    ];

    return icons[index % icons.length];
  }

  String _cleanTitle(String title) {
    return title.replaceFirst(RegExp(r'^\d+\.\s*'), '').trim();
  }

  Widget _buildLoadingBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _purple.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _purple.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Generating AI report using patient profile and diagnosis data...",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: _purple,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _purple.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        "AI report is not generated yet. Tap Regenerate.",
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w700,
          fontSize: 12,
          color: _purple,
        ),
      ),
    );
  }

  Widget _buildSection(_AiSection section, int index) {
    final color = _sectionColor(index);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 420 + (index * 70)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 16),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.45), width: 1.4),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.10),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.75, end: 1),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (_, scale, child) {
                return Transform.scale(scale: scale, child: child);
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color, color.withOpacity(0.62)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(
                  _sectionIcon(index),
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _cleanTitle(section.title),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: color,
                    ),
                  ),
                  if (section.body.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      section.body.trim(),
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        fontSize: 12.5,
                        height: 1.58,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sections = _parseSections(widget.aiText);

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xffffffff),
                Color(0xfffff1fb),
                Color(0xfff4efff),
              ],
            ),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: _pink, width: 1.8),
            boxShadow: [
              BoxShadow(
                color: _pink.withOpacity(0.18),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.82, end: 1),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.elasticOut,
                    builder: (_, scale, child) {
                      return Transform.scale(scale: scale, child: child);
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [_pink, _purple],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: _purple.withOpacity(0.22),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "AI Generated Report",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: _purple,
                          ),
                        ),
                        Text(
                          "Personalized by profile + diagnosis",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 10.5,
                            color: Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: widget.isGenerating ? null : widget.onGenerateAgain,
                    borderRadius: BorderRadius.circular(30),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: widget.isGenerating
                            ? Colors.grey.withOpacity(0.12)
                            : _pink.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: widget.isGenerating
                              ? Colors.grey.withOpacity(0.35)
                              : _pink.withOpacity(0.45),
                        ),
                      ),
                      child: Row(
                        children: [
                          widget.isGenerating
                              ? const SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                              : const Icon(
                            Icons.refresh_rounded,
                            size: 17,
                            color: _pink,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            widget.isGenerating ? "Generating" : "Regenerate",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                              color: widget.isGenerating ? Colors.grey : _pink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (widget.isGenerating && widget.aiText.trim().isEmpty)
                _buildLoadingBox()
              else if (sections.isNotEmpty)
                ...List.generate(
                  sections.length,
                      (index) => _buildSection(sections[index], index),
                )
              else
                _buildEmptyBox(),
              if (widget.error.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _orange.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _orange.withOpacity(0.35)),
                  ),
                  child: Text(
                    "AI Error: ${widget.error}",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      color: _orange,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AiSection {
  final String title;
  final String body;

  _AiSection({required this.title, required this.body});
}

class _ResolvedReportAssets {
  final String patientUid;
  final List<String> imageUrls;

  _ResolvedReportAssets({
    required this.patientUid,
    required this.imageUrls,
  });
}

// --------------------- Shared UI Widgets ---------------------

class _ConfidenceBar extends StatelessWidget {
  final String title;
  final double value;
  final Color barColor;
  final Color accent;

  const _ConfidenceBar({
    required this.title,
    required this.value,
    required this.barColor,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 1.0);
    final pct = (v * 100).toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w800,
            fontSize: 12,
            color: accent,
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Container(
            height: 12,
            color: Colors.black12,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: v,
              child: Container(color: barColor),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "$pct%",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 11,
            color: barColor,
          ),
        ),
      ],
    );
  }
}

class _RiskRow extends StatelessWidget {
  final String title;
  final String label;
  final Color color;

  const _RiskRow({
    required this.title,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w800,
            fontSize: 12,
            color: const Color(0xff7C4DFF),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 11,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LikelihoodMeter extends StatelessWidget {
  final String title;
  final double value;

  const _LikelihoodMeter({
    required this.title,
    required this.value,
  });

  static const _teal = Color(0xff00BFA5);
  static const _orange = Color(0xffFF8A65);

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 1.0);
    final pct = (v * 100).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _teal, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: _teal,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 12,
              value: v,
              backgroundColor: Colors.black12,
              valueColor: const AlwaysStoppedAnimation(_orange),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "$pct%",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: _orange,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagesGrid extends StatelessWidget {
  final List<String> urls;
  const _ImagesGrid({required this.urls});

  static const _pink = Color(0xffFF67CE);

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    if (urls.isEmpty) {
      return Text(
        t.noImagesForReport,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 12,
          color: _pink,
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: urls.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, i) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: _pink, width: 2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Image.network(
              urls[i],
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
              const Center(child: Icon(Icons.broken_image, size: 18)),
            ),
          ),
        );
      },
    );
  }
}

// ===================== SYMPTOM REPORTS LIST =====================

class _SymptomAssessmentsList extends StatelessWidget {
  final String firebaseUid;
  const _SymptomAssessmentsList({required this.firebaseUid});

  static const _pink = Color(0xffFF67CE);

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    final query = FirebaseFirestore.instance
        .collection("symptomAssessments")
        .doc(firebaseUid)
        .collection("items")
        .orderBy("createdAt", descending: true);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Text(
            "${t.failedToLoadReports} ${snap.error}",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: _pink,
            ),
          );
        }

        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              t.noSymptomReportsYet,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: _pink,
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: docs.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (_, i) {
            final data = docs[i].data();
            return _AnimatedEntry(
              delayMs: 80 + (i * 70),
              child: _SymptomAssessmentCard(data: data, docId: docs[i].id),
            );
          },
        );
      },
    );
  }
}

class _SymptomAssessmentCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final String docId;

  const _SymptomAssessmentCard({
    required this.data,
    required this.docId,
  });

  @override
  State<_SymptomAssessmentCard> createState() => _SymptomAssessmentCardState();
}

class _SymptomAssessmentCardState extends State<_SymptomAssessmentCard> {
  static const _pink = Color(0xffFF67CE);
  static const _purple = Color(0xff7C4DFF);
  static const _bg = Color(0xffFFF5FB);

  final GlobalKey _graphKey = GlobalKey();

  String _dateStr(DateTime? dt) =>
      dt == null ? "" : DateFormat("yyyy-MM-dd").format(dt);

  Color _riskColorFromLevel(String level) {
    switch (level.toUpperCase()) {
      case "HIGH":
        return Colors.redAccent;
      case "MEDIUM":
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  List<String> _asStringList(dynamic v) {
    if (v is List) return v.map((e) => e.toString()).toList();
    return const [];
  }

  List<String> _asKeyFindings(dynamic v) {
    if (v is List) {
      return v.map((e) {
        if (e is Map) {
          final title = (e["title"] ?? e["name"] ?? "Finding").toString();
          final desc = (e["description"] ?? e["detail"] ?? "").toString();
          return desc.isEmpty ? title : "$title: $desc";
        }
        return e.toString();
      }).toList();
    }
    if (v is Map) return v.entries.map((e) => "${e.key}: ${e.value}").toList();
    return const [];
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w700,
          fontSize: 11,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _bullets(String title, List<String> items, Color accent) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: accent,
            ),
          ),
          const SizedBox(height: 8),
          ...items.take(15).map(
                (x) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "• ",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w800,
                      color: accent,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      x,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: _pink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<Uint8List?> _captureGraphPng() async {
    try {
      final boundary =
      _graphKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  Future<void> _downloadPdf({
    required String riskLevel,
    required String urgency,
    required int score,
    required int uiRiskPercent,
    required List<String> keyFindings,
    required List<String> recommendedTests,
  }) async {
    final t = AppLocalizations.of(context)!;
    final graphPng = await _captureGraphPng();

    final doc = pw.Document();
    final baseFont = await PdfGoogleFonts.poppinsRegular();
    final boldFont = await PdfGoogleFonts.poppinsBold();

    final pdfPink = pdfc.PdfColor.fromInt(_pink.toARGB32());
    final pdfPurple = pdfc.PdfColor.fromInt(_purple.toARGB32());
    final pdfBg = pdfc.PdfColor.fromInt(_bg.toARGB32());
    final pdfRiskColor = pdfc.PdfColor.fromInt(_riskColorFromLevel(riskLevel).toARGB32());

    pw.Widget pill(String text, pdfc.PdfColor color) {
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: pw.BoxDecoration(
          color: color,
          borderRadius: pw.BorderRadius.circular(999),
        ),
        child: pw.Text(
          text,
          style: pw.TextStyle(
            font: boldFont,
            fontSize: 10,
            color: pdfc.PdfColors.white,
          ),
        ),
      );
    }

    pw.Widget bullets(String title, List<String> items, pdfc.PdfColor accent) {
      if (items.isEmpty) return pw.SizedBox();
      return pw.Container(
        margin: const pw.EdgeInsets.only(top: 10),
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: pdfc.PdfColors.white,
          borderRadius: pw.BorderRadius.circular(14),
          border: pw.Border.all(color: accent, width: 1.2),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(font: boldFont, fontSize: 12, color: accent),
            ),
            pw.SizedBox(height: 6),
            ...items.take(15).map(
                  (x) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "• ",
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 12,
                        color: accent,
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        x,
                        style: pw.TextStyle(font: baseFont, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    doc.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: baseFont, bold: boldFont),
        pageFormat: pdfc.PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (_) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: pdfBg,
              borderRadius: pw.BorderRadius.circular(18),
              border: pw.Border.all(color: pdfPink, width: 1.4),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  t.symptomAssessmentReportPdfTitle,
                  style: pw.TextStyle(font: boldFont, fontSize: 18, color: pdfPink),
                ),
                pw.SizedBox(height: 10),
                pw.Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    pill("${t.riskLevel}: $riskLevel", pdfRiskColor),
                    pill("${t.scoreLabel}: $score", pdfPurple),
                    pill("${t.riskLabel}: $uiRiskPercent%", pdfRiskColor),
                    if (urgency.isNotEmpty) pill("${t.urgencyLabel}: $urgency", pdfPurple),
                  ],
                ),
                pw.SizedBox(height: 14),
                if (graphPng != null)
                  pw.ClipRRect(
                    horizontalRadius: 12,
                    verticalRadius: 12,
                    child: pw.Image(pw.MemoryImage(graphPng), height: 200),
                  ),
              ],
            ),
          ),
          bullets(t.keyFindingsTitle, keyFindings, pdfPurple),
          bullets(t.recommendedTestsTitle, recommendedTests, pdfRiskColor),
          pw.SizedBox(height: 12),
          pw.Text(
            t.disclaimer,
            style: pw.TextStyle(
              font: baseFont,
              fontSize: 9,
              color: pdfc.PdfColors.grey700,
            ),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) async => doc.save(),
      name: "symptom_report_${widget.docId}.pdf",
    );

    if (!mounted) return;

    AwesomeDialog(
      context: context,
      dialogType: DialogType.success,
      animType: AnimType.scale,
      title: t.pdfReadyTitle,
      desc: t.pdfReadyDesc,
      btnOkText: t.ok,
      btnOkOnPress: () {},
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    final result = (widget.data["result"] is Map)
        ? (widget.data["result"] as Map).cast<String, dynamic>()
        : <String, dynamic>{};

    final riskLevel =
    (result["riskLevel"] ?? widget.data["riskLevel"] ?? "UNKNOWN").toString();
    final urgency = (result["urgency"] ?? widget.data["urgency"] ?? "").toString();

    final score = (result["score"] is num)
        ? (result["score"] as num).toInt()
        : (widget.data["score"] is num)
        ? (widget.data["score"] as num).toInt()
        : 0;

    final uiRiskPercent = (widget.data["uiRiskPercent"] is num)
        ? (widget.data["uiRiskPercent"] as num).toInt()
        : (result["uiRiskPercent"] is num)
        ? (result["uiRiskPercent"] as num).toInt()
        : 0;

    final recommendedTests = _asStringList(
      result["recommendedTests"] ??
          result["recommendedTest"] ??
          widget.data["recommendedTests"] ??
          widget.data["recommendedTest"],
    );

    final keyFindings = _asKeyFindings(
      result["keyFindings"] ?? widget.data["keyFindings"],
    );

    final createdAt = (widget.data["createdAt"] as Timestamp?)?.toDate();
    final dateStr = _dateStr(createdAt);

    final riskColor = _riskColorFromLevel(riskLevel);
    final v = (uiRiskPercent.clamp(0, 100)) / 100.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _pink, width: 2),
        color: _bg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  t.symptomDiagnosisTitle,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: _pink,
                  ),
                ),
              ),
              if (dateStr.isNotEmpty)
                Text(
                  dateStr,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    color: _pink,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _pill("${t.riskLevel}: $riskLevel", riskColor),
              _pill("${t.scoreLabel}: $score", _purple),
              _pill("${t.riskLabel}: ${uiRiskPercent.clamp(0, 100)}%", riskColor),
              if (urgency.isNotEmpty) _pill("${t.urgencyLabel}: $urgency", _purple),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 12,
              value: v,
              backgroundColor: Colors.black12,
              valueColor: AlwaysStoppedAnimation(riskColor),
            ),
          ),
          const SizedBox(height: 12),
          RepaintBoundary(
            key: _graphKey,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _purple, width: 1.2),
              ),
              child: SizedBox(
                height: 190,
                width: double.infinity,
                child: CustomPaint(
                  painter: _SymptomGraphPainter(
                    riskPercent: uiRiskPercent.clamp(0, 100),
                    score: score,
                    riskLevel: riskLevel,
                    urgency: urgency,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _pink,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => _downloadPdf(
                riskLevel: riskLevel,
                urgency: urgency,
                score: score,
                uiRiskPercent: uiRiskPercent.clamp(0, 100),
                keyFindings: keyFindings,
                recommendedTests: recommendedTests,
              ),
              icon: const Icon(Icons.download, color: Colors.white, size: 18),
              label: Text(
                t.downloadPdf,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          _bullets(t.keyFindingsTitle, keyFindings, _purple),
          _bullets(t.recommendedTestsTitle, recommendedTests, riskColor),
        ],
      ),
    );
  }
}

class _SymptomGraphPainter extends CustomPainter {
  final int riskPercent;
  final int score;
  final String riskLevel;
  final String urgency;

  _SymptomGraphPainter({
    required this.riskPercent,
    required this.score,
    required this.riskLevel,
    required this.urgency,
  });

  int _urgencyPercent() {
    switch (urgency.toUpperCase()) {
      case "URGENT":
        return 95;
      case "HIGH":
        return 85;
      case "MEDIUM":
        return 60;
      case "LOW":
        return 30;
      default:
        return 40;
    }
  }

  int _riskLevelPercent() {
    switch (riskLevel.toUpperCase()) {
      case "HIGH":
        return 85;
      case "MEDIUM":
        return 55;
      case "LOW":
        return 25;
      default:
        return 40;
    }
  }

  int _scorePercent() {
    const maxScore = 200;
    final s = score.clamp(0, maxScore);
    return ((s / maxScore) * 100).round();
  }

  @override
  void paint(Canvas canvas, Size size) {
    const topPad = 16.0;
    const bottomPad = 22.0;
    const leftPad = 8.0;
    const rightPad = 8.0;

    final chartW = size.width - leftPad - rightPad;
    final chartH = size.height - topPad - bottomPad;
    final baseY = topPad + chartH;

    final bgPaint = Paint()
      ..color = Colors.black12
      ..style = PaintingStyle.fill;

    final fillPaint = Paint()
      ..color = const Color(0xffFF67CE)
      ..style = PaintingStyle.fill;

    final axisPaint = Paint()
      ..color = const Color(0xff7C4DFF)
      ..strokeWidth = 2;

    final framePaint = Paint()
      ..color = const Color(0xff7C4DFF).withOpacity(0.20)
      ..strokeWidth = 1;

    final values = <int>[
      riskPercent.clamp(0, 100),
      _scorePercent().clamp(0, 100),
      _riskLevelPercent().clamp(0, 100),
      _urgencyPercent().clamp(0, 100),
    ];

    const labels = ["Risk%", "Score", "RiskLvl", "Urgency"];

    canvas.drawLine(Offset(leftPad, topPad), Offset(size.width - rightPad, topPad), framePaint);
    canvas.drawLine(Offset(leftPad, baseY), Offset(size.width - rightPad, baseY), axisPaint);

    final n = values.length;
    final slotW = chartW / n;
    final barW = slotW * 0.38;
    final radius = const Radius.circular(14);

    for (int i = 0; i < n; i++) {
      final centerX = leftPad + slotW * (i + 0.5);
      final x = centerX - barW / 2;
      final pct = values[i] / 100.0;
      final barH = chartH * pct;

      final bgRect = Rect.fromLTWH(x, topPad, barW, chartH);
      canvas.drawRRect(RRect.fromRectAndRadius(bgRect, radius), bgPaint);

      final fillRect = Rect.fromLTWH(x, baseY - barH, barW, barH);
      canvas.drawRRect(RRect.fromRectAndRadius(fillRect, radius), fillPaint);

      final valuePainter = TextPainter(
        text: TextSpan(
          text: "${values[i]}%",
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Color(0xff7C4DFF),
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: ui.TextDirection.ltr,
      )..layout(maxWidth: slotW);

      final valueY = (baseY - barH - 16).clamp(topPad - 2, baseY - 18).toDouble();
      valuePainter.paint(canvas, Offset(centerX - valuePainter.width / 2, valueY));

      final labelPainter = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Color(0xff7C4DFF),
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: ui.TextDirection.ltr,
      )..layout(maxWidth: slotW);

      labelPainter.paint(canvas, Offset(centerX - labelPainter.width / 2, baseY + 4));
    }
  }

  @override
  bool shouldRepaint(covariant _SymptomGraphPainter oldDelegate) {
    return oldDelegate.riskPercent != riskPercent ||
        oldDelegate.score != score ||
        oldDelegate.riskLevel != riskLevel ||
        oldDelegate.urgency != urgency;
  }
}
