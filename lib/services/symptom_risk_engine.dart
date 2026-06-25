import 'package:project/models/symptom_intake.dart';
import 'package:project/models/symptom_result.dart';

class SymptomRiskEngine {
  /// answers: Map<QuestionId, bool>
  static SymptomResult evaluate({
    required Map<String, bool> answers,
    required int? age,
    required SymptomIntake intake,
  }) {
    bool yes(String id) => answers[id] == true;
    final a = age ?? 0;

    int score = 0;
    final redFlags = <String>[];
    final findings = <String>[];
    final tests = <String>{};
    final nextSteps = <String>[];

    // ---------------------------
    // CRITICAL RED FLAGS
    // ---------------------------
    if (yes("q_bloody_discharge")) {
      score += 28;
      redFlags.add("Bloody nipple discharge");
      tests.add("Urgent clinical breast examination");
      tests.add("Breast ultrasound");
      if (a >= 30) tests.add("Diagnostic mammogram");
    }

    if (yes("q_peau_dorange")) {
      score += 28;
      redFlags.add("Peau d’orange (orange-peel skin texture)");
      tests.add("Urgent clinical breast examination");
      tests.add("Breast ultrasound");
      if (a >= 30) tests.add("Diagnostic mammogram");
    }

    if (yes("q_skin_dimpling")) {
      score += 18;
      redFlags.add("Skin dimpling / pulling");
      tests.add("Clinical breast examination");
      tests.add("Breast ultrasound");
      if (a >= 30) tests.add("Diagnostic mammogram");
    }

    if (yes("q_new_nipple_inversion")) {
      score += 16;
      redFlags.add("New nipple inversion");
      tests.add("Clinical breast examination");
      tests.add("Breast ultrasound");
      if (a >= 30) tests.add("Diagnostic mammogram");
    }

    if (yes("q_axillary_nodes")) {
      score += 18;
      redFlags.add("Swollen lymph nodes (underarm/neck)");
      tests.add("Clinical examination (breast + lymph nodes)");
      tests.add("Breast + axillary ultrasound");
    }

    // ---------------------------
    // LUMP / MASS PATTERN
    // ---------------------------
    final hasLump = yes("q_lump_present");
    if (hasLump) {
      score += 14;
      findings.add("Breast lump reported");
      tests.add("Clinical breast examination");
      if (a < 30) {
        tests.add("Breast ultrasound (first imaging under ~30)");
      } else if (a < 40) {
        tests.add("Breast ultrasound");
        tests.add("Diagnostic mammogram (if clinician advises)");
      } else {
        tests.add("Diagnostic mammogram");
        tests.add("Breast ultrasound (as advised)");
      }
    }

    if (yes("q_lump_hard_fixed")) {
      score += 16;
      findings.add("Hard/fixed lump features");
      tests.add("Targeted imaging of suspicious area");
    }

    if (yes("q_lump_growing")) {
      score += 14;
      findings.add("Lump is growing/changing");
      tests.add("Repeat imaging / urgent review");
    }

    // ---------------------------
    // INFECTION / INFLAMMATION
    // ---------------------------
    if (yes("q_fever_redness")) {
      score += 10;
      findings.add("Fever/redness pattern (possible infection)");
      tests.add("Doctor assessment for infection (mastitis/abscess)");
      tests.add("Breast ultrasound (to rule out abscess if needed)");
    }

    // ---------------------------
    // INTAKE: DURATION, HISTORY, RISK FACTORS
    // ---------------------------
    final weeks = intake.symptomDurationWeeks ?? 0;

    if (weeks >= 8) {
      score += 8;
      findings.add("Symptoms lasting ≥ 8 weeks");
    } else if (weeks >= 4) {
      score += 5;
      findings.add("Symptoms lasting ≥ 4 weeks");
    }

    if (intake.familyHistoryFirstDegree) {
      score += 10;
      findings.add("First-degree family history");
      tests.add("Clinician risk assessment");
      tests.add("Consider genetic counseling/testing if strong family history");
    }

    if (intake.geneticMutationKnown) {
      score += 18;
      findings.add("Known genetic mutation risk (e.g., BRCA)");
      tests.add("Specialist breast clinic referral");
    }

    if (intake.priorBreastCancer) {
      score += 18;
      findings.add("Previous breast cancer history");
      tests.add("Specialist follow-up review");
    }

    if (intake.onHormoneTherapy) {
      score += 4;
      findings.add("Hormone therapy / hormonal medication use");
    }

    if (intake.weightLossOrFatigue) {
      score += 4;
      findings.add("Systemic symptoms (fatigue/weight loss)");
    }

    // ---------------------------
    // AGE ADJUSTMENT (small)
    // ---------------------------
    if (a >= 50) score += 10;
    else if (a >= 40) score += 7;
    else if (a >= 30) score += 3;

    // ---------------------------
    // FINAL DECISION
    // ---------------------------
    final hasCriticalRedFlag = redFlags.isNotEmpty;

    String riskLevel;
    String urgency;

    // ✅ High if critical red flag OR strong lump + duration + risk factor OR score high
    if (hasCriticalRedFlag || score >= 55) {
      riskLevel = "HIGH";
      urgency = "URGENT";
      tests.add("Biopsy referral (ONLY if imaging/doctor finds suspicious area)");
      nextSteps.add("Book an urgent appointment with a breast specialist/doctor.");
      nextSteps.add("Do not delay if symptoms are new/worsening or include skin changes/discharge.");
    } else if (score >= 28) {
      riskLevel = "MEDIUM";
      urgency = "SOON";
      nextSteps.add("Book a doctor appointment soon for evaluation.");
      nextSteps.add("Track symptoms (lump size, pain, discharge) and share details with doctor.");
    } else {
      riskLevel = "LOW";
      urgency = "ROUTINE";
      nextSteps.add("Monitor symptoms and repeat self-check after a short interval.");
      nextSteps.add("Seek medical advice if symptoms persist > 2 weeks or any red-flag symptom appears.");
    }

    final explanation = _explain(riskLevel, redFlags, findings, weeks);

    // Always include minimum recommended baseline test wording
    tests.add("Clinical breast examination by a qualified doctor");

    return SymptomResult(
      riskLevel: riskLevel,
      urgency: urgency,
      score: score,
      redFlags: redFlags,
      keyFindings: findings,
      recommendedTests: tests.toList(),
      nextSteps: nextSteps,
      explanation: explanation,
      disclaimer:
      "This is symptom-based screening only and is NOT a confirmed diagnosis. "
          "Only a doctor with appropriate tests (imaging/biopsy) can confirm cancer.",
    );
  }

  static String _explain(
      String level,
      List<String> redFlags,
      List<String> findings,
      int durationWeeks,
      ) {
    final d = durationWeeks <= 0 ? "" : " Symptoms duration: ${durationWeeks} week(s).";
    if (level == "HIGH") {
      return "Your answers include higher-concern patterns "
          "${redFlags.isNotEmpty ? "(e.g., ${redFlags.take(2).join(", ")})" : ""}. "
          "This does NOT confirm cancer, but urgent medical evaluation is recommended.$d";
    }
    if (level == "MEDIUM") {
      return "Your answers suggest a moderate concern pattern. "
          "Many non-cancer conditions can cause similar symptoms, but follow-up testing is recommended.$d";
    }
    return "Your answers suggest a lower concern pattern. "
        "This does not rule out disease. If symptoms persist or worsen, consult a doctor.$d";
  }
}
