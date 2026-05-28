import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:fyp_flutter_application/core/constants/app_constants.dart';
import 'package:fyp_flutter_application/core/utils/validators.dart';
import 'package:fyp_flutter_application/data/models/app_user.dart';
import 'package:fyp_flutter_application/services/firebase_auth_service.dart';

class AuthRepository {
  AuthRepository({
    FirebaseAuthService? authService,
    FirebaseFirestore? firestore,
  })  : _authService = authService ?? FirebaseAuthService(),
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuthService _authService;
  final FirebaseFirestore _firestore;

  Stream<User?> get authStateChanges => _authService.authStateChanges;

  User? get currentFirebaseUser => _authService.currentUser;

  Future<void> sendPasswordResetEmail(String email) {
    return _authService.sendPasswordResetEmail(email);
  }

  Future<void> resendEmailVerification() {
    return _authService.sendEmailVerification();
  }

  Future<AppUser?> getCurrentAppUser() async {
    debugPrint('[AuthRepository.getCurrentAppUser] started');
    final user = _authService.currentUser;
    if (user == null) return null;
    debugPrint('[AuthRepository.getCurrentAppUser] firebase uid=${user.uid}');
    await _authService.reloadCurrentUser();
    final refreshedUser = _authService.currentUser;
    if (refreshedUser == null) return null;
    final authEmailVerified = _authService.isEmailVerified;

    const maxAttempts = 5;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(refreshedUser.uid)
          .get();

      final data = doc.data();
      if (data != null) {
        final appUser = AppUser.fromMap(data);
        debugPrint('[AuthRepository.getCurrentAppUser] profile found role=${appUser.role}');
        if (appUser.emailVerified != authEmailVerified) {
          await _firestore.collection(AppConstants.usersCollection).doc(refreshedUser.uid).update({
            'emailVerified': authEmailVerified,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          return appUser.copyWith(emailVerified: authEmailVerified);
        }
        return appUser;
      }

      if (attempt < maxAttempts - 1) {
        await Future<void>.delayed(Duration(milliseconds: 200 * (attempt + 1)));
      }
    }

    return null;
  }

  Future<AppUser> register({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required bool termsAccepted,
    String communityId = '',
    String communityName = '',
  }) async {
    final normalizedPhoneNumber = Validators.normalizePhoneNumber(phoneNumber);
    final credential = await _authService.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw Exception('Unable to create user account.');
    }
    await _authService.sendEmailVerification();

    final userDoc = _firestore
        .collection(AppConstants.usersCollection)
        .doc(firebaseUser.uid);

    await userDoc.set({
      'uid': firebaseUser.uid,
      'fullName': fullName.trim(),
      'email': email.trim(),
      'phoneNumber': normalizedPhoneNumber,
      'role': AppConstants.roleResident,
      'verificationStatus': AppConstants.verificationPending,
      'emailVerified': _authService.isEmailVerified,
      'phoneVerified': false,
      'profileImageUrl': '',
      'communityId': communityId.trim(),
      'communityName': communityName.trim(),
      'unitNumber': '',
      'reputationScore': 0.0,
      'totalReviews': 0,
      'completedBorrowings': 0,
      'completedLendings': 0,
      'completedServices': 0,
      'termsAccepted': termsAccepted,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final createdDoc = await userDoc.get();
    final data = createdDoc.data();
    if (data == null) {
      final now = DateTime.now();
      return AppUser(
        uid: firebaseUser.uid,
        fullName: fullName.trim(),
        email: email.trim(),
        phoneNumber: normalizedPhoneNumber,
        emailVerified: _authService.isEmailVerified,
        phoneVerified: false,
        role: AppConstants.roleResident,
        verificationStatus: AppConstants.verificationPending,
        profileImageUrl: '',
        communityId: communityId.trim(),
        communityName: communityName.trim(),
        unitNumber: '',
        reputationScore: 0.0,
        totalReviews: 0,
        completedBorrowings: 0,
        completedLendings: 0,
        completedServices: 0,
        termsAccepted: termsAccepted,
        createdAt: now,
        updatedAt: now,
      );
    }

    return AppUser.fromMap(data);
  }

  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    debugPrint('[AuthRepository.login] signIn started email=${email.trim()}');
    final credential = await _authService.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw Exception('Unable to login user.');
    }
    debugPrint('[AuthRepository.login] signIn success uid=${firebaseUser.uid}');

    await _authService.reloadCurrentUser();
    debugPrint('[AuthRepository.login] firebase user reloaded');
    final appUser = await getCurrentAppUser();
    if (appUser == null) {
      throw Exception('User profile not found. Please contact support.');
    }
    if (appUser.role.trim().isEmpty) {
      throw Exception('User role is missing. Please contact support.');
    }

    return appUser;
  }

