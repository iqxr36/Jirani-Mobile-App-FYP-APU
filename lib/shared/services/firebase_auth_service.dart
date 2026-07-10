import 'package:firebase_auth/firebase_auth.dart';
import 'package:jirani/core/utils/auth_debug_log.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Auth service: wraps Firebase Auth, Google sign-in, email verification, and password reset.
class FirebaseAuthService {
  FirebaseAuthService({FirebaseAuth? firebaseAuth, GoogleSignIn? googleSignIn})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
      _googleSignIn = googleSignIn ?? _defaultGoogleSignIn;

  /// Web OAuth client from Firebase (`google-services.json`, client_type 3).
  /// Required on Android so Firebase Auth receives a valid [idToken].
  static const String googleWebClientId =
      '790648716224-ghb1d69upr43lf1k6in0d0ulu6hll6o2.apps.googleusercontent.com';

  static final GoogleSignIn _defaultGoogleSignIn = GoogleSignIn(
    serverClientId: googleWebClientId,
  );

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  /// Auth feature: exposes Firebase session changes to AuthViewModel.
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  User? get currentUser => _firebaseAuth.currentUser;
  bool get isEmailVerified => _firebaseAuth.currentUser?.emailVerified ?? false;

  /// Auth feature: signs a resident/admin in with Firebase email and password.
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Auth registration: creates the Firebase Auth account before a users/{uid} profile is written.
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Auth feature: signs out Firebase and any active Google session.
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Ignore if Google sign-in was never used.
    }
    await _firebaseAuth.signOut();
  }

  /// Auth recovery: sends Firebase's password reset email.
  Future<void> sendPasswordResetEmail(String email) {
    return _firebaseAuth.sendPasswordResetEmail(email: email.trim());
  }

  /// Auth/profile feature: starts Firebase's secure email-change verification flow.
  Future<void> verifyBeforeUpdateEmail(String email) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'You must be signed in to update your email.',
      );
    }
    await user.verifyBeforeUpdateEmail(email.trim());
  }

  /// Auth verification: sends the Firebase email verification message to the current user.
  Future<void> sendEmailVerification() async {
    await _firebaseAuth.currentUser?.sendEmailVerification();
  }

  /// Auth verification: reloads the Firebase user so email/phone verification flags are fresh.
  Future<void> reloadCurrentUser() async {
    await _firebaseAuth.currentUser?.reload();
  }

  /// Google OAuth via [GoogleSignIn]. Returns `null` if the user closed the picker.
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _firebaseAuth.signInWithCredential(credential);
    } on FirebaseAuthException {
      rethrow;
    } on PlatformException catch (e) {
      authDebugLogError(
        '[FirebaseAuthService.signInWithGoogle]',
        '${e.code}: ${e.message}',
      );
      if (e.code == 'sign_in_canceled') {
        return null;
      }
      if (e.code == 'network_error') {
        throw Exception('Network error. Please try again.');
      }
      final message = e.message ?? '';
      if (message.contains('ApiException: 10') ||
          message.contains('DEVELOPER_ERROR')) {
        throw Exception(
          'Google sign-in is not configured for this Android app. Add its SHA fingerprints in Firebase and replace google-services.json.',
        );
      }
      throw Exception(
        'Google sign-in failed (${e.code}). ${e.message ?? 'Please try again.'}',
      );
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('network') || msg.contains('Network')) {
        throw Exception('Network error. Please try again.');
      }
      throw Exception('Google sign-in failed. Please try again.');
    }
  }
}
