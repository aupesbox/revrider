// lib/services/google_auth_service.dart
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  GoogleAuthService._();
  static final GoogleAuthService instance = GoogleAuthService._();

  final GoogleSignIn _g = GoogleSignIn(
    scopes: <String>['email', 'https://www.googleapis.com/auth/userinfo.profile'],
  );

  String? lastError; // for debugging UI/logcat

  GoogleSignInAccount? get currentUser => _g.currentUser;

  Future<GoogleSignInAccount?> signInSilently() async {
    try {
      final acct = await _g.signInSilently();
      return acct;
    } catch (e) {
      lastError = 'silent: $e';
      debugPrint('[GoogleAuth] signInSilently error: $e');
      return null;
    }
  }

  Future<GoogleSignInAccount?> signIn() async {
    try {
      // Sometimes a stale session causes null; clear then retry.
      if (_g.currentUser != null) {
        try { await _g.disconnect(); } catch (_) {}
      }
      final acct = await _g.signIn();
      return acct;
    } catch (e) {
      lastError = 'interactive: $e';
      debugPrint('[GoogleAuth] signIn error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    try { await _g.disconnect(); } catch (_) {}
  }
}
