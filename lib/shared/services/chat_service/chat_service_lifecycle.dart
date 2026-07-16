part of '../chat_service.dart';

mixin _ChatServiceLifecycleMixin on _ChatServiceBase {
  /// Chat lifecycle: opens an existing one-to-one chat or creates it after validating both residents.
  Future<ChatModel> openOrCreateChat({
    required AppUser currentUser,
    required AppUser neighbor,
  }) async {
    _validateParticipants(currentUser: currentUser, neighbor: neighbor);
    final chatId = ChatModel.chatId(currentUser.uid, neighbor.uid);
    final doc = _chats.doc(chatId);
    final now = FieldValue.serverTimestamp();

    final baseData = <String, dynamic>{
      'participantIds': <String>[currentUser.uid, neighbor.uid]..sort(),
      'communityId': currentUser.communityId,
      'connectionId': chatId,
      'participantNames': <String, String>{
        currentUser.uid: _displayName(currentUser),
        neighbor.uid: _displayName(neighbor),
      },
      'participantImageUrls': <String, String>{
        currentUser.uid: currentUser.profileImageUrl,
        neighbor.uid: neighbor.profileImageUrl,
      },
      'participantLookup': <String, bool>{
        currentUser.uid: true,
        neighbor.uid: true,
      },
      'updatedAt': now,
    };

    try {
      final snapshot = await doc.get();
      if (snapshot.exists) {
        await doc.update({
          ...baseData,
          'deletedFor': FieldValue.arrayRemove([currentUser.uid]),
        });
      } else {
        await doc.set({
          ...baseData,
          'lastMessageText': '',
          'lastMessageType': AppConstants.chatMessageText,
          'lastMessageAt': null,
          'lastSenderId': '',
          'unreadCounts': <String, int>{currentUser.uid: 0, neighbor.uid: 0},
          'deletedFor': <String>[],
          'createdAt': now,
        });
      }
    } catch (error) {
      rethrow;
    }

    final created = await doc.get();
    return ChatModel.fromMap(created.id, created.data() ?? const {});
  }

  /// Chat lifecycle: hides a chat for one user without deleting it for the other participant.
  Future<void> deleteChatForUser({
    required ChatModel chat,
    required String currentUserId,
  }) {
    return _chats.doc(chat.id).update({
      'deletedFor': FieldValue.arrayUnion([currentUserId]),
      'unreadCounts.$currentUserId': 0,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Community change cleanup: hides chats that no longer belong to the resident's selected community.
  Future<void> archiveChatsOutsideCommunity({
    required String uid,
    required String communityId,
  }) async {
    final targetCommunityId = communityId.trim();
    final snapshot = await _chats
        .where('participantLookup.$uid', isEqualTo: true)
        .get();

    final batch = _firestore.batch();
    var hasUpdates = false;
    for (final doc in snapshot.docs) {
      final chat = ChatModel.fromMap(doc.id, doc.data());
      if (chat.communityId.trim() == targetCommunityId ||
          chat.isDeletedFor(uid)) {
        continue;
      }
      batch.update(doc.reference, {
        'deletedFor': FieldValue.arrayUnion([uid]),
        'unreadCounts.$uid': 0,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      hasUpdates = true;
    }

    if (hasUpdates) {
      await batch.commit();
    }
  }
}
