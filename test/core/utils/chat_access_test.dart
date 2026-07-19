// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : chat_access_test.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Thursday,18-June-2026
// Last Edited on  : Saturday,18-July-2026

import 'package:flutter_test/flutter_test.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/resident/logic/chat_access.dart';
import 'package:jirani/shared/models/app_user.dart';
import 'package:jirani/shared/models/chat_model.dart';

void main() {
  group('validateChatAccess', () {
    test('rejects chats outside sender community', () {
      final sender = _user(
        communityId: 'community-b',
        verificationStatus: AppConstants.verificationVerified,
      );
      final chat = _chat(communityId: 'community-a');

      expect(
        () => validateChatAccess(chat: chat, sender: sender),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('inside your community'),
          ),
        ),
      );
    });

    test('rejects archived chats for sender', () {
      final sender = _user(
        communityId: 'community-a',
        verificationStatus: AppConstants.verificationVerified,
      );
      final chat = _chat(
        communityId: 'community-a',
        deletedFor: const ['user-1'],
      );

      expect(
        () => validateChatAccess(chat: chat, sender: sender),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('no longer available'),
          ),
        ),
      );
    });

    test('allows chat in sender community', () {
      final sender = _user(
        communityId: 'community-a',
        verificationStatus: AppConstants.verificationVerified,
      );
      final chat = _chat(communityId: 'community-a');

      expect(
        () => validateChatAccess(chat: chat, sender: sender),
        returnsNormally,
      );
    });
  });
}

AppUser _user({
  required String communityId,
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
    communityName: 'Community',
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

ChatModel _chat({
  required String communityId,
  List<String> deletedFor = const [],
}) {
  return ChatModel(
    id: 'chat-1',
    participantIds: ['user-1', 'user-2'],
    communityId: communityId,
    connectionId: 'chat-1',
    participantNames: const {'user-1': 'Test', 'user-2': 'Neighbor'},
    participantImageUrls: const {'user-1': '', 'user-2': ''},
    lastMessageText: '',
    lastMessageType: AppConstants.chatMessageText,
    lastMessageAt: null,
    lastSenderId: '',
    unreadCounts: const {'user-1': 0, 'user-2': 0},
    deletedFor: deletedFor,
    createdAt: DateTime(2026, 6, 18),
    updatedAt: DateTime(2026, 6, 18),
  );
}
