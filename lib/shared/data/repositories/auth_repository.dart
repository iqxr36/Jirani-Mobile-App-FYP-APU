// Data-layer convention: ViewModels and Providers depend on repositories under
// `shared/data/repositories/` for Firestore-backed entities. Orchestration lives
// in `shared/services/`; some repositories delegate to a service. UI must not
// import services directly.
import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:jirani/core/utils/auth_debug_log.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/core/utils/firebase_storage_url.dart';
import 'package:jirani/core/utils/validators.dart';
import 'package:jirani/shared/models/admin_user.dart';
import 'package:jirani/shared/models/admin_notification_preferences.dart';
import 'package:jirani/shared/models/app_user.dart';
import 'package:jirani/shared/services/firebase_auth_service.dart';

// Authentication data layer: coordinates Firebase Auth sessions with users/{uid} and admins/{uid} profile documents.
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

  // Authentication feature: exposes Firebase session changes to AuthViewModel and AuthWrapper.
  Stream<User?> get authStateChanges => _authService.authStateChanges;

  User? get currentFirebaseUser => _authService.currentUser;

  // Authentication feature: sends a Firebase password reset email for the login screen.
  Future<void> sendPasswordResetEmail(String email) {
    return _authService.sendPasswordResetEmail(email);
  }

  // Authentication feature: resends Firebase email verification for residents who have not verified email yet.
  Future<void> resendEmailVerification() {
    return _authService.sendEmailVerification();
  }

  // Authentication feature: reloads Firebase Auth and reads/synchronizes the resident users/{uid} profile.
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
        final pendingEmail = appUser.pendingEmail.trim();
        if (pendingEmail.isNotEmpty &&
            authEmail.isNotEmpty &&
            pendingEmail.toLowerCase() == authEmail.toLowerCase()) {
          profileUpdates['pendingEmail'] = '';
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
            pendingEmail: profileUpdates.containsKey('pendingEmail')
                ? ''
                : appUser.pendingEmail,
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

  // Admin authentication feature: reads admins/{uid}, validates active role, and returns the admin profile.
  Future<AdminUser?> getCurrentAdminUser({
    bool reloadAuthUser = true,
    bool preferServer = false,
  }) async {
    authDebugLog('[AuthRepository.getCurrentAdminUser] started');
    final user = _authService.currentUser;
    authDebugLog(
      '[AuthRepository.getCurrentAdminUser] firebase session=${user != null}',
    );
    if (user == null) return null;
    if (reloadAuthUser) {
      await _authService.reloadCurrentUser();
    }
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
        doc = preferServer
            ? await docRef.get(const GetOptions(source: Source.server))
            : await docRef.get();
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

  // Profile feature: uploads resident/admin avatar bytes to Storage and returns the download URL.
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
    final detected = _detectProfileImageFormat(bytes, extension);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ref = _storage
        .ref()
        .child(AppConstants.storageProfileImagesPath)
        .child(accountFolder)
        .child(uid)
        .child('avatar_$timestamp.${detected.extension}');

    final metadata = SettableMetadata(
      contentType: detected.contentType,
      customMetadata: {
        'ownerUid': uid,
        'accountType': accountFolder,
        'originalFileName': originalFileName,
      },
    );

    await ref.putData(bytes, metadata).timeout(_networkTimeout);
    return ref.getDownloadURL().timeout(_networkTimeout);
  }

  // Profile feature: downloads avatar bytes via authenticated Storage path reads.
  Future<Uint8List?> downloadProfileImageBytes(String downloadUrl) async {
    final trimmed = downloadUrl.trim();
    if (trimmed.isEmpty) return null;

    const maxBytes = 5 * 1024 * 1024;
    final objectPath = firebaseStorageObjectPathFromProfileImageReference(
      trimmed,
    );
    if (objectPath != null) {
      try {
        final ref = _storage.ref(objectPath);
        return ref.getData(maxBytes).timeout(_networkTimeout);
      } catch (e) {
        if (_isHttpUrl(trimmed)) {
          authDebugLogError(
            '[AuthRepository.downloadProfileImageBytes] Storage SDK read failed; falling back to HTTP download',
            e,
          );
          return _downloadProfileImageBytesOverHttp(trimmed, maxBytes);
        }
        throw Exception(_profileImageDownloadFailureMessage(e));
      }
    }

    if (_isHttpUrl(trimmed)) {
      return _downloadProfileImageBytesOverHttp(trimmed, maxBytes);
    }

    throw Exception(
      'Saved profile photo reference is not a supported Firebase Storage path or download URL.',
    );
  }

  // Admin profile feature: stores the latest admin avatar URL on admins/{uid}.
  Future<void> updateAdminProfileImageUrl({
    required String uid,
    required String profileImageUrl,
  }) async {
    await _firestore.collection(AppConstants.adminsCollection).doc(uid).update({
      'profileImageUrl': profileImageUrl.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Admin settings feature: saves editable admin profile fields and notification prefs.
  Future<void> updateAdminProfile({
    required String uid,
    required String fullName,
    required String phoneNumber,
    required AdminNotificationPreferences notificationPreferences,
  }) async {
    final trimmedPhone = phoneNumber.trim();
    await _firestore.collection(AppConstants.adminsCollection).doc(uid).update({
      'fullName': fullName.trim(),
      'phoneNumber': trimmedPhone.isEmpty
          ? ''
          : Validators.normalizePhoneNumber(trimmedPhone),
      'notificationPreferences': notificationPreferences.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Resident profile feature: starts Firebase's verified email-change flow and stores pendingEmail in Firestore.
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

    // Duplicate checks must go through Firebase Auth — residents cannot query
    // /users by email (Firestore list rules are admin-only).
    await _authService.verifyBeforeUpdateEmail(trimmedEmail);
    await _firestore.collection(AppConstants.usersCollection).doc(firebaseUser.uid).update({
      'pendingEmail': trimmedEmail,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _authService.reloadCurrentUser();
  }

  // Admin authentication feature: maps and validates admin role/account status before entering the portal.
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

  // Resident registration feature: creates Firebase Auth user, sends email verification, and writes users/{uid}.
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
      'completedServicesProvided': 0,
      'completedServicesRequested': 0,
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
        completedServicesProvided: 0,
        completedServicesRequested: 0,
        termsAccepted: termsAccepted,
        locationVerified: false,
        createdAt: now,
        updatedAt: now,
      );
    }

    return AppUser.fromMap(data);
  }

  // Authentication feature: signs in with email/password and reloads the Firebase session.
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

  // Authentication feature: signs in with Google and creates the resident profile if this OAuth user is new.
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

  // Authentication feature: signs in with Apple and creates the resident profile if this OAuth user is new.
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

  // OAuth profile feature: creates users/{uid} for first-time Google/Apple users or returns the existing profile.
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
      'completedServicesProvided': 0,
      'completedServicesRequested': 0,
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

  // OAuth profile feature: splits provider displayName into first and last name fields for users/{uid}.
  (String, String) _splitName(String fullName) {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) return ('', '');

    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) return (parts.first, '');
    return (parts.first, parts.skip(1).join(' '));
  }

  // Phone verification feature: links an SMS code credential to the registered user and marks phoneVerified.
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

  // Phone verification feature: links an already-built phone credential and updates the resident phone metadata.
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

  // Authentication feature: signs the current Firebase user out.
  Future<void> logout() {
    return _authService.signOut();
  }

  // Profile feature: normalizes avatar file extension before uploading to Firebase Storage.
  static String _profileImageExtension(String fileName) {
    final trimmed = fileName.trim().toLowerCase();
    final extension = trimmed.contains('.') ? trimmed.split('.').last : 'jpg';
    return switch (extension) {
      'jpg' || 'jpeg' || 'png' || 'webp' => extension,
      _ => 'jpg',
    };
  }

  // Profile feature: maps avatar extension to Firebase Storage content type.
  static String _profileImageContentType(String extension) {
    return switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
  }

  static ({String extension, String contentType}) _detectProfileImageFormat(
    Uint8List bytes,
    String fallbackExtension,
  ) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return (extension: 'jpg', contentType: 'image/jpeg');
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return (extension: 'png', contentType: 'image/png');
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return (extension: 'webp', contentType: 'image/webp');
    }
    final extension = _profileImageExtension(fallbackExtension);
    return (
      extension: extension,
      contentType: _profileImageContentType(extension),
    );
  }

  static bool _isHttpUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  static String _profileImageDownloadFailureMessage(Object error) {
    if (error is TimeoutException) {
      return 'Profile photo download timed out.';
    }
    if (error is FirebaseException) {
      return switch (error.code) {
        'object-not-found' =>
          'Profile photo file was not found in Firebase Storage.',
        'unauthorized' || 'permission-denied' =>
          'Firebase Storage denied access to the saved profile photo. Check the deployed Storage read rules.',
        'canceled' => 'Profile photo download was canceled.',
        'retry-limit-exceeded' =>
          'Profile photo download failed after too many retries.',
        _ =>
          'Firebase Storage could not read the saved profile photo (${error.code}).',
      };
    }
    return 'Could not read the saved profile photo from Firebase Storage.';
  }

  static Future<Uint8List?> _downloadProfileImageBytesOverHttp(
    String url,
    int maxBytes,
  ) async {
    final uri = Uri.tryParse(url);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw Exception(
        'Saved profile photo reference is not a valid download URL.',
      );
    }

    final response = await http.get(uri).timeout(_networkTimeout);
    if (response.statusCode != 200) {
      throw Exception(
        'Profile photo HTTP download failed with status ${response.statusCode}.',
      );
    }
    final bytes = response.bodyBytes;
    if (bytes.lengthInBytes > maxBytes) {
      throw Exception('Saved profile photo is larger than 5 MB.');
    }
    return bytes;
  }
}
