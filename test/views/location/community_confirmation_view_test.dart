import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/shared/data/repositories/auth_repository.dart';
import 'package:jirani/shared/data/repositories/chat_repository.dart';
import 'package:jirani/shared/data/repositories/connection_repository.dart';
import 'package:jirani/shared/data/repositories/user_repository.dart';
import 'package:jirani/shared/data/repositories/verification_repository.dart';
import 'package:jirani/shared/services/community_service.dart';
import 'package:jirani/shared/models/app_user.dart';
import 'package:jirani/shared/models/community_model.dart';
import 'package:jirani/shared/logic/auth_viewmodel.dart';
import 'package:jirani/resident/screens/location/community_confirmation_view.dart';
import 'package:provider/provider.dart';

void main() {
  group('CommunityConfirmationView', () {
    late List<CommunityModel> communities;
    late AppUser currentUser;

    setUp(() {
      communities = [
        CommunityModel(
          communityId: 'community-a',
          name: 'Community A',
          centerLocation: const GeoPoint(3.0, 101.0),
          radiusInMeters: 500,
          isActive: true,
          city: 'City A',
        ),
        CommunityModel(
          communityId: 'community-b',
          name: 'Community B',
          centerLocation: const GeoPoint(3.1, 101.1),
          radiusInMeters: 500,
          isActive: true,
          city: 'City B',
        ),
      ];
      currentUser = _testUser(
        communityId: 'community-a',
        communityName: 'Community A',
        verificationStatus: AppConstants.verificationPending,
      );
    });

    testWidgets('shows warning for pending user changing community', (
      tester,
    ) async {
      final authViewModel = _TrackingAuthViewModel(currentUser: currentUser);

      await tester.pumpWidget(
        _buildHarness(
          authViewModel: authViewModel,
          communityReader: _FakeCommunityReader(communities),
        ),
      );
      await tester.pumpAndSettle();

      await _selectCommunityB(tester);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Change community?'), findsOneWidget);
      expect(find.text('Neighbor connections will be removed'), findsOneWidget);
      expect(find.text('Verification will reset'), findsNothing);
    });

    testWidgets('shows verification warning for verified user', (
      tester,
    ) async {
      final authViewModel = _TrackingAuthViewModel(
        currentUser: currentUser.copyWith(
          verificationStatus: AppConstants.verificationVerified,
        ),
      );

      await tester.pumpWidget(
        _buildHarness(
          authViewModel: authViewModel,
          communityReader: _FakeCommunityReader(communities),
        ),
      );
      await tester.pumpAndSettle();

      await _selectCommunityB(tester);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Verification will reset'), findsOneWidget);
      expect(find.text('Documents must be submitted again'), findsOneWidget);
    });

    testWidgets('cancel keeps community change from saving', (tester) async {
      final authViewModel = _TrackingAuthViewModel(currentUser: currentUser);

      await tester.pumpWidget(
        _buildHarness(
          authViewModel: authViewModel,
          communityReader: _FakeCommunityReader(communities),
        ),
      );
      await tester.pumpAndSettle();

      await _selectCommunityB(tester);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Keep Current'));
      await tester.pumpAndSettle();

      expect(authViewModel.updateCommunityCalls, 0);
      expect(find.text('Change community?'), findsNothing);
    });

    testWidgets('confirm proceeds with community update', (tester) async {
      final authViewModel = _TrackingAuthViewModel(currentUser: currentUser);

      await tester.pumpWidget(
        _buildHarness(
          authViewModel: authViewModel,
          communityReader: _FakeCommunityReader(communities),
        ),
      );
      await tester.pumpAndSettle();

      await _selectCommunityB(tester);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Change Community'));
      await tester.pump();

      expect(authViewModel.updateCommunityCalls, 1);
    });
  });
}

Future<void> _selectCommunityB(WidgetTester tester) async {
  await tester.tap(find.text('Change Community'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Community B'));
  await tester.pumpAndSettle();
}

Widget _buildHarness({
  required AuthViewModel authViewModel,
  required CommunityReader communityReader,
}) {
  return ChangeNotifierProvider<AuthViewModel>.value(
    value: authViewModel,
    child: MaterialApp(
      home: CommunityConfirmationView(communityReader: communityReader),
    ),
  );
}

class _FakeCommunityReader implements CommunityReader {
  _FakeCommunityReader(this._communities);

  final List<CommunityModel> _communities;

  @override
  Future<List<CommunityModel>> fetchActiveCommunities() async => _communities;
}

class _TrackingAuthViewModel extends AuthViewModel {
  _TrackingAuthViewModel({required AppUser currentUser})
    : super(
        repository: _FakeAuthRepository(),
        userRepository: _FakeUserRepository(),
        connectionRepository: _FakeConnectionRepository(),
        verificationRepository: _FakeVerificationRepository(),
        chatRepository: _FakeChatRepository(),
        listenToAuthChanges: false,
        initialCurrentUser: currentUser,
      );

  int updateCommunityCalls = 0;

  @override
  Future<void> updateSelectedCommunity({
    required String communityId,
    required String communityName,
  }) async {
    updateCommunityCalls += 1;
  }
}

class _FakeAuthRepository implements AuthRepository {
  @override
  Stream<User?> get authStateChanges => const Stream<User?>.empty();

  @override
  User? get currentFirebaseUser => null;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.isMethod) {
      return Future<void>.value();
    }
    return null;
  }
}

class _FakeUserRepository implements UserRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.isMethod) {
      return Future<void>.value();
    }
    return null;
  }
}

class _FakeConnectionRepository implements ConnectionRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.isMethod) {
      return Future<void>.value();
    }
    return null;
  }
}

class _FakeVerificationRepository implements VerificationRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.isMethod) {
      return Future<void>.value();
    }
    return null;
  }
}

class _FakeChatRepository implements ChatRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.isMethod) {
      return Future<void>.value();
    }
    return null;
  }
}

AppUser _testUser({
  required String communityId,
  required String communityName,
  required String verificationStatus,
}) {
  final now = DateTime(2026, 6, 18);
  return AppUser(
    uid: 'user-1',
    firstName: 'Test',
    lastName: 'Resident',
    email: 'test@example.com',
    phoneNumber: '+60123456789',
    emailVerified: true,
    phoneVerified: true,
    role: AppConstants.roleResident,
    verificationStatus: verificationStatus,
    profileImageUrl: '',
    communityId: communityId,
    communityName: communityName,
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
