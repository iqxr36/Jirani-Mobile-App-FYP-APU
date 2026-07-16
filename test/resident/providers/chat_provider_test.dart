import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/resident/providers/chat_provider.dart';
import 'package:jirani/shared/data/repositories/chat_repository.dart';
import 'package:jirani/shared/models/app_user.dart';
import 'package:jirani/shared/models/chat_model.dart';
import 'package:jirani/shared/services/chat_service.dart';
import 'package:firebase_storage/firebase_storage.dart';

Future<void> _ensureTestFirebase() async {
  if (Firebase.apps.isNotEmpty) return;
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'test',
        appId: 'test',
        messagingSenderId: 'test',
        projectId: 'test',
        storageBucket: 'test.appspot.com',
      ),
    );
  } on FirebaseException catch (error) {
    if (error.code != 'duplicate-app') rethrow;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();

  setUpAll(_ensureTestFirebase);

  group('ChatProvider.watchForUser', () {
    late FakeChatRepository repository;
    late ChatProvider provider;

    setUp(() {
      repository = FakeChatRepository();
      provider = ChatProvider(repository: repository);
    });

    tearDown(() {
      provider.dispose();
      repository.dispose();
    });

    test('does not subscribe for unverified resident', () {
      provider.watchForUser(_resident(verified: false));

      expect(repository.watchChatsCalls, 0);
      expect(provider.chats, isEmpty);
      expect(provider.totalUnreadCount, 0);
      expect(provider.isLoading, isFalse);
    });

    test('subscribes for verified resident with full access', () async {
      provider.watchForUser(_resident(verified: true));

      expect(repository.watchChatsCalls, 1);

      repository.emitChats([
        _chat(unreadForCurrentUser: 2),
      ]);
      await Future<void>.delayed(Duration.zero);

      expect(provider.chats, hasLength(1));
      expect(provider.totalUnreadCount, 2);
    });

    test('re-subscribes when verification status changes for same user', () {
      final pending = _resident(verified: false);
      final verified = _resident(verified: true);

      provider.watchForUser(pending);
      expect(repository.watchChatsCalls, 0);

      provider.watchForUser(verified);
      expect(repository.watchChatsCalls, 1);

      provider.watchForUser(pending);
      expect(repository.watchChatsCalls, 1);
      expect(provider.totalUnreadCount, 0);
    });
  });
}

class FakeChatRepository extends ChatRepository {
  FakeChatRepository()
    : super(
        service: ChatService(
          firestore: FakeFirebaseFirestore(),
          storage: FirebaseStorage.instanceFor(
            app: Firebase.app(),
            bucket: 'test.appspot.com',
          ),
        ),
      );

  int watchChatsCalls = 0;
  final _chatsController = StreamController<List<ChatModel>>.broadcast();

  void emitChats(List<ChatModel> chats) {
    _chatsController.add(chats);
  }

  void dispose() {
    _chatsController.close();
  }

  @override
  Stream<List<ChatModel>> watchChats(AppUser currentUser) {
    watchChatsCalls++;
    return _chatsController.stream;
  }
}

AppUser _resident({required bool verified}) {
  final now = DateTime(2026, 7, 11);
  return AppUser(
    uid: 'resident-1',
    firstName: 'Test',
    lastName: 'Resident',
    email: 'test@example.com',
    phoneNumber: '+60123456789',
    emailVerified: true,
    phoneVerified: true,
    role: AppConstants.roleResident,
    verificationStatus: verified
        ? AppConstants.verificationVerified
        : AppConstants.verificationPending,
    profileImageUrl: '',
    communityId: 'community-1',
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

ChatModel _chat({required int unreadForCurrentUser}) {
  final now = DateTime(2026, 7, 11);
  return ChatModel(
    id: 'chat-1',
    participantIds: const ['resident-1', 'resident-2'],
    communityId: 'community-1',
    connectionId: 'chat-1',
    participantNames: const {'resident-1': 'Test', 'resident-2': 'Neighbor'},
    participantImageUrls: const {'resident-1': '', 'resident-2': ''},
    lastMessageText: 'Hello',
    lastMessageType: AppConstants.chatMessageText,
    lastMessageAt: now,
    lastSenderId: 'resident-2',
    unreadCounts: {'resident-1': unreadForCurrentUser, 'resident-2': 0},
    deletedFor: const [],
    createdAt: now,
    updatedAt: now,
  );
}
