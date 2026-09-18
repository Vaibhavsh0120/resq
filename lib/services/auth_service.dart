import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'app_platform_info.dart';

/// A user-facing, already-friendly auth failure message. Screens show
/// [message] directly — no need to interpret Firebase error codes in the UI.
class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

/// The single place that talks to `firebase_auth` / `google_sign_in`.
///
/// Screens never import `firebase_auth` directly — they call through here,
/// so provider logic, platform branching, and error-message mapping stay in
/// one place as more providers (phone, Apple, etc.) are added later.
class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Emitted whenever the signed-in user changes (sign in, sign out, token
  /// refresh with a different user). This is the single source of truth
  /// [AuthGate] uses to decide Startup/Auth vs Home.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  bool get isSignedInAnonymously => currentUser?.isAnonymous ?? false;

  bool _googleInitialized = false;

  /// Must be called once before the first [signInWithGoogle] call on
  /// Android/iOS/macOS. Safe to call multiple times. No-op on web, where
  /// Firebase's `signInWithPopup` is used instead and `google_sign_in` isn't
  /// needed at all.
  Future<void> ensureGoogleSignInInitialized() async {
    if (_googleInitialized || AppPlatformInfo.isWeb) return;
    // No clientId/serverClientId is passed here: on Android this reads the
    // OAuth client from google-services.json automatically once a SHA-1 is
    // registered in the Firebase console; iOS reads it from the reversed
    // client ID in GoogleService-Info.plist / Info.plist URL scheme. Both
    // have been configured on the Firebase console side already (per user).
    await GoogleSignIn.instance.initialize();
    _googleInitialized = true;
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) => _guard(
    () => _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    ),
  );

  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) => _guard(
    () => _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    ),
  );

  Future<void> sendPasswordResetEmail(String email) =>
      _guard(() => _auth.sendPasswordResetEmail(email: email.trim()));

  /// "Emergency access" — anonymous sign-in so a user in crisis is never
  /// blocked by registration. Product requirement: emergency features must
  /// work before/without a full account (see project brief, section 3).
  Future<UserCredential> signInAsGuest() =>
      _guard(() => _auth.signInAnonymously());

  Future<UserCredential> signInWithGoogle() => _guard(() async {
    if (AppPlatformInfo.isWeb) {
      final provider = GoogleAuthProvider();
      return _auth.signInWithPopup(provider);
    }

    await ensureGoogleSignInInitialized();
    final account = await GoogleSignIn.instance.authenticate();
    final googleAuth = account.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );
    return _auth.signInWithCredential(credential);
  });

  Future<void> signOut() async {
    if (!AppPlatformInfo.isWeb && _googleInitialized) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {
        // Not signed in via Google, or plugin not initialized — fine to
        // ignore, Firebase sign-out below is what actually matters.
      }
    }
    await _auth.signOut();
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapFirebaseError(e));
    } on GoogleSignInException catch (e) {
      throw AuthFailure(_mapGoogleError(e));
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('AuthService unexpected error: $e');
      }
      throw const AuthFailure(
        'Something went wrong. Please check your connection and try again.',
      );
    }
  }

  String _mapGoogleError(GoogleSignInException e) {
    switch (e.code) {
      case GoogleSignInExceptionCode.canceled:
        return 'Sign-in was cancelled.';
      case GoogleSignInExceptionCode.interrupted:
        return 'Sign-in was interrupted. Please try again.';
      case GoogleSignInExceptionCode.clientConfigurationError:
        return 'Google sign-in isn\'t configured for this app yet.';
      default:
        return 'Couldn\'t sign in with Google. Please try again.';
    }
  }

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'That email address doesn\'t look right.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'invalid-credential':
      case 'wrong-password':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists with that email.';
      case 'weak-password':
        return 'Choose a stronger password (at least 6 characters).';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      case 'operation-not-allowed':
        return 'This sign-in method isn\'t enabled yet.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }
}
