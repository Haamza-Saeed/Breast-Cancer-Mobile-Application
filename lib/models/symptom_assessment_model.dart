import 'package:cloud_firestore/cloud_firestore.dart';

class SymptomAssessmentModel {
  final String id;
  final DateTime? createdAt;

  final int score;
  final String riskLevel;
  final String urgency;
  final int uiRiskPercent;

  final List<String> recommendedTests;
  final List<String> keyFindings;

  const SymptomAssessmentModel({
    required this.id,
    required this.createdAt,
    required this.score,
    required this.riskLevel,
    required this.urgency,
    required this.uiRiskPercent,
    required this.recommendedTests,
    required this.keyFindings,
  });

  static List<String> _asStringList(dynamic v) {
    if (v is List) return v.map((e) => e.toString()).toList();
    return const [];
  }

  static List<String> _asKeyFindings(dynamic v) {
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

  factory SymptomAssessmentModel.fromFirestore({
    required String id,
    required Map<String, dynamic> data,
  }) {
    final result = (data["result"] is Map)
        ? (data["result"] as Map).cast<String, dynamic>()
        : <String, dynamic>{};

    final score = (result["score"] is num)
        ? (result["score"] as num).toInt()
        : (data["score"] is num)
        ? (data["score"] as num).toInt()
        : 0;

    final riskLevel =
    (result["riskLevel"] ?? data["riskLevel"] ?? "UNKNOWN").toString();

    final urgency = (result["urgency"] ?? data["urgency"] ?? "").toString();

    final uiRiskPercent = (data["uiRiskPercent"] is num)
        ? (data["uiRiskPercent"] as num).toInt()
        : (result["uiRiskPercent"] is num)
        ? (result["uiRiskPercent"] as num).toInt()
        : 0;

    final recommendedTests = _asStringList(
      result["recommendedTests"] ??
          result["recommendedTest"] ??
          data["recommendedTests"] ??
          data["recommendedTest"],
    );

    final keyFindings = _asKeyFindings(result["keyFindings"] ?? data["keyFindings"]);

    final createdAt = (data["createdAt"] as Timestamp?)?.toDate();

    return SymptomAssessmentModel(
      id: id,
      createdAt: createdAt,
      score: score,
      riskLevel: riskLevel,
      urgency: urgency,
      uiRiskPercent: uiRiskPercent,
      recommendedTests: recommendedTests,
      keyFindings: keyFindings,
    );
  }
}