  /// Google Sign-In. Returns `null` if the user cancelled the account picker.
  Future<AppUser?> signInWithGoogle() async {
    debugPrint('[AuthRepository.signInWithGoogle] started');
    final credential = await _authService.signInWithGoogle();
    if (credential == null) {
      debugPrint('[AuthRepository.signInWithGoogle] cancelled');
      return null;
    }
    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw Exception('Unable to sign in with Google.');
    }
    await _authService.reloadCurrentUser();
    final refreshed = _authService.currentUser ?? firebaseUser;
    final appUser = await _ensureResidentProfileAfterOAuth(
      refreshed,
      preferredFullName: refreshed.displayName?.trim() ?? '',
      preferredEmail: refreshed.email?.trim() ?? '',
    );
    debugPrint('[AuthRepository.signInWithGoogle] done uid=${appUser.uid}');
    return appUser;
  }

  /// Apple Sign-In. Returns `null` if the user cancelled.
  Future<AppUser?> signInWithApple() async {
    debugPrint('[AuthRepository.signInWithApple] started');
    final AppleSignInFlowResult? result = await _authService.signInWithApple();
    if (result == null) {
      debugPrint('[AuthRepository.signInWithApple] cancelled');
      return null;
    }
    final firebaseUser = result.credential.user;
    if (firebaseUser == null) {
      throw Exception('Unable to sign in with Apple.');
    }
    await _authService.reloadCurrentUser();
    final refreshed = _authService.currentUser ?? firebaseUser;

    var fullName = '';
    if (result.givenName != null || result.familyName != null) {
      fullName = '${result.givenName ?? ''} ${result.familyName ?? ''}'.trim();
    }
    if (fullName.isEmpty) {
      fullName = refreshed.displayName?.trim() ?? '';
    }

    var email = refreshed.email?.trim() ?? '';
    if (email.isEmpty && result.appleEmail != null) {
      email = result.appleEmail!.trim();
    }

    final appUser = await _ensureResidentProfileAfterOAuth(
      refreshed,
      preferredFullName: fullName,
      preferredEmail: email,
    );
    debugPrint('[AuthRepository.signInWithApple] done uid=${appUser.uid}');
    return appUser;
  }

  /// Creates [users/{uid}] for OAuth users if missing; otherwise returns existing profile.
  Future<AppUser> _ensureResidentProfileAfterOAuth(
    User firebaseUser, {
    required String preferredFullName,
    required String preferredEmail,
  }) async {
    final docRef = _firestore.collection(AppConstants.usersCollection).doc(firebaseUser.uid);
    final snap = await docRef.get();
    if (snap.exists && snap.data() != null) {
      final existing = AppUser.fromMap(snap.data()!);
      if (existing.role.trim().isEmpty) {
        throw Exception('User role is missing. Please contact support.');
      }
      return existing;
    }

    await docRef.set({
      'uid': firebaseUser.uid,
      'fullName': preferredFullName,
      'email': preferredEmail,
      'phoneNumber': '',
      'role': AppConstants.roleResident,
      'verificationStatus': AppConstants.verificationPending,
      'emailVerified': _authService.isEmailVerified,
      'phoneVerified': false,
      'profileImageUrl': firebaseUser.photoURL ?? '',
      'communityId': '',
      'communityName': '',
      'unitNumber': '',
      'reputationScore': 0.0,
      'totalReviews': 0,
      'completedBorrowings': 0,
      'completedLendings': 0,
      'completedServices': 0,
      'termsAccepted': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    const maxAttempts = 5;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final created = await docRef.get();
      final data = created.data();
      if (data != null) {
        return AppUser.fromMap(data);
      }
      if (attempt < maxAttempts - 1) {
        await Future<void>.delayed(Duration(milliseconds: 200 * (attempt + 1)));
      }
    }

    throw Exception('Could not create your profile. Please try again.');
  }

  /// Links SMS credential to the current user (email/password account) and updates Firestore.
  ///
  /// Call after [FirebaseAuth.verifyPhoneNumber] provides [verificationId] and the user enters [smsCode].
  Future<void> linkRegisteredUserWithPhoneSms({
    required String verificationId,
    required String smsCode,
    required String phoneNumber,
  }) async {
    final user = _authService.currentUser;
    if (user == null) {
      throw Exception('Not signed in.');
    }

    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode.trim(),
    );
    await user.linkWithCredential(credential);

    final normalizedPhone = Validators.normalizePhoneNumber(phoneNumber);
    await _firestore.collection(AppConstants.usersCollection).doc(user.uid).set({
      'phoneVerified': true,
      'phoneNumber': normalizedPhone,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _authService.reloadCurrentUser();
  }

  Future<void> logout() {
    return _authService.signOut();
  }
}
