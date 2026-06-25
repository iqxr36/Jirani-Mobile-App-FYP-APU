import 'dart:async';

import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/shared/data/repositories/auth_repository.dart';
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
}

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

class _RefreshAuthRepository implements AuthRepository {
  _RefreshAuthRepository({
    required this.firebaseUser,
    required List<AppUser?> appUserResults,
  }) : _appUserResults = List<AppUser?>.from(appUserResults);

  final MockUser firebaseUser;
  final List<AppUser?> _appUserResults;

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
    if (invocation.isMethod) {
      return Future<void>.value();
    }
    return null;
  }
}
