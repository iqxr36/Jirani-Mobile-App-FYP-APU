// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : chat_thread_helpers.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Friday,26-June-2026
// Last Edited on  : Saturday,18-July-2026

part of '../resident_chat_thread_view.dart';

ChatMessageReply? _replyFromMessageMetadata(Map<String, Object?>? metadata) {
  if (metadata == null) return null;
  final messageId = metadata['replyToMessageId']?.toString() ?? '';
  if (messageId.isEmpty) return null;
  return ChatMessageReply(
    messageId: messageId,
    senderId: metadata['replyToSenderId']?.toString() ?? '',
    senderName: metadata['replyToSenderName']?.toString() ?? '',
    type: metadata['replyToType']?.toString() ?? AppConstants.chatMessageText,
    text: metadata['replyToText']?.toString() ?? '',
  );
}

