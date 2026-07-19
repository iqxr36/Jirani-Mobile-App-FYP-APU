// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : auth_viewmodel_refresh_test.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Friday,26-June-2026
// Last Edited on  : Saturday,18-July-2026

import 'dart:async';
import 'dart:typed_data';

import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/shared/data/repositories/auth_repository.dart';
import 'package:jirani/shared/models/admin_notification_preferences.dart';
import 'package:jirani/shared/models/admin_user.dart';
import 'package:jirani/shared/models/app_user.dart';
import 'package:jirani/shared/logic/auth_viewmodel.dart';

void main() {
  group('AuthViewModel.refreshCurrentUser', () {
    test('preserves cached resident profile when reload returns null', () async {
      final resident = _residentUser();
      final repository = _RefreshAuthRepository(
        firebaseUser: MockUser(uid: resident.uid),
        appUserResults: [null],
      );
      final viewModel = AuthViewModel(
        repository: repository,
        listenToAuthChanges: false,
        initialCurrentUser: resident,
      );
      viewModel.testingSetFirebaseUser(MockUser(uid: resident.uid));
      addTearDown(viewModel.dispose);

      await viewModel.refreshCurrentUser();

      expect(viewModel.currentUser, resident);
      expect(viewModel.currentAdmin, isNull);
      expect(viewModel.profileErrorMessage, isNotNull);
    });

    test('updates profile when reload succeeds', () async {
      final resident = _residentUser();
      final updated = resident.copyWith(firstName: 'Updated');
      final repository = _RefreshAuthRepository(
        firebaseUser: MockUser(uid: resident.uid),
        appUserResults: [updated],
      );
      final viewModel = AuthViewModel(
        repository: repository,
        listenToAuthChanges: false,
        initialCurrentUser: resident,
      );
      viewModel.testingSetFirebaseUser(MockUser(uid: resident.uid));
      addTearDown(viewModel.dispose);

      await viewModel.refreshCurrentUser();

      expect(viewModel.currentUser?.firstName, 'Updated');
      expect(viewModel.profileErrorMessage, isNull);
    });
  });

  group('AuthViewModel admin profile image', () {
    test('hydrates saved admin profile image bytes', () async {
      final admin = _adminUser(profileImageUrl: _adminPhotoUrl);
      final bytes = Uint8List.fromList([1, 2, 3]);
      final repository = _RefreshAuthRepository(
        firebaseUser: MockUser(uid: admin.uid),
        appUserResults: const [],
        downloadedProfileImageBytes: bytes,
      );
      final viewModel = AuthViewModel.forTesting(
        repository: repository,
        currentAdmin: admin,
      );
      viewModel.testingSetFirebaseUser(MockUser(uid: admin.uid));
      addTearDown(viewModel.dispose);

      final hydrated = await viewModel.testingHydrateAdminProfileImage();

      expect(hydrated, isTrue);
      expect(viewModel.adminProfileImageBytes, bytes);
      expect(viewModel.adminProfileImageErrorMessage, isNull);
    });

    test('preserves admin image URL and records error when hydration fails', () async {
      final admin = _adminUser(profileImageUrl: _adminPhotoUrl);
      final repository = _RefreshAuthRepository(
        firebaseUser: MockUser(uid: admin.uid),
        appUserResults: const [],
        throwOnProfileImageDownload: true,
      );
      final viewModel = AuthViewModel.forTesting(
        repository: repository,
        currentAdmin: admin,
      );
      viewModel.testingSetFirebaseUser(MockUser(uid: admin.uid));
      addTearDown(viewModel.dispose);

      final hydrated = await viewModel.testingHydrateAdminProfileImage();

      expect(hydrated, isFalse);
      expect(viewModel.currentAdmin?.profileImageUrl, _adminPhotoUrl);
      expect(viewModel.adminProfileImageBytes, isNull);
      expect(viewModel.adminProfileImageErrorMessage, isNotNull);
    });

    test('preserves admin image URL without visible error when hydration is silent', () async {
      final admin = _adminUser(profileImageUrl: _adminPhotoUrl);
      final repository = _RefreshAuthRepository(
        firebaseUser: MockUser(uid: admin.uid),
        appUserResults: const [],
        throwOnProfileImageDownload: true,
      );
      final viewModel = AuthViewModel.forTesting(
        repository: repository,
        currentAdmin: admin,
        surfaceAdminProfileImageHydrationErrors: false,
      );
      viewModel.testingSetFirebaseUser(MockUser(uid: admin.uid));
      addTearDown(viewModel.dispose);

      final hydrated = await viewModel.testingHydrateAdminProfileImage();

      expect(hydrated, isFalse);
      expect(viewModel.currentAdmin?.profileImageUrl, _adminPhotoUrl);
      expect(viewModel.adminProfileImageBytes, isNull);
      expect(viewModel.adminProfileImageErrorMessage, isNull);
    });

    test('records visible error when admin avatar render fails', () async {
      final admin = _adminUser(profileImageUrl: _adminPhotoUrl);
      final repository = _RefreshAuthRepository(
        firebaseUser: MockUser(uid: admin.uid),
        appUserResults: const [],
      );
      final viewModel = AuthViewModel.forTesting(
        repository: repository,
        currentAdmin: admin,
      );
      viewModel.testingSetFirebaseUser(MockUser(uid: admin.uid));
      addTearDown(viewModel.dispose);

      viewModel.reportAdminProfileImageRenderFailure(Exception('image failed'));

      expect(viewModel.currentAdmin?.profileImageUrl, _adminPhotoUrl);
      expect(viewModel.adminProfileImageErrorMessage, isNotNull);
    });

    test('admin profile image upload succeeds only after server-confirmed URL', () async {
      final admin = _adminUser(profileImageUrl: '');
      final uploadBytes = Uint8List.fromList([4, 5, 6]);
      final repository = _RefreshAuthRepository(
        firebaseUser: MockUser(uid: admin.uid),
        appUserResults: const [],
        uploadedProfileImageUrl: _adminPhotoUrl,
        downloadedProfileImageBytes: uploadBytes,
        adminUserResults: [_adminUser(profileImageUrl: _adminPhotoUrl)],
      );
      final viewModel = AuthViewModel.forTesting(
        repository: repository,
        currentAdmin: admin,
      );
      viewModel.testingSetFirebaseUser(MockUser(uid: admin.uid));
      addTearDown(viewModel.dispose);

      final success = await viewModel.updateAdminProfileImage(
        bytes: uploadBytes,
        originalFileName: 'avatar.jpg',
      );

      expect(success, isTrue);
      expect(viewModel.currentAdmin?.profileImageUrl, _adminPhotoUrl);
      expect(viewModel.adminProfileImageBytes, uploadBytes);
      expect(viewModel.adminProfileImageErrorMessage, isNull);
    });

    test('admin profile image upload fails when server URL is not confirmed', () async {
      final admin = _adminUser(profileImageUrl: '');
      final repository = _RefreshAuthRepository(
        firebaseUser: MockUser(uid: admin.uid),
        appUserResults: const [],
        uploadedProfileImageUrl: _adminPhotoUrl,
        adminUserResults: [_adminUser(profileImageUrl: '')],
      );
      final viewModel = AuthViewModel.forTesting(
        repository: repository,
        currentAdmin: admin,
      );
      viewModel.testingSetFirebaseUser(MockUser(uid: admin.uid));
      addTearDown(viewModel.dispose);

      final success = await viewModel.updateAdminProfileImage(
        bytes: Uint8List.fromList([7, 8, 9]),
        originalFileName: 'avatar.jpg',
      );

      expect(success, isFalse);
      expect(viewModel.currentAdmin?.profileImageUrl, isEmpty);
      expect(viewModel.adminProfileImageBytes, isNull);
      expect(viewModel.errorMessage, contains('could not be saved'));
    });

    test('admin profile image upload succeeds when saved URL byte reload fails', () async {
      final admin = _adminUser(profileImageUrl: '');
      final uploadBytes = Uint8List.fromList([10, 11, 12]);
      final repository = _RefreshAuthRepository(
        firebaseUser: MockUser(uid: admin.uid),
        appUserResults: const [],
        uploadedProfileImageUrl: _adminPhotoUrl,
        throwOnProfileImageDownload: true,
        adminUserResults: [_adminUser(profileImageUrl: _adminPhotoUrl)],
      );
      final viewModel = AuthViewModel.forTesting(
        repository: repository,
        currentAdmin: admin,
      );
      viewModel.testingSetFirebaseUser(MockUser(uid: admin.uid));
      addTearDown(viewModel.dispose);

      final success = await viewModel.updateAdminProfileImage(
        bytes: uploadBytes,
        originalFileName: 'avatar.jpg',
      );

      expect(success, isTrue);
      expect(viewModel.currentAdmin?.profileImageUrl, _adminPhotoUrl);
      expect(viewModel.adminProfileImageBytes, uploadBytes);
      expect(viewModel.adminProfileImageErrorMessage, isNull);
      expect(viewModel.errorMessage, isNull);
    });

    test('admin settings save surfaces permission-denied guidance', () async {
      final admin = _adminUser(profileImageUrl: '');
      final repository = _RefreshAuthRepository(
        firebaseUser: MockUser(uid: admin.uid),
        appUserResults: const [],
        throwOnAdminProfileUpdate: true,
      );
      final viewModel = AuthViewModel.forTesting(
        repository: repository,
        currentAdmin: admin,
      );
      viewModel.testingSetFirebaseUser(MockUser(uid: admin.uid));
      addTearDown(viewModel.dispose);

      final success = await viewModel.updateAdminProfileSettings(
        fullName: 'Updated Admin',
        phoneNumber: '+60123456789',
        notificationPreferences: AdminNotificationPreferences.defaults,
        themePresetId: 'teal',
      );

      expect(success, isFalse);
      expect(viewModel.errorMessage, contains('Could not save admin settings'));
    });
  });
}

