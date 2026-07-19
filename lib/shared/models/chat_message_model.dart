// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : chat_message_model.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Tuesday,16-June-2026
// Last Edited on  : Saturday,18-July-2026

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' as chat_core;
import 'package:jirani/core/constants/app_constants.dart';

/// Chat DB model: stores a lightweight quoted-message snapshot for replies.
class ChatMessageReply {
  const ChatMessageReply({
    required this.messageId,
    required this.senderId,
    required this.senderName,
    required this.type,
    required this.text,
  });

  final String messageId;
  final String senderId;
  final String senderName;
  final String type;
  final String text;

  /// Chat replies: reads reply metadata saved on a chat message document.
  factory ChatMessageReply.fromMap(Map<String, dynamic> data) {
    return ChatMessageReply(
      messageId: (data['messageId'] as String?) ?? '',
      senderId: (data['senderId'] as String?) ?? '',
      senderName: (data['senderName'] as String?) ?? '',
      type: (data['type'] as String?) ?? AppConstants.chatMessageText,
      text: (data['text'] as String?) ?? '',
    );
  }

  /// Chat replies: serializes reply metadata when sending a message that quotes another message.
  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'senderId': senderId,
      'senderName': senderName,
      'type': type,
      'text': text,
    };
  }
}

/// Chat DB model: represents chats/{chatId}/messages/{messageId}, including text, image, file, read, delete, and reply data.
class ChatMessageModel {
  const ChatMessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.type,
    required this.text,
    required this.mediaUrl,
    required this.storagePath,
    required this.fileName,
    required this.mimeType,
    required this.fileSize,
    required this.createdAt,
    required this.readBy,
    required this.deletedFor,
    this.replyTo,
  });

  final String id;
  final String chatId;
  final String senderId;
  final String type;
  final String text;
  final String mediaUrl;
  final String storagePath;
  final String fileName;
  final String mimeType;
  final int fileSize;
  final DateTime createdAt;
  final List<String> readBy;
  final List<String> deletedFor;
  final ChatMessageReply? replyTo;

  bool get isImage => type == AppConstants.chatMessageImage;
  bool get isFile => type == AppConstants.chatMessageFile;
  bool get isText => type == AppConstants.chatMessageText;

  bool isDeletedFor(String userId) => deletedFor.contains(userId);

  /// Chat feature: returns the inbox preview text for text, image, and file messages.
  String get previewText => previewFor(type: type, text: text, fileName: fileName);

  /// Chat feature: formats a safe preview for notifications, pinned messages, and chat lists.
  static String previewFor({
    required String type,
    required String text,
    required String fileName,
  }) {
    if (type == AppConstants.chatMessageImage) {
      return text.trim().isEmpty ? 'Photo' : text.trim();
    }
    if (type == AppConstants.chatMessageFile) {
      return fileName.trim().isEmpty ? 'Attachment' : fileName.trim();
    }
    final body = text.trim();
    return body.isEmpty ? 'Message' : body;
  }

  /// Chat replies: converts reply data into metadata understood by the Flutter chat UI package.
  Map<String, Object?> _replyMetadata() {
    final reply = replyTo;
    if (reply == null) return const {};
    return {
      'replyToMessageId': reply.messageId,
      'replyToSenderId': reply.senderId,
      'replyToSenderName': reply.senderName,
      'replyToType': reply.type,
      'replyToText': reply.text,
    };
  }

  /// Chat UI adapter: converts the Firestore message model into flutter_chat_core message objects.
  chat_core.Message toChatMessage({required String currentUserId}) {
    final seenByOther = readBy.any((id) => id != senderId);
    final status = senderId == currentUserId && seenByOther
        ? chat_core.MessageStatus.seen
        : chat_core.MessageStatus.sent;
    final metadata = _replyMetadata();

    if (isImage) {
      return chat_core.Message.image(
        id: id,
        authorId: senderId,
        createdAt: createdAt,
        sentAt: createdAt,
        seenAt: seenByOther ? createdAt : null,
        status: status,
        source: mediaUrl,
        text: text.isEmpty ? null : text,
        size: fileSize == 0 ? null : fileSize,
        metadata: {
          'storagePath': storagePath,
          ...metadata,
        },
      );
    }

    if (isFile) {
      return chat_core.Message.file(
        id: id,
        authorId: senderId,
        createdAt: createdAt,
        sentAt: createdAt,
        seenAt: seenByOther ? createdAt : null,
        status: status,
        source: mediaUrl,
        name: fileName.isEmpty ? 'Attachment' : fileName,
        size: fileSize == 0 ? null : fileSize,
        mimeType: mimeType.isEmpty ? null : mimeType,
        metadata: {
          'storagePath': storagePath,
          ...metadata,
        },
      );
    }

    return chat_core.Message.text(
      id: id,
      authorId: senderId,
      createdAt: createdAt,
      sentAt: createdAt,
      seenAt: seenByOther ? createdAt : null,
      status: status,
      text: text,
      metadata: metadata,
    );
  }

  /// Chat DB model: converts a Firestore message document into the app message model.
  factory ChatMessageModel.fromMap(String id, Map<String, dynamic> data) {
    final replyId = (data['replyToMessageId'] as String?) ?? '';
    final reply = replyId.trim().isEmpty
        ? null
        : ChatMessageReply(
            messageId: replyId,
            senderId: (data['replyToSenderId'] as String?) ?? '',
            senderName: (data['replyToSenderName'] as String?) ?? '',
            type:
                (data['replyToType'] as String?) ??
                AppConstants.chatMessageText,
            text: (data['replyToText'] as String?) ?? '',
          );
    return ChatMessageModel(
      id: id,
      chatId: (data['chatId'] as String?) ?? '',
      senderId: (data['senderId'] as String?) ?? '',
      type: (data['type'] as String?) ?? AppConstants.chatMessageText,
      text: (data['text'] as String?) ?? '',
      mediaUrl: (data['mediaUrl'] as String?) ?? '',
      storagePath: (data['storagePath'] as String?) ?? '',
      fileName: (data['fileName'] as String?) ?? '',
      mimeType: (data['mimeType'] as String?) ?? '',
      fileSize: _parseInt(data['fileSize']),
      createdAt: _parseDate(data['createdAt']),
      readBy: _toStringList(data['readBy']),
      deletedFor: _toStringList(data['deletedFor']),
      replyTo: reply,
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  static List<String> _toStringList(dynamic value) {
    if (value is List) {
      return value
          .map((entry) => entry?.toString() ?? '')
          .where((entry) => entry.isNotEmpty)
          .toList(growable: false);
    }
    return const <String>[];
  }
}
