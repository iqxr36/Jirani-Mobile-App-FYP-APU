import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' as chat_core;
import 'package:jirani/core/constants/app_constants.dart';

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

  bool get isImage => type == AppConstants.chatMessageImage;
  bool get isFile => type == AppConstants.chatMessageFile;
  bool get isText => type == AppConstants.chatMessageText;

  chat_core.Message toChatMessage({required String currentUserId}) {
    final seenByOther = readBy.any((id) => id != senderId);
    final status = senderId == currentUserId && seenByOther
        ? chat_core.MessageStatus.seen
        : chat_core.MessageStatus.sent;

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
        metadata: {'storagePath': storagePath},
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
        metadata: {'storagePath': storagePath},
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
    );
  }

  factory ChatMessageModel.fromMap(String id, Map<String, dynamic> data) {
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