const _adminPhotoUrl =
    'https://firebasestorage.googleapis.com/v0/b/example.appspot.com/o/profile_images%2Fadmins%2Fadmin-1%2Favatar.jpg?alt=media&token=abc';

AppUser _residentUser() {
  final now = DateTime(2026, 6, 18);
  return AppUser(
    uid: 'resident-1',
    firstName: 'Test',
    lastName: 'Resident',
    email: 'resident@example.com',
    phoneNumber: '+60123456789',
    emailVerified: true,
    phoneVerified: true,
    role: AppConstants.roleResident,
    verificationStatus: AppConstants.verificationVerified,
    profileImageUrl: '',
    communityId: 'community-1',
    communityName: 'One South',
    unitNumber: 'A-1-1',
    reputationScore: 0,
    totalReviews: 0,
    completedBorrowings: 0,
    completedLendings: 0,
    completedServices: 0,
    termsAccepted: true,
    locationVerified: true,
    createdAt: now,
    updatedAt: now,
  );
}

AdminUser _adminUser({required String profileImageUrl}) {
  final now = DateTime(2026, 6, 18);
  return AdminUser(
    uid: 'admin-1',
    fullName: 'Test Admin',
    email: 'admin@example.com',
    phoneNumber: '+60123456789',
    role: AppConstants.roleCommunityAdmin,
    communityId: 'community-1',
    communityName: 'One South',
    profileImageUrl: profileImageUrl,
    themePresetId: 'teal',
    permissions: const [],
    notificationPreferences: AdminNotificationPreferences.defaults,
    isActive: true,
    createdAt: now,
    updatedAt: now,
  );
}

