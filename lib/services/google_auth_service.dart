// lib/services/google_auth_service.dart
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class GoogleAccountLite {
  final String email;
  final String? displayName;
  final String? photoUrl;
  GoogleAccountLite({required this.email, this.displayName, this.photoUrl});
}

class GoogleAuthService {
  GoogleAuthService._();
  static final GoogleAuthService instance = GoogleAuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  GoogleAccountLite? get currentUser {
    final u = _auth.currentUser;
    if (u == null) return null;
    return GoogleAccountLite(
      email: u.email ?? '',
      displayName: u.displayName,
      photoUrl: u.photoURL,
    );
    // NOTE: On Android/iOS, Firebase persists the session – this is your “silent sign-in”.
  }

  /// "Silent" sign-in: just return the persisted Firebase user if present.
  Future<GoogleAccountLite?> signInSilently() async {
    final u = _auth.currentUser;
    if (u == null) return null;
    return currentUser;
  }

  /// Interactive Google sign-in via Firebase Auth's Google provider.
  Future<GoogleAccountLite?> signIn() async {
    try {
      if (kIsWeb) {
        // Web: use a popup
        await _auth.signInWithPopup(GoogleAuthProvider());
      } else {
        // Android/iOS: use native provider flow (no google_sign_in plugin required)
        await _auth.signInWithProvider(GoogleAuthProvider());
      }
      return currentUser;
    } catch (e) {
      // You can log e for debugging
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
