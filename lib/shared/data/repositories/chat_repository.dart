// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : chat_repository.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Wednesday,24-June-2026
// Last Edited on  : Saturday,18-July-2026

import 'dart:typed_data';

import 'package:jirani/shared/models/app_user.dart';
import 'package:jirani/shared/models/chat_message_model.dart';
import 'package:jirani/shared/models/chat_model.dart';
import 'package:jirani/shared/services/chat_service.dart';

// Chat data layer: exposes chat use cases to providers while keeping Firestore/storage details inside ChatService.
class ChatRepository {
  ChatRepository({ChatService? service}) : _service = service ?? ChatService();

  final ChatService _service;

  // Chat feature: streams the current resident's inbox conversations.
  Stream<List<ChatModel>> watchChats(AppUser currentUser) {
    return _service.watchChats(currentUser);
  }

  // Chat feature: streams visible messages for one chat and filters messages deleted for this user.
  Stream<List<ChatMessageModel>> watchMessages(
    String chatId,
    String currentUserId,
  ) {
    return _service.watchMessages(chatId, currentUserId);
  }

  // Chat feature: opens an existing one-to-one chat or creates it with a deterministic chat id.
  Future<ChatModel> openOrCreateChat({
    required AppUser currentUser,
    required AppUser neighbor,
  }) {
    return _service.openOrCreateChat(
      currentUser: currentUser,
      neighbor: neighbor,
    );
  }

  // Chat feature: sends a plain text chat message.
  Future<void> sendTextMessage({
    required ChatModel chat,
    required AppUser sender,
    required String text,
    ChatMessageModel? replyTo,
  }) {
    return _service.sendTextMessage(
      chat: chat,
      sender: sender,
      text: text,
      replyTo: replyTo,
    );
  }

  // Chat feature: uploads and sends a chat attachment message.
  Future<void> sendAttachmentMessage({
    required ChatModel chat,
    required AppUser sender,
    Uint8List? bytes,
    String? localFilePath,
    required String fileName,
    required String type,
    required int fileSize,
    ChatMessageModel? replyTo,
  }) {
    return _service.sendAttachmentMessage(
      chat: chat,
      sender: sender,
      bytes: bytes,
      localFilePath: localFilePath,
      fileName: fileName,
      type: type,
      fileSize: fileSize,
      replyTo: replyTo,
    );
  }

  // Chat feature: clears unread count for the current user in a conversation.
  Future<void> markChatRead({
    required ChatModel chat,
    required String currentUserId,
  }) {
    return _service.markChatRead(chat: chat, currentUserId: currentUserId);
  }

  // Chat feature: hides a conversation only from the current resident's inbox.
  Future<void> deleteChatForUser({
    required ChatModel chat,
    required String currentUserId,
  }) {
    return _service.deleteChatForUser(chat: chat, currentUserId: currentUserId);
  }

  // Geofence/community feature: archives chats that no longer belong to the resident's selected community.
  Future<void> archiveChatsOutsideCommunity({
    required String uid,
    required String communityId,
  }) {
    return _service.archiveChatsOutsideCommunity(
      uid: uid,
      communityId: communityId,
    );
  }

  // Report feature: forwards chat report details and message snapshots to the reports collection.
  Future<void> reportChat({
    required ChatModel chat,
    required AppUser reporter,
    required String category,
    required String note,
    List<ChatMessageModel> reportedMessages = const [],
    bool reportEntireConversation = false,
  }) {
    return _service.reportChat(
      chat: chat,
      reporter: reporter,
      category: category,
      note: note,
      reportedMessages: reportedMessages,
      reportEntireConversation: reportEntireConversation,
    );
  }

  // Chat feature: pins a message on a conversation.
  Future<void> pinMessage({
    required ChatModel chat,
    required AppUser user,
    required ChatMessageModel message,
  }) {
    return _service.pinMessage(chat: chat, user: user, message: message);
  }

  // Chat feature: removes the pinned message from a conversation.
  Future<void> unpinMessage({
    required ChatModel chat,
    required AppUser user,
  }) {
    return _service.unpinMessage(chat: chat, user: user);
  }

  // Chat feature: hides one message for one user without deleting the shared message document.
  Future<void> deleteMessageForUser({
    required ChatModel chat,
    required String messageId,
    required String userId,
  }) {
    return _service.deleteMessageForUser(
      chat: chat,
      messageId: messageId,
      userId: userId,
    );
  }
}
