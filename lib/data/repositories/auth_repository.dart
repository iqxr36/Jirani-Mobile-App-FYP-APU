import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/core/utils/validators.dart';
import 'package:jirani/data/models/admin_user.dart';
import 'package:jirani/data/models/app_user.dart';
import 'package:jirani/services/firebase_auth_service.dart';

class AuthRepository {
  AuthRepository({
    FirebaseAuthService? authService,
    FirebaseFirestore? firestore,
  }) : _authService = authService ?? FirebaseAuthService(),
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
        debugPrint(
          '[AuthRepository.getCurrentAppUser] profile found role=${appUser.role}',
        );
        if (appUser.emailVerified != authEmailVerified) {
          await _firestore
              .collection(AppConstants.usersCollection)
              .doc(refreshedUser.uid)
              .update({
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

  Future<AdminUser?> getCurrentAdminUser() async {
    debugPrint('[AuthRepository.getCurrentAdminUser] started');
    final user = _authService.currentUser;
    debugPrint(
      '[AuthRepository.getCurrentAdminUser] current FirebaseAuth UID=${user?.uid}',
    );
    if (user == null) return null;
    await _authService.reloadCurrentUser();
    final refreshedUser = _authService.currentUser;
    debugPrint(
      '[AuthRepository.getCurrentAdminUser] refreshed FirebaseAuth UID=${refreshedUser?.uid}',
    );
    if (refreshedUser == null) return null;

    const maxAttempts = 5;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final docRef = _firestore
          .collection(AppConstants.adminsCollection)
          .doc(refreshedUser.uid);
      debugPrint(
        '[AuthRepository.getCurrentAdminUser] Firestore path=${docRef.path}',
      );
      final DocumentSnapshot<Map<String, dynamic>> doc;
      try {
        doc = await docRef.get();
      } on FirebaseException catch (e) {
        debugPrint(
          '[AuthRepository.getCurrentAdminUser] Firestore read failed path=${docRef.path} code=${e.code} message=${e.message}',
        );
        throw Exception(
          'Firestore read failed for ${docRef.path}: ${e.code}'
          '${e.message == null ? '' : ' - ${e.message}'}',
        );
      }

      debugPrint(
        '[AuthRepository.getCurrentAdminUser] doc.exists=${doc.exists}',
      );
      final data = doc.data();
      debugPrint('[AuthRepository.getCurrentAdminUser] doc.data=$data');
      if (data != null) {
        return _mapAdminProfile({...data, 'uid': refreshedUser.uid});
      }

      if (doc.exists) {
        throw Exception(
          'Admin document found at ${docRef.path}, but Firestore returned null data.',
        );
      }

      if (attempt < maxAttempts - 1) {
        await Future<void>.delayed(Duration(milliseconds: 200 * (attempt + 1)));
      }
    }

    throw Exception(
      'Admin document not found at ${AppConstants.adminsCollection}/${refreshedUser.uid}.',
    );
  }

  AdminUser _mapAdminProfile(Map<String, dynamic> data) {
    const fieldsUsedByAdminUser = <String>[
      'uid',
      'fullName',
      'email',
      'phoneNumber',
      'role',
      'communityId',
      'communityName',
      'profileImageUrl',
      'permissions',
      'isActive',
      'status',
      'createdAt',
      'updatedAt',
    ];
    for (final field in fieldsUsedByAdminUser) {
      final value = data[field];
      debugPrint(
        '[AuthRepository._mapAdminProfile] AdminUser.fromMap field "$field" '
        'type=${value.runtimeType} value=$value',
      );
    }

    final AdminUser admin;
    try {
      admin = AdminUser.fromMap(data);
    } catch (e, stackTrace) {
      debugPrint(
        '[AuthRepository._mapAdminProfile] AdminUser.fromMap exception: $e',
      );
      debugPrintStack(stackTrace: stackTrace);
      throw Exception('Admin document found but model mapping failed: $e');
    }

    debugPrint(
      '[AuthRepository.getCurrentAdminUser] profile mapped '
      'uid=${admin.uid} role=${admin.role} isActive=${admin.isActive} '
      'email=${admin.email} communityId=${admin.communityId} '
      'communityName=${admin.communityName} permissions=${admin.permissions}',
    );
    if (!admin.isActive) {
      throw Exception('This admin account is disabled.');
    }
    if (!admin.isCommunityAdmin && !admin.isSystemAdmin) {
      throw Exception('Admin role is invalid. Please contact support.');
    }
    return admin;
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
      'locationVerified': false,
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
        locationVerified: false,
        createdAt: now,
        updatedAt: now,
      );
    }

    return AppUser.fromMap(data);
  }

  Future<void> login({required String email, required String password}) async {
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
    final docRef = _firestore
        .collection(AppConstants.usersCollection)
        .doc(firebaseUser.uid);
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
      'locationVerified': false,
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
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .set({
          'phoneVerified': true,
          'phoneNumber': normalizedPhone,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

    await _authService.reloadCurrentUser();
  }

  Future<void> linkRegisteredUserWithPhoneCredential({
    required PhoneAuthCredential credential,
    required String phoneNumber,
  }) async {
    final user = _authService.currentUser;
    if (user == null) {
      throw Exception('Not signed in.');
    }

    await user.linkWithCredential(credential);

    final normalizedPhone = Validators.normalizePhoneNumber(phoneNumber);
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .set({
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
