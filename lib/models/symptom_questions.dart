// lib/models/symptom_questions.dart
import 'package:project/models/symptom_question.dart';

class SymptomQuestions {
  static const List<SymptomQuestion> all = [
    // --------------------
    // "General" questions (shown to everyone)
    // Add as many as you want (40/60/100)
    // --------------------
    SymptomQuestion(id: "q_lump_present", l10nKey: "symptomQ1", tags: ["lump"]),
    SymptomQuestion(id: "q_lump_hard_fixed", l10nKey: "symptomQ2", tags: ["lump"]),
    SymptomQuestion(id: "q_lump_growing", l10nKey: "symptomQ3", tags: ["lump"]),
    SymptomQuestion(id: "q_skin_dimpling", l10nKey: "symptomQ4", tags: ["skin", "redflag"]),
    SymptomQuestion(id: "q_peau_dorange", l10nKey: "symptomQ5", tags: ["skin", "redflag"]),
    SymptomQuestion(id: "q_bloody_discharge", l10nKey: "symptomQ6", tags: ["discharge", "redflag"]),
    SymptomQuestion(id: "q_new_nipple_inversion", l10nKey: "symptomQ7", tags: ["nipple", "redflag"]),
    SymptomQuestion(id: "q_axillary_nodes", l10nKey: "symptomQ8", tags: ["lymph", "redflag"]),
    SymptomQuestion(id: "q_persistent_pain", l10nKey: "symptomQ9", tags: ["pain"]),
    SymptomQuestion(id: "q_fever_redness", l10nKey: "symptomQ10", tags: ["infection"]),
    SymptomQuestion(id: "q_family_history", l10nKey: "symptomQ11", tags: ["risk"]),
    SymptomQuestion(id: "q_previous_cancer", l10nKey: "symptomQ12", tags: ["risk"]),

    // ...continue adding your general questions symptomQ13..symptomQ40 etc
    // SymptomQuestion(id:"...", l10nKey:"symptomQ13", tags:[...]),

    // --------------------
    // Age-based questions (only shown when applicable)
    // --------------------

    // Menopause question should NEVER show to 22-year old
    SymptomQuestion(
      id: "q_menopause_after_55",
      l10nKey: "symptomQ41",
      minAge: 45, // you can tune (45/50/55). Main goal: don't show to young.
      tags: ["risk"],
    ),

    // Pregnancy after 30 should only show to age >= 30
    SymptomQuestion(
      id: "q_first_pregnancy_after_30_or_never",
      l10nKey: "symptomQ42",
      minAge: 30,
      tags: ["risk"],
    ),

    // Add more age-specific questions like this:
    // SymptomQuestion(id:"q_screening_mammo", l10nKey:"symptomQ60", minAge:40, tags:["screening"]),
  ];
}
