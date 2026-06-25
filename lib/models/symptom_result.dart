// lib/models/symptom_result.dart
class SymptomResult {
  final String riskLevel; // LOW/MEDIUM/HIGH
  final String urgency;   // ROUTINE/SOON/URGENT
  final int score;

  final List<String> redFlags;
  final List<String> keyFindings;

  final List<String> recommendedTests;
  final List<String> nextSteps;

  final String explanation;
  final String disclaimer;

  const SymptomResult({
    required this.riskLevel,
    required this.urgency,
    required this.score,
    required this.redFlags,
    required this.keyFindings,
    required this.recommendedTests,
    required this.nextSteps,
    required this.explanation,
    required this.disclaimer,
  });

  Map<String, dynamic> toMap() => {
    "riskLevel": riskLevel,
    "urgency": urgency,
    "score": score,
    "redFlags": redFlags,
    "keyFindings": keyFindings,
    "recommendedTests": recommendedTests,
    "nextSteps": nextSteps,
    "explanation": explanation,
    "disclaimer": disclaimer,
  };
}
