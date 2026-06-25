import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/shared/models/chat_message_model.dart';

class PinnedChatMessage {
  const PinnedChatMessage({
    required this.messageId,
    required this.senderId,
    required this.senderName,
    required this.type,
    required this.text,
    required this.mediaUrl,
    required this.fileName,
    required this.createdAt,
  });

  final String messageId;
  final String senderId;
  final String senderName;
  final String type;
  final String text;
  final String mediaUrl;
  final String fileName;
  final DateTime createdAt;

  String get previewText => ChatMessageModel.previewFor(
    type: type,
    text: text,
    fileName: fileName,
  );

  factory PinnedChatMessage.fromMessage(
    ChatMessageModel message, {
    required String senderName,
  }) {
    return PinnedChatMessage(
      messageId: message.id,
      senderId: message.senderId,
      senderName: senderName,
      type: message.type,
      text: message.text,
      mediaUrl: message.mediaUrl,
      fileName: message.fileName,
      createdAt: message.createdAt,
    );
  }

  factory PinnedChatMessage.fromMap(Map<String, dynamic> data) {
    return PinnedChatMessage(
      messageId: (data['messageId'] as String?) ?? '',
      senderId: (data['senderId'] as String?) ?? '',
      senderName: (data['senderName'] as String?) ?? '',
      type: (data['type'] as String?) ?? AppConstants.chatMessageText,
      text: (data['text'] as String?) ?? '',
      mediaUrl: (data['mediaUrl'] as String?) ?? '',
      fileName: (data['fileName'] as String?) ?? '',
      createdAt: _parseDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'senderId': senderId,
      'senderName': senderName,
      'type': type,
      'text': text,
      'mediaUrl': mediaUrl,
      'fileName': fileName,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
