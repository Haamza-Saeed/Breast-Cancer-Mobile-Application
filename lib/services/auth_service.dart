import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1) Send sign-in link (verification)
  Future<void> sendEmailLink({
    required String email,
    required String packageName, // e.g. "com.example.project"
    required String androidInstallApp,
    required String androidMinimumVersion,
    required String continueUrl, // a URL you add in Firebase Auth settings
  }) async {
    final actionCodeSettings = ActionCodeSettings(
      url: continueUrl,
      handleCodeInApp: true,
      androidPackageName: packageName,
      androidInstallApp: androidInstallApp.toLowerCase() == "true",
      androidMinimumVersion: androidMinimumVersion,
      iOSBundleId: null, // set if you use iOS
    );

    await _auth.sendSignInLinkToEmail(
      email: email,
      actionCodeSettings: actionCodeSettings,
    );
  }

  // 2) Complete sign-in with email link
  Future<UserCredential> signInWithEmailLink({
    required String email,
    required String emailLink,
  }) async {
    return await _auth.signInWithEmailLink(email: email, emailLink: emailLink);
  }

  // 3) After verified, attach password (so user can login next time with email+password)
  Future<void> linkPassword({
    required String email,
    required String password,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("No logged-in user to link password.");

    final credential = EmailAuthProvider.credential(email: email, password: password);
    await user.linkWithCredential(credential);
  }

  // 4) Normal login (your "Login" button)
  Future<UserCredential> loginWithEmailPassword({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> logout() async => _auth.signOut();
}