class _RefreshAuthRepository implements AuthRepository {
  _RefreshAuthRepository({
    required this.firebaseUser,
    required List<AppUser?> appUserResults,
    List<AdminUser?> adminUserResults = const [],
    this.downloadedProfileImageBytes,
    this.throwOnProfileImageDownload = false,
    this.throwOnAdminProfileUpdate = false,
    this.uploadedProfileImageUrl,
  }) : _appUserResults = List<AppUser?>.from(appUserResults),
       _adminUserResults = List<AdminUser?>.from(adminUserResults);

  final MockUser firebaseUser;
  final List<AppUser?> _appUserResults;
  final List<AdminUser?> _adminUserResults;
  final Uint8List? downloadedProfileImageBytes;
  final bool throwOnProfileImageDownload;
  final bool throwOnAdminProfileUpdate;
  final String? uploadedProfileImageUrl;
  String? savedAdminProfileImageUrl;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.isGetter && invocation.memberName == #authStateChanges) {
      return Stream<Never>.empty();
    }
    if (invocation.isGetter && invocation.memberName == #currentFirebaseUser) {
      return firebaseUser;
    }
    if (invocation.memberName == #getCurrentAppUser) {
      if (_appUserResults.isEmpty) {
        return Future<AppUser?>.value(null);
      }
      return Future<AppUser?>.value(_appUserResults.removeAt(0));
    }
    if (invocation.memberName == #getCurrentAdminUser) {
      if (_adminUserResults.isEmpty) {
        return Future<AdminUser?>.value(null);
      }
      return Future<AdminUser?>.value(_adminUserResults.removeAt(0));
    }
    if (invocation.memberName == #downloadProfileImageBytes) {
      if (throwOnProfileImageDownload) {
        return Future<Uint8List?>.error(Exception('download failed'));
      }
      return Future<Uint8List?>.value(downloadedProfileImageBytes);
    }
    if (invocation.memberName == #uploadProfileImage) {
      return Future<String>.value(uploadedProfileImageUrl ?? _adminPhotoUrl);
    }
    if (invocation.memberName == #updateAdminProfileImageUrl) {
      savedAdminProfileImageUrl =
          invocation.namedArguments[#profileImageUrl] as String?;
      return Future<void>.value();
    }
    if (invocation.memberName == #updateAdminProfile) {
      if (throwOnAdminProfileUpdate) {
        return Future<void>.error(
          Exception(
            'Could not save admin settings. Confirm admins/${firebaseUser.uid} exists, '
            'role is communityAdmin or systemAdmin, the account is active, and '
            'deployed Firestore rules allow admin self-profile updates.',
          ),
        );
      }
      return Future<void>.value();
    }
    if (invocation.isMethod) {
      return Future<void>.value();
    }
    return null;
  }
}
