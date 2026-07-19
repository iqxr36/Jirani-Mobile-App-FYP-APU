// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : chat_service_messages.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Friday,26-June-2026
// Last Edited on  : Saturday,18-July-2026

part of '../chat_service.dart';

mixin _ChatServiceMessagesMixin on _ChatServiceBase {
  /// Chat messages: sends a text message and optional reply metadata.
  Future<void> sendTextMessage({
    required ChatModel chat,
    required AppUser sender,
    required String text,
    ChatMessageModel? replyTo,
  }) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return;
    final lengthError = Validators.validateMaxLength(
      cleanText,
      maxLength: AppConstants.maxLongTextLength,
      fieldName: 'Message',
    );
    if (lengthError != null) {
      throw Exception(lengthError);
    }
    await _sendMessage(
      chat: chat,
      sender: sender,
      type: AppConstants.chatMessageText,
      text: cleanText,
      replyTo: _replyFromMessage(chat: chat, message: replyTo),
    );
  }

  /// Chat attachments: uploads image/file data to Storage, then sends the attachment message document.
  Future<void> sendAttachmentMessage({
    required ChatModel chat,
    required AppUser sender,
    Uint8List? bytes,
    String? localFilePath,
    required String fileName,
    required String type,
    required int fileSize,
    ChatMessageModel? replyTo,
  }) async {
    if (bytes == null && (localFilePath == null || localFilePath.isEmpty)) {
      throw Exception('Attachment file data is missing.');
    }

    final cleanFileName = fileName.trim().isEmpty
        ? 'attachment'
        : p.basename(fileName.trim());
    final messageDoc = _chats
        .doc(chat.id)
        .collection(AppConstants.messagesCollection)
        .doc();
    final extension = p.extension(cleanFileName);
    final storagePath =
        '${AppConstants.storageChatAttachmentsPath}/${chat.id}/${sender.uid}/${messageDoc.id}$extension';
    final mimeType = lookupMimeType(cleanFileName, headerBytes: bytes);
    final ref = _storage.ref(storagePath);
    final metadata = SettableMetadata(
      contentType: mimeType ?? 'application/octet-stream',
      customMetadata: {
        'chatId': chat.id,
        'senderId': sender.uid,
        'fileName': cleanFileName,
      },
    );

    try {
      final path = localFilePath;
      if (path != null && path.isNotEmpty) {
        await ref.putFile(File(path), metadata);
      } else {
        await ref.putData(bytes!, metadata);
      }
    } catch (error) {
      rethrow;
    }
    final url = await ref.getDownloadURL();

    await _sendMessage(
      chat: chat,
      sender: sender,
      type: type,
      text: type == AppConstants.chatMessageImage ? 'Photo' : cleanFileName,
      mediaUrl: url,
      storagePath: storagePath,
      fileName: cleanFileName,
      mimeType: mimeType ?? '',
      fileSize: fileSize,
      messageId: messageDoc.id,
      replyTo: _replyFromMessage(chat: chat, message: replyTo),
    );
  }

  /// Chat pinning: saves a message snapshot on the chat document so both users see it pinned.
  Future<void> pinMessage({
    required ChatModel chat,
    required AppUser user,
    required ChatMessageModel message,
  }) {
    validateChatAccess(chat: chat, sender: user);
    final pinned = PinnedChatMessage.fromMessage(
      message,
      senderName: chat.participantName(message.senderId),
    );
    return _chats.doc(chat.id).update({
      'pinnedMessage': pinned.toMap(),
      'pinnedBy': user.uid,
      'pinnedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Chat pinning: clears pinned message metadata from the chat document.
  Future<void> unpinMessage({
    required ChatModel chat,
    required AppUser user,
  }) {
    validateChatAccess(chat: chat, sender: user);
    return _chats.doc(chat.id).update({
      'pinnedMessage': FieldValue.delete(),
      'pinnedBy': FieldValue.delete(),
      'pinnedAt': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Chat messages: hides one message for one user without deleting it for the other participant.
  Future<void> deleteMessageForUser({
    required ChatModel chat,
    required String messageId,
    required String userId,
  }) async {
    if (!chat.participantIds.contains(userId)) {
      throw Exception('You are not a participant in this chat.');
    }

    final messageRef = _chats
        .doc(chat.id)
        .collection(AppConstants.messagesCollection)
        .doc(messageId);

    try {
      final snapshot = await messageRef.get();
      if (!snapshot.exists) {
        throw Exception('Message not found.');
      }

      final existing = _stringListFrom(snapshot.data()?['deletedFor']);
      if (existing.contains(userId)) return;

      await messageRef.update({
        'deletedFor': <String>[...existing, userId],
      });
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
          'Unable to delete this message. Please try again later.',
        );
      }
      rethrow;
    }
  }

  /// Chat read receipts: clears unread count and marks recent incoming messages read by the current user.
  Future<void> markChatRead({
    required ChatModel chat,
    required String currentUserId,
  }) async {
    final chatRef = _chats.doc(chat.id);
    try {
      await chatRef.update({'unreadCounts.$currentUserId': 0});
    } catch (error) {
      rethrow;
    }

    final unreadMessages = await chatRef
        .collection(AppConstants.messagesCollection)
        .orderBy('createdAt', descending: true)
        .limit(30)
        .get();
    final batch = _firestore.batch();
    for (final doc in unreadMessages.docs) {
      final data = doc.data();
      if (data['senderId'] == currentUserId) continue;
      final readBy = data['readBy'];
      if (readBy is List && readBy.contains(currentUserId)) continue;
      batch.update(doc.reference, {
        'readBy': FieldValue.arrayUnion([currentUserId]),
      });
    }
    await batch.commit();
  }

  /// Chat messages: writes the message and updates chat preview/unread counters in one Firestore batch.
  Future<void> _sendMessage({
    required ChatModel chat,
    required AppUser sender,
    required String type,
    required String text,
    String mediaUrl = '',
    String storagePath = '',
    String fileName = '',
    String mimeType = '',
    int fileSize = 0,
    String? messageId,
    ChatMessageReply? replyTo,
  }) async {
    validateChatAccess(chat: chat, sender: sender);

    final recipientId = chat.otherParticipantId(sender.uid);
    if (recipientId.isEmpty) {
      throw Exception('Unable to find the chat recipient.');
    }

    final chatRef = _chats.doc(chat.id);
    final messageRef = messageId == null
        ? chatRef.collection(AppConstants.messagesCollection).doc()
        : chatRef.collection(AppConstants.messagesCollection).doc(messageId);
    final now = FieldValue.serverTimestamp();
    final batch = _firestore.batch();

    batch.set(messageRef, {
      'chatId': chat.id,
      'senderId': sender.uid,
      'type': type,
      'text': text,
      'mediaUrl': mediaUrl,
      'storagePath': storagePath,
      'fileName': fileName,
      'mimeType': mimeType,
      'fileSize': fileSize,
      'createdAt': now,
      'readBy': <String>[sender.uid],
      'deletedFor': <String>[],
      ..._replyFields(replyTo),
    });

    batch.update(chatRef, {
      'lastMessageText': _previewText(type: type, text: text),
      'lastMessageType': type,
      'lastMessageAt': now,
      'lastSenderId': sender.uid,
      'updatedAt': now,
      'unreadCounts.${sender.uid}': 0,
      'unreadCounts.$recipientId': FieldValue.increment(1),
    });

    try {
      await batch.commit();
    } catch (error) {
      rethrow;
    }
    // Chat message notifications are created server-side by Cloud Functions.
  }
}
