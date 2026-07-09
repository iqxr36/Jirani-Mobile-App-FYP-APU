import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/shared/models/reported_chat_message_snapshot.dart';
import 'package:jirani/shared/utils/display_labels.dart';

String chatReportCategoryLabel(String category) {
  return switch (category) {
    AppConstants.chatReportCategoryHarassment => 'Harassment / abusive language',
    AppConstants.chatReportCategoryScam => 'Scam / suspicious offer',
    AppConstants.chatReportCategoryThreat => 'Threatening behavior',
    AppConstants.chatReportCategorySpam => 'Spam',
    AppConstants.chatReportCategoryOther => 'Other',
    _ => lookupDisplayLabel(category),
  };
}

String buildChatReportDescription({
  required String category,
  required String note,
  required List<ReportedChatMessageSnapshot> reportedMessages,
}) {
  final buffer = StringBuffer('Category: ${chatReportCategoryLabel(category)}');
  final trimmedNote = note.trim();
  if (trimmedNote.isNotEmpty) {
    buffer.writeln();
    buffer.writeln();
    buffer.write('Resident note: $trimmedNote');
  }
  if (reportedMessages.isEmpty) {
    buffer.writeln();
    buffer.writeln();
    buffer.write('No specific message was attached to this report.');
    return buffer.toString();
  }
  buffer.writeln();
  buffer.writeln();
  buffer.writeln(
    reportedMessages.length == 1
        ? 'Reported message:'
        : 'Reported messages:',
  );
  for (final message in reportedMessages) {
    buffer.writeln();
    buffer.write(
      '"${message.displayBody}" — ${message.senderName}, '
      '${_formatTimestamp(message.sentAt)}',
    );
  }
  return buffer.toString();
}

String _formatTimestamp(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '${value.year}-$month-$day $hour:$minute';
}
