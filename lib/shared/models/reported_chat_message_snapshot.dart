// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : reported_chat_message_snapshot.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Thursday,25-June-2026
// Last Edited on  : Saturday,18-July-2026

import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/shared/models/chat_message_model.dart';

/// Reports DB model: immutable snapshot of a chat message captured when a resident reports chat misconduct.
class ReportedChatMessageSnapshot {
  const ReportedChatMessageSnapshot({
    required this.messageId,
    required this.senderId,
    required this.senderName,
    required this.type,
    required this.text,
    required this.mediaUrl,
    required this.fileName,
    required this.sentAt,
  });

  final String messageId;
  final String senderId;
  final String senderName;
  final String type;
  final String text;
  final String mediaUrl;
  final String fileName;
  final DateTime sentAt;

  /// Chat reports: captures a message and sender name before storing it in reports/{reportId}.
  factory ReportedChatMessageSnapshot.fromMessage(
    ChatMessageModel message, {
    required String senderName,
  }) {
    return ReportedChatMessageSnapshot(
      messageId: message.id,
      senderId: message.senderId,
      senderName: senderName,
      type: message.type,
      text: message.text,
      mediaUrl: message.mediaUrl,
      fileName: message.fileName,
      sentAt: message.createdAt,
    );
  }

  /// Chat reports: reads a stored reported-message snapshot from Firestore.
  factory ReportedChatMessageSnapshot.fromMap(Map<String, dynamic> data) {
    return ReportedChatMessageSnapshot(
      messageId: (data['messageId'] as String?) ?? '',
      senderId: (data['senderId'] as String?) ?? '',
      senderName: (data['senderName'] as String?) ?? '',
      type: (data['type'] as String?) ?? AppConstants.chatMessageText,
      text: (data['text'] as String?) ?? '',
      mediaUrl: (data['mediaUrl'] as String?) ?? '',
      fileName: (data['fileName'] as String?) ?? '',
      sentAt: _parseDate(data['sentAt']),
    );
  }

  /// Chat reports: serializes the snapshot into report data for admin review.
  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'senderId': senderId,
      'senderName': senderName,
      'type': type,
      'text': text,
      'mediaUrl': mediaUrl,
      'fileName': fileName,
      'sentAt': sentAt.toIso8601String(),
    };
  }

  /// Chat reports UI: renders readable text for reported text, image, or file messages.
  String get displayBody {
    if (type == AppConstants.chatMessageImage) {
      return text.trim().isEmpty ? '[Image attachment]' : text.trim();
    }
    if (type == AppConstants.chatMessageFile) {
      final name = fileName.trim().isEmpty ? 'Attachment' : fileName.trim();
      return '[File: $name]';
    }
    final body = text.trim();
    return body.isEmpty ? '[Empty message]' : body;
  }

  static DateTime _parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
