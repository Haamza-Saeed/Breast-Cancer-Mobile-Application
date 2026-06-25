// lib/models/symptom_question.dart
class SymptomQuestion {
  final String id; // stable key e.g. "q_menopause_55"
  final String l10nKey; // your ARB key name e.g. "symptomQ41"
  final int? minAge; // inclusive
  final int? maxAge; // inclusive

  // tags used by the engine to trigger tests/recommendations
  final List<String> tags;

  const SymptomQuestion({
    required this.id,
    required this.l10nKey,
    this.minAge,
    this.maxAge,
    this.tags = const [],
  });

  bool appliesToAge(int? age) {
    if (age == null) return true; // if age missing, show all to be safe
    if (minAge != null && age < minAge!) return false;
    if (maxAge != null && age > maxAge!) return false;
    return true;
  }
}
