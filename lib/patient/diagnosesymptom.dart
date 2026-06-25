// lib/patient/diagnose_symptoms.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project/patient/rootpage.dart';
import 'package:project/l10n/app_localizations.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:project/models/patient_profile.dart';
import 'package:project/models/symptom_question.dart';
import 'package:project/models/symptom_questions.dart';
import 'package:project/models/symptom_result.dart';
import 'package:project/models/symptom_intake.dart';
import 'package:project/services/symptom_risk_engine.dart';

class DiagnoseSymptoms extends StatefulWidget {
  const DiagnoseSymptoms({super.key});

  @override
  State<DiagnoseSymptoms> createState() => _DiagnoseSymptomsState();
}

enum _ItemType { sectionHeader, intakeText, intakeToggle, symptomToggle }

class _FormItem {
  final _ItemType type;

  // For symptom question
  final SymptomQuestion? q;

  // For intake
  final String? keyName; // used for toggle/text storage
  final String? label;
  final String? helper;

  const _FormItem._({
    required this.type,
    this.q,
    this.keyName,
    this.label,
    this.helper,
  });

  factory _FormItem.section(String title) =>
      _FormItem._(type: _ItemType.sectionHeader, label: title);

  factory _FormItem.intakeToggle({
    required String key,
    required String label,
    String? helper,
  }) =>
      _FormItem._(
        type: _ItemType.intakeToggle,
        keyName: key,
        label: label,
        helper: helper,
      );

  factory _FormItem.intakeText({
    required String key,
    required String label,
    String? helper,
  }) =>
      _FormItem._(
        type: _ItemType.intakeText,
        keyName: key,
        label: label,
        helper: helper,
      );

  factory _FormItem.symptom(SymptomQuestion q) =>
      _FormItem._(type: _ItemType.symptomToggle, q: q);
}

class _DiagnoseSymptomsState extends State<DiagnoseSymptoms> {
  static const _pink = Color(0xffFF67CE);
  static const _doneGreen = Color(0xFF2ECC71);
  static const _currentOrange = Color(0xFFFF9800);
  static const _remainingRed = Color(0xFFE53935);

  static const int _pages = 5;
  static const int _perPage = 10;
  static const int _maxItemsToShow = _pages * _perPage; // 50

  // ✅ score normalization (change if your engine uses another max)
  static const int _scoreMax = 200;

  final _pageController = PageController();
  int _pageIndex = 0;

  bool _saving = false;
  bool _loading = true;

  PatientProfile? _patient;

  // Intake values
  final Map<String, bool> _toggleValues = {};
  final Map<String, TextEditingController> _textCtrls = {};

  // Symptom answers (switches for each question.id)
  final Map<String, bool> _symptomSwitch = {};

  // Items across all pages
  List<_FormItem> _items = [];

  // ✅ Only pages the user actually completed (pressed Next successfully)
  final Set<int> _completedPages = {};

  @override
  void initState() {
    super.initState();
    _initPatientAndBuildFlow();
  }

