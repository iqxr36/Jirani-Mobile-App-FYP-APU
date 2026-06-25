part of '../chat_service.dart';

mixin _ChatServiceQueriesMixin on _ChatServiceBase {
  Stream<List<ChatModel>> watchChats(AppUser currentUser) {
    final currentUserId = currentUser.uid;
    final communityId = currentUser.communityId.trim();
    // #region agent log
    unawaited(
      agentDebugLog(
        runId: 'pre-fix',
        hypothesisId: 'H3',
        location: 'lib/services/chat_service.dart:34',
        message: 'Starting chat inbox Firestore query',
        data: <String, Object?>{
          'currentUserId': agentDebugId(currentUserId),
          'queryField': 'participantLookup.<uid>',
          'communityId': agentDebugId(communityId),
          'collection': AppConstants.chatsCollection,
        },
      ),
    );
    // #endregion
    return _chats
        .where('participantLookup.$currentUserId', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final chats = snapshot.docs
              .map((doc) => ChatModel.fromMap(doc.id, doc.data()))
              .where(
                (chat) =>
                    chat.communityId == communityId &&
                    !chat.isDeletedFor(currentUserId),
              )
              .toList(growable: false);
          chats.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          return chats;
        });
  }

  Stream<List<ChatMessageModel>> watchMessages(
    String chatId,
    String currentUserId,
  ) {
    return _chats
        .doc(chatId)
        .collection(AppConstants.messagesCollection)
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ChatMessageModel.fromMap(doc.id, doc.data()))
              .where((message) => !message.isDeletedFor(currentUserId))
              .toList(growable: false);
        });
  }
}
