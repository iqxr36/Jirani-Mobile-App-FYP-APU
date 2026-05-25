import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Holds Firebase credential plus Apple name tokens (only populated on some first-time sign-ins).
class AppleSignInFlowResult {
  AppleSignInFlowResult({
    required this.credential,
    this.givenName,
    this.familyName,
    this.appleEmail,
  });

  final UserCredential credential;
  final String? givenName;
  final String? familyName;
  final String? appleEmail;
}

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

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  User? get currentUser => _firebaseAuth.currentUser;
  bool get isEmailVerified => _firebaseAuth.currentUser?.emailVerified ?? false;

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Ignore if Google sign-in was never used.
    }
    await _firebaseAuth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _firebaseAuth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> sendEmailVerification() async {
    await _firebaseAuth.currentUser?.sendEmailVerification();
  }

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
      debugPrint(
        '[FirebaseAuthService.signInWithGoogle] ${e.code}: ${e.message}',
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

  /// Apple OAuth. Returns `null` if the user cancelled.
  /// On unsupported platforms, throws [Exception] with a clear message.
  Future<AppleSignInFlowResult?> signInWithApple() async {
    if (kIsWeb) {
      throw Exception('Apple sign-in is not available on this device.');
    }
    final available = await SignInWithApple.isAvailable();
    if (!available) {
      throw Exception('Apple sign-in is not available on this device.');
    }

    try {
      final rawNonce = generateNonce();
      final nonce = sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      if (appleCredential.identityToken == null ||
          appleCredential.identityToken!.isEmpty) {
        throw Exception('Apple sign-in failed. Missing identity token.');
      }

      final oauthCredential = OAuthProvider(
        'apple.com',
      ).credential(idToken: appleCredential.identityToken, rawNonce: rawNonce);

      final userCred = await _firebaseAuth.signInWithCredential(
        oauthCredential,
      );
      return AppleSignInFlowResult(
        credential: userCred,
        givenName: appleCredential.givenName,
        familyName: appleCredential.familyName,
        appleEmail: appleCredential.email,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return null;
      }
      throw Exception(
        e.message.isNotEmpty ? e.message : 'Apple sign-in failed.',
      );
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('Apple sign-in is not available')) {
        throw Exception('Apple sign-in is not available on this device.');
      }
      if (msg.contains('network') || msg.contains('Network')) {
        throw Exception('Network error. Please try again.');
      }
      throw Exception('Apple sign-in failed. Please try again.');
    }
  }

  static String generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  static String sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
