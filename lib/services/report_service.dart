import 'package:cloud_firestore/cloud_firestore.dart';

class ReportService {
  ReportService._();
  static final ReportService instance = ReportService._();

  final _db = FirebaseFirestore.instance;

  /// Creates a report in Firestore and returns the new reportId (doc id)
  Future<String> createReport({
    required String firebaseUid,
    required String predictedLabel,
    required bool isCancerous,
    required double confidence,
    int imagesCount = 0,
  }) async {
    final doc = _db
        .collection('reports')
        .doc(); // auto id

    await doc.set({
      "firebaseUid": firebaseUid,
      "predictedLabel": predictedLabel,
      "isCancerous": isCancerous,
      "confidence": confidence,
      "imagesCount": imagesCount,
      "createdAt": FieldValue.serverTimestamp(),
    });

    return doc.id;
  }
}
