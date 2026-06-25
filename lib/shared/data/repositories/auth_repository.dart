/// Data-layer convention: ViewModels and Providers depend on repositories under
/// `shared/data/repositories/` for Firestore-backed entities. Orchestration lives
/// in `shared/services/`; some repositories delegate to a service. UI must not
/// import services directly.
import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:jirani/core/utils/auth_debug_log.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/core/utils/validators.dart';
import 'package:jirani/shared/models/admin_user.dart';
import 'package:jirani/shared/models/app_user.dart';
import 'package:jirani/shared/services/firebase_auth_service.dart';

class AuthRepository {
  AuthRepository({
    FirebaseAuthService? authService,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _authService = authService ?? FirebaseAuthService(),
       _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance;

  final FirebaseAuthService _authService;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  static const Duration _networkTimeout = Duration(seconds: 30);

  Stream<User?> get authStateChanges => _authService.authStateChanges;

  User? get currentFirebaseUser => _authService.currentUser;

  Future<void> sendPasswordResetEmail(String email) {
    return _authService.sendPasswordResetEmail(email);
  }

  Future<void> resendEmailVerification() {
    return _authService.sendEmailVerification();
  }

  Future<AppUser?> getCurrentAppUser() async {
    authDebugLog('[AuthRepository.getCurrentAppUser] started');
    final user = _authService.currentUser;
    if (user == null) return null;
    authDebugLog('[AuthRepository.getCurrentAppUser] firebase session present');
    await _authService.reloadCurrentUser();
    final refreshedUser = _authService.currentUser;
    if (refreshedUser == null) return null;
    final authEmailVerified = _authService.isEmailVerified;
    final authEmail = refreshedUser.email?.trim() ?? '';

    const maxAttempts = 5;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(refreshedUser.uid)
          .get();

      final data = doc.data();
      if (data != null) {
        final appUser = AppUser.fromMap(data);
        authDebugLog(
          '[AuthRepository.getCurrentAppUser] profile found role=${appUser.role}',
        );
        final profileUpdates = <String, dynamic>{};
        final syncedEmail = authEmail.isNotEmpty ? authEmail : appUser.email;
        if (authEmail.isNotEmpty &&
            appUser.email.trim().toLowerCase() != authEmail.toLowerCase()) {
          profileUpdates['email'] = authEmail;
        }
        if (appUser.emailVerified != authEmailVerified) {
          profileUpdates['emailVerified'] = authEmailVerified;
        }
        if (profileUpdates.isNotEmpty) {
          profileUpdates['updatedAt'] = FieldValue.serverTimestamp();
          await _firestore
              .collection(AppConstants.usersCollection)
              .doc(refreshedUser.uid)
              .update(profileUpdates);
          return appUser.copyWith(
            email: syncedEmail,
            emailVerified: authEmailVerified,
          );
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
    authDebugLog('[AuthRepository.getCurrentAdminUser] started');
    final user = _authService.currentUser;
    authDebugLog(
      '[AuthRepository.getCurrentAdminUser] firebase session=${user != null}',
    );
    if (user == null) return null;
    await _authService.reloadCurrentUser();
    final refreshedUser = _authService.currentUser;
    authDebugLog(
      '[AuthRepository.getCurrentAdminUser] firebase session refreshed',
    );
    if (refreshedUser == null) return null;

    const maxAttempts = 5;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final docRef = _firestore
          .collection(AppConstants.adminsCollection)
          .doc(refreshedUser.uid);
      authDebugLog(
        '[AuthRepository.getCurrentAdminUser] Firestore read attempt ${attempt + 1}',
      );
      final DocumentSnapshot<Map<String, dynamic>> doc;
      try {
        doc = await docRef.get();
      } on FirebaseException catch (e) {
        authDebugLog(
          '[AuthRepository.getCurrentAdminUser] Firestore read failed code=${e.code}',
        );
        throw Exception(
          'Firestore read failed for ${docRef.path}: ${e.code}'
          '${e.message == null ? '' : ' - ${e.message}'}',
        );
      }

      authDebugLog(
        '[AuthRepository.getCurrentAdminUser] doc.exists=${doc.exists}',
      );
      final data = doc.data();
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

  Future<String> uploadProfileImage({
    required String uid,
    required Uint8List bytes,
    required String originalFileName,
    required String accountFolder,
  }) async {
    if (bytes.isEmpty) {
      throw Exception('The selected image is empty.');
    }

    final extension = _profileImageExtension(originalFileName);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ref = _storage
        .ref()
        .child(AppConstants.storageProfileImagesPath)
        .child(accountFolder)
        .child(uid)
        .child('avatar_$timestamp.$extension');

    final metadata = SettableMetadata(
      contentType: _profileImageContentType(extension),
      customMetadata: {
        'ownerUid': uid,
        'accountType': accountFolder,
        'originalFileName': originalFileName,
      },
    );

    await ref.putData(bytes, metadata).timeout(_networkTimeout);
    return ref.getDownloadURL().timeout(_networkTimeout);
  }

  Future<void> updateAdminProfileImageUrl({
    required String uid,
    required String profileImageUrl,
  }) async {
    await _firestore.collection(AppConstants.adminsCollection).doc(uid).update({
      'profileImageUrl': profileImageUrl.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateResidentEmail(String newEmail) async {
    final firebaseUser = _authService.currentUser;
    if (firebaseUser == null) {
      throw Exception('You must be signed in to update your email.');
    }
    final trimmedEmail = newEmail.trim();
    final emailError = Validators.validateEmail(trimmedEmail);
    if (emailError != null) {
      throw Exception(emailError);
    }
    final currentEmail = (firebaseUser.email ?? '').trim();
    if (trimmedEmail.toLowerCase() == currentEmail.toLowerCase()) {
      return;
    }

    final existingProfile = await _firestore
        .collection(AppConstants.usersCollection)
        .where('email', isEqualTo: trimmedEmail)
        .limit(2)
        .get();
    final emailBelongsToOtherProfile = existingProfile.docs.any(
      (doc) => doc.id != firebaseUser.uid,
    );
    if (emailBelongsToOtherProfile) {
      throw Exception('This email is already used by another account.');
    }

    await _authService.verifyBeforeUpdateEmail(trimmedEmail);
    await _authService.reloadCurrentUser();
  }

  AdminUser _mapAdminProfile(Map<String, dynamic> data) {
    final AdminUser admin;
    try {
      admin = AdminUser.fromMap(data);
    } catch (e, stackTrace) {
      authDebugLogError('[AuthRepository._mapAdminProfile]', e, stackTrace);
      throw Exception('Admin document found but model mapping failed: $e');
    }

    authDebugLog(
      '[AuthRepository.getCurrentAdminUser] profile mapped '
      'role=${admin.role} isActive=${admin.isActive}',
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
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String password,
    required bool termsAccepted,
    String communityId = '',
    String communityName = '',
  }) async {
    final validationError =
        Validators.validateFirstName(firstName) ??
        Validators.validateLastName(lastName) ??
        Validators.validateEmail(email) ??
        Validators.validatePhone(phoneNumber) ??
        Validators.validatePassword(password);
    if (validationError != null) {
      throw Exception(validationError);
    }
    if (!termsAccepted) {
      throw Exception('Accept the terms and conditions to continue.');
    }

    final trimmedFirstName = firstName.trim();
    final trimmedLastName = lastName.trim();
    final fullName = '$trimmedFirstName $trimmedLastName'.trim();
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
      'firstName': trimmedFirstName,
      'lastName': trimmedLastName,
      'fullName': fullName,
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
        firstName: trimmedFirstName,
        lastName: trimmedLastName,
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
    authDebugLog('[AuthRepository.login] signIn started');
    final credential = await _authService.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw Exception('Unable to login user.');
    }
    authDebugLog('[AuthRepository.login] signIn success');

    await _authService.reloadCurrentUser();
    authDebugLog('[AuthRepository.login] firebase user reloaded');
  }

  /// Google Sign-In. Returns `null` if the user cancelled the account picker.
  Future<AppUser?> signInWithGoogle() async {
    authDebugLog('[AuthRepository.signInWithGoogle] started');
    final credential = await _authService.signInWithGoogle();
    if (credential == null) {
      authDebugLog('[AuthRepository.signInWithGoogle] cancelled');
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
    authDebugLog('[AuthRepository.signInWithGoogle] done');
    return appUser;
  }

  /// Apple Sign-In. Returns `null` if the user cancelled.
  Future<AppUser?> signInWithApple() async {
    authDebugLog('[AuthRepository.signInWithApple] started');
    final AppleSignInFlowResult? result = await _authService.signInWithApple();
    if (result == null) {
      authDebugLog('[AuthRepository.signInWithApple] cancelled');
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
    authDebugLog('[AuthRepository.signInWithApple] done');
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
    final names = _splitName(preferredFullName);

    await docRef.set({
      'uid': firebaseUser.uid,
      'firstName': names.$1,
      'lastName': names.$2,
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

  (String, String) _splitName(String fullName) {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) return ('', '');

    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) return (parts.first, '');
    return (parts.first, parts.skip(1).join(' '));
  }

  /// Links SMS credential to the current user (email/password account) and updates Firestore.
  ///
  /// Call after [FirebaseAuth.verifyPhoneNumber] provides [verificationId] and the user enters [smsCode].
  Future<void> linkRegisteredUserWithPhoneSms({
    required String verificationId,
    required String smsCode,
    required String phoneNumber,
  }) async {
    final codeError = Validators.validateSixDigitCode(smsCode);
    if (codeError != null) {
      throw Exception(codeError);
    }
    final phoneError = Validators.validatePhone(phoneNumber);
    if (phoneError != null) {
      throw Exception(phoneError);
    }
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
    final phoneError = Validators.validatePhone(phoneNumber);
    if (phoneError != null) {
      throw Exception(phoneError);
    }
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

  static String _profileImageExtension(String fileName) {
    final trimmed = fileName.trim().toLowerCase();
    final extension = trimmed.contains('.') ? trimmed.split('.').last : 'jpg';
    return switch (extension) {
      'jpg' || 'jpeg' || 'png' || 'webp' => extension,
      _ => 'jpg',
    };
  }

  static String _profileImageContentType(String extension) {
    return switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
  }
}
