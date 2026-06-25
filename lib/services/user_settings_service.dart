import 'package:cloud_firestore/cloud_firestore.dart';

class UserSettingsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<Map<String, dynamic>?> streamUser(String docId) {
    return _db.collection('users').doc(docId).snapshots().map((doc) => doc.data());
  }

  Future<void> ensureUserDoc(String docId) async {
    final ref = _db.collection('users').doc(docId);
    final snap = await ref.get();

    if (!snap.exists) {
      await ref.set({
        'languageCode': 'en',
        'darkMode': false,
        'role': 'patient',
      });
    }
  }

  Future<void> updateLanguage(String docId, String languageCode) async {
    await _db.collection('users').doc(docId).set({
      'languageCode': languageCode,
    }, SetOptions(merge: true));
  }

  Future<void> updateDarkMode(String docId, bool darkMode) async {
    await _db.collection('users').doc(docId).set({
      'darkMode': darkMode,
    }, SetOptions(merge: true));
  }
}
