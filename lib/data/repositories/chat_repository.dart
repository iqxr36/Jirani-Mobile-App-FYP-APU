import 'dart:typed_data';

import 'package:jirani/shared/models/app_user.dart';
import 'package:jirani/shared/models/chat_message_model.dart';
import 'package:jirani/shared/models/chat_model.dart';
import 'package:jirani/services/chat_service.dart';

class ChatRepository {
  ChatRepository({ChatService? service}) : _service = service ?? ChatService();

  final ChatService _service;

  Stream<List<ChatModel>> watchChats(AppUser currentUser) {
    return _service.watchChats(currentUser);
  }

  Stream<List<ChatMessageModel>> watchMessages(String chatId) {
    return _service.watchMessages(chatId);
  }

  Future<ChatModel> openOrCreateChat({
    required AppUser currentUser,
    required AppUser neighbor,
  }) {
    return _service.openOrCreateChat(
      currentUser: currentUser,
      neighbor: neighbor,
    );
  }

  Future<void> sendTextMessage({
    required ChatModel chat,
    required AppUser sender,
    required String text,
  }) {
    return _service.sendTextMessage(chat: chat, sender: sender, text: text);
  }

  Future<void> sendAttachmentMessage({
    required ChatModel chat,
    required AppUser sender,
    Uint8List? bytes,
    String? localFilePath,
    required String fileName,
    required String type,
    required int fileSize,
  }) {
    return _service.sendAttachmentMessage(
      chat: chat,
      sender: sender,
      bytes: bytes,
      localFilePath: localFilePath,
      fileName: fileName,
      type: type,
      fileSize: fileSize,
    );
  }

  Future<void> markChatRead({
    required ChatModel chat,
    required String currentUserId,
  }) {
    return _service.markChatRead(chat: chat, currentUserId: currentUserId);
  }

  Future<void> deleteChatForUser({
    required ChatModel chat,
    required String currentUserId,
  }) {
    return _service.deleteChatForUser(chat: chat, currentUserId: currentUserId);
  }

  Future<void> reportChat({
    required ChatModel chat,
    required AppUser reporter,
    required String reason,
  }) {
    return _service.reportChat(chat: chat, reporter: reporter, reason: reason);
  }
}