  @override
  void dispose() {
    for (final c in _textCtrls.values) {
      c.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  // ✅ Firestore notification helper (same structure your Notifications page expects)
  Future<void> _pushNotification({
    required String uid,
    required String message,
    String type = "symptoms",
    String? refId, // optional: store assessment doc id later if you want
    bool isSuccess = true,
  }) async {
    await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("notifications")
        .add({
      "message": message,
      "isRead": false,
      "createdAt": FieldValue.serverTimestamp(),
      "type": type,
      "refId": refId,
      "status": isSuccess ? "success" : "failed",
    });
  }

  // localization for symptomQ1..symptomQ50
  List<String> _localizedQuestions(AppLocalizations t) => [
    t.symptomQ1,
    t.symptomQ2,
    t.symptomQ3,
    t.symptomQ4,
    t.symptomQ5,
    t.symptomQ6,
    t.symptomQ7,
    t.symptomQ8,
    t.symptomQ9,
    t.symptomQ10,
    t.symptomQ11,
    t.symptomQ12,
    t.symptomQ13,
    t.symptomQ14,
    t.symptomQ15,
    t.symptomQ16,
    t.symptomQ17,
    t.symptomQ18,
    t.symptomQ19,
    t.symptomQ20,
    t.symptomQ21,
    t.symptomQ22,
    t.symptomQ23,
    t.symptomQ24,
    t.symptomQ25,
    t.symptomQ26,
    t.symptomQ27,
    t.symptomQ28,
    t.symptomQ29,
    t.symptomQ30,
    t.symptomQ31,
    t.symptomQ32,
    t.symptomQ33,
    t.symptomQ34,
    t.symptomQ35,
    t.symptomQ36,
    t.symptomQ37,
    t.symptomQ38,
    t.symptomQ39,
    t.symptomQ40,
    t.symptomQ41,
    t.symptomQ42,
    t.symptomQ43,
    t.symptomQ44,
    t.symptomQ45,
    t.symptomQ46,
    t.symptomQ47,
    t.symptomQ48,
    t.symptomQ49,
    t.symptomQ50,
  ];

  String _textFromL10nKey(List<String> qs, String l10nKey) {
    final match = RegExp(r'^symptomQ(\d+)$').firstMatch(l10nKey);
    if (match == null) return l10nKey;
    final n = int.tryParse(match.group(1) ?? "");
    if (n == null) return l10nKey;
    final idx = n - 1;
    if (idx < 0 || idx >= qs.length) return l10nKey;
    return qs[idx];
  }

  int get _lastPageIndex {
    if (_items.isEmpty) return 0;
    final last = ((_items.length - 1) / _perPage).floor();
    return last.clamp(0, _pages - 1);
  }

  Future<void> _initPatientAndBuildFlow() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }

    try {
      final doc =
      await FirebaseFirestore.instance.collection("users").doc(user.uid).get();
      final data = doc.data();

      final firstName = (data?["firstName"] ?? "").toString();
      final lastName = (data?["lastName"] ?? "").toString();
      final name = ("$firstName $lastName").trim();
      final email = (data?["email"] ?? (user.email ?? "")).toString();

      final dynamic ageRaw = data?["age"];
      int? age;
      if (ageRaw is int) {
        age = ageRaw;
      } else if (ageRaw != null) {
        age = int.tryParse(ageRaw.toString());
      }

      final patient = PatientProfile(
        uid: user.uid,
        name: name.isEmpty ? "Patient" : name,
        email: email,
        age: age,
      );

      // ✅ SHOW ALL questions always
      final allQuestions = SymptomQuestions.all;

      // Symptom switches default false
      _symptomSwitch.clear();
      for (final q in allQuestions) {
        _symptomSwitch[q.id] = false;
      }

      final intake = _buildBigIntakeItems();

      final items = <_FormItem>[
        ...intake,
        ...allQuestions.map(_FormItem.symptom),
      ];

      // Cap to UI limit 50
      final capped =
      items.length > _maxItemsToShow ? items.take(_maxItemsToShow).toList() : items;

      // Init intake storage
      for (final it in capped) {
        if (it.type == _ItemType.intakeToggle) {
          _toggleValues.putIfAbsent(it.keyName!, () => false);
        } else if (it.type == _ItemType.intakeText) {
          _textCtrls.putIfAbsent(it.keyName!, () => TextEditingController());
        }
      }

      if (!mounted) return;
      setState(() {
        _patient = patient;
        _items = capped;
        _loading = false;
        _pageIndex = 0;
        _completedPages.clear(); // ✅ important: no pre-completion
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  // Intake + history sections (fits inside 50 with symptom list)
  List<_FormItem> _buildBigIntakeItems() {
    // ✅ If you want these localized later, I can convert labels to t.xxx keys.
    return [
      _FormItem.section("Background / timeline"),
      _FormItem.intakeText(
        key: "symptomDurationWeeks",
        label: "How many weeks have symptoms been present?",
        helper: "Enter number of weeks (e.g., 2).",
      ),
      _FormItem.intakeToggle(
        key: "firstTimeNoticed",
        label: "This is the first time you noticed these symptoms?",
      ),
      _FormItem.section("Current symptoms / breast changes"),
      _FormItem.intakeToggle(key: "pain", label: "Breast pain?"),
      _FormItem.intakeToggle(key: "lump", label: "Breast lump felt?"),
      _FormItem.intakeToggle(key: "lumpGrowing", label: "Lump is growing / changing?"),
      _FormItem.intakeToggle(key: "discharge", label: "Nipple discharge?"),
      _FormItem.intakeToggle(key: "bloodyDischarge", label: "Discharge is bloody?"),
      _FormItem.intakeToggle(key: "skinDimpling", label: "Skin dimpling / pulling?"),
      _FormItem.intakeToggle(key: "nippleInversion", label: "New nipple inversion?"),
      _FormItem.intakeToggle(
          key: "swollenNodes", label: "Swollen lymph nodes (underarm/neck)?"),
      _FormItem.section("Family history"),
      _FormItem.intakeToggle(
        key: "familyHistoryFirstDegree",
        label: "First-degree family history (mother/sister/daughter)?",
      ),
      _FormItem.intakeToggle(
        key: "familyHistorySecondDegree",
        label: "Second-degree family history (aunt/grandmother)?",
      ),
      _FormItem.intakeToggle(
        key: "knownBRCA",
        label: "Known genetic mutation risk (e.g., BRCA)?",
      ),
      _FormItem.section("Past medical history"),
      _FormItem.intakeToggle(
          key: "priorBreastCancer", label: "Previous breast cancer history?"),
      _FormItem.intakeToggle(
          key: "priorBreastBiopsy", label: "Previous breast biopsy?"),
      _FormItem.intakeToggle(
          key: "priorBreastSurgery", label: "Any breast surgery in past?"),
      _FormItem.section("Hormonal / reproductive"),
      _FormItem.intakeToggle(key: "pregnant", label: "Currently pregnant?"),
      _FormItem.intakeToggle(key: "breastfeeding", label: "Breastfeeding currently?"),
      _FormItem.intakeToggle(
          key: "hormoneTherapy", label: "On hormone therapy / hormonal meds?"),
      _FormItem.intakeToggle(
          key: "onBirthControl", label: "Using hormonal birth control?"),
      _FormItem.section("Lifestyle / general"),
      _FormItem.intakeToggle(key: "smoker", label: "Smoker?"),
      _FormItem.intakeToggle(key: "alcohol", label: "Frequent alcohol use?"),
      _FormItem.intakeToggle(
          key: "weightLossOrFatigue", label: "Unexplained fatigue/weight loss?"),
    ];
  }

  // ✅ Completion rules:
  // Only require weeks text if it appears on that page.
  bool _isPageComplete(int page) {
    final start = page * _perPage;
    if (start >= _items.length) return false;

    final end = (start + _perPage).clamp(0, _items.length);

    for (int i = start; i < end; i++) {
      final it = _items[i];
      if (it.type == _ItemType.intakeText && it.keyName == "symptomDurationWeeks") {
        final txt = _textCtrls["symptomDurationWeeks"]?.text.trim() ?? "";
        final w = int.tryParse(txt);
        if (w == null) return false;
      }
    }
    return true;
  }

  Future<void> _goToPage(int index) async {
    FocusScope.of(context).unfocus(); // ✅ close keyboard before navigation
    final safe = index.clamp(0, _lastPageIndex);
    setState(() => _pageIndex = safe);
    await _pageController.animateToPage(
      safe,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
  }

  void _showIncompleteSnack(AppLocalizations t) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t.pleaseAnswerAllQuestions)),
    );
  }

  Future<void> _onNext(AppLocalizations t) async {
    if (!_isPageComplete(_pageIndex)) {
      _showIncompleteSnack(t);
      return;
    }

    // ✅ Mark this page completed ONLY when user successfully moves forward
    setState(() => _completedPages.add(_pageIndex));

    if (_pageIndex < _lastPageIndex) {
      await _goToPage(_pageIndex + 1);
    }
  }

  Future<void> _onBack() async {
    if (_pageIndex == 0) return;
    await _goToPage(_pageIndex - 1);
  }

  // ------------------- RESULT UI HELPERS -------------------

  Color _riskColor(String level) {
    switch (level) {
      case "HIGH":
        return _remainingRed;
      case "MEDIUM":
        return _currentOrange;
      default:
        return _doneGreen;
    }
  }

  List<Color> _riskGradient(String level) {
    switch (level) {
      case "HIGH":
        return const [Color(0xFFFF4D6D), Color(0xFFFF8FA3)];
      case "MEDIUM":
        return const [Color(0xFFFFA000), Color(0xFFFFD54F)];
      default:
        return const [Color(0xFF00C853), Color(0xFF69F0AE)];
    }
  }

  IconData _riskIcon(String level) {
    switch (level) {
      case "HIGH":
        return Icons.warning_rounded;
      case "MEDIUM":
        return Icons.info_rounded;
      default:
        return Icons.check_circle_rounded;
    }
  }

  // ✅ Convert score to 0–100% so it never shows 138%
  int _scoreToRiskPercent(int score) {
    final pct = ((score / _scoreMax) * 100.0);
    return pct.clamp(0.0, 100.0).round();
  }

  String _riskTitle(String level) {
    switch (level) {
      case "HIGH":
        return "Higher Concern Pattern";
      case "MEDIUM":
        return "Moderate Concern Pattern";
      default:
        return "Lower Concern Pattern";
    }
  }

  String _urgencyLine(String urgency) {
    switch (urgency) {
      case "URGENT":
        return "Urgency: Seek medical evaluation as soon as possible.";
      case "SOON":
        return "Urgency: Needs medical evaluation soon.";
      default:
        return "Urgency: Monitor unless symptoms persist or worsen.";
    }
  }

  Widget _bulletItem(String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Icon(Icons.circle, size: 7, color: color ?? _pink),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Sweet dialog (no patient/email, no red flags, no next steps, no raw score)
  Future<void> _showResultDialogEnhanced(AppLocalizations t, SymptomResult r) async {
    final badgeColor = _riskColor(r.riskLevel);
    final grad = _riskGradient(r.riskLevel);
    final icon = _riskIcon(r.riskLevel);
    final title = _riskTitle(r.riskLevel);

    final int riskPercent = _scoreToRiskPercent(r.score);
    final String explanation = r.explanation.trim();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: grad,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withOpacity(0.35)),
                      ),
                      child: Icon(icon, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        "$riskPercent% Risk",
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: badgeColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Body
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: badgeColor.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: badgeColor.withOpacity(0.35)),
                        ),
                        child: Text(
                          _urgencyLine(r.urgency),
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF2B2B2B),
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        explanation,
                        style: GoogleFonts.poppins(fontSize: 13, height: 1.35),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        "Recommended tests to confirm:",
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 10),
                      for (final test in r.recommendedTests.take(10))
                        _bulletItem(test, color: badgeColor),
                      const SizedBox(height: 8),
                      Text(
                        r.disclaimer,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: const Color(0xFF555555),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Footer button
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _pink,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      t.ok,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------- FINISH -------------------

  Future<void> _onFinish(AppLocalizations t) async {
    if (!_isPageComplete(_pageIndex)) {
      _showIncompleteSnack(t);
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t.pleaseLoginFirst)));
      return;
    }

    final patient = _patient;
    if (patient == null) {
      _showIncompleteSnack(t);
      return;
    }

    setState(() => _saving = true);

    try {
      final weeks = int.tryParse(_textCtrls["symptomDurationWeeks"]?.text.trim() ?? "");

      final intake = SymptomIntake(
        symptomDurationWeeks: weeks,
        familyHistoryFirstDegree: _toggleValues["familyHistoryFirstDegree"] == true,
        geneticMutationKnown: _toggleValues["knownBRCA"] == true,
        priorBreastCancer: _toggleValues["priorBreastCancer"] == true,
        currentlyPregnant: _toggleValues["pregnant"] == true,
        breastfeeding: _toggleValues["breastfeeding"] == true,
        onHormoneTherapy: _toggleValues["hormoneTherapy"] == true,
        smoker: _toggleValues["smoker"] == true,
        weightLossOrFatigue: _toggleValues["weightLossOrFatigue"] == true,
      );

      // Symptom answers (true/false)
      final Map<String, bool> finalAnswers = {};
      for (final q in SymptomQuestions.all) {
        finalAnswers[q.id] = _symptomSwitch[q.id] == true;
      }

      final result = SymptomRiskEngine.evaluate(
        answers: finalAnswers,
        age: patient.age,
        intake: intake,
      );

      // ✅ Save assessment and capture docId (so notification can link to it later)
      final docRef = await FirebaseFirestore.instance
          .collection("symptomAssessments")
          .doc(user.uid)
          .collection("items")
          .add({
        "firebaseUid": user.uid,
        "createdAt": FieldValue.serverTimestamp(),
        "patient": patient.toMap(),
        "intake": intake.toMap(),
        "intakeExtra": {
          "toggles": _toggleValues,
          "texts": _textCtrls.map((k, v) => MapEntry(k, v.text)),
        },
        "answers": finalAnswers,
        "result": result.toMap(),
        "uiRiskPercent": _scoreToRiskPercent(result.score),
      });

      // ✅ Send notification (badge count++ automatically because isRead=false)
      final riskPercent = _scoreToRiskPercent(result.score);
      final notifMsg =
          "Symptoms assessment complete: ${result.riskLevel} risk ($riskPercent%).";

      await _pushNotification(
        uid: user.uid,
        message: notifMsg,
        type: "symptoms",
        refId: docRef.id,
        isSuccess: true,
      );

      if (!mounted) return;

      await _showResultDialogEnhanced(t, result);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.symptomsSavedSuccessfully)),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const RootPage()),
            (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      // ✅ Optional: notify failure
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await _pushNotification(
            uid: user.uid,
            message: "Symptoms assessment failed. Please try again.",
            type: "symptoms",
            isSuccess: false,
          );
        }
      } catch (_) {
        // ignore notification failure
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${t.failedToSaveSymptoms} $e")),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // -------------------- UI --------------------

  Widget _stepper(AppLocalizations t) {
    Color stepColor(int index) {
      final isActive = index == _pageIndex;
      final isDone = _completedPages.contains(index);
      if (isActive) return _currentOrange;
      if (isDone) return _doneGreen;
      return _remainingRed;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pages, (index) {
        final isDone = _completedPages.contains(index);
        final isActive = index == _pageIndex;
        final color = stepColor(index);

        return Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: isActive ? 2 : 0),
              ),
              child: Center(
                child: isDone
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : Text(
                  "${index + 1}",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            if (index != _pages - 1)
              Container(width: 35, height: 2, color: color),
          ],
        );
      }),
    );
  }

  Widget _cardContainer({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xffFFF5FB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _pink, width: 1.5),
      ),
      child: child,
    );
  }

  Widget _sectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: _pink,
        ),
      ),
    );
  }

  Widget _intakeTextCard(String label, String key, {String? helper}) {
    final ctrl = _textCtrls.putIfAbsent(key, () => TextEditingController());

    return _cardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700)),
          if (helper != null) ...[
            const SizedBox(height: 6),
            Text(helper, style: GoogleFonts.poppins(fontSize: 12)),
          ],
          const SizedBox(height: 8),
          TextField(
            controller: ctrl,
            keyboardType: key == "symptomDurationWeeks"
                ? TextInputType.number
                : TextInputType.text,
            enabled: !_saving,
            decoration: InputDecoration(
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _pink, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleCard(String label, String key) {
    final value = _toggleValues[key] ?? false;

    return _cardContainer(
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          Switch(
            value: value,
            onChanged: _saving ? null : (v) => setState(() => _toggleValues[key] = v),
            activeColor: _pink,
          ),
        ],
      ),
    );
  }

  Widget _symptomToggleCard(
      AppLocalizations t, List<String> l10nList, SymptomQuestion q) {
    final value = _symptomSwitch[q.id] ?? false;

    return _cardContainer(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              _textFromL10nKey(l10nList, q.l10nKey),
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: _pink,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged:
            _saving ? null : (v) => setState(() => _symptomSwitch[q.id] = v),
            activeColor: _pink,
          ),
        ],
      ),
    );
  }

  Widget _page(AppLocalizations t, List<String> l10nList, int pageIndex) {
    final start = pageIndex * _perPage;
    final end = (start + _perPage).clamp(0, _items.length);

    return ListView(
      padding: const EdgeInsets.only(top: 6, bottom: 120),
      children: [
        Center(
          child: Text(
            "${t.pageLabel} ${pageIndex + 1}/$_pages",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: _pink,
            ),
          ),
        ),
        const SizedBox(height: 12),
        for (int i = start; i < end; i++)
          Builder(builder: (_) {
            final it = _items[i];

            if (it.type == _ItemType.sectionHeader) return _sectionHeader(it.label!);
            if (it.type == _ItemType.intakeText) {
              return _intakeTextCard(it.label!, it.keyName!, helper: it.helper);
            }
            if (it.type == _ItemType.intakeToggle) {
              return _toggleCard(it.label!, it.keyName!);
            }
            return _symptomToggleCard(t, l10nList, it.q!);
          }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final l10nList = _localizedQuestions(t);
    final bool keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    final bool onLastPage = (_pageIndex == _lastPageIndex);
    final String btnText = (_pageIndex == 0) ? t.next : (onLastPage ? t.finish : t.next);

    final VoidCallback? btnAction =
    _saving ? null : (onLastPage ? () => _onFinish(t) : () => _onNext(t));

    return Stack(
      children: [
        Scaffold(
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
          body: SafeArea(
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
                        icon: const Icon(Icons.arrow_back_ios_new,
                            color: _pink, size: 18),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const RootPage()),
                          );
                        },
                      ),
                    ),
                  ),
                  if (!keyboardOpen) ...[
                    Image.asset("assets/images/uploadimage.png", width: 373, height: 249),
                    const SizedBox(height: 10),
                  ],
                  Text(
                    t.diagnoseSymptomsTitle,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: keyboardOpen ? 22 : 27,
                      color: _pink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _stepper(t),
                  const SizedBox(height: 16),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (i) => setState(() => _pageIndex = i),
                      children: List.generate(_pages, (i) => _page(t, l10nList, i)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  if (_pageIndex != 0) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving ? null : _onBack,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: _pink, width: 1.5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          t.back,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            color: _pink,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      onPressed: btnAction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _pink,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        btnText,
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
        if (_saving)
          Container(
            color: Colors.black.withOpacity(0.35),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}