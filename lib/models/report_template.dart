class ReportTemplate {
  final String displayName;
  final List<String> whatItMeans;
  final List<String> symptoms;
  final List<String> riskFactors;
  final List<String> nextSteps;

  const ReportTemplate({
    required this.displayName,
    required this.whatItMeans,
    required this.symptoms,
    required this.riskFactors,
    required this.nextSteps,
  });
}

class ReportTemplates {
  static ReportTemplate byLabel({
    required String predictedLabel,
    required bool isMalignant,
  }) {
    final label = predictedLabel.trim().toLowerCase();

    if (!isMalignant) {
      if (label == "benign_fibroadenoma") return benignFibroadenoma;
      if (label == "benign_phyllodes_tumor") return benignPhyllodes;
      if (label == "benign_tubular_adenoma") return benignTubularAdenoma;
      return benignAdenosis;
    } else {
      if (label == "malignant_lobular_carcinoma") return malignantLobular;
      if (label == "malignant_mucinous_carcinoma") return malignantMucinous;
      if (label == "malignant_papillary_carcinoma") return malignantPapillary;
      return malignantDuctal;
    }
  }

  static const benignAdenosis = ReportTemplate(
    displayName: "Benign Adenosis",
    whatItMeans: [
      "Your result suggests a benign (non-cancerous) pattern related to glandular tissue changes.",
      "Benign findings are commonly manageable but should still be reviewed clinically.",
    ],
    symptoms: [
      "A lump that may feel smooth and movable",
      "Usually painless (sometimes mild tenderness)",
      "Often no skin changes",
    ],
    riskFactors: [
      "Hormonal changes (common trigger)",
      "Benign tissue growth patterns",
      "Sometimes family tendency",
    ],
    nextSteps: [
      "Schedule a clinical breast exam for confirmation",
      "Consider ultrasound or mammogram if recommended",
      "Monitor changes in size, pain, or skin appearance",
    ],
  );

  static const benignFibroadenoma = ReportTemplate(
    displayName: "Benign Fibroadenoma",
    whatItMeans: [
      "A fibroadenoma is a common benign breast lump.",
      "It typically does not spread and is often monitored over time.",
    ],
    symptoms: [
      "Round/oval lump, smooth edges, movable",
      "Usually painless",
      "May change with menstrual cycle",
    ],
    riskFactors: [
      "Age (more common in younger individuals)",
      "Hormonal sensitivity",
      "Family history may play a role",
    ],
    nextSteps: [
      "Clinical exam + ultrasound is often recommended",
      "Follow-up imaging to ensure stability",
      "Biopsy may be advised if growth is rapid or appearance is atypical",
    ],
  );

  static const benignPhyllodes = ReportTemplate(
    displayName: "Benign Phyllodes Tumor",
    whatItMeans: [
      "Phyllodes tumors are usually benign but can grow quickly.",
      "Even benign phyllodes tumors may require surgical removal to prevent recurrence.",
    ],
    symptoms: [
      "Fast-growing lump",
      "Stretching sensation or discomfort",
      "Sometimes visible swelling",
    ],
    riskFactors: [
      "Unknown exact cause",
      "Possible hormonal influence",
      "Can occur across a wide age range",
    ],
    nextSteps: [
      "Clinical evaluation is important",
      "Imaging + biopsy may be recommended",
      "Discuss removal options if it is enlarging",
    ],
  );

  static const benignTubularAdenoma = ReportTemplate(
    displayName: "Benign Tubular Adenoma",
    whatItMeans: [
      "Tubular adenoma is a rare benign tumor of glandular breast tissue.",
      "It is usually treated similarly to other benign lumps and monitored.",
    ],
    symptoms: [
      "Small, firm, movable lump",
      "Usually painless",
      "Often detected on imaging",
    ],
    riskFactors: [
      "More common in younger patients",
      "Hormonal factors may contribute",
    ],
    nextSteps: [
      "Confirm with ultrasound/mammogram as advised",
      "Consider biopsy if imaging is unclear",
      "Follow-up imaging for stability",
    ],
  );

  static const malignantDuctal = ReportTemplate(
    displayName: "Malignant Ductal Carcinoma (IDC/DCIS Pattern)",
    whatItMeans: [
      "This pattern can be consistent with ductal-type breast cancer features.",
      "A clinical diagnosis is required — AI output should be treated as a high-priority screening signal.",
    ],
    symptoms: [
      "A persistent lump (may be hard/irregular)",
      "Skin dimpling or nipple changes",
      "Possible nipple discharge",
    ],
    riskFactors: [
      "Age and family history",
      "Prior breast conditions",
      "Genetic factors (e.g., BRCA) may contribute",
    ],
    nextSteps: [
      "Book urgent evaluation with a breast specialist",
      "Imaging (mammogram/ultrasound) + biopsy is typically required",
      "Discuss staging and treatment planning if confirmed",
    ],
  );

  static const malignantLobular = ReportTemplate(
    displayName: "Malignant Lobular Carcinoma (ILC Pattern)",
    whatItMeans: [
      "This pattern may align with lobular-type malignancy characteristics.",
      "Lobular cancer can be subtle on physical exam and imaging — specialist evaluation is important.",
    ],
    symptoms: [
      "Thickening rather than a clear lump",
      "Change in breast shape/contour",
      "Persistent fullness in one area",
    ],
    riskFactors: [
      "Hormone exposure",
      "Family history / genetics",
      "Age-related risk",
    ],
    nextSteps: [
      "Urgent clinical evaluation",
      "Imaging + biopsy to confirm",
      "Discuss hormone receptor testing and treatment strategy if confirmed",
    ],
  );

  static const malignantMucinous = ReportTemplate(
    displayName: "Malignant Mucinous Carcinoma Pattern",
    whatItMeans: [
      "This pattern may be consistent with mucinous (colloid) carcinoma features.",
      "Some subtypes have favorable prognosis, but confirmation is mandatory.",
    ],
    symptoms: [
      "Soft lump that persists",
      "Possible breast pain or tenderness",
      "Imaging abnormalities",
    ],
    riskFactors: [
      "Age",
      "Hormonal and genetic factors",
    ],
    nextSteps: [
      "Specialist evaluation",
      "Mammogram/ultrasound + biopsy",
      "Discuss treatment options if confirmed",
    ],
  );

  static const malignantPapillary = ReportTemplate(
    displayName: "Malignant Papillary Carcinoma Pattern",
    whatItMeans: [
      "This pattern may align with papillary carcinoma characteristics.",
      "Often associated with nipple discharge — requires specialist review.",
    ],
    symptoms: [
      "Nipple discharge (possibly bloody)",
      "Lump near the nipple",
      "Nipple or areola changes",
    ],
    riskFactors: [
      "Age",
      "Hormonal exposure",
      "Family history",
    ],
    nextSteps: [
      "Urgent breast specialist appointment",
      "Imaging + biopsy",
      "Treatment planning if confirmed",
    ],
  );
}
