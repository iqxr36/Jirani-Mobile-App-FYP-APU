part of '../chat_service.dart';

mixin _ChatServiceQueriesMixin on _ChatServiceBase {
  /// Chat inbox: streams visible chats for the current resident within their selected community.
  Stream<List<ChatModel>> watchChats(AppUser currentUser) {
    final currentUserId = currentUser.uid;
    final communityId = currentUser.communityId.trim();
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

  /// Chat thread: streams visible messages for one chat, excluding messages deleted for the current user.
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
