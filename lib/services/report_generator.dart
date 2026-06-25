class ReportGenerator {
  /// Main entry: returns a FULL patient-facing report as plain text.
  /// You can store this string in Firebase directly.
  static String generate({
    required String predictedLabel,
    required bool isMalignant,
    required double confidence, // 0..1
  }) {
    final pct = (confidence * 100).toStringAsFixed(1);

    // Human-friendly name
    final readable = _prettyLabel(predictedLabel);

    // Disease-specific sections (if we have a template)
    final template = _templates[predictedLabel];

    // Fallback (if label not in templates)
    final diseaseIntro = template?.intro ??
        (isMalignant
            ? "Your result suggests a malignant (cancerous) pattern. This does NOT replace a doctor’s diagnosis. It means you should seek medical evaluation urgently."
            : "Your result suggests a benign (non-cancerous) pattern. This does NOT replace a doctor’s diagnosis, but benign findings are commonly manageable.");

    final symptoms = template?.symptoms ??
        (isMalignant
            ? [
          "A lump that grows over time",
          "Skin dimpling or thickening",
          "Nipple inversion or discharge (sometimes bloody)",
          "Persistent breast pain (not always present)",
          "Swollen lymph nodes (armpit/near collarbone)",
        ]
            : [
          "A breast lump that may feel smooth and movable",
          "Usually painless (sometimes mild tenderness)",
          "Often no skin changes",
        ]);

    final causes = template?.causes ??
        (isMalignant
            ? [
          "Genetic risk (family history, BRCA mutations)",
          "Age and hormonal factors",
          "Lifestyle risk factors (obesity, alcohol, etc.)",
          "Previous chest radiation exposure (rare)",
        ]
            : [
          "Hormonal changes (common trigger)",
          "Benign tissue growth patterns",
          "Sometimes family tendency",
        ]);

    final effects = template?.effects ??
        (isMalignant
            ? [
          "Can grow and spread if not treated",
          "Early detection improves outcomes",
          "May require surgery, chemotherapy, radiotherapy, or targeted therapy",
        ]
            : [
          "Usually does not spread",
          "May remain stable or shrink over time",
          "Can still require follow-up to ensure stability",
        ]);

    final precautions = template?.precautions ??
        (isMalignant
            ? [
          "Book an urgent appointment with a breast specialist/oncologist",
          "Do not delay imaging/biopsy if recommended",
          "Track changes (size, pain, skin/nipple changes)",
          "Ensure emotional support (family/counselor)",
        ]
            : [
          "Follow up with a clinician for confirmation",
          "Monthly self-check awareness",
          "Attend imaging follow-ups if advised",
          "Maintain healthy lifestyle (sleep, diet, activity)",
        ]);

    final medicines = template?.medicines ??
        (isMalignant
            ? [
          "Medicines are prescribed only by an oncologist after confirmation (biopsy).",
          "Common treatment categories include chemotherapy, hormone therapy, targeted therapy, or immunotherapy depending on type.",
        ]
            : [
          "Usually no medicine is required for benign conditions.",
          "If pain exists, doctors may recommend mild pain relief depending on your case.",
        ]);

    final warnings = isMalignant
        ? [
      "This AI result is NOT a final diagnosis.",
      "You should seek medical evaluation as soon as possible.",
      "A biopsy/imaging may be required to confirm."
    ]
        : [
      "This AI result is NOT a final diagnosis.",
      "Follow-up imaging/clinical exam is recommended for confirmation."
    ];

    return """
🩺 Breast Health Report
Diagnosis: $readable
Result Type: ${isMalignant ? "Malignant (Cancerous pattern)" : "Benign (Non-cancerous pattern)"}
Confidence: $pct%

📌 What this means
$diseaseIntro

🔍 Common symptoms
${_bullets(symptoms)}

🧬 Possible causes / risk factors
${_bullets(causes)}

📉 Possible effects
${_bullets(effects)}

💊 Medicines / treatment guidance
${_bullets(medicines)}

🛡️ Precautions & self-care
${_bullets(precautions)}

🚨 When to see a doctor immediately
${_bullets([
      "Rapidly growing lump",
      "Skin dimpling, redness, or thickening",
      "Nipple inversion or unusual discharge",
      "Persistent pain or swelling",
      "New lump in armpit or collarbone area",
    ])}

✅ Important note
${_bullets(warnings)}

This report is AI-assisted and intended for educational guidance only.
Always consult a qualified healthcare professional for clinical decisions.
""";
  }

  static String _bullets(List<String> items) =>
      items.map((e) => "• $e").join("\n");

  static String _prettyLabel(String label) {
    // Example: benign_fibroadenoma -> Benign Fibroadenoma
    return label
        .replaceAll("_", " ")
        .split(" ")
        .map((w) => w.isEmpty ? w : "${w[0].toUpperCase()}${w.substring(1)}")
        .join(" ");
  }

  // ---- templates per label (add as your model supports) ----
  static final Map<String, _DiseaseTemplate> _templates = {
    "benign_fibroadenoma": _DiseaseTemplate(
      intro:
      "Fibroadenoma is a common benign breast lump made of fibrous and glandular tissue. It does not spread and is often monitored rather than treated.",
      symptoms: [
        "Smooth, rubbery lump that moves under the skin",
        "Usually painless",
        "Often stable size (can change with hormones)",
      ],
      causes: [
        "Hormonal influence (estrogen-related)",
        "Common in younger women",
        "Sometimes grows in pregnancy or with hormone therapy",
      ],
      effects: [
        "Does not spread to other parts of the body",
        "Usually safe, but should be monitored",
        "May be removed if growing or uncomfortable",
      ],
      medicines: [
        "Usually no medicine needed",
        "If painful, a clinician may advise pain relief depending on your case",
      ],
      precautions: [
        "Follow-up ultrasound/clinical exam if advised",
        "Monthly self-awareness checks",
        "Return if lump grows or becomes painful",
      ],
    ),

    // Add more labels as your model outputs:
    // "benign_adenosis": _DiseaseTemplate(...),
    // "malignant_ductal_carcinoma": _DiseaseTemplate(...),
  };
}

class _DiseaseTemplate {
  final String intro;
  final List<String> symptoms;
  final List<String> causes;
  final List<String> effects;
  final List<String> medicines;
  final List<String> precautions;

  const _DiseaseTemplate({
    required this.intro,
    required this.symptoms,
    required this.causes,
    required this.effects,
    required this.medicines,
    required this.precautions,
  });
}
