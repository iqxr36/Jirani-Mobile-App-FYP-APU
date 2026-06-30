part of '../chat_service.dart';

mixin _ChatServiceReportsMixin on _ChatServiceBase {
  /// Chat reports: creates an admin report for a conversation or selected messages with immutable message snapshots.
  Future<void> reportChat({
    required ChatModel chat,
    required AppUser reporter,
    required String category,
    required String note,
    List<ChatMessageModel> reportedMessages = const [],
    bool reportEntireConversation = false,
  }) {
    final reportedUserId = chat.otherParticipantId(reporter.uid);
    final reportedUserName = chat.participantName(reportedUserId);
    final snapshots = reportedMessages
        .map(
          (message) => ReportedChatMessageSnapshot.fromMessage(
            message,
            senderName: chat.participantName(message.senderId),
          ),
        )
        .toList(growable: false);
    final title = reportEntireConversation || snapshots.isEmpty
        ? 'Chat conversation reported'
        : 'Chat message reported';
    final description = buildChatReportDescription(
      category: category,
      note: note,
      reportedMessages: snapshots,
    );
    final evidenceImageUrl = snapshots
        .where(
          (message) =>
              message.type == AppConstants.chatMessageImage &&
              message.mediaUrl.trim().isNotEmpty,
        )
        .map((message) => message.mediaUrl.trim())
        .firstOrNull;
    final now = FieldValue.serverTimestamp();
    return _reports.add({
      'type': AppConstants.reportTypeUserMisconduct,
      'status': AppConstants.reportStatusOpen,
      'title': title,
      'description': description,
      'reporterId': reporter.uid,
      'reporterName': reporter.fullName,
      'reportedUserId': reportedUserId,
      'reportedUserName': reportedUserName,
      'chatId': chat.id,
      'reportCategory': category,
      'reportedMessageIds': snapshots.map((message) => message.messageId).toList(),
      'reportedMessages': snapshots.map((message) => message.toMap()).toList(),
      'relatedBorrowRequestId': '',
      'itemId': '',
      if (evidenceImageUrl != null) 'evidenceImageUrl': evidenceImageUrl,
      'communityId': reporter.communityId,
      'communityName': reporter.communityName,
      'createdAt': now,
      'updatedAt': now,
    });
  }
}
