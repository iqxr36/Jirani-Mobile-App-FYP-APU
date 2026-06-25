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

