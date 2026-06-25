import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class AiReportService {
  AiReportService._();

  static final AiReportService instance = AiReportService._();

  // Emulator:
  // static const String apiUrl = "http://10.0.2.2/project_api/generate_ai_report.php";

  // Real phone: use your laptop IPv4.
  static const String apiUrl =
      "http://192.168.1.18/project_api/generate_ai_report.php";

  dynamic _cleanForJson(dynamic value) {
    if (value == null) return null;

    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is DateTime) return value.toIso8601String();
    if (value is DocumentReference) return value.path;

    if (value is GeoPoint) {
      return {
        "latitude": value.latitude,
        "longitude": value.longitude,
      };
    }

    if (value is List) {
      return value.map((e) => _cleanForJson(e)).toList();
    }

    if (value is Map) {
      return value.map(
            (key, val) => MapEntry(key.toString(), _cleanForJson(val)),
      );
    }

    return value;
  }

  String _value(Map<String, dynamic> data, String key, [String fallback = "Not provided"]) {
    final v = data[key];
    if (v == null) return fallback;
    final s = v.toString().trim();
    return s.isEmpty ? fallback : s;
  }

  String _yesNo(dynamic v) {
    if (v == true || v == "true" || v == 1 || v == "1") return "Yes";
    if (v == false || v == "false" || v == 0 || v == "0") return "No";
    return v?.toString() ?? "Not provided";
  }

  String _fallbackDiagnosisReport({
    required Map<String, dynamic> patientData,
    required Map<String, dynamic> diagnosisData,
  }) {
    final name = _value(patientData, "firstName", "Patient");
    final age = _value(patientData, "age");
    final marital = _value(patientData, "maritalStatus");
    final medication = _value(patientData, "anyMedication");
    final medicationDetails = _value(patientData, "medicationDetails");
    final familyCancer = _value(patientData, "cancerInFamily");
    final familyDetails = _value(patientData, "cancerFamilyDetails");

    final label = _value(diagnosisData, "displayLabel",
        _value(diagnosisData, "predictedLabel", "Unknown"));
    final malignant = _yesNo(diagnosisData["isMalignant"]);

    final confidenceValue = diagnosisData["confidence"];
    final confidence = confidenceValue is num
        ? "${(confidenceValue.toDouble() * 100).toStringAsFixed(1)}%"
        : "Not available";

    return """
1. Patient Summary
Name: $name
Age: $age
Marital Status: $marital

2. Image Diagnosis Summary
The uploaded histopathology image was analyzed by the AI image model.
Detected type: $label
Malignant concern: $malignant
Confidence: $confidence

3. What This Result May Mean
This result is an AI-based screening interpretation. It may suggest patterns related to the detected breast tissue category, but it is not a final medical diagnosis. The result should be reviewed by a qualified doctor or pathologist.

4. Possible Causes and Risk Context
Medication status: $medication
Medication details: $medicationDetails
Cancer in family: $familyCancer
Family history details: $familyDetails

These profile details can help a doctor understand the patient's background, but they cannot confirm or reject cancer by themselves.

5. Recommended Next Steps
Please consult a breast specialist or pathologist for confirmation. A doctor may recommend physical examination, ultrasound, mammogram, biopsy confirmation, or repeat histopathology review depending on symptoms and clinical findings.

6. Important Disclaimer
This AI-generated report is for screening and educational support only. It is not a replacement for professional medical advice, diagnosis, or treatment.
""";
  }

  Future<String> generateDiagnosisReport({
    required Map<String, dynamic> patientData,
    required Map<String, dynamic> diagnosisData,
  }) async {
    final cleanPatient = _cleanForJson(patientData) as Map<String, dynamic>;
    final cleanDiagnosis = _cleanForJson(diagnosisData) as Map<String, dynamic>;

    final body = {
      "mode": "single_diagnosis_report",
      "patient": cleanPatient,
      "diagnosis": cleanDiagnosis,
    };

    try {
      final response = await http
          .post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      )
          .timeout(const Duration(seconds: 35));

      if (response.statusCode != 200) {
        return _fallbackDiagnosisReport(
          patientData: cleanPatient,
          diagnosisData: cleanDiagnosis,
        );
      }

      final data = jsonDecode(response.body);

      if (data["success"] != true) {
        return _fallbackDiagnosisReport(
          patientData: cleanPatient,
          diagnosisData: cleanDiagnosis,
        );
      }

      final report = (data["report"] ?? "").toString().trim();

      if (report.isEmpty) {
        return _fallbackDiagnosisReport(
          patientData: cleanPatient,
          diagnosisData: cleanDiagnosis,
        );
      }

      return report;
    } catch (_) {
      return _fallbackDiagnosisReport(
        patientData: cleanPatient,
        diagnosisData: cleanDiagnosis,
      );
    }
  }

  Future<String> generateReport({
    required Map<String, dynamic> patientData,
    required Map<String, dynamic>? latestImageReport,
    required Map<String, dynamic>? latestSymptomReport,
  }) async {
    final diagnosisData = latestImageReport ?? <String, dynamic>{};

    return generateDiagnosisReport(
      patientData: patientData,
      diagnosisData: {
        ...diagnosisData,
        "latestSymptomReport": latestSymptomReport,
      },
    );
  }
}