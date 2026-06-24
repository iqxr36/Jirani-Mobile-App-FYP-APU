import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/shared/data/repositories/auth_repository.dart';
import 'package:jirani/shared/data/repositories/chat_repository.dart';
import 'package:jirani/shared/data/repositories/connection_repository.dart';
import 'package:jirani/shared/data/repositories/user_repository.dart';
import 'package:jirani/shared/data/repositories/verification_repository.dart';
import 'package:jirani/shared/models/app_user.dart';
import 'package:jirani/shared/logic/auth_viewmodel.dart';

void main() {
  group('AuthViewModel.updateSelectedCommunity', () {
    test('does not reset verification when community stays the same', () async {
      final userRepository = _RecordingUserRepository();
      final connectionRepository = _RecordingConnectionRepository();
      final verificationRepository = _RecordingVerificationRepository();
      final chatRepository = _RecordingChatRepository();
      final viewModel = AuthViewModel(
        repository: _FakeAuthRepository(),
        userRepository: userRepository,
        connectionRepository: connectionRepository,
        verificationRepository: verificationRepository,
        chatRepository: chatRepository,
        listenToAuthChanges: false,
        initialCurrentUser: _user(
          communityId: 'community-a',
          communityName: 'Community A',
          verificationStatus: AppConstants.verificationVerified,
        ),
      );
      addTearDown(viewModel.dispose);

      await viewModel.updateSelectedCommunity(
        communityId: 'community-a',
        communityName: 'Community A',
      );

      expect(verificationRepository.cancelCalls, 0);
      expect(connectionRepository.removeCalls, 0);
      expect(chatRepository.archiveCalls, 0);
      expect(userRepository.lastFields?['verificationStatus'], isNull);
      expect(viewModel.currentUser?.verificationStatus,
          AppConstants.verificationVerified);
    });

    test('resets verification and runs cleanup when community changes', () async {
      final userRepository = _RecordingUserRepository();
      final connectionRepository = _RecordingConnectionRepository();
      final verificationRepository = _RecordingVerificationRepository();
      final chatRepository = _RecordingChatRepository();
      final viewModel = AuthViewModel(
        repository: _FakeAuthRepository(),
        userRepository: userRepository,
        connectionRepository: connectionRepository,
        verificationRepository: verificationRepository,
        chatRepository: chatRepository,
        listenToAuthChanges: false,
        initialCurrentUser: _user(
          communityId: 'community-a',
          communityName: 'Community A',
          verificationStatus: AppConstants.verificationSubmitted,
        ),
      );
      addTearDown(viewModel.dispose);

      await viewModel.updateSelectedCommunity(
        communityId: 'community-b',
        communityName: 'Community B',
      );

      expect(verificationRepository.cancelCalls, 1);
      expect(connectionRepository.removeCalls, 1);
      expect(connectionRepository.lastCommunityId, 'community-b');
      expect(chatRepository.archiveCalls, 1);
      expect(chatRepository.lastCommunityId, 'community-b');
      expect(
        userRepository.lastFields?['verificationStatus'],
        AppConstants.verificationPending,
      );
      expect(userRepository.lastFields?['locationVerified'], isFalse);
      expect(viewModel.currentUser?.communityId, 'community-b');
      expect(viewModel.currentUser?.verificationStatus,
          AppConstants.verificationPending);
      expect(viewModel.currentUser?.locationVerified, isFalse);
    });

    test('skips cleanup when user selects community for the first time', () async {
      final userRepository = _RecordingUserRepository();
      final connectionRepository = _RecordingConnectionRepository();
      final verificationRepository = _RecordingVerificationRepository();
      final chatRepository = _RecordingChatRepository();
      final viewModel = AuthViewModel(
        repository: _FakeAuthRepository(),
        userRepository: userRepository,
        connectionRepository: connectionRepository,
        verificationRepository: verificationRepository,
        chatRepository: chatRepository,
        listenToAuthChanges: false,
        initialCurrentUser: _user(
          communityId: '',
          communityName: '',
          verificationStatus: AppConstants.verificationPending,
        ),
      );
      addTearDown(viewModel.dispose);

      await viewModel.updateSelectedCommunity(
        communityId: 'community-a',
        communityName: 'Community A',
      );

      expect(verificationRepository.cancelCalls, 0);
      expect(connectionRepository.removeCalls, 0);
      expect(chatRepository.archiveCalls, 0);
      expect(userRepository.lastFields?['verificationStatus'], isNull);
    });
  });
}

AppUser _user({
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

class _FakeAuthRepository implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.isGetter && invocation.memberName == #authStateChanges) {
      return Stream<User?>.empty();
    }
    if (invocation.isGetter && invocation.memberName == #currentFirebaseUser) {
      return null;
    }
    if (invocation.isMethod) {
      return Future<void>.value();
    }
    return null;
  }
}

class _RecordingUserRepository implements UserRepository {
  Map<String, dynamic>? lastFields;

  @override
  Future<void> updateUserFields({
    required String uid,
    required Map<String, dynamic> fields,
  }) async {
    lastFields = fields;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.isMethod) {
      return Future<void>.value();
    }
    return null;
  }
}

class _RecordingConnectionRepository implements ConnectionRepository {
  int removeCalls = 0;
  String? lastCommunityId;

  @override
  Future<void> removeConnectionsOutsideCommunity({
    required String uid,
    required String communityId,
  }) async {
    removeCalls += 1;
    lastCommunityId = communityId;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.isMethod) {
      return Future<void>.value();
    }
    return null;
  }
}

class _RecordingVerificationRepository implements VerificationRepository {
  int cancelCalls = 0;

  @override
  Future<void> cancelActiveVerificationRequestIfAny() async {
    cancelCalls += 1;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.isMethod) {
      return Future<void>.value();
    }
    return null;
  }
}

class _RecordingChatRepository implements ChatRepository {
  int archiveCalls = 0;
  String? lastCommunityId;

  @override
  Future<void> archiveChatsOutsideCommunity({
    required String uid,
    required String communityId,
  }) async {
    archiveCalls += 1;
    lastCommunityId = communityId;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.isMethod) {
      return Future<void>.value();
    }
    return null;
  }
}
